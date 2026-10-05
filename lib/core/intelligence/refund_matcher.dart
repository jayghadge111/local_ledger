import '../db/app_database.dart';

class RefundMatch {
  const RefundMatch(this.creditId, this.debitId);
  final String creditId;
  final String debitId;
}

final _refundWordsInText = RegExp(
  r'refund|revers|cancel|return|chargeback',
  caseSensitive: false,
);

// Words that appear in lots of unrelated merchant strings.
const _stopTokens = {
  'upi',
  'imps',
  'neft',
  'rtgs',
  'payment',
  'refund',
  'credit',
  'txn',
  'reversal',
  'reversed',
  'bank',
  'from',
  'your',
  'unknown',
  'merchant',
  'transfer',
  'pay',
  'the',
  'and',
};

Set<String> _tokens(Transaction t) {
  final text = '${t.merchant} ${t.rawMerchant ?? ''}'.toLowerCase();
  return text
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 3 && !_stopTokens.contains(w))
      .toSet();
}

bool _isCandidateCredit(Transaction t) =>
    !t.isDeleted &&
    t.type == 'credit' &&
    t.kind == 'normal' &&
    !t.kindLocked &&
    t.refundOfId == null;

bool _isCandidateDebit(Transaction t) =>
    !t.isDeleted && t.type == 'debit' && t.kind == 'normal';

/// Links refund / reversal credits to the debit they undo, so they net
/// against that spend instead of inflating income.
///
/// A credit matches a debit when it comes after it (within 30 days, or 60
/// if the message itself talks about a refund) and doesn't exceed what's
/// still un-refunded on that debit. Without refund wording the merchant
/// must also match AND the amount must be identical — otherwise any credit
/// from a shop you've bought from would look like a refund. With wording, a
/// merchant match OR an identical amount within 10 days (typical of a failed
/// UPI payment reversal, which names no merchant) is enough.
List<RefundMatch> detectRefunds(List<Transaction> transactions) {
  final debits = transactions.where(_isCandidateDebit).toList();
  final remaining = {for (final d in debits) d.id: d.amountMinor};

  // Account for refunds that were already linked on earlier runs.
  for (final t in transactions) {
    if (t.isDeleted || t.kind != 'refund' || t.refundOfId == null) continue;
    final left = remaining[t.refundOfId];
    if (left != null) remaining[t.refundOfId!] = left - t.amountMinor;
  }

  final credits = transactions.where(_isCandidateCredit).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final matches = <RefundMatch>[];

  for (final credit in credits) {
    final creditText = '${credit.merchant} ${credit.rawMerchant ?? ''}';
    final hinted = credit.refundHint || _refundWordsInText.hasMatch(creditText);
    final creditTokens = _tokens(credit);

    Transaction? best;
    var bestScore = -1;
    Duration? bestGap;

    for (final debit in debits) {
      if (debit.currency != credit.currency) continue;
      if ((remaining[debit.id] ?? 0) < credit.amountMinor) continue;

      final gap = credit.date.difference(debit.date);
      if (gap.isNegative && gap.inHours > -1) {
        // Allow a little clock skew between the two messages.
      } else if (gap.isNegative) {
        continue;
      }
      final maxDays = hinted ? 60 : 30;
      if (gap.inDays > maxDays) continue;

      final exact =
          (remaining[debit.id] == credit.amountMinor) ||
          debit.amountMinor == credit.amountMinor;
      final similar = creditTokens.intersection(_tokens(debit)).isNotEmpty;

      final ok = hinted
          ? (similar || (exact && gap.inDays <= 10))
          : (similar && exact);
      if (!ok) continue;

      final score = (exact ? 2 : 0) + (similar ? 1 : 0);
      if (score > bestScore || (score == bestScore && gap.abs() < bestGap!)) {
        best = debit;
        bestScore = score;
        bestGap = gap.abs();
      }
    }

    if (best != null) {
      remaining[best.id] = remaining[best.id]! - credit.amountMinor;
      matches.add(RefundMatch(credit.id, best.id));
    }
  }
  return matches;
}
