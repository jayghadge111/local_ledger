import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/update_controller.dart';
import '../../shared/widgets/glass_surface.dart';

/// "A new version is available" on Home: update, watch it download inside the
/// app, then restart to install. Hidden when there is nothing to offer.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: state.visible
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _Card(state: state),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(updateControllerProvider.notifier);
    final offer = state.offer;
    final label = offer?.label ?? 'New version';
    final important = offer?.isImportant ?? false;

    final (
      IconData icon,
      String title,
      String subtitle,
    ) = switch (state.stage) {
      UpdateStage.downloading => (
        Icons.downloading_rounded,
        'Downloading update…',
        'NativeSpend $label',
      ),
      UpdateStage.downloaded => (
        Icons.system_update_alt_rounded,
        'Update ready',
        'Restart NativeSpend to finish installing $label.',
      ),
      UpdateStage.installing => (
        Icons.autorenew_rounded,
        'Installing…',
        'NativeSpend will restart in a moment.',
      ),
      UpdateStage.installed => (
        Icons.check_circle_rounded,
        'Update installed',
        state.message ?? '',
      ),
      UpdateStage.failed => (
        Icons.error_outline_rounded,
        'Update failed',
        state.message ?? 'Something went wrong.',
      ),
      _ => (
        Icons.system_update_rounded,
        important ? 'Important update' : 'Update available',
        'NativeSpend $label is ready to download.',
      ),
    };

    final downloading = state.stage == UpdateStage.downloading;
    final working = downloading || state.stage == UpdateStage.installing;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.surface, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (offer?.simulated ?? false) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'TEST',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (working) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        // Null = indeterminate: used when the store doesn't say how far along it is.
                        value: downloading ? state.progress : null,
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (downloading && state.progress != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      '${(state.progress! * 100).round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (downloading) ...[
              const SizedBox(height: 6),
              Text(
                'You can keep using the app while it downloads.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: switch (state.stage) {
              UpdateStage.available => [
                if (!important)
                  TextButton(
                    onPressed: controller.dismiss,
                    child: const Text('Later'),
                  ),
                FilledButton(
                  onPressed: controller.start,
                  child: const Text('Update'),
                ),
              ],
              UpdateStage.downloaded => [
                FilledButton(
                  onPressed: controller.install,
                  child: const Text('Restart to install'),
                ),
              ],
              UpdateStage.failed => [
                TextButton(
                  onPressed: controller.clear,
                  child: const Text('Dismiss'),
                ),
                FilledButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ],
              UpdateStage.installed => [
                FilledButton(
                  onPressed: controller.clear,
                  child: const Text('Done'),
                ),
              ],
              _ => const <Widget>[],
            },
          ),
        ],
      ),
    );
  }
}
