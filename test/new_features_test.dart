import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/alerts/budget_alerts.dart';
import 'package:local_ledger/core/analytics/budget_status.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/budgets_repository.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/lending/lending_math.dart';
import 'package:local_ledger/core/lending/lending_repository.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';
import 'package:local_ledger/core/sms/parser_templates.dart';
import 'package:local_ledger/core/sms/template_learning.dart';
import 'package:local_ledger/features/calendar/calendar_math.dart';

import 'helpers.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

LendingEntry entry(
  String id,
  String dir,
  int amount, {
  DateTime? due,
  bool settled = false,
  String person = 'Rahul',
}) => LendingEntry(
  id: id,
  person: person,
  direction: dir,
  amountMinor: amount,
  date: DateTime(2026, 10, 1),
  dueDate: due,
  isSettled: settled,
  createdAt: DateTime(2026, 10, 1),
);

LendingPayment pay(String id, String entryId, int amount) => LendingPayment(
  id: id,
  entryId: entryId,
  amountMinor: amount,
  date: DateTime(2026, 10, 5),
);

void main() {
  group('parser learning', () {
    const first =
        'Alert from ACME BANK: account XX1234 settlement of INR 750.00 to merchant ZINGY CAFE MUMBAI on 03-Oct-26 '
        'ref 8837291 is complete. Thank you for banking with ACME BANK';
    const second =
        'Alert from ACME BANK: account XX1234 settlement of INR 1,250.50 to merchant BREW HOUSE PUNE on 07-Oct-26 '
        'ref 1190233 is complete. Thank you for banking with ACME BANK';

    test('the built-in parser really cannot read this layout', () {
      expect(parseBankSms(first), isNull);
    });

    test(
      'a corrected message teaches the layout, amount and payee included',
      () {
        final pattern = buildTemplatePattern(
          body: first,
          amountMinor: 75000,
          merchant: 'Zingy Cafe',
        )!;
        final match = matchTemplate(second, compileTemplate(pattern))!;
        expect(match.amountMinor, 125050);
        expect(match.merchant, 'BREW HOUSE PUNE');
      },
    );

    test('an unrelated message does not match', () {
      final re = compileTemplate(
        buildTemplatePattern(
          body: first,
          amountMinor: 75000,
          merchant: 'Zingy Cafe',
        )!,
      );
      expect(matchTemplate('Your OTP is 123456. Do not share it.', re), isNull);
      expect(
        matchTemplate(
          'Rs 500 spent at SWIGGY on HDFC Bank Card XX1234 on 03-Oct-26',
          re,
        ),
        isNull,
      );
    });

    test('a message too short to be distinctive is never learned', () {
      expect(
        buildTemplatePattern(
          body: 'INR 500 paid to ABC',
          amountMinor: 50000,
          merchant: 'ABC',
        ),
        isNull,
      );
    });

    test('without a payee the name stays fixed: it fits the same merchant again, not others', () {
      final pattern = buildTemplatePattern(body: first, amountMinor: 75000)!;
      expect(pattern.contains('(?<m>'), isFalse);
      final re = compileTemplate(pattern);
      final again = first
          .replaceFirst('750.00', '320.00')
          .replaceFirst('8837291', '5551212');
      expect(matchTemplate(again, re)!.amountMinor, 32000);
      expect(matchTemplate(second, re), isNull);
    });

    test('the amount must be in the message', () {
      expect(buildTemplatePattern(body: first, amountMinor: 99999), isNull);
    });

    group('in the ingestion pipeline', () {
      late AppDatabase db;
      late TransactionIngestor ingestor;

      setUp(() {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        ingestor = TransactionIngestor(db, _FakeEncryption());
      });
      tearDown(() => db.close());

      test(
        'a layout the app could not read is read after the user teaches it',
        () async {
          var session = await ingestor.begin();
          await session.add(
            source: 'sms',
            sender: 'VM-ACMEBK-S',
            body: first,
            date: DateTime(2026, 10, 3),
          );
          expect(session.imported, 0);
          expect(session.queued, 1);

          final learned = await ParserTemplateStore(db, _FakeEncryption())
              .learn(
                body: first,
                type: 'debit',
                amountMinor: 75000,
                merchant: 'Zingy Cafe',
              );
          expect(learned, isTrue);
          // Same layout again is not stored twice.
          expect(
            await ParserTemplateStore(db, _FakeEncryption()).learn(
              body: first,
              type: 'debit',
              amountMinor: 75000,
              merchant: 'Zingy Cafe',
            ),
            isFalse,
          );

          session = await ingestor.begin();
          await session.add(
            source: 'sms',
            sender: 'VM-ACMEBK-S',
            body: second,
            date: DateTime(2026, 10, 7),
          );
          await session.finish();
          expect(session.imported, 1);
          final t = (await db.select(db.transactions).get()).single;
          expect(t.amountMinor, 125050);
          expect(t.type, 'debit');
          expect(t.merchant.toLowerCase(), contains('brew house'));
          // The usage is counted.
          expect((await db.select(db.parserTemplates).get()).single.hits, 1);
        },
      );

      test('stored templates are encrypted', () async {
        await ParserTemplateStore(db, _FakeEncryption()).learn(
          body: first,
          type: 'debit',
          amountMinor: 75000,
          merchant: 'Zingy Cafe',
        );
        final row = (await db.select(db.parserTemplates).get()).single;
        expect(row.patternEncrypted, startsWith('enc:'));
      });
    });
  });

  group('lending', () {
    final now = DateTime(2026, 10, 10);

    test('balances, repayments and totals', () {
      final balances = lendingBalances(
        [
          entry('a', 'lent', 500000),
          entry('b', 'borrowed', 200000),
          entry('c', 'lent', 100000, settled: true),
        ],
        [pay('p1', 'a', 150000), pay('p2', 'b', 200000)],
      );
      final byId = {for (final b in balances) b.entry.id: b};
      expect(byId['a']!.outstandingMinor, 350000);
      expect(byId['b']!.outstandingMinor, 0);
      expect(byId['b']!.isSettled, isTrue); // paid in full
      expect(byId['c']!.outstandingMinor, 0);
      final totals = lendingTotals(balances);
      expect(totals.owedToMeMinor, 350000);
      expect(totals.iOweMinor, 0);
      expect(totals.netMinor, 350000);
      // Open entries first.
      expect(balances.first.entry.id, 'a');
    });

    test('due soon and overdue', () {
      final balances = lendingBalances([
        entry('late', 'lent', 100000, due: DateTime(2026, 10, 7)),
        entry('soon', 'borrowed', 100000, due: DateTime(2026, 10, 12)),
        entry('far', 'lent', 100000, due: DateTime(2026, 11, 30)),
        entry('none', 'lent', 100000),
        entry(
          'done',
          'lent',
          100000,
          due: DateTime(2026, 10, 1),
          settled: true,
        ),
      ], []);
      final due = dueSoon(balances, now);
      expect(due.map((b) => b.entry.id), ['late', 'soon']);
      expect(due.first.isOverdue(now), isTrue);
      expect(due.first.daysUntilDue(now), -3);
      expect(due.last.isOverdue(now), isFalse);
    });

    test(
      'repository: part payments, settling by paying in full, and reopening',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = LendingRepository(db);
        final id = await repo.addEntry(
          person: 'Asha',
          direction: 'lent',
          amountMinor: 100000,
          date: DateTime(2026, 10, 1),
        );

        await repo.addPayment(
          id,
          amountMinor: 40000,
          date: DateTime(2026, 10, 3),
        );
        var e = await (db.select(
          db.lendingEntries,
        )..where((x) => x.id.equals(id))).getSingle();
        expect(e.isSettled, isFalse);

        await repo.addPayment(
          id,
          amountMinor: 60000,
          date: DateTime(2026, 10, 4),
        );
        e = await (db.select(
          db.lendingEntries,
        )..where((x) => x.id.equals(id))).getSingle();
        expect(e.isSettled, isTrue);

        final last = (await db.select(db.lendingPayments).get()).firstWhere(
          (p) => p.amountMinor == 60000,
        );
        await repo.deletePayment(last.id);
        e = await (db.select(
          db.lendingEntries,
        )..where((x) => x.id.equals(id))).getSingle();
        expect(e.isSettled, isFalse); // reopened

        await repo.deleteEntry(id);
        expect(await db.select(db.lendingEntries).get(), isEmpty);
        expect(await db.select(db.lendingPayments).get(), isEmpty);
      },
    );
  });

  group('budget alerts', () {
    final oct = DateTime(2026, 10);
    BudgetStatus status(String cat, int limit, int spent) =>
        BudgetStatus(categoryId: cat, limitMinor: limit, spentMinor: spent);

    test('each threshold is announced once per month', () {
      final statuses = [
        status('cat_food', 1000, 1200),
        status('cat_shopping', 1000, 850),
        status('cat_bills', 1000, 100),
      ];
      final first = newBudgetAlerts(statuses, oct, {});
      expect(first.map((a) => '${a.status.categoryId}:${a.level.name}'), [
        'cat_food:over',
        'cat_shopping:warning',
      ]);

      final shown = {for (final a in first) a.key};
      expect(newBudgetAlerts(statuses, oct, shown), isEmpty);

      // Crossing from warning to over is news.
      final worse = [status('cat_shopping', 1000, 1100)];
      expect(newBudgetAlerts(worse, oct, shown).single.level, BudgetLevel.over);
    });

    test('a new month starts fresh and old keys are dropped', () {
      final keys = {
        budgetAlertKey(DateTime(2026, 9), 'cat_food', BudgetLevel.over),
        budgetAlertKey(oct, 'cat_food', BudgetLevel.over),
      };
      expect(keysForMonth(keys, oct), {
        budgetAlertKey(oct, 'cat_food', BudgetLevel.over),
      });
      expect(
        newBudgetAlerts(
          [status('cat_food', 1000, 1200)],
          DateTime(2026, 11),
          keysForMonth(keys, DateTime(2026, 11)),
        ),
        hasLength(1),
      );
    });
  });

  group('per-month budgets', () {
    Budget standing(String cat, int limit) =>
        Budget(id: 'b$cat', categoryId: cat, monthlyLimitMinor: limit);
    BudgetOverride override(String cat, String key, int limit) =>
        BudgetOverride(
          id: 'o$cat$key',
          categoryId: cat,
          monthKey: key,
          limitMinor: limit,
        );

    test('a limit set for October changes October only', () {
      final standingList = [standing('cat_shopping', 500000)];
      final overrides = [override('cat_shopping', '2026-10', 300000)];
      expect(
        budgetsForMonth(
          standingList,
          overrides,
          DateTime(2026, 10),
        ).single.monthlyLimitMinor,
        300000,
      );
      expect(
        budgetsForMonth(
          standingList,
          overrides,
          DateTime(2026, 9),
        ).single.monthlyLimitMinor,
        500000,
      );
      expect(
        budgetsForMonth(
          standingList,
          overrides,
          DateTime(2026, 11),
        ).single.monthlyLimitMinor,
        500000,
      );
    });

    test('a category can have a limit for one month only', () {
      final overrides = [override('cat_food', '2026-12', 80000)];
      expect(
        budgetsForMonth(
          [],
          overrides,
          DateTime(2026, 12),
        ).single.monthlyLimitMinor,
        80000,
      );
      expect(budgetsForMonth([], overrides, DateTime(2026, 11)), isEmpty);
    });

    test(
      'repository: set for one month, then back to the usual limit',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = BudgetsRepository(db);
        await repo.setBudget(
          categoryId: 'cat_shopping',
          monthlyLimitMinor: 500000,
        );
        await repo.setMonthBudget(
          categoryId: 'cat_shopping',
          month: DateTime(2026, 10),
          limitMinor: 300000,
        );
        await repo.setMonthBudget(
          categoryId: 'cat_shopping',
          month: DateTime(2026, 10),
          limitMinor: 250000,
        ); // update, not duplicate

        final standingList = await db.select(db.budgets).get();
        var overrides = await db.select(db.budgetOverrides).get();
        expect(overrides, hasLength(1));
        expect(
          budgetsForMonth(
            standingList,
            overrides,
            DateTime(2026, 10),
          ).single.monthlyLimitMinor,
          250000,
        );
        expect(
          budgetsForMonth(
            standingList,
            overrides,
            DateTime(2026, 11),
          ).single.monthlyLimitMinor,
          500000,
        );

        await repo.clearMonthBudget(
          categoryId: 'cat_shopping',
          month: DateTime(2026, 10),
        );
        overrides = await db.select(db.budgetOverrides).get();
        expect(
          budgetsForMonth(
            standingList,
            overrides,
            DateTime(2026, 10),
          ).single.monthlyLimitMinor,
          500000,
        );
      },
    );

    test('statuses use the month\'s own limit', () {
      final october = budgetsForMonth(
        [standing('cat_shopping', 500000)],
        [override('cat_shopping', '2026-10', 300000)],
        DateTime(2026, 10),
      );
      final s = budgetStatuses(
        budgets: october,
        transactions: [
          tx(
            '1',
            amount: 350000,
            categoryId: 'cat_shopping',
            date: DateTime(2026, 10, 5),
          ),
        ],
        month: DateTime(2026, 10),
      ).single;
      expect(s.isOver, isTrue); // over ₹3,000 although under the usual ₹5,000
      expect(s.overByMinor, 50000);
    });
  });

  group('calendar', () {
    test('day totals count each day separately and skip other months', () {
      final totals = dayTotals([
        tx('1', amount: 10000, date: DateTime(2026, 10, 3)),
        tx('2', amount: 5000, date: DateTime(2026, 10, 3)),
        tx('3', amount: 90000, type: 'credit', date: DateTime(2026, 10, 3)),
        tx('4', amount: 7000, date: DateTime(2026, 10, 20)),
        tx('5', amount: 999, date: DateTime(2026, 9, 3)),
      ], DateTime(2026, 10));
      expect(totals[3]!.spentMinor, 15000);
      expect(totals[3]!.receivedMinor, 90000);
      expect(totals[20]!.spentMinor, 7000);
      expect(totals.containsKey(4), isFalse);
    });

    test('the grid starts on Monday', () {
      // 1 Oct 2026 is a Thursday: three blank cells first.
      final grid = monthGrid(DateTime(2026, 10));
      expect(grid.take(3), everyElement(isNull));
      expect(grid[3], DateTime(2026, 10, 1));
      expect(grid.whereType<DateTime>(), hasLength(31));
      // February 2027 starts on a Monday: no padding.
      expect(monthGrid(DateTime(2027, 2)).first, DateTime(2027, 2, 1));
    });

    test('compact amounts', () {
      expect(compactMoney(85000), '₹850');
      expect(compactMoney(120000), '₹1.2k');
      expect(compactMoney(4500000), '₹45k');
      expect(compactMoney(12000000), '₹1.2L');
      expect(compactMoney(100000), '₹1k');
      expect(compactMoney(3500000000), '₹3.5Cr');
    });
  });
}
