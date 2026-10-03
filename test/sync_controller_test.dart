import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/sms/sms_import_service.dart';
import 'package:local_ledger/core/sms/sms_providers.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/core/ui/root_messenger.dart';
import 'package:local_ledger/shared/widgets/sync_banner.dart';

/// A scan the test drives by hand: reports progress, then waits to be released.
class _FakeSms implements SmsImportService {
  final release = Completer<SmsImportResult>();
  late ImportProgressCallback report;

  @override
  bool get isSupported => true;

  @override
  Future<bool> get hasPermission async => true;

  @override
  Future<DateTime?> lastSyncedAt() async => null;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<SmsImportResult> importFromInbox({
    ImportProgressCallback? onProgress,
  }) {
    report = onProgress!;
    onProgress(const ImportProgress('Reading', done: 10, total: 100));
    return release.future;
  }

  @override
  Future<SmsImportResult?> syncIfDue({
    bool force = false,
    ImportProgressCallback? onProgress,
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
        overrides: [smsImportServiceProvider.overrideWithValue(fake)],
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
}
