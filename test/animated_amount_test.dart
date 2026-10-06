import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/shared/widgets/animated_amount.dart';

Widget _host(int minor) => MaterialApp(
  home: Scaffold(body: AnimatedAmount(amountMinor: minor)),
);

void main() {
  testWidgets('counts up on first show, then settles fast on updates', (
    tester,
  ) async {
    await tester.pumpWidget(_host(100000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('₹1,000'), findsNothing); // still counting up

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('₹1,000'), findsOneWidget);

    // Rows landing repeatedly must not keep the figure crawling.
    for (var i = 1; i <= 5; i++) {
      await tester.pumpWidget(_host(100000 + i * 10000));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('₹1,500'), findsOneWidget);
  });
}
