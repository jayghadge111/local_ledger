import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/obligations/obligation_repository.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/placeholder_body.dart';
import 'obligation_card.dart';

/// Everything the app has learned about auto-debits: failures, what is coming
/// up, the mandates in force, and how earlier ones went. None of it is
/// counted as spending — the real debit is, when it happens.
class ObligationsScreen extends ConsumerWidget {
  const ObligationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(obligationsProvider).value ?? const <Obligation>[];
    final failures = ref.watch(recentFailuresProvider);
    final upcoming = ref.watch(upcomingObligationsProvider);
    final mandates = ref.watch(activeMandatesProvider);
    final earlier =
        [
          for (final o in all)
            if (o.kind != 'mandate' &&
                (o.status == ObligationStatus.paid ||
                    o.status == ObligationStatus.missed ||
                    (o.status == ObligationStatus.failed &&
                        !failures.contains(o))))
              o,
        ]..sort(
          (a, b) =>
              (b.dueDate ?? b.receivedAt).compareTo(a.dueDate ?? a.receivedAt),
        );

    Widget section(String title, List<Obligation> items, {String? note}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            for (final o in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ObligationCard(
                  obligation: o,
                  onTap: () => showObligationDetails(context, ref, o),
                ),
              ),
          ],
        ),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Auto-pay & dues')),
        body: all.isEmpty
            ? const PlaceholderBody(
                icon: Icons.event_repeat_rounded,
                title: 'Nothing yet',
                subtitle: 'When your bank warns you about an upcoming auto-debit, an EMI or a credit card bill, it shows up here — with a reminder before it is due. These are not counted as spending.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  section(
                    'Failed auto-debits',
                    failures,
                    note: 'Add money to your account to avoid return charges.',
                  ),
                  section(
                    'Coming up',
                    upcoming,
                    note: 'Not counted as spending until the money leaves.',
                  ),
                  section('Active mandates', mandates),
                  section('Earlier', earlier),
                ],
              ),
      ),
    );
  }
}

/// The facts behind one row, and a way to remove it.
Future<void> showObligationDetails(
  BuildContext context,
  WidgetRef ref,
  Obligation o,
) {
  final theme = Theme.of(context);
  final date = DateFormat('d MMM yyyy');
  final money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final rows = <(String, String)>[
    ('Status', _statusText(o)),
    if (o.amountMinor != null)
      (
        o.kind == 'card_due'
            ? 'Total due'
            : o.isMaxAmount
            ? 'Maximum'
            : 'Amount',
        money.format(o.amountMinor! / 100),
      ),
    if (o.minDueMinor != null)
      ('Minimum due', money.format(o.minDueMinor! / 100)),
    if (o.dueDate != null)
      (o.kind == 'mandate' ? 'Next debit' : 'Date', date.format(o.dueDate!)),
    if (o.accountLast4 != null) ('Account', '••${o.accountLast4}'),
    if (o.refLast4 != null)
      (o.refType == 'card' ? 'Card' : 'Loan', o.refLast4!),
    if (o.frequency != null) ('Repeats', o.frequency!),
    if (o.umrn != null) ('Mandate reference', o.umrn!),
    if (o.reason != null) ('Reason', o.reason!),
    ('Read from', o.source == 'email' ? 'Email' : 'SMS'),
  ];

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(obligationTitle(o), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        r.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(r.$2, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await ref.read(obligationsRepositoryProvider).delete(o.id);
                  if (sheet.mounted) Navigator.of(sheet).pop();
                },
                child: const Text('Remove'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _statusText(Obligation o) => switch (o.status) {
  ObligationStatus.paid => 'Paid — the debit was seen',
  ObligationStatus.failed => 'Failed',
  ObligationStatus.missed => 'No matching debit seen',
  ObligationStatus.active => 'Active',
  _ => 'Upcoming',
};
