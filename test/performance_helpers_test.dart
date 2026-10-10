import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/analytics_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/money_format.dart';
import 'package:local_ledger/core/rules/parser_rules.dart';
import 'package:local_ledger/features/dashboard/dashboard_summary.dart';
import 'package:local_ledger/shared/widgets/fade_slide_in.dart';
import 'package:local_ledger/shared/widgets/merchant_badge.dart';

Transaction _txn(
  String id,
  int amount,
  String type,
  String category,
  DateTime date,
) => Transaction(
  id: id,
  amountMinor: amount,
  currency: 'INR',
  merchant: 'Shop $id',
  source: 'manual',
  categoryId: category,
  date: date,
  type: type,
  isRecurring: false,
  isInternational: false,
  isFlaggedUnusual: false,
  isDeleted: false,
  userEdited: false,
  createdAt: date,
  kind: 'normal',
  kindLocked: false,
  refundHint: false,
);

void main() {
  group('number formats are made once and read the same', () {
    test('same arguments share one instance', () {
      expect(
        identical(appCurrency(decimalDigits: 0), appCurrency(decimalDigits: 0)),
        isTrue,
      );
      expect(
        identical(appCurrency(decimalDigits: 0), appCurrency(decimalDigits: 2)),
        isFalse,
      );
      expect(identical(appCurrency(symbol: '\$'), appCurrency()), isFalse);
    });

    test('Indian grouping is unchanged', () {
      expect(appCurrency().format(1234567.5), '₹12,34,567.50');
      expect(appCurrency(decimalDigits: 0).format(100000), '₹1,00,000');
      expect(appCurrency(symbol: 'USD ').format(12.5), 'USD 12.50');
    });
  });

  group('brand lookup is remembered', () {
    tearDown(() => ParserRules.use(null));

    test('known and unknown names answer the same every time', () {
      final first = brandFor('Swiggy Instamart')?.name;
      expect(first, isNotNull);
      expect(brandFor('Swiggy Instamart')?.name, first);
      expect(brandFor('zzzz no such shop 12345'), isNull);
      expect(brandFor('zzzz no such shop 12345'), isNull);
    });

    test('a new rule set replaces what was remembered', () {
      expect(brandFor('Swiggy'), isNotNull);
      final empty = ParserRules.bundled();
      ParserRules.use(empty);
      // Same bundled content, new instance: still answers, from fresh.
      expect(brandFor('Swiggy'), isNotNull);
    });
  });

  group('FadeSlideIn', () {
    testWidgets('animates in, then leaves no timer behind', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeSlideIn(
            delay: Duration(milliseconds: 100),
            child: Text('hello'),
          ),
        ),
      );
      double opacity() => tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value;
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 60));
      expect(opacity(), 0); // still inside the delay
      await tester.pump(const Duration(milliseconds: 600));
      expect(opacity(), 1);
      await tester.pumpWidget(const SizedBox());
      // No pending timers: the test would fail on teardown otherwise.
    });

    testWidgets('shows at once when the system asks to reduce motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: FadeSlideIn(
              delay: Duration(milliseconds: 300),
              child: Text('hello'),
            ),
          ),
        ),
      );
      final fade = tester.widget<FadeTransition>(
        find.byType(FadeTransition).last,
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('dashboard summary', () {
    test('totals, categories and the six-month trend', () {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final txns = [
        _txn(
          'a',
          50000,
          'debit',
          'cat_food',
          month.add(const Duration(hours: 5)),
        ),
        _txn(
          'b',
          30000,
          'debit',
          'cat_food',
          month.add(const Duration(hours: 6)),
        ),
        _txn(
          'c',
          20000,
          'debit',
          'cat_bills',
          month.add(const Duration(hours: 7)),
        ),
        _txn(
          'd',
          900000,
          'credit',
          'cat_income',
          month.add(const Duration(hours: 8)),
        ),
        // Last month: in the trend, not in this month's totals.
        _txn(
          'e',
          70000,
          'debit',
          'cat_food',
          DateTime(month.year, month.month - 1, 10),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          analyticsTransactionsProvider.overrideWithValue(txns),
          categoriesProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final s = container.read(dashboardSummaryProvider(month));
      expect(s.spentMinor, 100000);
      expect(s.receivedMinor, 900000);
      expect(s.slices.first.amountMinor, 80000); // food
      expect(s.slices.first.fraction, closeTo(0.8, 1e-9));
      expect(s.buckets, hasLength(6));
      expect(s.buckets.last.amountMinor, 100000); // this month
      expect(s.buckets[4].amountMinor, 70000); // last month
      expect(s.hasTrendData, isTrue);

      // Same inputs, same object: nothing is recomputed.
      expect(
        identical(
          container.read(dashboardSummaryProvider(month)),
          container.read(dashboardSummaryProvider(month)),
        ),
        isTrue,
      );
    });
  });
}
