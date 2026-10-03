import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/intelligence/merchant_normalizer.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';

void main() {
  migrationTests();
  group('isGenericMerchantLabel', () {
    test('purpose and plumbing labels are generic', () {
      for (final g in [
        'UPI payment',
        'NEFT transfer',
        'IMPS transfer',
        'Credit',
        'Unknown merchant',
        'ATM withdrawal',
        'Home Loan EMI',
        'Loan EMI',
        'Mobile recharge',
        'Bank charges',
        'UPI',
        'UPI/405912345678',
        'POS',
      ]) {
        expect(isGenericMerchantLabel(g), isTrue, reason: g);
      }
    });

    test('named payees are not', () {
      for (final s in [
        'Swiggy',
        'Rahul Sharma',
        'Sunrise Store',
        'rahul.sharma@okhdfcbank',
        'UPI-RAHUL SHARMA',
      ]) {
        expect(isGenericMerchantLabel(s), isFalse, reason: s);
      }
    });
  });

  group('editing one transaction', () {
    late AppDatabase db;
    late TransactionsRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = TransactionsRepository(db);
    });
    tearDown(() => db.close());

    Future<void> insert(
      String id,
      String merchant, {
      String? raw,
      String category = 'cat_other',
      int amount = 10000,
    }) {
      return db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              amountMinor: amount,
              merchant: merchant,
              rawMerchant: Value(raw),
              categoryId: Value(category),
              type: 'debit',
              date: DateTime(2026, 10, 1),
              source: 'sms',
            ),
          );
    }

    Future<Transaction> get(String id) =>
        (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

    test('re-categorising a "UPI payment" changes only that payment', () async {
      await insert('a', 'UPI payment', raw: 'UPI/1');
      await insert('b', 'UPI payment', raw: 'UPI/2');
      await insert('c', 'UPI payment', raw: 'UPI/3');

      final others = await repo.updateTransaction(
        'a',
        amountMinor: 10000,
        merchant: 'UPI payment',
        categoryId: 'cat_food',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );

      expect(others, 0);
      expect((await get('a')).categoryId, 'cat_food');
      expect((await get('b')).categoryId, 'cat_other');
      expect((await get('c')).categoryId, 'cat_other');
      expect(await db.select(db.rules).get(), isEmpty);
    });

    test('renaming one "NEFT transfer" does not rename the others', () async {
      await insert('a', 'NEFT transfer', raw: 'NEFT transfer');
      await insert('b', 'NEFT transfer', raw: 'NEFT transfer');

      await repo.updateTransaction(
        'a',
        amountMinor: 10000,
        merchant: 'Landlord - rent',
        categoryId: 'cat_bills',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );

      expect((await get('a')).merchant, 'Landlord - rent');
      expect((await get('b')).merchant, 'NEFT transfer');
      expect(await db.select(db.merchantAliases).get(), isEmpty);
    });

    test('a named payee is still learned', () async {
      await insert('a', 'Sunrise Store', raw: 'SUNRISE STORE');
      await insert('b', 'Sunrise Store', raw: 'SUNRISE STORE');

      final others = await repo.updateTransaction(
        'a',
        amountMinor: 10000,
        merchant: 'Sunrise Supermarket',
        categoryId: 'cat_groceries',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      );

      expect(others, 1);
      expect((await get('b')).merchant, 'Sunrise Supermarket');
      expect((await get('b')).categoryId, 'cat_groceries');
    });
  });
}

void migrationTests() {
  test(
    'upgrade undoes what an old "UPI payment" rule did to unedited payments',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      Future<void> tx(
        String id,
        String merchant,
        String category, {
        bool edited = false,
        String? raw,
      }) => db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              amountMinor: 5000,
              merchant: merchant,
              rawMerchant: Value(raw),
              categoryId: Value(category),
              type: 'debit',
              date: DateTime(2026, 10, 1),
              source: 'sms',
              userEdited: Value(edited),
            ),
          );

      // The bad rule from an old edit, and what it spread to.
      await db
          .into(db.rules)
          .insert(
            RulesCompanion.insert(
              id: 'r1',
              pattern: 'upi payment',
              categoryId: 'cat_health',
              source: 'user',
            ),
          );
      await db
          .into(db.rules)
          .insert(
            RulesCompanion.insert(
              id: 'r2',
              pattern: 'swiggy',
              categoryId: 'cat_food',
              source: 'user',
            ),
          );
      await tx('spa', 'UPI payment', 'cat_health');
      await tx('chosen', 'UPI payment', 'cat_health', edited: true);
      await tx('food', 'Swiggy', 'cat_food');

      await db.undoGenericLearning();

      final rules = (await db.select(db.rules).get()).map((r) => r.pattern);
      expect(rules, ['swiggy']); // the specific rule survives
      Future<String?> cat(String id) async => (await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle()).categoryId;
      expect(await cat('spa'), 'cat_other'); // no longer Health
      expect(await cat('chosen'), 'cat_health'); // the user's own pick stays
      expect(await cat('food'), 'cat_food');
    },
  );
}
