import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../core/db/settings_repository.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/glass_switch_row.dart';
import '../../../shared/widgets/import_progress_view.dart';
import '../../../shared/widgets/text_button_styles.dart';

/// Connect / scan Gmail. The import itself runs in [SyncController], so it
/// keeps going if the user leaves this page; this card just reflects it.
class EmailConnectCard extends ConsumerStatefulWidget {
  const EmailConnectCard({super.key});

  @override
  ConsumerState<EmailConnectCard> createState() => _EmailConnectCardState();
}

class _EmailConnectCardState extends ConsumerState<EmailConnectCard> {
  @override
  void initState() {
    super.initState();
    // Purely informational ("Connected as …") — nothing is imported.
    Future.microtask(
      () => ref.read(syncControllerProvider.notifier).restoreGmailAccount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final job = sync.gmail;
    final working = job.running;
    final email = sync.gmailAccount;
    final connected = email != null;

    Widget spinnerOr(IconData icon) => working
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gmail import', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Finds bank alert emails in your Gmail and adds them as transactions. '
            'Read-only: your emails are never changed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (connected) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected as $email',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            StreamBuilder<String?>(
              stream: ref
                  .read(settingsRepositoryProvider)
                  .watch(SettingsKeys.gmailLastScannedAt),
              builder: (context, snapshot) {
                final at = DateTime.tryParse(snapshot.data ?? '');
                if (at == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4, left: 26),
                  child: Text(
                    'Last checked ${DateFormat.MMMd().add_jm().format(at)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            StreamBuilder<String?>(
              stream: ref
                  .read(settingsRepositoryProvider)
                  .watch(SettingsKeys.gmailAutoScan),
              builder: (context, snapshot) => GlassSwitchRow(
                label: 'Check for new bank emails when the app opens',
                value: snapshot.data != 'false',
                onChanged: (v) => ref
                    .read(settingsRepositoryProvider)
                    .set(SettingsKeys.gmailAutoScan, v.toString()),
              ),
            ),
            Text(
              'Reads only new bank emails, at most every few hours, and only '
              'while you are connected. Nothing is changed in your mailbox.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!connected)
            FilledButton.icon(
              onPressed: working
                  ? null
                  : () => controller.startGmail(fresh: true),
              icon: spinnerOr(Icons.mail_outline),
              label: Text(working ? 'Working…' : 'Connect Gmail'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: working
                      ? null
                      : () => controller.startGmail(fresh: false),
                  icon: spinnerOr(Icons.sync_rounded),
                  label: Text(working ? 'Working…' : 'Scan now'),
                ),
                OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () => controller.startGmail(fresh: true),
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch account'),
                ),
                TextButton(
                  onPressed: working ? null : controller.disconnectGmail,
                  style: dangerTextButtonStyle(context),
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          if (working && job.progress != null) ...[
            const SizedBox(height: 14),
            ImportProgressView(progress: job.progress!),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.stopping ? 'Stopping…' : 'You can leave this page — the sync keeps running in the background.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: job.stopping ? null : controller.stopGmail,
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
                  onPressed: controller.resumeGmail,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
                TextButton(
                  onPressed: controller.dismissGmail,
                  style: dangerTextButtonStyle(context),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ],
          if (job.message != null && !working) ...[
            const SizedBox(height: 14),
            ImportResultNote(ok: !job.failed, text: job.message!),
            if (job.failed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      controller.startGmail(fresh: job.needsReconnect || !connected),
                  icon: Icon(
                    job.needsReconnect
                        ? Icons.link_rounded
                        : Icons.refresh_rounded,
                  ),
                  label: Text(
                    job.needsReconnect ? 'Reconnect Gmail' : 'Try again',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
