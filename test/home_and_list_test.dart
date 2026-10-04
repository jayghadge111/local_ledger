import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/budget_status.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/dashboard/dashboard_month.dart';
import 'package:local_ledger/features/transactions/transactions_screen.dart';
import 'package:local_ledger/shared/widgets/shimmer.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Drift closes its stream queries on a zero-length timer when the screen is
/// disposed; let it fire so the test doesn't end with a pending timer.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  group('budget status', () {
    Budget budget(String cat, int limit) => Budget(
      id: 'b$cat',
      categoryId: cat,
      monthlyLimitMinor: limit,
      fromMonthKey: '0000-00',
    );
    final oct = DateTime(2026, 10);

    test('over, warning and ok, worst first; only the chosen month counts', () {
      final statuses = budgetStatuses(
        budgets: [
          budget('cat_food', 100000),
          budget('cat_shopping', 100000),
          budget('cat_bills', 100000),
        ],
        transactions: [
          tx(
            '1',
            amount: 120000,
            categoryId: 'cat_food',
            date: DateTime(2026, 10, 3),
          ),
          tx(
            '2',
            amount: 85000,
            categoryId: 'cat_shopping',
            date: DateTime(2026, 10, 4),
          ),
          tx(
            '3',
            amount: 10000,
            categoryId: 'cat_bills',
            date: DateTime(2026, 10, 5),
          ),
          tx(
            '4',
            amount: 900000,
            categoryId: 'cat_bills',
            date: DateTime(2026, 9, 5),
          ), // other month
          tx(
            '5',
            amount: 50000,
            categoryId: 'cat_bills',
            type: 'credit',
            date: DateTime(2026, 10, 6),
          ), // income
        ],
        month: oct,
      );
      expect(statuses.map((s) => s.categoryId), [
        'cat_food',
        'cat_shopping',
        'cat_bills',
      ]);
      expect(statuses[0].level, BudgetLevel.over);
      expect(statuses[0].overByMinor, 20000);
      expect(statuses[1].level, BudgetLevel.warning);
      expect(statuses[1].remainingMinor, 15000);
      expect(statuses[2].level, BudgetLevel.ok);
      expect(statuses[2].spentMinor, 10000);
    });

    test('exactly at the limit is not over', () {
      final s = budgetStatuses(
        budgets: [budget('cat_food', 100000)],
        transactions: [
          tx(
            '1',
            amount: 100000,
            categoryId: 'cat_food',
            date: DateTime(2026, 10, 3),
          ),
        ],
        month: oct,
      ).single;
      expect(s.isOver, isFalse);
      expect(s.level, BudgetLevel.warning);
    });
  });

  group('dashboard month', () {
    test('steps back, never past the current month', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final current = monthOf(DateTime.now());
      expect(c.read(dashboardMonthProvider), current);
      c.read(dashboardMonthProvider.notifier).previous();
      expect(
        c.read(dashboardMonthProvider),
        DateTime(current.year, current.month - 1),
      );
      c.read(dashboardMonthProvider.notifier).next();
      c.read(dashboardMonthProvider.notifier).next(); // already current: stays
      expect(c.read(dashboardMonthProvider), current);
      c.read(dashboardMonthProvider.notifier).select(DateTime(2020, 3, 17));
      expect(c.read(dashboardMonthProvider), DateTime(2020, 3));
      c.read(dashboardMonthProvider.notifier).reset();
      expect(c.read(dashboardMonthProvider), current);
    });

    test('wording', () {
      expect(monthPhrase(monthOf(DateTime.now())), 'this month');
      expect(monthPhrase(DateTime(2025, 3)), 'in Mar 2025');
      expect(monthYearLabel(DateTime(2025, 3)), 'March 2025');
    });
  });

  group('transactions screen', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      for (var i = 0; i < 100; i++) {
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 't$i',
                amountMinor: 10000 + i,
                merchant: 'Merchant $i',
                categoryId: const Value('cat_food'),
                type: i.isEven ? 'debit' : 'credit',
                date: DateTime(2026, 10, 1).subtract(Duration(hours: i)),
                source: 'manual',
              ),
            );
      }
    });
    tearDown(() => db.close());

    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: TransactionsScreen()),
        ),
      );
      await settle(tester);
    }

    testWidgets(
      'search has a filter button; filters live in a panel from the top',
      (tester) async {
        await pumpScreen(tester);
        expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
        // The old inline dropdowns are gone.
        expect(find.byType(DropdownButtonFormField<String?>), findsNothing);

        await tester.tap(find.byIcon(Icons.filter_alt_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Filters'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);

        await tester.tap(find.text('Received'));
        await tester.pump();
        await tester.tap(find.text('Apply'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Active filter shows as a chip and on the icon.
        expect(find.byType(InputChip), findsOneWidget);
        expect(find.byIcon(Icons.filter_alt_rounded), findsOneWidget);
        await unmount(tester);
      },
    );

    testWidgets('running past the loaded rows shows shimmer, then more rows', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Only a first page is built, with placeholders waiting after it.
      expect(find.byType(TransactionTileSkeleton), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(TransactionTileSkeleton), findsWidgets);

      // After the page delay the next rows arrive.
      await tester.pump(kPageDelay + const Duration(milliseconds: 100));
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pump(const Duration(milliseconds: 100));
      // The end of the first 40 rows was Merchant 39; the next page reaches
      // well past it.
      expect(find.text('Merchant 69'), findsOneWidget);
      // Let any page still on its delay finish before the screen goes away.
      await tester.pump(kPageDelay * 2);
      await unmount(tester);
    });
  });
}
