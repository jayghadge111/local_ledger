import '../db/app_database.dart';

/// The categories that mean money lent out and money borrowed.
const kLendingCategoryId = 'cat_lending';
const kBorrowingCategoryId = 'cat_borrowing';

/// 'lent' or 'borrowed' when a transaction in [categoryId] of [type]
/// (debit = spent, credit = received) is a loan, otherwise null.
///
/// Lending money is money going out and borrowing money is money coming in.
/// The other way round (a "Lending money" payment you *received*) is most
/// likely a repayment, so it does not start a new loan.
String? lendingDirectionFor(String? categoryId, String type) {
  if (categoryId == kLendingCategoryId && type == 'debit') return 'lent';
  if (categoryId == kBorrowingCategoryId && type == 'credit') return 'borrowed';
  return null;
}

/// One lent/borrowed entry together with what has been paid back so far.
class LendingBalance {
  const LendingBalance({required this.entry, required this.paidMinor});

  final LendingEntry entry;
  final int paidMinor;

  bool get isLent => entry.direction == 'lent';
  int get outstandingMinor => entry.isSettled
      ? 0
      : (entry.amountMinor - paidMinor).clamp(0, entry.amountMinor);
  bool get isSettled => entry.isSettled || outstandingMinor == 0;

  /// Days from [now] until the due date (negative once past); null if none.
  int? daysUntilDue(DateTime now) {
    final due = entry.dueDate;
    if (due == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).difference(today).inDays;
  }

  bool isOverdue(DateTime now) => !isSettled && (daysUntilDue(now) ?? 0) < 0;
}

/// Totals across all open entries.
class LendingTotals {
  const LendingTotals({required this.owedToMeMinor, required this.iOweMinor});

  /// Still to be received from people the user lent to.
  final int owedToMeMinor;

  /// Still to be repaid to people the user borrowed from.
  final int iOweMinor;

  /// Positive when others owe the user more than the user owes.
  int get netMinor => owedToMeMinor - iOweMinor;
}

List<LendingBalance> lendingBalances(
  List<LendingEntry> entries,
  List<LendingPayment> payments,
) {
  final paid = <String, int>{};
  for (final p in payments) {
    paid.update(
      p.entryId,
      (v) => v + p.amountMinor,
      ifAbsent: () => p.amountMinor,
    );
  }
  final list =
      [
        for (final e in entries)
          LendingBalance(entry: e, paidMinor: paid[e.id] ?? 0),
      ]..sort((a, b) {
        // Open entries first, then by due date (soonest first), then newest.
        if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
        final ad = a.entry.dueDate, bd = b.entry.dueDate;
        if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
        if (ad != null && bd == null) return -1;
        if (ad == null && bd != null) return 1;
        return b.entry.date.compareTo(a.entry.date);
      });
  return list;
}

LendingTotals lendingTotals(List<LendingBalance> balances) {
  var owedToMe = 0, iOwe = 0;
  for (final b in balances) {
    if (b.isLent) {
      owedToMe += b.outstandingMinor;
    } else {
      iOwe += b.outstandingMinor;
    }
  }
  return LendingTotals(owedToMeMinor: owedToMe, iOweMinor: iOwe);
}

/// Open entries that are overdue or due within [withinDays] days, soonest first.
List<LendingBalance> dueSoon(
  List<LendingBalance> balances,
  DateTime now, {
  int withinDays = 3,
}) {
  final list = [
    for (final b in balances)
      if (!b.isSettled &&
          b.daysUntilDue(now) != null &&
          b.daysUntilDue(now)! <= withinDays)
        b,
  ]..sort((a, b) => a.daysUntilDue(now)!.compareTo(b.daysUntilDue(now)!));
  return list;
}
