import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/budgets_repository.dart';
import 'package:local_ledger/core/db/rules_repository.dart';
import 'package:local_ledger/core/lending/lending_repository.dart';
import 'package:local_ledger/core/obligations/obligation_repository.dart';
import 'package:local_ledger/core/ui/root_messenger.dart';
import 'package:local_ledger/core/ui/undo.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionsRepository txns;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txns = TransactionsRepository(db);
  });
  tearDown(() => db.close());

  Future<List<Transaction>> live() => (db.select(
    db.transactions,
  )..where((t) => t.isDeleted.equals(false))).get();

  Future<String> add(
    String merchant, {
    String category = 'cat_food',
    String? raw,
    bool edited = false,
    int amount = 10000,
  }) async {
    final id = '$merchant-${DateTime.now().microsecondsSinceEpoch}';
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            amountMinor: amount,
            merchant: merchant,
            rawMerchant: Value(raw),
            source: 'sms',
            type: 'debit',
            date: DateTime(2026, 10, 1),
            categoryId: Value(category),
            userEdited: Value(edited),
          ),
        );
    return id;
  }

  group('deleting a transaction', () {
    test('Undo brings it back', () async {
      final id = await add('Swiggy');
      final undo = await txns.softDelete(id);
      expect(await live(), isEmpty);
      await undo();
      expect((await live()).single.id, id);
    });

    test('Undo also brings back its loan entry and repayments', () async {
      final id = await add('Rahul', category: 'cat_lending');
      final lending = LendingRepository(db);
      final entryId = await lending.addEntry(
        person: 'Rahul',
        direction: 'lent',
        amountMinor: 10000,
        date: DateTime(2026, 10, 1),
        transactionId: id,
      );
      await lending.addPayment(
        entryId,
        amountMinor: 4000,
        date: DateTime(2026, 10, 2),
      );

      final restoreLoan = await lending.captureForTransaction(id);
      await lending.syncFromTransaction(
        transactionId: id,
        direction: null,
        person: '',
        amountMinor: 0,
        date: DateTime.now(),
      );
      final undoDelete = await txns.softDelete(id);
      // Repayments were recorded, so the entry is detached, not deleted.
      expect((await lending.entryForTransaction(id)), isNull);

      await undoDelete();
      await restoreLoan();
      expect((await lending.entryForTransaction(id))?.id, entryId);
      expect(await db.select(db.lendingPayments).get(), hasLength(1));
    });
  });

  group('lending', () {
    test('a deleted entry and its repayments come back', () async {
      final lending = LendingRepository(db);
      final id = await lending.addEntry(
        person: 'Asha',
        direction: 'borrowed',
        amountMinor: 50000,
        date: DateTime(2026, 9, 1),
      );
      await lending.addPayment(
        id,
        amountMinor: 20000,
        date: DateTime(2026, 9, 5),
      );
      final undo = await lending.deleteEntry(id);
      expect(await db.select(db.lendingEntries).get(), isEmpty);
      expect(await db.select(db.lendingPayments).get(), isEmpty);

      await undo();
      expect((await db.select(db.lendingEntries).getSingle()).person, 'Asha');
      expect(await db.select(db.lendingPayments).get(), hasLength(1));
    });

    test('a deleted repayment comes back, and so does "settled"', () async {
      final lending = LendingRepository(db);
      final id = await lending.addEntry(
        person: 'Asha',
        direction: 'lent',
        amountMinor: 10000,
        date: DateTime(2026, 9, 1),
      );
      await lending.addPayment(
        id,
        amountMinor: 10000,
        date: DateTime(2026, 9, 5),
      );
      var entry = await db.select(db.lendingEntries).getSingle();
      expect(entry.isSettled, isTrue);

      final payment = await db.select(db.lendingPayments).getSingle();
      final undo = await lending.deletePayment(payment.id);
      entry = await db.select(db.lendingEntries).getSingle();
      expect(entry.isSettled, isFalse);

      await undo();
      entry = await db.select(db.lendingEntries).getSingle();
      expect(entry.isSettled, isTrue);
      expect(await db.select(db.lendingPayments).get(), hasLength(1));
    });
  });

  test('a removed auto-debit notice, rule and budget can each come back',
      () async {
    await db
        .into(db.obligations)
        .insert(
          ObligationsCompanion.insert(
            id: 'o1',
            kind: 'mandate',
            status: 'active',
            source: 'sms',
            receivedAt: DateTime(2026, 10, 1),
            biller: const Value('Nippon'),
          ),
        );
    final undoObligation = await ObligationsRepository(db).delete('o1');
    expect(await db.select(db.obligations).get(), isEmpty);
    await undoObligation();
    expect((await db.select(db.obligations).getSingle()).biller, 'Nippon');

    await RulesRepository(db).addRule(pattern: 'zomato', categoryId: 'cat_food');
    final rule = await db.select(db.rules).getSingle();
    final undoRule = await RulesRepository(db).deleteRule(rule.id);
    expect(await db.select(db.rules).get(), isEmpty);
    await undoRule();
    expect((await db.select(db.rules).getSingle()).pattern, 'zomato');

    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: 'b1',
            categoryId: 'cat_food',
            monthlyLimitMinor: 500000,
          ),
        );
    final undoBudget = await BudgetsRepository(db).deleteBudget('b1');
    expect(await db.select(db.budgets).get(), isEmpty);
    await undoBudget();
    expect(
      (await db.select(db.budgets).getSingle()).monthlyLimitMinor,
      500000,
    );
  });

  group('"also updated N similar transactions"', () {
    test('Undo puts the others back, and forgets what it learned', () async {
      final edited = await add('SWIGGY*ORDER', raw: 'SWIGGY*ORDER');
      final other1 = await add('SWIGGY*ORDER', raw: 'SWIGGY*ORDER');
      final other2 = await add('SWIGGY*ORDER', raw: 'SWIGGY*ORDER');

      final result = await txns.updateTransactionUndoable(
        edited,
        amountMinor: 10000,
        merchant: 'Swiggy',
        categoryId: 'cat_food',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );
      expect(result.applied, 2);
      expect(result.undo, isNotNull);

      Future<Transaction> row(String id) => (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      expect((await row(other1)).merchant, 'Swiggy');
      expect(await db.select(db.merchantAliases).get(), hasLength(1));

      await result.undo!();
      expect((await row(other1)).merchant, 'SWIGGY*ORDER');
      expect((await row(other2)).merchant, 'SWIGGY*ORDER');
      expect(await db.select(db.merchantAliases).get(), isEmpty);
      // The one the user edited by hand keeps their edit.
      expect((await row(edited)).merchant, 'Swiggy');
    });

    test('Undo of a category change restores categories and the rule', () async {
      final edited = await add('Uber', category: 'cat_other');
      final other = await add('Uber', category: 'cat_other');

      final result = await txns.updateTransactionUndoable(
        edited,
        amountMinor: 10000,
        merchant: 'Uber',
        categoryId: 'cat_transport',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );
      expect(result.applied, 1);
      Future<Transaction> row(String id) => (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      expect((await row(other)).categoryId, 'cat_transport');
      expect(
        (await db.select(db.rules).get()).where((r) => r.source == 'user'),
        hasLength(1),
      );

      await result.undo!();
      expect((await row(other)).categoryId, 'cat_other');
      expect(
        (await db.select(db.rules).get()).where((r) => r.source == 'user'),
        isEmpty,
      );
    });

    test('nothing to undo when nothing else changed', () async {
      final only = await add('Solo Cafe');
      final result = await txns.updateTransactionUndoable(
        only,
        amountMinor: 10000,
        merchant: 'Solo Cafe',
        categoryId: 'cat_shopping',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );
      expect(result.applied, 0);
      expect(result.undo, isNull);
    });
  });

  testWidgets('the snackbar offers Undo and runs it once', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootMessengerKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    showUndoSnackBar('Deleted', () async => undone++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, 1);
  });

  testWidgets('a failing undo says so instead of crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootMessengerKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    showUndoSnackBar('Deleted', () async => throw StateError('gone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("Couldn't undo that."), findsOneWidget);
  });
}
