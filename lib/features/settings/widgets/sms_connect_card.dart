import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../shared/widgets/import_progress_view.dart';
import '../../../core/sms/sms_providers.dart';
import '../../../shared/widgets/glass_switch_row.dart';
import '../../../shared/widgets/glass_surface.dart';

/// Scan SMS and tune auto-sync. The import itself runs in [SyncController],
/// so it keeps going if the user leaves this page; this card just reflects it.
class SmsConnectCard extends ConsumerWidget {
  const SmsConnectCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final job = ref.watch(syncControllerProvider).sms;
    final scanning = job.running;
    final service = ref.read(smsImportServiceProvider);

    if (!service.isSupported) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMS import (Android)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Scans your SMS inbox for bank transaction alerts and adds any new ones. '
            'Parsing happens entirely on this device — the original message is stored '
            'encrypted, never sent anywhere.',
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
              if (last == null) return const SizedBox.shrink();
              final stale =
                  DateTime.now().difference(last) > const Duration(days: 3);
              return Padding(
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
            Text(
              'You can leave this page — the scan keeps running in the background.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (job.message != null && !scanning) ...[
            const SizedBox(height: 14),
            ImportResultNote(ok: !job.failed, text: job.message!),
          ],
        ],
      ),
    );
  }
}
