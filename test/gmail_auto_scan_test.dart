import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/core/email/email_providers.dart';
import 'package:local_ledger/core/email/gmail_auth_service.dart';
import 'package:local_ledger/core/email/gmail_import_service.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/sync/connectivity.dart';
import 'package:local_ledger/core/sync/import_checkpoints.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/core/ui/root_messenger.dart';

/// Stands in for the Gmail import: records what it was asked and answers as
/// told. It never touches Google.
class _FakeGmail implements GmailImportService {
  int calls = 0;
  DateTime? since;
  EmailImportResult? result = const EmailImportResult(scanned: 0, imported: 0);
  bool nothing = false;
  Object? error;

  @override
  Future<EmailImportResult?> importSince(
    DateTime s, {
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
  }) async {
    calls++;
    since = s;
    if (error != null) throw error!;
    return nothing ? null : result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _FakeGmail gmail;
  late ProviderContainer container;
  var online = true;

  SettingsRepository settings() => SettingsRepository(db);
  SyncController controller() =>
      container.read(syncControllerProvider.notifier);

  Future<void> connect({String account = 'me@example.com'}) =>
      settings().set(SettingsKeys.gmailAccount, account);

  setUp(() {
    online = true;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gmail = _FakeGmail();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        gmailImportServiceProvider.overrideWithValue(gmail),
        internetCheckProvider.overrideWithValue(() async => online),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('when it runs', () {
    test('not at all without a connected account', () async {
      await controller().syncGmailIfDue();
      expect(gmail.calls, 0);
    });

    test('not when the switch on the Gmail card is off', () async {
      await connect();
      await settings().set(SettingsKeys.gmailAutoScan, 'false');
      await controller().syncGmailIfDue();
      expect(gmail.calls, 0);
    });

    test('not while there is no internet', () async {
      await connect();
      online = false;
      await controller().syncGmailIfDue();
      expect(gmail.calls, 0);
    });

    test('not over a scan the user stopped and can resume', () async {
      await connect();
      await CheckpointStore(settings()).saveGmail(
        GmailCheckpoint(
          doneIds: {'a'},
          total: 10,
          found: 1,
          savedAt: DateTime.now(),
        ),
      );
      await controller().syncGmailIfDue();
      expect(gmail.calls, 0);
    });

    test('at most once in a few hours, unless forced', () async {
      await connect();
      await controller().syncGmailIfDue();
      await controller().syncGmailIfDue();
      expect(gmail.calls, 1);

      await settings().set(
        SettingsKeys.gmailLastAutoCheck,
        DateTime.now()
            .subtract(kGmailAutoGap + const Duration(minutes: 1))
            .toIso8601String(),
      );
      await controller().syncGmailIfDue();
      expect(gmail.calls, 2);

      await controller().syncGmailIfDue(force: true);
      expect(gmail.calls, 3);
    });
  });

  group('what it reads and records', () {
    test('only mail since the last finished scan', () async {
      await connect();
      final last = DateTime(2026, 10, 8, 9, 30);
      await settings().set(
        SettingsKeys.gmailLastScannedAt,
        last.toIso8601String(),
      );
      await controller().syncGmailIfDue();
      expect(gmail.since, last);
    });

    test(
      'with no record, a short look-back rather than the whole year',
      () async {
        await connect();
        await controller().syncGmailIfDue();
        final age = DateTime.now().difference(gmail.since!);
        expect(
          (age - kGmailCatchUpDefault).abs(),
          lessThan(const Duration(minutes: 1)),
        );
      },
    );

    test('a finished run moves the "last checked" time forward', () async {
      await connect();
      await controller().syncGmailIfDue();
      final saved = DateTime.parse(
        (await settings().get(SettingsKeys.gmailLastScannedAt))!,
      );
      expect(DateTime.now().difference(saved).inSeconds, lessThan(10));
      expect(container.read(syncControllerProvider).gmail.running, isFalse);
    });

    test('disconnecting forgets it', () async {
      await connect();
      await controller().syncGmailIfDue();
      await controller().disconnectGmail();
      expect(await settings().get(SettingsKeys.gmailLastScannedAt), isNull);
      expect(await settings().get(SettingsKeys.gmailLastAutoCheck), isNull);
    });
  });

  group('how it behaves on screen', () {
    testWidgets('says so when it found something, and only then', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.runAsync(connect);

      // Nothing new: no message.
      await tester.runAsync(controller().syncGmailIfDue);
      await tester.pump();
      expect(find.byType(SnackBar), findsNothing);

      // Something new: one line.
      gmail.result = const EmailImportResult(scanned: 3, imported: 2);
      await tester.runAsync(() => controller().syncGmailIfDue(force: true));
      await tester.pump();
      expect(find.text('From Gmail: 2 new transactions'), findsOneWidget);
    });

    test(
      'leaves the Gmail card as it was when it could not sign in quietly',
      () async {
        await connect();
        gmail.nothing = true;
        await controller().syncGmailIfDue();
        expect(
          container.read(syncControllerProvider).gmail.status,
          SyncStatus.idle,
        );
      },
    );

    test(
      'asks to reconnect, without a pop-up, when Google wants consent again',
      () async {
        await connect();
        gmail.error = const GmailAccessException('401');
        await controller().syncGmailIfDue();
        final job = container.read(syncControllerProvider).gmail;
        expect(job.failed, isTrue);
        expect(job.needsReconnect, isTrue);
      },
    );

    test('a hiccup leaves no trace and is not retried at once', () async {
      await connect();
      gmail.error = StateError('socket closed');
      await controller().syncGmailIfDue();
      expect(container.read(syncControllerProvider).gmail.failed, isFalse);
      await controller().syncGmailIfDue();
      expect(gmail.calls, 1);
    });
  });
}
