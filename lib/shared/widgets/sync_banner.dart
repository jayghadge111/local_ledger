import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import_progress.dart';
import '../../core/sync/sync_controller.dart';
import 'glass_surface.dart';
import 'import_progress_view.dart';
import 'text_button_styles.dart';

/// A live "syncing" strip shown at the top of the app while a Gmail or SMS
/// import is running — wherever the user is — with a Stop button. A stopped
/// or interrupted import stays here with Resume / Dismiss until dealt with.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);

    final cards = <Widget>[
      if (sync.gmail.running || sync.gmail.canResume)
        _JobCard(
          name: 'Gmail',
          job: sync.gmail,
          onStop: controller.stopGmail,
          onResume: controller.resumeGmail,
          onDismiss: controller.dismissGmail,
        ),
      if (sync.sms.running || sync.sms.canResume)
        _JobCard(
          name: 'SMS',
          job: sync.sms,
          onStop: controller.stopSms,
          onResume: controller.resumeSms,
          onDismiss: controller.dismissSms,
        ),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: cards.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(children: cards),
            ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.name,
    required this.job,
    required this.onStop,
    required this.onResume,
    required this.onDismiss,
  });

  final String name;
  final SyncJob job;
  final VoidCallback onStop;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final progress = job.progress ?? const ImportProgress('Preparing…');
    final running = job.running;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (running)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 18,
                    color: muted,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    running
                        ? (job.stopping ? 'Stopping $name…' : 'Syncing $name')
                        : '$name sync paused',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (running)
                  TextButton(
                    onPressed: job.stopping ? null : onStop,
                    style: dangerTextButtonStyle(context),
                    child: const Text('Stop'),
                  )
                else ...[
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  FilledButton(
                    onPressed: onResume,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Resume'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ImportProgressView(progress: progress),
            ),
            if (running && !job.stopping)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Keeps going if you leave this page.',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
