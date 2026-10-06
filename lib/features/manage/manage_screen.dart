import '../../core/money_format.dart';
import '../../core/lending/lending_repository.dart';
import '../lending/lending_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/rules_repository.dart';
import '../../core/db/small_repositories.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../budgets/budgets_screen.dart';
import 'manage_card.dart';
import '../rules/rules_screen.dart';
import '../splits/splits_ui.dart';
import '../../core/obligations/obligation_repository.dart';
import '../obligations/obligations_screen.dart';

/// The "Manage" tab: everything that organises the data beyond the basic
/// lists, surfaced here (with a live one-line summary each) so new users
/// find it without digging through Settings.
class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final money = appCurrency(symbol: '₹',
      decimalDigits: 0,
    );

    final now = DateTime.now();
    final budgets = ref.watch(
      monthBudgetsProvider(DateTime(now.year, now.month)),
    );
    final shares = ref.watch(splitSharesProvider).value ?? const <SplitShare>[];
    final rules = ref.watch(rulesProvider).value ?? const <Rule>[];

    final upcomingDues = ref.watch(upcomingObligationsProvider);
    final mandatesNow = ref.watch(activeMandatesProvider);
    final failedDebits = ref.watch(recentFailuresProvider);
    final lendingBalancesNow = ref.watch(lendingBalancesProvider);
    final lendingTotals = ref.watch(lendingTotalsProvider);
    final lendingOpen = lendingBalancesNow.where((b) => !b.isSettled).length;
    final owed = shares
        .where((s) => !s.settled)
        .fold<int>(0, (sum, s) => sum + s.shareMinor);

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
            : upcomingDues.isEmpty && mandatesNow.isEmpty
            ? 'Upcoming auto-debits, EMIs and card bills, from your bank messages'
            : '${upcomingDues.length} coming up · ${mandatesNow.length} mandate${mandatesNow.length == 1 ? '' : 's'}',
        badge: failedDebits.isEmpty ? null : failedDebits.length,
        screen: const ObligationsScreen(),
      ),
      ManageItem(
        icon: Icons.call_split_rounded,
        title: 'Splits & IOUs',
        subtitle: owed > 0
            ? '${money.format(owed / 100)} owed to you'
            : 'Split an expense with friends and track who owes you',
        screen: const SplitsScreen(),
      ),
      ManageItem(
        icon: Icons.handshake_rounded,
        title: 'Lend & borrow',
        subtitle: lendingOpen == 0
            ? 'Note money you lent or borrowed, with reminders'
            : '${lendingTotals.owedToMeMinor > 0 ? "You'll get ${money.format(lendingTotals.owedToMeMinor / 100)}" : ''}'
                  '${lendingTotals.owedToMeMinor > 0 && lendingTotals.iOweMinor > 0 ? ' · ' : ''}'
                  '${lendingTotals.iOweMinor > 0 ? 'You owe ${money.format(lendingTotals.iOweMinor / 100)}' : ''}',
        screen: const LendingScreen(),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text('Manage', style: theme.textTheme.headlineSmall),
          ),
        ),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeSlideIn(
              delay: Duration(milliseconds: 25 * (i + 1)),
              child: ManageCard(item: items[i]),
            ),
          ),
      ],
    );
  }
}
