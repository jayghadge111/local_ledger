import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import_progress.dart';
import '../../core/sync/sync_controller.dart';
import '../../core/theme/app_theme.dart';
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

/// One import's card. Small by default — name, percentage, a thin bar and
/// Stop/Resume on a single line — because a first scan can run for minutes and
/// the full card (steps, counts, hints) took too much of the screen. The
/// chevron opens it up.
class _JobCard extends StatefulWidget {
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
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final job = widget.job;
    final name = widget.name;
    final progress = job.progress ?? const ImportProgress('Preparing…');
    final running = job.running;
    final fraction = progress.fraction;
    final percent = fraction == null ? null : (fraction * 100).floor();

    final title = running
        ? (job.stopping
              ? 'Stopping $name…'
              : (job.background
                    ? 'Checking $name for new emails'
                    : 'Syncing $name'))
        : '$name sync paused';

    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 10),
        child: LayoutBuilder(
          builder: (context, box) {
            // Resume sits beside the title when there is room for it (about
            // 340 logical px of card at normal text size), and under it on a
            // narrow screen or with large text, where it would not fit.
            final inlineResume = !running && box.maxWidth / scale >= 340;
            return Column(
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
                        title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (percent != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          '$percent%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (running)
                      TextButton(
                        onPressed: job.stopping ? null : widget.onStop,
                        style: dangerTextButtonStyle(context),
                        child: const Text('Stop'),
                      )
                    else if (inlineResume)
                      FilledButton(
                        onPressed: widget.onResume,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Resume'),
                      ),
                    IconButton(
                      tooltip: _expanded ? 'Hide details' : 'Show details',
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                    ),
                  ],
                ),
                // Resume sits under the title, not beside it: with a percentage and
                // the chevron it does not fit a narrow screen or large text.
                if (!running && !inlineResume)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10, bottom: 8),
                      child: FilledButton(
                        onPressed: widget.onResume,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Resume'),
                      ),
                    ),
                  ),
                // The thin bar is the whole progress display while collapsed; the
                // expanded view has its own full-size one.
                if (!_expanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.outline,
                        color: ChartColors.of(context).accent,
                      ),
                    ),
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImportProgressView(progress: progress),
                              if (running && !job.stopping)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Keeps going if you leave this page.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                              if (!running)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.onDismiss,
                                    child: const Text('Dismiss'),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
