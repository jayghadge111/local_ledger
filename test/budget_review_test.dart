import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/budget_review.dart';
import 'package:local_ledger/core/analytics/budget_review_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/budgets_repository.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/dashboard/widgets/budget_review_card.dart';

import 'helpers.dart';

Budget budget(String cat, int limit) => Budget(
  id: 'b$cat',
  categoryId: cat,
  monthlyLimitMinor: limit,
  fromMonthKey: '0000-00',
);

Transaction debit(String id, int amount, String cat, DateTime date) =>
    tx(id, amount: amount, categoryId: cat, date: date);

void main() {
  final sep = DateTime(2026, 9);

  group('the review of a month that just ended', () {
    test('lists only the categories that went over, worst first', () {
      final review = buildBudgetReview(
        budgetsLastMonth: [
          budget('cat_food', 500000),
          budget('cat_fuel', 200000),
          budget('cat_shopping', 300000),
        ],
        transactions: [
          debit('1', 620000, 'cat_food', DateTime(2026, 9, 5)), // 124%
          debit('2', 100000, 'cat_fuel', DateTime(2026, 9, 6)), // within
          debit('3', 600000, 'cat_shopping', DateTime(2026, 9, 7)), // 200%
          debit('4', 999999, 'cat_food', DateTime(2026, 10, 1)), // other month
        ],
        month: sep,
      )!;
      expect(review.totalBudgets, 3);
      expect(review.overCount, 2);
      expect(review.over.map((i) => i.categoryId), [
        'cat_shopping',
        'cat_food',
      ]);
      expect(review.allWithinLimits, isFalse);
    });

    test('nothing to review when last month had no budgets', () {
      expect(
        buildBudgetReview(
          budgetsLastMonth: const [],
          transactions: [debit('1', 100, 'cat_food', DateTime(2026, 9, 1))],
          month: sep,
        ),
        isNull,
      );
    });

    test('everything within limits is a clean review', () {
      final review = buildBudgetReview(
        budgetsLastMonth: [budget('cat_food', 500000)],
        transactions: [debit('1', 100000, 'cat_food', DateTime(2026, 9, 1))],
        month: sep,
      )!;
      expect(review.allWithinLimits, isTrue);
    });
  });

  group('the suggested limit', () {
    test('rounds up to ₹100, then ₹500 from ₹5,000', () {
      expect(roundUpLimit(123400), 130000); // ₹1,234 -> ₹1,300
      expect(roundUpLimit(130000), 130000);
      expect(roundUpLimit(512300), 550000); // ₹5,123 -> ₹5,500
      expect(roundUpLimit(500000), 500000);
    });

    test('uses the recent average when it is above the limit', () {
      // Limit 5,000; spent 6,200 last month, 3-month average 6,000.
      expect(
        suggestedLimit(
          limitMinor: 500000,
          lastMonthSpentMinor: 620000,
          averageSpentMinor: 600000,
        ),
        600000,
      );
    });

    test('covers last month when one bad month lifts only that month', () {
      // Average 4,800 is under the 5,000 limit, but last month hit 6,200.
      expect(
        suggestedLimit(
          limitMinor: 500000,
          lastMonthSpentMinor: 620000,
          averageSpentMinor: 480000,
        ),
        650000,
      );
    });

    test('is always above the old limit', () {
      final review = buildBudgetReview(
        budgetsLastMonth: [budget('cat_food', 500000)],
        transactions: [debit('1', 500001, 'cat_food', DateTime(2026, 9, 5))],
        month: sep,
      )!;
      expect(review.over.single.suggestedMinor, greaterThan(500000));
    });
  });

  group('when the review is shown', () {
    final review = BudgetReview(
      month: sep,
      totalBudgets: 2,
      over: const [
        ReviewItem(
          categoryId: 'cat_food',
          limitMinor: 500000,
          spentMinor: 620000,
          suggestedMinor: 650000,
        ),
      ],
    );
    bool show({int day = 4, String? dismissed, BudgetReview? r}) =>
        shouldShowReview(
          review: r ?? review,
          now: DateTime(2026, 10, day),
          dismissedForMonthKey: dismissed,
          currentMonthKey: '2026-10',
        );

    test('early in the month, until put away', () {
      expect(show(), isTrue);
      expect(show(day: 5), isTrue);
      expect(show(day: 6), isFalse);
      expect(show(dismissed: '2026-10'), isFalse);
      expect(show(dismissed: '2026-09'), isTrue); // an old dismissal
    });

    test('never when nothing went over or there was no review', () {
      expect(
        show(
          r: BudgetReview(month: sep, totalBudgets: 2, over: const []),
        ),
        isFalse,
      );
      expect(
        shouldShowReview(
          review: null,
          now: DateTime(2026, 10, 4),
          dismissedForMonthKey: null,
          currentMonthKey: '2026-10',
        ),
        isFalse,
      );
    });
  });

  group('the month-end notification text', () {
    String name(String id) => {
      'cat_food': 'Food',
      'cat_fuel': 'Fuel',
      'cat_shopping': 'Shopping',
      'cat_bills': 'Bills',
    }[id]!;
    ReviewItem item(String id) => ReviewItem(
      categoryId: id,
      limitMinor: 100,
      spentMinor: 200,
      suggestedMinor: 300,
    );

    test('names the categories that went over', () {
      final t = monthSummaryText(
        BudgetReview(
          month: sep,
          totalBudgets: 12,
          over: [item('cat_food'), item('cat_shopping'), item('cat_fuel')],
        ),
        name,
        'September',
      );
      expect(t.title, 'September budgets');
      expect(t.body, '3 of 12 went over: Food, Shopping, Fuel.');
    });

    test('says how many more when there are many', () {
      final t = monthSummaryText(
        BudgetReview(
          month: sep,
          totalBudgets: 12,
          over: [
            item('cat_food'),
            item('cat_shopping'),
            item('cat_fuel'),
            item('cat_bills'),
          ],
        ),
        name,
        'September',
      );
      expect(t.body, '4 of 12 went over: Food, Shopping, Fuel and 1 more.');
    });

    test('good news when everything stayed within limits', () {
      expect(
        monthSummaryText(
          BudgetReview(month: sep, totalBudgets: 12, over: const []),
          name,
          'September',
        ).body,
        'All 12 budgets stayed within their limits.',
      );
      expect(
        monthSummaryText(
          BudgetReview(month: sep, totalBudgets: 1, over: const []),
          name,
          'September',
        ).body,
        'Your budget stayed within its limit.',
      );
    });
  });

  group('the Home card', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    final real = DateTime.now();
    final thisMonth = DateTime(real.year, real.month);
    final lastMonth = DateTime(real.year, real.month - 1);
    // The 4th of the real current month, so the card's 5-day window is open.
    DateTime today() => DateTime(real.year, real.month, 4);

    const food = ReviewItem(
      categoryId: 'cat_food',
      limitMinor: 500000,
      spentMinor: 620000,
      suggestedMinor: 650000,
    );
    const fuel = ReviewItem(
      categoryId: 'cat_fuel',
      limitMinor: 200000,
      spentMinor: 260000,
      suggestedMinor: 260000,
    );
    const shopping = ReviewItem(
      categoryId: 'cat_shopping',
      limitMinor: 300000,
      spentMinor: 450000,
      suggestedMinor: 450000,
    );

    Future<void> pump(
      WidgetTester tester, {
      List<ReviewItem> over = const [food],
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            budgetReviewProvider.overrideWithValue(
              BudgetReview(month: lastMonth, totalBudgets: 3, over: over),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: BudgetReviewCard(today: today)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('offers a one-tap raise from this month on', (tester) async {
      await tester.runAsync(
        () => BudgetsRepository(db).setBudgetFrom(
          categoryId: 'cat_food',
          fromMonth: DateTime(real.year - 1, 1),
          limitMinor: 500000,
        ),
      );
      await pump(tester);
      expect(find.textContaining('review'), findsOneWidget);
      expect(find.text('Raise to ₹6,500'), findsOneWidget);
      expect(find.text('Keep as is'), findsOneWidget);

      await tester.tap(find.text('Raise to ₹6,500'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final rows = await tester.runAsync(() => db.select(db.budgets).get());
      final now = budgetsForMonth(rows!, const [], thisMonth).single;
      final before = budgetsForMonth(rows, const [], lastMonth).single;
      expect(now.monthlyLimitMinor, 650000);
      expect(before.monthlyLimitMinor, 500000); // last month untouched
      // Handled, so the card goes away.
      expect(find.text('Raise to ₹6,500'), findsNothing);
      await unmount(tester);
    });

    Future<void> seedBudgets(WidgetTester tester) => tester.runAsync(() async {
      final repo = BudgetsRepository(db);
      for (final e in {
        'cat_food': 500000,
        'cat_fuel': 200000,
        'cat_shopping': 300000,
      }.entries) {
        await repo.setBudgetFrom(
          categoryId: e.key,
          fromMonth: DateTime(real.year - 1, 1),
          limitMinor: e.value,
        );
      }
    });

    testWidgets('shows two rows, and the rest in a popup', (tester) async {
      await seedBudgets(tester);
      await pump(tester, over: const [food, fuel, shopping]);

      // Two on the card, the third behind "Show 1 more".
      expect(find.textContaining('Raise to'), findsNWidgets(2));
      expect(find.text('Show 1 more'), findsOneWidget);

      await tester.tap(find.text('Show 1 more'));
      await tester.pump(const Duration(milliseconds: 400));
      // The popup lists all three (the card still shows its two behind it).
      expect(find.text('Raise to ₹6,500'), findsNWidgets(2));
      expect(find.text('Raise to ₹2,600'), findsNWidgets(2));
      expect(find.text('Raise to ₹4,500'), findsNWidgets(1));
      expect(find.byTooltip('Close'), findsOneWidget);

      // Raising the one only the popup could reach.
      await tester.tap(find.text('Raise to ₹4,500'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final rows = await tester.runAsync(() => db.select(db.budgets).get());
      final limits = {
        for (final b in budgetsForMonth(rows!, const [], thisMonth))
          b.categoryId: b.monthlyLimitMinor,
      };
      expect(limits['cat_shopping'], 450000);
      expect(limits['cat_food'], 500000); // others untouched

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byTooltip('Close'), findsNothing);
      await unmount(tester);
    });

    testWidgets('never overflows, at any width the page animates through', (
      tester,
    ) async {
      await seedBudgets(tester);
      for (final width in [
        120.0,
        151.0,
        200.0,
        239.0,
        240.0,
        280.0,
        340.0,
        402.0,
      ]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(width),
            overrides: [
              databaseProvider.overrideWithValue(db),
              budgetReviewProvider.overrideWithValue(
                BudgetReview(
                  month: lastMonth,
                  totalBudgets: 3,
                  over: const [food, fuel, shopping],
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BudgetReviewCard(today: today),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at width $width',
        );
      }
      addTearDown(tester.view.reset);
      await unmount(tester);
    });

    testWidgets('two or fewer: no "Show more"', (tester) async {
      await seedBudgets(tester);
      await pump(tester, over: const [food, fuel]);
      expect(find.textContaining('Raise to'), findsNWidgets(2));
      expect(find.textContaining('Show'), findsNothing);
      await unmount(tester);
    });

    testWidgets('"Keep as is" puts it away for the month', (tester) async {
      await tester.runAsync(
        () => BudgetsRepository(db).setBudgetFrom(
          categoryId: 'cat_food',
          fromMonth: DateTime(real.year - 1, 1),
          limitMinor: 500000,
        ),
      );
      await pump(tester);
      await tester.tap(find.text('Keep as is'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Keep as is'), findsNothing);
      final rows = await tester.runAsync(() => db.select(db.budgets).get());
      expect(rows, hasLength(1)); // nothing changed
      await unmount(tester);
    });
  });
}
