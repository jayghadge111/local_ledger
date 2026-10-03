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
        label,
      ),
      UpdateStage.downloaded => (
        Icons.system_update_alt_rounded,
        'Update ready',
        'Restart to finish installing $label',
      ),
      UpdateStage.installing => (
        Icons.autorenew_rounded,
        'Installing…',
        'NativeSpend will restart shortly',
      ),
      UpdateStage.installed => (
        Icons.check_circle_rounded,
        'Update installed',
        state.message ?? '',
      ),
      UpdateStage.failed => (
        Icons.error_outline_rounded,
        'Update failed',
        state.message ?? 'Something went wrong',
      ),
      _ => (
        Icons.system_update_rounded,
        important ? 'Important update' : 'Update available',
        label,
      ),
    };

    final downloading = state.stage == UpdateStage.downloading;
    final working = downloading || state.stage == UpdateStage.installing;

    // Compact buttons that sit in the title row, so the card stays short.
    final filled = FilledButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final text = TextButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final actions = switch (state.stage) {
      UpdateStage.available => <Widget>[
        if (!important)
          TextButton(
            style: text,
            onPressed: controller.dismiss,
            child: const Text('Later'),
          ),
        FilledButton(
          style: filled,
          onPressed: controller.start,
          child: const Text('Update'),
        ),
      ],
      UpdateStage.downloaded => <Widget>[
        FilledButton(
          style: filled,
          onPressed: controller.install,
          child: const Text('Restart'),
        ),
      ],
      UpdateStage.failed => <Widget>[
        TextButton(
          style: text,
          onPressed: controller.clear,
          child: const Text('Dismiss'),
        ),
        FilledButton(
          style: filled,
          onPressed: controller.retry,
          child: const Text('Retry'),
        ),
      ],
      UpdateStage.installed => <Widget>[
        FilledButton(
          style: filled,
          onPressed: controller.clear,
          child: const Text('Done'),
        ),
      ],
      _ => const <Widget>[],
    };

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.onSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.surface, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (offer?.simulated ?? false) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
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
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 6),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
          if (working) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        // Null = indeterminate: used when the store doesn't say how far along it is.
                        value: downloading ? state.progress : null,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (downloading && state.progress != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      '${(state.progress! * 100).round()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
