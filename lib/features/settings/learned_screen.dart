import '../../shared/widgets/text_button_styles.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/rules_repository.dart';
import '../../core/sms/parser_templates.dart';
import '../../core/ui/undo.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../import_review/learned_layouts_screen.dart';

/// The names the user taught the app ("SWIGGY*ORDER" is "Swiggy").
final merchantAliasesProvider = StreamProvider<List<MerchantAliase>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.merchantAliases,
  )..orderBy([(a) => OrderingTerm.asc(a.pattern)])).watch();
});

/// Everything NativeSpend has learned from the user's corrections, in one
/// place, each item removable (with Undo): merchant names, categories and
/// message layouts. The app learns by being corrected; this is how to take a
/// lesson back.
class LearnedScreen extends ConsumerWidget {
  const LearnedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aliases = ref.watch(merchantAliasesProvider).value ?? const [];
    final rules = [
      for (final r in ref.watch(rulesProvider).value ?? const <Rule>[])
        if (r.source == 'user') r,
    ];
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c.name,
    };
    final layouts = ref.watch(parserTemplateCountProvider).value ?? 0;
    final db = ref.read(databaseProvider);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget section(String title, String help, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(help, style: muted),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: children.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Nothing yet.', style: muted),
                )
              : Column(children: children),
        ),
      ],
    );

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('What the app learned')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              'NativeSpend learns when you fix something: a merchant name, a '
              'category, a message it misread. Everything stays on this phone. '
              'Remove a lesson here and the app goes back to its own guess.',
              style: muted,
            ),
            section(
              'Merchant names',
              'How a name in a bank message is shown.',
              [
                for (final a in aliases)
                  ListTile(
                    title: Text(a.displayName),
                    subtitle: Text('from “${a.pattern}”'),
                    trailing: IconButton(
                      tooltip: 'Forget',
                      color: dangerColor(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        await (db.delete(
                          db.merchantAliases,
                        )..where((x) => x.id.equals(a.id))).go();
                        showUndoSnackBar('Forgot “${a.displayName}”', () async {
                          await db
                              .into(db.merchantAliases)
                              .insertOnConflictUpdate(a);
                        });
                      },
                    ),
                  ),
              ],
            ),
            section(
              'Categories',
              'Merchants you filed under a category.',
              [
                for (final r in rules)
                  ListTile(
                    title: Text('“${r.pattern}”'),
                    subtitle: Text(
                      '→ ${categories[r.categoryId] ?? 'Unknown category'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Forget',
                      color: dangerColor(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final undo = await ref
                            .read(rulesRepositoryProvider)
                            .deleteRule(r.id);
                        showUndoSnackBar('Forgot “${r.pattern}”', undo);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LearnedLayoutsScreen()),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message layouts',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          layouts == 0
                              ? 'How bank messages are read — nothing learned yet'
                              : '$layouts learned',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
