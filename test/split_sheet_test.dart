import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/splits/splits_ui.dart';

void main() {
  late AppDatabase db;
  late Transaction txn;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't1',
            amountMinor: 90000,
            merchant: 'Dinner',
            source: 'sms',
            type: 'debit',
            date: DateTime(2026, 10, 1),
            categoryId: const Value('cat_other'),
          ),
        );
    txn = await db.select(db.transactions).getSingle();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSplitSheet(context, txn),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(db.close);
  }

  testWidgets('one name field; people first, then equal shares', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Split equally'), findsNothing); // no people yet

    await tester.enterText(find.byType(TextField), 'Asha, Ravi');
    await tester.tap(find.byTooltip('Add person'));
    await tester.pump();

    // Three ways (you + 2): ₹300 each, so your share is ₹300.
    expect(find.text('Split equally'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('₹300.00'), findsNWidgets(2));
    expect(find.textContaining('your share ₹300.00'), findsOneWidget);

    await tester.tap(find.text('Save split'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final rows = await tester.runAsync(() => db.select(db.splitShares).get());
    expect(rows!.map((r) => (r.personName, r.shareMinor)).toSet(), {
      ('Asha', 30000),
      ('Ravi', 30000),
    });
    await close(tester);
  });

  testWidgets('custom amounts start from the equal split and are checked', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Asha');
    await tester.tap(find.byTooltip('Add person'));
    await tester.pump();

    await tester.tap(find.text('Custom amounts'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '450.00'), findsOneWidget);
    final amount = find.byType(TextField).last; // the name field is first

    await tester.enterText(amount, '1000');
    await tester.pump();
    expect(find.text('These add up to more than the total.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save split'))
          .onPressed,
      isNull,
    );

    await tester.enterText(amount, '200');
    await tester.pump();
    expect(find.textContaining('your share ₹700.00'), findsOneWidget);
    await close(tester);
  });
}
