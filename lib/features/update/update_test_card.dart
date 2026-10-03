import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/update_controller.dart';
import '../../shared/widgets/glass_surface.dart';

/// Debug builds only: pretend a new version exists so the in-app update flow
/// can be tried without a Google Play release. Shown from Settings, guarded by
/// `kDebugMode` where it is placed.
class UpdateTestCard extends ConsumerWidget {
  const UpdateTestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(updateControllerProvider.notifier);
    final stage = ref.watch(updateControllerProvider).stage;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test: in-app update', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Debug builds only. Google Play updates can only be tried from a Play release, so these buttons fake an '
            'available update and a download. The banner appears on Home.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => controller.simulate(),
                icon: const Icon(Icons.system_update_rounded),
                label: const Text('Update with % progress'),
              ),
              OutlinedButton(
                onPressed: () => controller.simulate(withProgress: false),
                child: const Text('Play-style (no %)'),
              ),
              OutlinedButton(
                onPressed: () => controller.simulate(failAtFraction: 0.5),
                child: const Text('Fail halfway'),
              ),
              if (stage != UpdateStage.none)
                TextButton(
                  onPressed: controller.stopSimulating,
                  child: const Text('Reset'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
