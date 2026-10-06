import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/obligations/obligation_repository.dart';
import 'package:local_ledger/features/obligations/obligations_screen.dart';

Obligation _paid(String id, String biller, DateTime due) => Obligation(
  id: id,
  kind: 'pre_debit',
  status: ObligationStatus.paid,
  biller: biller,
  amountMinor: 64900,
  isMaxAmount: false,
  dueDate: due,
  source: 'sms',
  receivedAt: due,
  createdAt: due,
);

void main() {
  testWidgets('Earlier lists only this month and last month', (tester) async {
    final now = DateTime.now();
    final rows = [
      _paid('a', 'NETFLIX THIS', DateTime(now.year, now.month, 1)),
      _paid('b', 'NETFLIX LAST', DateTime(now.year, now.month - 1, 15)),
      _paid('c', 'NETFLIX OLD', DateTime(now.year, now.month - 2, 15)),
      _paid('d', 'NETFLIX ANCIENT', DateTime(now.year - 1, now.month, 15)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          obligationsProvider.overrideWith((ref) => Stream.value(rows)),
        ],
        child: const MaterialApp(home: ObligationsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('NETFLIX THIS'), findsOneWidget);
    expect(find.text('NETFLIX LAST'), findsOneWidget);
    expect(find.text('NETFLIX OLD'), findsNothing);
    expect(find.text('NETFLIX ANCIENT'), findsNothing);
  });
}
