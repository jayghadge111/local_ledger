import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/diagnostics/app_guard.dart';
import 'package:local_ledger/core/diagnostics/diagnostic_log.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/email/email_providers.dart';
import 'package:local_ledger/core/email/gmail_auth_service.dart';
import 'package:local_ledger/core/sync/connectivity.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/permissions/app_permissions.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/sms_import_service.dart';
import 'package:local_ledger/core/sms/sms_providers.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/features/settings/widgets/diagnostics_card.dart';
import 'package:local_ledger/shared/widgets/permission_notice.dart';
import 'package:permission_handler/permission_handler.dart';

class _FlakyEncryption extends EncryptionService {
  _FlakyEncryption({this.failFirst = 0});
  int failFirst;
  @override
  Future<String> encryptString(String plainText) async {
    if (failFirst > 0) {
      failFirst--;
      throw StateError('keystore unavailable');
    }
    return 'enc:$plainText';
  }

  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

class _SmsNeedingSettings implements SmsImportService {
  _SmsNeedingSettings(this.result);
  final PermissionState result;

  @override
  bool get isSupported => true;
  @override
  Future<bool> get hasPermission async => false;
  @override
  Future<PermissionState> requestPermission() async => result;
  @override
  Future<DateTime?> lastSyncedAt() async => null;
  @override
  Future<SmsImportResult> importFromInbox({
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
    bool resume = false,
  }) => throw StateError('must not scan without permission');
  @override
  Future<SmsImportResult?> syncIfDue({
    bool force = false,
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
  }) async => null;
  @override
  Future<void> listenForNewMessages(
    void Function(SmsImportResult) onResult,
  ) async {}
}

class _NoSnapshots implements SnapshotService {
  @override
  Future<SnapshotInfo?> snapshot(String reason) async => null;
  @override
  Future<bool> restore(SnapshotInfo snapshot) async => false;
  @override
  bool delete(SnapshotInfo snapshot) => false;
}

class _AuthThrowing extends GmailAuthService {
  _AuthThrowing(this.error);
  final Object error;
  int calls = 0;
  @override
  Future<GoogleSignInAccount?> currentAccount() async => null;
  @override
  Future<GoogleSignInAccount> signInFresh() async {
    calls++;
    throw error;
  }
}

const _goodSms =
    'Rs 500 debited from A/c XX4921 on 05-OCT-26 to SHOP via UPI. Avl bal Rs 9,000.';
const _otherSms =
    'Rs 250.00 debited from A/c XX4921 on 06-OCT-26 to CAFE via UPI. Avl bal Rs 8,750.';

void main() {
  group('the diagnostic log', () {
    late Directory dir;
    late DiagnosticLog log;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('diag');
      log = DiagnosticLog.inDirectory(dir);
      await log.init();
    });
    tearDown(() => dir.delete(recursive: true));

    test('keeps what was recorded, newest first, across restarts', () async {
      log.record('flutter', StateError('first'), StackTrace.current);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      log.record('zone', StateError('second'), null, 'while testing');

      final reopened = DiagnosticLog.inDirectory(dir);
      await reopened.init();
      final list = await reopened.entries();
      expect(list.map((e) => e.message), [
        'Bad state: second',
        'Bad state: first',
      ]);
      expect(list.first.note, 'while testing');
      expect(list.last.stack, isNotNull);
    });

    test('errors that arrive before it is ready are not lost', () async {
      final early = DiagnosticLog.inDirectory(dir);
      early.record('zone', StateError('too early'));
      await early.init();
      expect((await early.entries()).single.message, contains('too early'));
    });

    test('what could identify the user is blanked out', () async {
      log.record(
        'ingest',
        FormatException(
          'bad text: Rs 12,450.00 debited from A/c XX4921 ref 99887766 '
          'by rahul.k@example.com',
        ),
      );
      final text = (await log.entries()).single.message;
      expect(text, isNot(contains('12,450')));
      expect(text, isNot(contains('4921')));
      expect(text, isNot(contains('99887766')));
      expect(text, isNot(contains('rahul')));
      expect(text, contains('bad text'));
    });

    test('the same error in a burst is written once', () async {
      for (var i = 0; i < 50; i++) {
        log.record('flutter', StateError('overflow'));
      }
      expect(await log.entries(), hasLength(1));
    });

    test('it stays small', () async {
      for (var i = 0; i < 400; i++) {
        log.record('zone', StateError('problem number $i ' 'x' * 600));
      }
      final list = await log.entries();
      expect(list.length, lessThanOrEqualTo(DiagnosticLog.maxEntries));
      expect(
        File('${dir.path}/diagnostics.jsonl').lengthSync(),
        lessThan(260 * 1024),
      );
      expect(list.first.message, contains('problem number 399'));
    });

    test('the report says what it holds and what it leaves out', () async {
      log.record('zone', StateError('boom'), StackTrace.current);
      final text = await log.report(extra: {'Build': 'test'});
      expect(text, contains('diagnostic log'));
      expect(text, contains('Build: test'));
      expect(text, contains('boom'));
      expect(text, contains('no transactions'));
    });

    test('clearing empties it', () async {
      log.record('zone', StateError('boom'));
      await log.clear();
      expect(await log.entries(), isEmpty);
    });

    test('a log that cannot be written never throws', () async {
      final blocked = File('${dir.path}/not-a-dir')..writeAsStringSync('x');
      final broken = DiagnosticLog.inDirectory(Directory(blocked.path));
      await broken.init();
      expect(() => broken.record('zone', StateError('x')), returnsNormally);
    });
  });

  group('error handlers', () {
    late Directory dir;
    late DiagnosticLog log;
    late FlutterExceptionHandler? savedFlutter;
    late bool Function(Object, StackTrace)? savedPlatform;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('diag');
      log = DiagnosticLog.inDirectory(dir);
      await log.init();
      savedFlutter = FlutterError.onError;
      savedPlatform = PlatformDispatcher.instance.onError;
    });
    tearDown(() async {
      FlutterError.onError = savedFlutter;
      PlatformDispatcher.instance.onError = savedPlatform;
      await dir.delete(recursive: true);
    });

    test('a framework error and an unawaited one both land in the log', () async {
      installErrorHandlers(log);
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('widget broke')),
      );
      final handled = PlatformDispatcher.instance.onError!(
        StateError('nobody awaited me'),
        StackTrace.current,
      );
      expect(handled, isTrue);

      final messages = (await log.entries()).map((e) => e.message).join('|');
      expect(messages, contains('widget broke'));
      expect(messages, contains('nobody awaited me'));
    });

    test('guarded() records and returns null instead of throwing', () async {
      final result = await guarded<int>('a thing', () async {
        throw StateError('nope');
      });
      expect(result, isNull);
      expect(await guarded<int>('fine', () async => 7), 7);
    });
  });

  group('one bad message does not stop the rest', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('a message that throws is set aside, and the next one is read',
        () async {
      // The keystore fails once: the first message can't be stored.
      final ingestor = TransactionIngestor(db, _FlakyEncryption(failFirst: 1));
      final session = await ingestor.begin();
      final first = await session.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: _goodSms,
        date: DateTime(2026, 10, 5, 10),
      );
      final second = await session.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: _otherSms,
        date: DateTime(2026, 10, 6, 10),
      );
      await session.finish();

      expect(first, IngestOutcome.queued);
      expect(second, IngestOutcome.imported);
      expect(session.failed, 1);
      expect(session.imported, 1);
      expect(await db.select(db.unparsedMessages).get(), hasLength(1));
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('even when it cannot be set aside, the import carries on', () async {
      final ingestor = TransactionIngestor(db, _FlakyEncryption(failFirst: 2));
      final session = await ingestor.begin();
      final first = await session.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: _goodSms,
        date: DateTime(2026, 10, 5, 10),
      );
      final second = await session.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: _otherSms,
        date: DateTime(2026, 10, 6, 10),
      );
      expect(first, IngestOutcome.failed);
      expect(second, IngestOutcome.imported);
      await session.finish();
    });
  });

  group('permissions', () {
    test('every plugin status maps to something the UI can act on', () {
      expect(
        mapPermissionStatus(PermissionStatus.granted),
        PermissionState.granted,
      );
      expect(
        mapPermissionStatus(PermissionStatus.limited),
        PermissionState.granted,
      );
      expect(
        mapPermissionStatus(PermissionStatus.denied),
        PermissionState.denied,
      );
      expect(
        mapPermissionStatus(PermissionStatus.permanentlyDenied),
        PermissionState.blocked,
      );
      expect(
        mapPermissionStatus(PermissionStatus.restricted),
        PermissionState.unavailable,
      );
    });

    test('a missing or broken plugin is reported, not thrown', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const service = PermissionService();
      expect(await service.status(AppPermission.sms), isA<PermissionState>());
      expect(await service.request(AppPermission.notifications),
          isA<PermissionState>());
      expect(await service.openSettings(), isA<bool>());
    });

    for (final (state, wantsSettings) in [
      (PermissionState.blocked, true),
      (PermissionState.denied, false),
    ]) {
      test('SMS $state on Scan: says so${wantsSettings ? ", offers settings" : ""}',
          () async {
        final container = ProviderContainer(
          overrides: [
            smsImportServiceProvider.overrideWithValue(
              _SmsNeedingSettings(state),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(syncControllerProvider.notifier).startSms();
        final job = container.read(syncControllerProvider).sms;
        expect(job.failed, isTrue);
        expect(job.needsSettings, wantsSettings);
        expect(job.message, isNotEmpty);
      });
    }

    testWidgets('the notice offers Allow, or Open settings once blocked',
        (tester) async {
      var allowed = 0;
      var opened = 0;
      Future<void> show(PermissionState s) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionNotice(
              state: s,
              message: 'SMS access is off.',
              onAllow: () => allowed++,
              onOpenSettings: () => opened++,
            ),
          ),
        ),
      );

      await show(PermissionState.denied);
      await tester.tap(find.text('Allow'));
      expect((allowed, opened), (1, 0));

      await show(PermissionState.blocked);
      expect(find.text('Allow'), findsNothing);
      await tester.tap(find.text('Open settings'));
      expect((allowed, opened), (1, 1));
    });
  });

  group('Gmail failures are explained', () {
    test('access taken away', () {
      expect(
        describeGmailFailure(const GmailAccessException('401')),
        contains('Connect Gmail'),
      );
    });
    test('no network', () {
      expect(
        describeGmailFailure(const SocketException('x')),
        contains('internet'),
      );
      expect(
        describeGmailFailure(TimeoutException('slow')),
        contains('internet'),
      );
    });
    test('sign-in problems', () {
      expect(
        describeGmailFailure(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.interrupted,
          ),
        ),
        contains('interrupted'),
      );
      expect(
        describeGmailFailure(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        ),
        contains("isn't set up"),
      );
    });
    test('anything else still says something', () {
      expect(describeGmailFailure(StateError('odd')), contains('odd'));
    });
  });

  group('Gmail never leaves the user staring at a spinner', () {
    ProviderContainer containerFor(_AuthThrowing auth, {required bool online}) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          gmailAuthServiceProvider.overrideWithValue(auth),
          internetCheckProvider.overrideWithValue(() async => online),
          snapshotServiceProvider.overrideWithValue(_NoSnapshots()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('no connection: says so at once, without asking Google', () async {
      final auth = _AuthThrowing(StateError('must not be reached'));
      final c = containerFor(auth, online: false);
      await c.read(syncControllerProvider.notifier).startGmail(fresh: true);
      final job = c.read(syncControllerProvider).gmail;
      expect(job.status, SyncStatus.failed);
      expect(job.message, contains('internet connection'));
      expect(job.needsReconnect, isFalse);
      expect(auth.calls, 0);
    });

    test('access taken away: offers to reconnect', () async {
      final auth = _AuthThrowing(const GmailAccessException('401'));
      final c = containerFor(auth, online: true);
      await c.read(syncControllerProvider.notifier).startGmail(fresh: false);
      final job = c.read(syncControllerProvider).gmail;
      expect(job.status, SyncStatus.failed);
      expect(job.needsReconnect, isTrue);
      expect(job.message, contains('Connect Gmail'));
    });

    test('a network error mid-way is also explained', () async {
      final auth = _AuthThrowing(const SocketException('gone'));
      final c = containerFor(auth, online: true);
      await c.read(syncControllerProvider.notifier).startGmail(fresh: true);
      final job = c.read(syncControllerProvider).gmail;
      expect(job.message, contains('internet connection'));
      expect(job.needsReconnect, isFalse);
    });
  });

  testWidgets('Settings → Email diagnostic log shows the count and the buttons',
      (tester) async {
    late Directory dir;
    late DiagnosticLog log;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('diag');
      log = DiagnosticLog.inDirectory(dir);
      await log.init();
      log.record('zone', StateError('boom'));
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DiagnosticsCard(log: log)),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    expect(find.text('1 problem noted.'), findsOneWidget);
    expect(find.text('Email diagnostic log'), findsOneWidget);

    expect(find.text('Clear'), findsOneWidget);
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
