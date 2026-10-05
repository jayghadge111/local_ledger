import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sms/parser_templates.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/text_button_styles.dart';

/// What the parser has learned from the user's corrections — and a way to
/// forget it.
class LearnedLayoutsScreen extends ConsumerWidget {
  const LearnedLayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final count = ref.watch(parserTemplateCountProvider).value ?? 0;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Learned message layouts')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0
                        ? 'Nothing learned yet'
                        : '$count layout${count == 1 ? '' : 's'} learned',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you fix a transaction that came from a bank message, or add one from “Messages to review”, '
                    'NativeSpend remembers how that message was laid out — where the amount and the payee sit — so the '
                    'next message like it is read correctly on its own. It also remembers messages you chose to ignore '
                    'when deleting a transaction, so they stop appearing.\n\n'
                    'Layouts are stored encrypted on this device and never leave it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: dangerTextButtonStyle(context),
                      onPressed: () async {
                        await ref.read(parserTemplateStoreProvider).clearAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot all learned layouts'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Forget everything learned'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
