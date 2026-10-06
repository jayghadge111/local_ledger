import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/rules_repository.dart';
import '../../core/obligations/obligation_repository.dart';
import '../budgets/budgets_screen.dart';
import '../obligations/obligations_screen.dart';
import '../rules/rules_screen.dart';
import 'manage_card.dart';

/// Budgets, auto-pay and category rules, each a card with a live one-line
/// summary. They sit in Settings, right after the SMS and Gmail connections.
class PlanningCards extends ConsumerWidget {
  const PlanningCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final budgets = ref.watch(
      monthBudgetsProvider(DateTime(now.year, now.month)),
    );
    final rules = ref.watch(rulesProvider).value ?? const <Rule>[];
    final upcomingDues = ref.watch(upcomingObligationsProvider);
    final mandates = ref.watch(activeMandatesProvider);
    final failedDebits = ref.watch(recentFailuresProvider);

    final items = <ManageItem>[
      ManageItem(
        icon: Icons.pie_chart_rounded,
        title: 'Budgets',
        subtitle: budgets.isEmpty
            ? 'Set a monthly limit for each category'
            : '${budgets.length} budget${budgets.length == 1 ? '' : 's'} set',
        screen: const BudgetsScreen(),
      ),
      ManageItem(
        icon: Icons.event_repeat_rounded,
        title: 'Auto-pay & dues',
        subtitle: failedDebits.isNotEmpty
            ? '${failedDebits.length} failed auto-debit${failedDebits.length == 1 ? '' : 's'} · fund your account'
            : upcomingDues.isEmpty && mandates.isEmpty
            ? 'Upcoming auto-debits, EMIs and card bills, from your bank messages'
            : '${upcomingDues.length} coming up · ${mandates.length} mandate${mandates.length == 1 ? '' : 's'}',
        badge: failedDebits.isEmpty ? null : failedDebits.length,
        screen: const ObligationsScreen(),
      ),
      ManageItem(
        icon: Icons.rule_rounded,
        title: 'Category rules',
        subtitle: rules.isEmpty
            ? 'Teach the app which merchants belong to which category'
            : '${rules.length} rule${rules.length == 1 ? '' : 's'} saved',
        screen: const RulesScreen(),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          ManageCard(item: items[i]),
        ],
      ],
    );
  }
}
