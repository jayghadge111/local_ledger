import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/spend_analytics.dart';
import 'package:local_ledger/core/intelligence/refund_matcher.dart';
import 'package:local_ledger/core/intelligence/transfer_detector.dart';

import 'helpers.dart';

void main() {
  final t0 = DateTime(2026, 10, 1, 12);

  group('transfers', () {
    test('pairs same-amount debit/credit across different accounts', () {
      final result = detectTransfers([
        tx('d', amount: 500000, type: 'debit', accountId: 'a', date: t0),
        tx('c', amount: 500000, type: 'credit', accountId: 'b', date: t0.add(const Duration(minutes: 2))),
      ], const []);
      expect(result.pairs.single.debitId, 'd');
      expect(result.pairs.single.creditId, 'c');
    });

    test('same amount alone is not enough', () {
      final result = detectTransfers([
        tx('d', amount: 50000, type: 'debit', merchant: 'Rahul', date: t0),
        tx('c', amount: 50000, type: 'credit', merchant: 'Priya', date: t0.add(const Duration(minutes: 5))),
      ], const []);
      expect(result.pairs, isEmpty);
    });

    test('own name/VPA gives the missing evidence', () {
      final result = detectTransfers([
        tx('d', amount: 50000, type: 'debit', merchant: 'UPI to JAYESH GHADGE', date: t0),
        tx('c', amount: 50000, type: 'credit', merchant: 'Credit', date: t0.add(const Duration(minutes: 1))),
      ], ['jayesh']);
      expect(result.pairs, hasLength(1));
    });

    test('outside the window is not paired', () {
      final result = detectTransfers([
        tx('d', amount: 100, type: 'debit', accountId: 'a', date: t0),
        tx('c', amount: 100, type: 'credit', accountId: 'b', date: t0.add(const Duration(hours: 3))),
      ], const []);
      expect(result.pairs, isEmpty);
    });

    test('one-sided transfer to own untracked account', () {
      final result = detectTransfers([
        tx('d', amount: 100, merchant: 'Jayesh Ghadge'),
      ], ['jayesh ghadge']);
      expect(result.singles, ['d']);
    });

    test('locked and already-linked rows are left alone', () {
      final result = detectTransfers([
        tx('d', amount: 100, type: 'debit', accountId: 'a', kindLocked: true, date: t0),
        tx('c', amount: 100, type: 'credit', accountId: 'b', date: t0),
      ], const []);
      expect(result.pairs, isEmpty);
    });

    test('each credit is used once', () {
      final result = detectTransfers([
        tx('d1', amount: 100, type: 'debit', accountId: 'a', date: t0),
        tx('d2', amount: 100, type: 'debit', accountId: 'a', date: t0.add(const Duration(minutes: 1))),
        tx('c', amount: 100, type: 'credit', accountId: 'b', date: t0),
      ], const []);
      expect(result.pairs, hasLength(1));
    });
  });

  group('refunds', () {
    test('same merchant + same amount without refund wording', () {
      final matches = detectRefunds([
        tx('d', amount: 79900, merchant: 'Amazon', date: t0),
        tx('c', amount: 79900, type: 'credit', merchant: 'Amazon', date: t0.add(const Duration(days: 6))),
      ]);
      expect(matches.single.debitId, 'd');
    });

    test('different amount without wording is not a refund', () {
      final matches = detectRefunds([
        tx('d', amount: 79900, merchant: 'Amazon', date: t0),
        tx('c', amount: 50000, type: 'credit', merchant: 'Amazon', date: t0.add(const Duration(days: 6))),
      ]);
      expect(matches, isEmpty);
    });

    test('partial refund with wording', () {
      final matches = detectRefunds([
        tx('d', amount: 79900, merchant: 'Amazon', date: t0),
        tx('c', amount: 20000, type: 'credit', merchant: 'Amazon', refundHint: true, date: t0.add(const Duration(days: 9))),
      ]);
      expect(matches, hasLength(1));
    });

    test('failed-UPI reversal names no merchant: matches on exact amount', () {
      final matches = detectRefunds([
        tx('d', amount: 25000, merchant: 'Raju Tea', date: t0),
        tx('c', amount: 25000, type: 'credit', merchant: 'Credit', refundHint: true, date: t0.add(const Duration(hours: 2))),
      ]);
      expect(matches.single.debitId, 'd');
    });

    test('a debit cannot be refunded twice over', () {
      final matches = detectRefunds([
        tx('d', amount: 10000, merchant: 'Amazon', date: t0),
        tx('c1', amount: 10000, type: 'credit', merchant: 'Amazon', refundHint: true, date: t0.add(const Duration(days: 2))),
        tx('c2', amount: 10000, type: 'credit', merchant: 'Amazon', refundHint: true, date: t0.add(const Duration(days: 3))),
      ]);
      expect(matches, hasLength(1));
    });

    test('credit before the debit is never a refund', () {
      final matches = detectRefunds([
        tx('c', amount: 100, type: 'credit', merchant: 'Amazon', refundHint: true, date: t0),
        tx('d', amount: 100, merchant: 'Amazon', date: t0.add(const Duration(days: 3))),
      ]);
      expect(matches, isEmpty);
    });

    test('too old', () {
      final matches = detectRefunds([
        tx('d', amount: 100, merchant: 'Amazon', date: t0),
        tx('c', amount: 100, type: 'credit', merchant: 'Amazon', date: t0.add(const Duration(days: 45))),
      ]);
      expect(matches, isEmpty);
    });
  });

  group('spendingView', () {
    test('drops transfers, nets refunds, excludes foreign currency', () {
      final view = spendingView([
        tx('spend', amount: 100000),
        tx('refund', amount: 30000, type: 'credit', kind: 'refund', refundOfId: 'spend'),
        tx('xfer', amount: 999, kind: 'transfer'),
        tx('usd', amount: 5000, currency: 'USD'),
        tx('salary', amount: 8500000, type: 'credit'),
        tx('gone', amount: 1, isDeleted: true),
      ]);
      expect(view.map((t) => t.id), unorderedEquals(['spend', 'salary']));
      expect(view.firstWhere((t) => t.id == 'spend').amountMinor, 70000);
    });

    test('fully refunded spend disappears', () {
      final view = spendingView([
        tx('spend', amount: 100),
        tx('refund', amount: 100, type: 'credit', kind: 'refund', refundOfId: 'spend'),
      ]);
      expect(view, isEmpty);
    });

    test('only your share of a split counts', () {
      final view = spendingView(
        [tx('dinner', amount: 300000)],
        othersShareByTxn: {'dinner': 200000},
      );
      expect(view.single.amountMinor, 100000);
    });
  });
}
