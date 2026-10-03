import 'package:flutter/material.dart';

import '../../core/import_progress.dart';

/// Progress bar plus plain-language status for a running import: the
/// current step, "done of total · left", and transactions found so far.
class ImportProgressView extends StatelessWidget {
  const ImportProgressView({super.key, required this.progress});

  final ImportProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final fraction = progress.fraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(progress.phase, style: theme.textTheme.bodyMedium)),
            if (fraction != null)
              Text(
                '${(fraction * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        if (progress.total > 0)
          Text('${progress.done} of ${progress.total} checked · ${progress.remaining} left', style: muted),
        if (progress.found > 0)
          Text(
            '${progress.found} transaction${progress.found == 1 ? '' : 's'} added so far',
            style: muted,
          ),
      ],
    );
  }
}
