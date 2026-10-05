import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/lending/lending_math.dart';
import 'package:local_ledger/core/lending/lending_repository.dart';
import 'package:local_ledger/features/transactions/transaction_form_sheet.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<LendingEntry>> entries() => db.select(db.lendingEntries).get();
  Future<List<Transaction>> txns() => db.select(db.transactions).get();

  group('which transactions are loans', () {
    test('lending is money out, borrowing is money in', () {
      expect(lendingDirectionFor('cat_lending', 'debit'), 'lent');
      expect(lendingDirectionFor('cat_borrowing', 'credit'), 'borrowed');
    });

    test('the other way round is a repayment, not a new loan', () {
      expect(lendingDirectionFor('cat_lending', 'credit'), isNull);
      expect(lendingDirectionFor('cat_borrowing', 'debit'), isNull);
    });

    test('any other category is not a loan', () {
      expect(lendingDirectionFor('cat_food', 'debit'), isNull);
      expect(lendingDirectionFor(null, 'debit'), isNull);
    });
  });

  group('keeping Lend & borrow in step with a transaction', () {
    late LendingRepository repo;
    setUp(() => repo = LendingRepository(db));
    final date = DateTime(2026, 10, 5);
    final due = DateTime(2026, 11, 5);

    Future<LendingSync> sync(
      String direction, {
      int amount = 500000,
      DateTime? dueDate,
      String person = 'Ramesh',
    }) => repo.syncFromTransaction(
      transactionId: 't1',
      direction: direction,
      person: person,
      amountMinor: amount,
      date: date,
      dueDate: dueDate ?? due,
    );

    test('marking a transaction as lending adds an entry', () async {
      expect(await sync('lent'), LendingSync.created);
      final e = (await entries()).single;
      expect(e.person, 'Ramesh');
      expect(e.direction, 'lent');
      expect(e.amountMinor, 500000);
      expect(e.dueDate, due);
      expect(e.transactionId, 't1');
    });

    test('editing it updates the same entry — never adds a second', () async {
      await sync('lent');
      expect(
        await sync(
          'lent',
          amount: 700000,
          person: 'Ramesh K',
          dueDate: DateTime(2026, 12, 1),
        ),
        LendingSync.updated,
      );
      final e = (await entries()).single;
      expect(e.amountMinor, 700000);
      expect(e.person, 'Ramesh K');
      expect(e.dueDate, DateTime(2026, 12, 1));
    });

    test('changing lending to borrowing flips the entry', () async {
      await sync('lent');
      await sync('borrowed');
      expect((await entries()).single.direction, 'borrowed');
    });

    test('changing the category away removes an untouched entry', () async {
      await sync('lent');
      expect(
        await repo.syncFromTransaction(
          transactionId: 't1',
          direction: null,
          person: 'Ramesh',
          amountMinor: 500000,
          date: date,
        ),
        LendingSync.removed,
      );
      expect(await entries(), isEmpty);
    });

    test('but keeps one that has repayments, detached', () async {
      await sync('lent');
      final id = (await entries()).single.id;
      await repo.addPayment(id, amountMinor: 100000, date: date);
      expect(
        await repo.syncFromTransaction(
          transactionId: 't1',
          direction: null,
          person: 'Ramesh',
          amountMinor: 500000,
          date: date,
        ),
        LendingSync.keptWithPayments,
      );
      final e = (await entries()).single;
      expect(e.transactionId, isNull);
      expect(await (db.select(db.lendingPayments).get()), hasLength(1));
    });

    test(
      'a transaction that never made an entry has nothing to remove',
      () async {
        expect(
          await repo.syncFromTransaction(
            transactionId: 'other',
            direction: null,
            person: 'x',
            amountMinor: 1,
            date: date,
          ),
          LendingSync.none,
        );
      },
    );

    test('two transactions make two separate entries', () async {
      await sync('lent');
      await repo.syncFromTransaction(
        transactionId: 't2',
        direction: 'lent',
        person: 'Suresh',
        amountMinor: 100000,
        date: date,
        dueDate: due,
      );
      expect(await entries(), hasLength(2));
    });
  });

  group('the transaction form', () {
    Future<void> openForm(WidgetTester tester, {Transaction? existing}) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(body: TransactionFormSheet(existing: existing)),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> pickCategory(WidgetTester tester, String name) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(name).last);
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> fill(WidgetTester tester, {String who = 'Ramesh'}) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (₹)'),
        '5000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Merchant / description'),
        who,
      );
      await tester.pump();
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('an ordinary category asks for no due date', (tester) async {
      await openForm(tester);
      await pickCategory(tester, 'Food & dining');
      expect(find.textContaining('Set due date'), findsNothing);
      await unmount(tester);
    });

    testWidgets('Lending money asks for a due date, and insists on it', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester);
      await pickCategory(tester, 'Lending money');

      expect(find.text('Set due date (reminder) *'), findsOneWidget);
      // The name field says what it is for.
      expect(find.text('Lent to'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(
        find.text('Due date is required for lending and borrowing'),
        findsOneWidget,
      );
      expect(await tester.runAsync(txns), isEmpty); // nothing saved
      expect(await tester.runAsync(entries), isEmpty);
      await unmount(tester);
    });

    testWidgets('with a due date it saves the transaction and the entry', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester);
      await pickCategory(tester, 'Lending money');

      await tester.tap(find.text('Set due date (reminder) *'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Due '), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      final t = (await tester.runAsync(txns))!.single;
      expect(t.categoryId, 'cat_lending');
      expect(t.type, 'debit');
      final e = (await tester.runAsync(entries))!.single;
      expect(e.person, 'Ramesh');
      expect(e.direction, 'lent');
      expect(e.amountMinor, 500000);
      expect(e.dueDate, isNotNull);
      expect(e.transactionId, t.id);
      await unmount(tester);
    });

    testWidgets('Borrowing money (received) makes a borrowed entry', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester, who: 'Priya');
      await tester.tap(find.text('Received'));
      await tester.pump();
      await pickCategory(tester, 'Borrowing money');
      expect(find.text('Borrowed from'), findsOneWidget);

      await tester.tap(find.text('Set due date (reminder) *'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      final e = (await tester.runAsync(entries))!.single;
      expect(e.direction, 'borrowed');
      expect(e.person, 'Priya');
      await unmount(tester);
    });

    testWidgets('a "Lending money" payment received is not a new loan', (
      tester,
    ) async {
      await openForm(tester);
      await fill(tester);
      await tester.tap(find.text('Received'));
      await tester.pump();
      await pickCategory(tester, 'Lending money');
      expect(find.textContaining('Set due date'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      expect(await tester.runAsync(txns), hasLength(1));
      expect(await tester.runAsync(entries), isEmpty);
      await unmount(tester);
    });

    testWidgets('editing a loan transaction updates its entry, once', (
      tester,
    ) async {
      // A loan transaction and its entry, as the form leaves them.
      final id = await tester.runAsync(() async {
        final id = await TransactionsRepository(db).addManualTransaction(
          amountMinor: 500000,
          merchant: 'Ramesh',
          categoryId: 'cat_lending',
          type: 'debit',
          date: DateTime(2026, 10, 1),
        );
        await LendingRepository(db).syncFromTransaction(
          transactionId: id,
          direction: 'lent',
          person: 'Ramesh',
          amountMinor: 500000,
          date: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 11, 1),
        );
        return id;
      });
      final existing = (await tester.runAsync(txns))!.single;
      expect(existing.id, id);

      await openForm(tester, existing: existing);
      // The due date is the entry's, not blank.
      expect(find.text('Due 1 Nov 2026'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (₹)'),
        '7000',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();

      final list = (await tester.runAsync(entries))!;
      expect(list, hasLength(1));
      expect(list.single.amountMinor, 700000);
      expect(list.single.dueDate, DateTime(2026, 11, 1));
      await unmount(tester);
    });
  });
}
