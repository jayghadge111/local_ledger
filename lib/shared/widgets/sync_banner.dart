import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_controller.dart';
import 'glass_surface.dart';
import 'import_progress_view.dart';

/// A live "syncing" strip shown at the top of the app while a Gmail or SMS
/// import is running — wherever the user is. Disappears when it ends.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);

    final jobs = [
      if (sync.gmail.running && sync.gmail.progress != null)
        ('Gmail', sync.gmail.progress!),
      if (sync.sms.running && sync.sms.progress != null)
        ('SMS', sync.sms.progress!),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: jobs.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  for (final (name, progress) in jobs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Syncing $name',
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '· keeps going if you leave this page',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ImportProgressView(progress: progress),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
