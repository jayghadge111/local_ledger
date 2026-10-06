import '../../../shared/widgets/text_button_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../shared/widgets/import_progress_view.dart';
import '../../../shared/widgets/glass_switch_row.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/permission_notice.dart';

/// Scan SMS and tune auto-sync. The import itself runs in [SyncController],
/// so it keeps going if the user leaves this page; this card just reflects it.
class SmsConnectCard extends ConsumerWidget {
  const SmsConnectCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final job = ref.watch(syncControllerProvider).sms;
    final scanning = job.running;
    final permission = ref.watch(permissionsProvider)[AppPermission.sms];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMS import (Android)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Finds bank alert messages on your phone and adds them as transactions. '
            'Everything stays on this phone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<String?>(
            stream: ref
                .read(settingsRepositoryProvider)
                .watch(SettingsKeys.smsLastSyncedAt),
            builder: (context, snapshot) {
              final last = snapshot.data == null
                  ? null
                  : DateTime.tryParse(snapshot.data!);
              // Access that worked before and is now off (revoked in system
              // settings), or one the system has stopped asking about.
              final off =
                  permission == PermissionState.blocked ||
                  (permission == PermissionState.denied && last != null);
              final notice = off
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PermissionNotice(
                        state: permission!,
                        message: 'SMS access is off, so new bank messages are not being picked up.',
                        onAllow: () => ref
                            .read(permissionsProvider.notifier)
                            .request(AppPermission.sms),
                        onOpenSettings: () => ref
                            .read(permissionsProvider.notifier)
                            .openSettings(),
                      ),
                    )
                  : const SizedBox.shrink();
              if (last == null) return notice;
              final stale =
                  DateTime.now().difference(last) > const Duration(days: 3);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  notice,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      stale
                          ? 'Last synced ${DateFormat.yMMMd().add_jm().format(last)} — opening the app catches up on anything missed.'
                          : 'Last synced ${DateFormat.yMMMd().add_jm().format(last)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stale
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          StreamBuilder<String?>(
            stream: ref
                .read(settingsRepositoryProvider)
                .watch(SettingsKeys.smsAutoSync),
            builder: (context, snapshot) => GlassSwitchRow(
              label: 'Sync automatically when the app opens',
              value: snapshot.data != 'false',
              onChanged: (v) => ref
                  .read(settingsRepositoryProvider)
                  .set(SettingsKeys.smsAutoSync, v.toString()),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: scanning
                ? null
                : ref.read(syncControllerProvider.notifier).startSms,
            icon: scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(scanning ? 'Scanning…' : 'Scan SMS inbox'),
          ),
          if (scanning && job.progress != null) ...[
            const SizedBox(height: 14),
            ImportProgressView(progress: job.progress!),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.stopping ? 'Stopping…' : 'You can leave this page — the scan keeps running in the background.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: job.stopping
                      ? null
                      : ref.read(syncControllerProvider.notifier).stopSms,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
          if (job.canResume) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: ref
                      .read(syncControllerProvider.notifier)
                      .resumeSms,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
                TextButton(
                  onPressed: ref
                      .read(syncControllerProvider.notifier)
                      .dismissSms,
                  style: dangerTextButtonStyle(context),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ],
          if (job.message != null && !scanning) ...[
            const SizedBox(height: 14),
            ImportResultNote(ok: !job.failed, text: job.message!),
            if (job.needsSettings)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(permissionsProvider.notifier).openSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open settings'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
