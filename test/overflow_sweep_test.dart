import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/permissions/app_permissions.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/features/onboarding/onboarding_connect_screen.dart';
import 'package:local_ledger/features/settings/learned_screen.dart';
import 'package:local_ledger/features/settings/widgets/backup_card.dart';
import 'package:local_ledger/features/settings/widgets/diagnostics_card.dart';
import 'package:local_ledger/features/settings/widgets/email_connect_card.dart';
import 'package:local_ledger/features/settings/widgets/message_tools_section.dart';
import 'package:local_ledger/features/settings/widgets/sms_connect_card.dart';
import 'package:local_ledger/shared/widgets/permission_notice.dart';
import 'package:local_ledger/shared/widgets/sync_banner.dart';

class _FixedSync extends SyncController {
  _FixedSync(this.fixed);
  final SyncState fixed;
  @override
  SyncState build() => fixed;
}

class _NoSnapshots implements SnapshotService {
  @override
  Future<SnapshotInfo?> snapshot(String reason) async => null;
  @override
  Future<bool> restore(SnapshotInfo snapshot) async => false;
  @override
  bool delete(SnapshotInfo snapshot) => false;
}

const _running = SyncJob(
  status: SyncStatus.running,
  progress: ImportProgress(
    'Reading bank emails',
    done: 624,
    total: 1000,
    found: 499,
  ),
);
const _stopping = SyncJob(
  status: SyncStatus.running,
  stopping: true,
  progress: ImportProgress('Reading bank emails', done: 6, total: 1000),
);
const _paused = SyncJob(
  status: SyncStatus.paused,
  resumable: true,
  progress: ImportProgress('Paused', done: 300, total: 1000, found: 120),
  message:
      'Stopped — added 120 so far. Tap Resume to carry on where it left off.',
);
const _failed = SyncJob(
  status: SyncStatus.failed,
  needsReconnect: true,
  message:
      'Google stopped letting NativeSpend read this Gmail account — access was removed or has expired. Tap Connect Gmail to sign in again. What was already read is saved.',
);
const _blocked = SyncJob(
  status: SyncStatus.failed,
  needsSettings: true,
  message:
      'SMS access is switched off for NativeSpend, so nothing was scanned. Turn on "SMS" under Permissions in the app\'s system settings, then come back and scan again.',
);

void main() {
  final states = <String, SyncState>{
    'idle': const SyncState(),
    'both running': const SyncState(gmail: _running, sms: _running),
    'stopping': const SyncState(gmail: _stopping, sms: _stopping),
    'paused': const SyncState(gmail: _paused, sms: _paused),
    'failed + connected': const SyncState(
      gmail: _failed,
      sms: _blocked,
      gmailAccount: 'a.very.long.email.address.for.testing@example-company.co.in',
    ),
  };

  final widgets = <String, Widget>{
    'sync banner': const SyncBanner(),
    'Gmail card': const EmailConnectCard(),
    'SMS card': const SmsConnectCard(),
    'onboarding import step': OnboardingConnectScreen(onDone: () {}),
    'permission notice': PermissionNotice(
      state: PermissionState.blocked,
      message:
          'SMS access is off, so new bank messages are not being picked up.',
      onAllow: () {},
      onOpenSettings: () {},
    ),
    'backup (file + automatic)': const BackupCard(),
    'diagnostics': const DiagnosticsCard(),
    'message tools': const MessageToolsSection(),
    'what the app learned': const LearnedScreen(),
  };

  // Whole screens manage their own scrolling.
  const fullScreens = {'onboarding import step', 'what the app learned'};

  widgets.forEach((name, widget) {
    states.forEach((stateName, state) {
      for (final width in [320.0, 360.0, 402.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('$name · $stateName · ${width.toInt()}px · ${scale}x', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width * 3, 874 * 3);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);
            final db = AppDatabase.forTesting(NativeDatabase.memory());
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  databaseProvider.overrideWithValue(db),
                  syncControllerProvider.overrideWith(() => _FixedSync(state)),
                  snapshotServiceProvider.overrideWithValue(_NoSnapshots()),
                ],
                child: MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: fullScreens.contains(name)
                      ? widget
                      : Scaffold(
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: widget,
                          ),
                        ),
                ),
              ),
            );
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)),
            );
            for (var i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 300));
            }
            expect(tester.takeException(), isNull);

            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(db.close);
          });
        }
      }
    });
  });
}
