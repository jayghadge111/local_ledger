import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/sync/import_checkpoints.dart';
import 'package:local_ledger/core/permissions/app_permissions.dart';
import 'package:local_ledger/core/sms/sms_import_service.dart';
import 'package:local_ledger/core/sms/sms_providers.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/core/ui/root_messenger.dart';
import 'package:local_ledger/shared/widgets/sync_banner.dart';

/// The copy taken before a scan is its own feature (see local_snapshots_test);
/// here it must not get in the way.
class _NoSnapshots implements SnapshotService {
  @override
  Future<SnapshotInfo?> snapshot(String reason) async => null;
  @override
  Future<bool> restore(SnapshotInfo snapshot) async => false;
  @override
  bool delete(SnapshotInfo snapshot) => false;
}

/// A scan the test drives by hand: reports progress, then waits to be released.
class _FakeSms implements SmsImportService {
  final release = Completer<SmsImportResult>();
  late ImportProgressCallback report;
  ImportCancelToken? token;
  bool? resumed;

  @override
  bool get isSupported => true;

  @override
  Future<bool> get hasPermission async => true;

  @override
  Future<DateTime?> lastSyncedAt() async => null;

  @override
  Future<PermissionState> requestPermission() async => PermissionState.granted;

  @override
  Future<SmsImportResult> importFromInbox({
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
    bool resume = false,
  }) {
    token = cancel;
    resumed = resume;
    report = onProgress!;
    onProgress(const ImportProgress('Reading', done: 10, total: 100));
    return release.future;
  }

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

void main() {
  testWidgets(
    'a scan outlives the screen that started it, shows a banner, and announces the end',
    (tester) async {
      final fake = _FakeSms();
      final container = ProviderContainer(
        overrides: [
          smsImportServiceProvider.overrideWithValue(fake),
          snapshotServiceProvider.overrideWithValue(_NoSnapshots()),
        ],
      );
      addTearDown(container.dispose);

      // The "Settings page" is just a reader of state; the shell shows the banner.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            scaffoldMessengerKey: rootMessengerKey,
            home: const Scaffold(body: SyncBanner()),
          ),
        ),
      );
      expect(find.text('Syncing SMS'), findsNothing);

      final started = container
          .read(syncControllerProvider.notifier)
          .startSms();
      await tester.pump();
      await tester.pump();
      expect(container.read(syncControllerProvider).sms.running, isTrue);
      expect(find.text('Syncing SMS'), findsOneWidget);

      // More progress arrives while no settings widget exists at all.
      fake.report(
        const ImportProgress('Reading', done: 60, total: 100, found: 7),
      );
      await tester.pump();
      expect(container.read(syncControllerProvider).sms.progress!.done, 60);

      // A second tap while running is ignored — no restart from zero.
      await container.read(syncControllerProvider.notifier).startSms();
      expect(container.read(syncControllerProvider).sms.progress!.done, 60);

      fake.release.complete(const SmsImportResult(scanned: 100, imported: 7));
      await started;
      await tester.pump();

      final state = container.read(syncControllerProvider);
      expect(state.sms.status, SyncStatus.succeeded);
      expect(state.sms.message, contains('added 7 transactions'));
      expect(find.text('Syncing SMS'), findsNothing);
      expect(
        find.text('SMS sync complete — added 7 transactions'),
        findsOneWidget,
      );
    },
  );

  test('onboarding may continue once running imports pass 25%', () {
    SyncState withProgress(ImportProgress? p) => SyncState(
      sms: SyncJob(status: SyncStatus.running, progress: p),
    );

    expect(canLeaveOnboarding(const SyncState()), isTrue);
    expect(
      canLeaveOnboarding(withProgress(const ImportProgress('Signing in'))),
      isFalse,
    );
    expect(
      canLeaveOnboarding(
        withProgress(const ImportProgress('r', done: 24, total: 100)),
      ),
      isFalse,
    );
    expect(
      canLeaveOnboarding(
        withProgress(const ImportProgress('r', done: 25, total: 100)),
      ),
      isTrue,
    );
    expect(
      syncPercent(
        withProgress(const ImportProgress('r', done: 37, total: 100)),
      ),
      37,
    );

    // Two imports: the slower one decides.
    const both = SyncState(
      gmail: SyncJob(
        status: SyncStatus.running,
        progress: ImportProgress('r', done: 90, total: 100),
      ),
      sms: SyncJob(
        status: SyncStatus.running,
        progress: ImportProgress('r', done: 10, total: 100),
      ),
    );
    expect(canLeaveOnboarding(both), isFalse);
    expect(syncPercent(both), 10);
  });

  group('stop and resume', () {
    late AppDatabase db;
    late _FakeSms fake;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      fake = _FakeSms();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          smsImportServiceProvider.overrideWithValue(fake),
          snapshotServiceProvider.overrideWithValue(_NoSnapshots()),
        ],
      );
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    SmsCheckpoint checkpoint() => SmsCheckpoint(
      beforeMillis: 1000,
      done: 40,
      total: 100,
      found: 3,
      startedAt: DateTime.now(),
      savedAt: DateTime.now(),
    );

    test(
      'Stop hands the import a cancelled token and leaves it resumable',
      () async {
        final controller = container.read(syncControllerProvider.notifier);
        final run = controller.startSms();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(syncControllerProvider).sms.running, isTrue);

        controller.stopSms();
        expect(fake.token!.isCancelled, isTrue);
        expect(container.read(syncControllerProvider).sms.stopping, isTrue);

        // The import notices, saves where it got to, and reports cancelled.
        await CheckpointStore(SettingsRepository(db)).saveSms(checkpoint());
        fake.release.complete(
          const SmsImportResult(scanned: 40, imported: 3, cancelled: true),
        );
        await run;

        final job = container.read(syncControllerProvider).sms;
        expect(job.status, SyncStatus.paused);
        expect(job.canResume, isTrue);
        expect(job.progress!.done, 40);
        expect(job.message, contains('added 3 so far'));
      },
    );

    test('Resume asks the service to carry on from the checkpoint', () async {
      final controller = container.read(syncControllerProvider.notifier);
      final run = controller.resumeSms();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fake.resumed, isTrue);
      fake.release.complete(const SmsImportResult(scanned: 100, imported: 9));
      await run;
      expect(
        container.read(syncControllerProvider).sms.status,
        SyncStatus.succeeded,
      );
    });

    test('an import cut short by the app being killed is offered back on next start', () async {
      await CheckpointStore(SettingsRepository(db)).saveSms(checkpoint());
      await container.read(syncControllerProvider.notifier).checkInterrupted();

      final job = container.read(syncControllerProvider).sms;
      expect(job.paused, isTrue);
      expect(job.canResume, isTrue);
      expect(job.progress!.fraction, 0.4);
      // And it is not started automatically.
      expect(job.running, isFalse);
      expect(container.read(syncControllerProvider).gmail.canResume, isFalse);
    });

    test('Discard forgets the checkpoint', () async {
      final store = CheckpointStore(SettingsRepository(db));
      await store.saveSms(checkpoint());
      final controller = container.read(syncControllerProvider.notifier);
      await controller.checkInterrupted();
      await controller.dismissSms();
      expect(await store.sms(), isNull);
      expect(container.read(syncControllerProvider).sms.canResume, isFalse);
    });
  });

  test('checkpoints survive a round trip and go stale after a week', () {
    final gmail = GmailCheckpoint(
      doneIds: {'a', 'b'},
      total: 10,
      found: 2,
      savedAt: DateTime.now(),
    );
    final back = GmailCheckpoint.decode(gmail.encode())!;
    expect(back.doneIds, {'a', 'b'});
    expect(back.total, 10);
    expect(back.found, 2);

    final old = GmailCheckpoint(
      doneIds: {'a'},
      total: 1,
      found: 0,
      savedAt: DateTime.now().subtract(const Duration(days: 8)),
    );
    expect(GmailCheckpoint.decode(old.encode()), isNull);
    expect(GmailCheckpoint.decode('not json'), isNull);
    expect(SmsCheckpoint.decode(null), isNull);
  });
}
