import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/obligations/obligation_reminders.dart';
import 'package:local_ledger/core/obligations/obligation_repository.dart';

Obligation ob({
  String id = 'o1',
  String kind = 'pre_debit',
  String status = ObligationStatus.upcoming,
  DateTime? due,
  int? amount = 500000,
  int? minDue,
  String? biller = 'NIPPON INDIA MUTUAL FUND',
  String? account = '4921',
  String? ref,
  String? reason,
}) => Obligation(
  id: id,
  kind: kind,
  status: status,
  biller: biller,
  amountMinor: amount,
  isMaxAmount: false,
  minDueMinor: minDue,
  dueDate: due ?? DateTime(2026, 10, 7),
  accountLast4: account,
  refLast4: ref,
  reason: reason,
  source: 'sms',
  receivedAt: DateTime(2026, 10, 5),
  createdAt: DateTime(2026, 10, 5),
);

void main() {
  group('a scheduled debit', () {
    test('reminds the morning before and the morning of', () {
      final r = planReminders(ob(), DateTime(2026, 10, 5, 12));
      expect(r.map((x) => x.when), [
        DateTime(2026, 10, 6, 9),
        DateTime(2026, 10, 7, 9),
      ]);
      expect(r.first.title, 'Auto-debit tomorrow: ₹5,000');
      expect(r.first.body, contains('NIPPON INDIA MUTUAL FUND'));
      expect(r.first.body, contains('A/c ••4921'));
      expect(r.last.title, 'Auto-debit today: ₹5,000');
    });

    test(
      'a notice that arrives on the day before still gets the day reminder',
      () {
        final r = planReminders(ob(), DateTime(2026, 10, 6, 10));
        expect(r.map((x) => x.when), [DateTime(2026, 10, 7, 9)]);
      },
    );

    test('nothing once the day is over', () {
      expect(planReminders(ob(), DateTime(2026, 10, 7, 9, 30)), isEmpty);
    });
  });

  test('an EMI is called an EMI', () {
    final r = planReminders(
      ob(kind: 'emi_due', biller: 'HDFC Bank', account: null, ref: '9012'),
      DateTime(2026, 10, 1),
    );
    expect(r.first.title, 'EMI due tomorrow: ₹5,000');
  });

  group('a card bill', () {
    final card = ob(
      kind: 'card_due',
      amount: 4421050,
      minDue: 221000,
      biller: 'HDFC Bank Credit Card',
      account: null,
      ref: '8210',
      due: DateTime(2026, 10, 22),
    );

    test('three days before, the day before, and the day', () {
      final r = planReminders(card, DateTime(2026, 10, 3));
      expect(r.map((x) => x.when), [
        DateTime(2026, 10, 19, 9),
        DateTime(2026, 10, 21, 9),
        DateTime(2026, 10, 22, 9),
      ]);
      expect(r.first.title, 'Credit card bill due in 3 days: ₹44,211');
      expect(r.first.body, contains('••8210'));
      expect(r.first.body, contains('minimum ₹2,210'));
    });

    test('skips the ones already past', () {
      final r = planReminders(card, DateTime(2026, 10, 20));
      expect(r.map((x) => x.when), [
        DateTime(2026, 10, 21, 9),
        DateTime(2026, 10, 22, 9),
      ]);
    });
  });

  test('paid, failed and missed ones have no reminders', () {
    for (final s in [
      ObligationStatus.paid,
      ObligationStatus.failed,
      ObligationStatus.missed,
    ]) {
      expect(planReminders(ob(status: s), DateTime(2026, 10, 1)), isEmpty);
    }
  });

  test('a mandate or an undated notice has none', () {
    expect(
      planReminders(
        ob(kind: 'mandate', status: ObligationStatus.active),
        DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
  });

  test(
    'ids are stable, distinct per slot and fit a 32-bit notification id',
    () {
      final a = reminderIdFor('obligation-a', 1);
      expect(reminderIdFor('obligation-a', 1), a);
      expect({
        for (var s = 0; s < reminderSlots; s++)
          reminderIdFor('obligation-a', s),
      }, hasLength(reminderSlots));
      expect(a, lessThanOrEqualTo(0x7fffffff));
      expect(failureIdFor('obligation-a'), lessThanOrEqualTo(0x7fffffff));
    },
  );

  test('the failed-debit alert says what and why', () {
    final t = failureText(ob(reason: 'Insufficient Funds'));
    expect(t.title, 'Auto-debit failed: ₹5,000');
    expect(t.body, contains('NIPPON INDIA MUTUAL FUND'));
    expect(t.body, contains('Insufficient Funds'));
  });
}
