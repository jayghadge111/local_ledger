import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/rules_repository.dart';
import '../../core/db/settings_repository.dart';
import '../../core/db/small_repositories.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../budgets/budgets_screen.dart';
import '../import_review/bank_email_domains_screen.dart';
import '../import_review/own_identifiers_screen.dart';
import '../import_review/unparsed_messages_screen.dart';
import '../rules/rules_screen.dart';
import '../splits/splits_ui.dart';

/// The "Manage" tab: everything that organises the data beyond the basic
/// lists, surfaced here (with a live one-line summary each) so new users
/// find it without digging through Settings.
class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
    final shares = ref.watch(splitSharesProvider).value ?? const <SplitShare>[];
    final unparsed =
        ref.watch(unparsedMessagesProvider).value ?? const <UnparsedMessage>[];
    final rules = ref.watch(rulesProvider).value ?? const <Rule>[];
    final own =
        ref.watch(ownIdentifiersProvider).value ?? const <OwnIdentifier>[];
    final senders =
        ref.watch(customBankEmailDomainsProvider).value ?? const <String>[];

    final owed = shares
        .where((s) => !s.settled)
        .fold<int>(0, (sum, s) => sum + s.shareMinor);

    final items = <_ManageItem>[
      _ManageItem(
        icon: Icons.pie_chart_rounded,
        title: 'Budgets',
        subtitle: budgets.isEmpty
            ? 'Set a monthly limit for each category'
            : '${budgets.length} budget${budgets.length == 1 ? '' : 's'} set',
        screen: const BudgetsScreen(),
      ),
      _ManageItem(
        icon: Icons.call_split_rounded,
        title: 'Splits & IOUs',
        subtitle: owed > 0
            ? '${money.format(owed / 100)} owed to you'
            : 'Split an expense with friends and track who owes you',
        screen: const SplitsScreen(),
      ),
      _ManageItem(
        icon: Icons.mark_email_unread_rounded,
        title: 'Messages to review',
        subtitle: unparsed.isEmpty
            ? 'Bank messages we couldn\'t read will appear here'
            : '${unparsed.length} need${unparsed.length == 1 ? 's' : ''} your attention',
        badge: unparsed.isEmpty ? null : unparsed.length,
        screen: const UnparsedMessagesScreen(),
      ),
      _ManageItem(
        icon: Icons.rule_rounded,
        title: 'Category rules',
        subtitle: rules.isEmpty
            ? 'Teach the app which merchants belong to which category'
            : '${rules.length} rule${rules.length == 1 ? '' : 's'} saved',
        screen: const RulesScreen(),
      ),
      _ManageItem(
        icon: Icons.swap_horiz_rounded,
        title: 'My other names & UPI IDs',
        subtitle: own.isEmpty
            ? 'Extra UPI IDs or spellings of your name, so transfers between your accounts aren\'t counted as spending'
            : '${own.length} saved · also used to spot Self Transfers',
        screen: const OwnIdentifiersScreen(),
      ),
      _ManageItem(
        icon: Icons.alternate_email_rounded,
        title: 'Bank email senders',
        subtitle: senders.isEmpty
            ? 'Gmail alerts from your bank skipped? Add its sender address'
            : '${senders.length} extra sender${senders.length == 1 ? '' : 's'} added',
        screen: const BankEmailDomainsScreen(),
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
              child: _ManageCard(item: items[i]),
            ),
          ),
      ],
    );
  }
}

class _ManageItem {
  const _ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
  final int? badge;
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({required this.item});
  final _ManageItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => item.screen)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (item.badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${item.badge}',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
