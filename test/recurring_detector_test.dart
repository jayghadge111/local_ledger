import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/intelligence/recurring_detector.dart';

import 'helpers.dart';

void main() {
  final now = DateTime(2026, 10, 15);

  test('daily cafe spend is not recurring', () {
    final txns = [
      for (var i = 0; i < 30; i++)
        tx('c$i', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 9, 15).add(Duration(days: i))),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });

  test('daily cafe with a few long gaps is still not recurring', () {
    // Gaps of 1 day and one of ~30 days: the average looks monthly, the
    // individual gaps don't.
    final txns = [
      tx('a', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 7, 1)),
      tx('b', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 7, 2)),
      tx('c', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 8, 5)),
      tx('d', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 8, 6)),
      tx('e', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 9, 10)),
      tx('f', amount: 15000, merchant: 'Jofrey Cafe', date: DateTime(2026, 9, 11)),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });

  test('monthly subscription is recurring', () {
    final txns = [
      tx('1', amount: 64900, merchant: 'Netflix', date: DateTime(2026, 7, 28)),
      tx('2', amount: 64900, merchant: 'Netflix', date: DateTime(2026, 8, 28)),
      tx('3', amount: 64900, merchant: 'Netflix', date: DateTime(2026, 9, 28)),
    ];
    final result = detectRecurring(txns, now: now);
    expect(result.single.merchant, 'Netflix');
    expect(result.single.nextExpectedDate.month, 10);
  });

  test('EMI with day-of-month drift is recurring', () {
    final txns = [
      tx('1', amount: 1250000, merchant: 'HDFC Loan EMI', date: DateTime(2026, 6, 5)),
      tx('2', amount: 1250000, merchant: 'HDFC Loan EMI', date: DateTime(2026, 7, 7)),
      tx('3', amount: 1250000, merchant: 'HDFC Loan EMI', date: DateTime(2026, 8, 5)),
      tx('4', amount: 1250000, merchant: 'HDFC Loan EMI', date: DateTime(2026, 9, 5)),
    ];
    expect(detectRecurring(txns, now: now), hasLength(1));
  });

  test('bill with varying amount (within 25%) is recurring', () {
    final txns = [
      tx('1', amount: 145000, merchant: 'BESCOM', date: DateTime(2026, 7, 10)),
      tx('2', amount: 172000, merchant: 'BESCOM', date: DateTime(2026, 8, 10)),
      tx('3', amount: 158000, merchant: 'BESCOM', date: DateTime(2026, 9, 10)),
    ];
    expect(detectRecurring(txns, now: now), hasLength(1));
  });

  test('two payments are not enough', () {
    final txns = [
      tx('1', amount: 100, merchant: 'Hotstar', date: DateTime(2026, 8, 20)),
      tx('2', amount: 100, merchant: 'Hotstar', date: DateTime(2026, 9, 20)),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });

  test('weekly payments are not monthly', () {
    final txns = [
      for (var i = 0; i < 6; i++)
        tx('w$i', amount: 50000, merchant: 'Maid', date: DateTime(2026, 8, 1).add(Duration(days: 7 * i))),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });

  test('a cancelled subscription drops off', () {
    final txns = [
      tx('1', amount: 100, merchant: 'Old Gym', date: DateTime(2026, 1, 5)),
      tx('2', amount: 100, merchant: 'Old Gym', date: DateTime(2026, 2, 5)),
      tx('3', amount: 100, merchant: 'Old Gym', date: DateTime(2026, 3, 5)),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });

  test('wildly different amounts are not a bill', () {
    final txns = [
      tx('1', amount: 10000, merchant: 'Amazon', date: DateTime(2026, 7, 10)),
      tx('2', amount: 90000, merchant: 'Amazon', date: DateTime(2026, 8, 10)),
      tx('3', amount: 25000, merchant: 'Amazon', date: DateTime(2026, 9, 10)),
    ];
    expect(detectRecurring(txns, now: now), isEmpty);
  });
}
