import '../../shared/widgets/text_button_styles.dart';
import '../../core/ui/undo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/db/rules_repository.dart';
import '../../shared/widgets/category_icons.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rulesAsync = ref.watch(rulesProvider);
    final categoriesById = {
      for (final c in ref.watch(categoriesProvider).value ?? []) c.id: c,
    };

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Category rules')),
        body: rulesAsync.when(
          data: (rules) {
            if (rules.isEmpty) {
              return const PlaceholderBody(
                icon: Icons.rule_outlined,
                title: 'No rules yet',
                subtitle: 'Add a rule so a merchant name is categorized automatically next time — e.g. "swiggy" → Food & dining.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: rules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final rule = rules[i];
                final category = categoriesById[rule.categoryId];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 25 * i),
                  child: GlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Icon(
                            iconForKey(category?.icon),
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${rule.pattern}"',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                '→ ${category?.name ?? 'Unknown category'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete rule',
                          color: dangerColor(context),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final undo = await ref
                                .read(rulesRepositoryProvider)
                                .deleteRule(rule.id);
                            showUndoSnackBar('Rule removed', undo);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load rules: $e')),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add rule',
          onPressed: () => _showAddRuleDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _showAddRuleDialog(BuildContext context, WidgetRef ref) async {
    final patternController = TextEditingController();
    String? categoryId;
    final categories = ref.read(categoriesProvider).value ?? [];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add category rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patternController,
                decoration: const InputDecoration(
                  labelText: 'Merchant contains',
                  hintText: 'e.g. swiggy',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (value) => setDialogState(() => categoryId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pattern = patternController.text.trim();
                if (pattern.isEmpty || categoryId == null) return;
                await ref
                    .read(rulesRepositoryProvider)
                    .addRule(pattern: pattern, categoryId: categoryId!);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
