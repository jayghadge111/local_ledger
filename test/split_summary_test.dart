import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/features/splits/split_summary.dart';

SplitShare share(String name, int amount, {bool settled = false}) => SplitShare(
  id: name,
  transactionId: 't',
  personName: name,
  shareMinor: amount,
  settled: settled,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  test('chip label by number of people', () {
    expect(splitChipLabel([share('Rahul', 100)]), 'Split · Rahul');
    expect(
      splitChipLabel([share('Rahul', 100), share('Priya', 100)]),
      'Split · Rahul, Priya',
    );
    expect(
      splitChipLabel([
        share('Rahul', 1),
        share('Priya', 1),
        share('Amit', 1),
        share('Neha', 1),
      ]),
      'Split · Rahul, Priya +2',
    );
  });

  test('settled once everyone has paid back', () {
    expect(
      splitChipLabel([share('Rahul', 100, settled: true)]),
      'Split · settled',
    );
    expect(
      splitChipLabel([share('Rahul', 100, settled: true), share('Priya', 100)]),
      'Split · Rahul, Priya',
    );
  });

  test('my share is the total minus others, never negative', () {
    expect(
      myShareMinor(300000, [share('Rahul', 100000), share('Priya', 100000)]),
      100000,
    );
    expect(myShareMinor(1000, [share('Rahul', 5000)]), 0);
    expect(myShareMinor(1000, const []), 1000);
  });
}
