import '../db/app_database.dart';

/// The transactions that totals, charts and budgets should be built from.
///
/// - Transfers between the user's own accounts are left out entirely.
/// - Refund credits are left out of income; instead the debit they reverse
///   is reduced by the refunded amount (and dropped if fully refunded).
/// - A debit the user split with others only counts their own share
///   ([othersShareByTxn] maps transaction id -> amount owed by others).
/// - Only INR is included: amounts in other currencies can't be added to
///   rupee totals without an exchange rate, and the app is offline-only.
///
/// The full list (everything, including transfers) is still what the
/// Transactions screen shows.
List<Transaction> spendingView(
  List<Transaction> all, {
  Map<String, int> othersShareByTxn = const {},
}) {
  final live = all.where((t) => !t.isDeleted && t.currency == 'INR').toList();

  final refundedOf = <String, int>{};
  for (final t in live) {
    if (t.kind == 'refund' && t.refundOfId != null) {
      refundedOf.update(t.refundOfId!, (v) => v + t.amountMinor, ifAbsent: () => t.amountMinor);
    }
  }

  final view = <Transaction>[];
  for (final t in live) {
    if (t.kind == 'transfer' || t.kind == 'refund') continue;
    if (t.type == 'credit') {
      view.add(t);
      continue;
    }
    final adjusted =
        t.amountMinor - (refundedOf[t.id] ?? 0) - (othersShareByTxn[t.id] ?? 0);
    if (adjusted <= 0) continue;
    view.add(adjusted == t.amountMinor ? t : t.copyWith(amountMinor: adjusted));
  }
  return view;
}
