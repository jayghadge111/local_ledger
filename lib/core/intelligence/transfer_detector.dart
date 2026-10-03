import '../db/app_database.dart';
import 'name_match.dart';

class TransferPair {
  const TransferPair(this.debitId, this.creditId);
  final String debitId;
  final String creditId;
}

class TransferDetection {
  const TransferDetection({this.pairs = const [], this.singles = const []});

  /// A debit and the credit it landed as — both sides are tracked.
  final List<TransferPair> pairs;

  /// One-sided transfers to/from the user's own untracked account.
  final List<String> singles;
}

bool _eligible(Transaction t) =>
    !t.isDeleted &&
    t.kind == 'normal' &&
    !t.kindLocked &&
    t.transferGroupId == null;

bool _mentionsOwn(
  Transaction t,
  List<String> ownIdentifiers,
  String? userName,
) {
  final text = '${t.merchant} ${t.rawMerchant ?? ''}'.toLowerCase();
  if (ownIdentifiers.any((id) => id.length >= 3 && text.contains(id))) {
    return true;
  }
  return isSameName(userName, t.rawMerchant) ||
      isSameName(userName, t.merchant);
}

/// Finds money moved between the user's own accounts, which would
/// otherwise be counted as both spending and income.
///
/// A debit and a credit are paired when they have the same amount and
/// currency, land within [window] of each other, AND there's evidence they
/// belong to the same person: both accounts are known and differ, or either
/// side names one of [ownIdentifiers] or is the [userName] itself. Same amount alone isn't enough —
/// paying a friend 500 and being paid 500 by someone else the same hour
/// would otherwise look like a transfer.
TransferDetection detectTransfers(
  List<Transaction> transactions,
  List<String> ownIdentifiers, {
  String? userName,
  Duration window = const Duration(minutes: 30),
}) {
  final candidates = transactions.where(_eligible).toList();
  final debits = candidates.where((t) => t.type == 'debit').toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final credits = candidates.where((t) => t.type == 'credit').toList();

  final used = <String>{};
  final pairs = <TransferPair>[];

  for (final debit in debits) {
    Transaction? best;
    Duration? bestGap;
    for (final credit in credits) {
      if (used.contains(credit.id)) continue;
      if (credit.amountMinor != debit.amountMinor ||
          credit.currency != debit.currency) {
        continue;
      }
      final gap = credit.date.difference(debit.date).abs();
      if (gap > window) continue;

      final accountsDiffer =
          debit.accountId != null &&
          credit.accountId != null &&
          debit.accountId != credit.accountId;
      final ownEvidence =
          _mentionsOwn(debit, ownIdentifiers, userName) ||
          _mentionsOwn(credit, ownIdentifiers, userName);
      if (!accountsDiffer && !ownEvidence) continue;

      if (bestGap == null || gap < bestGap) {
        best = credit;
        bestGap = gap;
      }
    }
    if (best != null) {
      used
        ..add(debit.id)
        ..add(best.id);
      pairs.add(TransferPair(debit.id, best.id));
    }
  }

  final singles = [
    for (final t in candidates)
      if (!used.contains(t.id) && _mentionsOwn(t, ownIdentifiers, userName))
        t.id,
  ];

  return TransferDetection(pairs: pairs, singles: singles);
}
