import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/intelligence/category_reason.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';

import 'helpers.dart';

void main() {
  group('"Remember for similar transactions" off', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> add(String id) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            amountMinor: 1000,
            merchant: 'SWIGGY*ORDER',
            rawMerchant: const Value('SWIGGY*ORDER'),
            source: 'sms',
            type: 'debit',
            date: DateTime(2026, 10, 1),
            categoryId: const Value('cat_other'),
          ),
        );

    test('a one-off correction teaches nothing and changes nothing else', () async {
      await add('a');
      await add('b');
      final r = await TransactionsRepository(db).updateTransactionUndoable(
        'a',
        amountMinor: 1000,
        merchant: 'Swiggy',
        categoryId: 'cat_food',
        type: 'debit',
        date: DateTime(2026, 10, 1),
        learn: false,
      );
      expect(r.applied, 0);
      expect(await db.select(db.merchantAliases).get(), isEmpty);
      expect(await db.select(db.rules).get(), isEmpty);
      final b = await (db.select(db.transactions)
            ..where((t) => t.id.equals('b')))
          .getSingle();
      expect((b.merchant, b.categoryId), ('SWIGGY*ORDER', 'cat_other'));
    });

    test('on (the default) it does teach', () async {
      await add('a');
      await add('b');
      final r = await TransactionsRepository(db).updateTransactionUndoable(
        'a',
        amountMinor: 1000,
        merchant: 'Swiggy',
        categoryId: 'cat_food',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );
      expect(r.applied, 1);
    });
  });

  group('"why this category?"', () {
    Rule rule(String pattern, String category, {String source = 'user'}) => Rule(
      id: pattern,
      pattern: pattern,
      categoryId: category,
      priority: 0,
      source: source,
    );

    test('your own rule', () {
      final text = categoryReason(
        tx('a', amount: 1, merchant: 'Chai Point', categoryId: 'cat_food'),
        rules: [rule('chai point', 'cat_food')],
        categoryName: 'Food & dining',
      );
      expect(text, contains('You taught'));
      expect(text, contains('chai point'));
    });

    test('something you chose by hand', () {
      final text = categoryReason(
        tx('a', amount: 1, categoryId: 'cat_food').copyWith(userEdited: true),
        rules: const [],
        categoryName: 'Food & dining',
      );
      expect(text, contains('You chose'));
    });

    test('the built-in word list names the word it matched', () {
      final text = categoryReason(
        tx('a', amount: 1, merchant: 'Swiggy', categoryId: 'cat_food'),
        rules: const [],
        categoryName: 'Food & dining',
      );
      expect(text.toLowerCase(), contains('swiggy'));
      expect(text, contains('built-in'));
    });

    test('Other says how to fix it', () {
      final text = categoryReason(
        tx('a', amount: 1, merchant: 'Qzx', categoryId: 'cat_other'),
        rules: const [],
        categoryName: 'Other',
      );
      expect(text, contains('Choose a category'));
    });
  });
}
