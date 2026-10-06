import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';

import 'generated_migrations/schema.dart';

// A bad migration is the one bug that can destroy a user's data, so every
// schema the app has ever had (drift_schemas/) is upgraded to the current one
// and checked two ways: the result must have exactly the tables, columns and
// indexes a fresh install has, and rows written by the old version must
// survive.
//
// To add a version: bump `schemaVersion`, then
//   dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/drift_schema_vN.json
//   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
void main() {
  late SchemaVerifier verifier;
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  final current = AppDatabase.forTesting(
    NativeDatabase.memory(),
  ).schemaVersion;

  test('the newest schema file matches the app', () {
    expect(
      GeneratedHelper.versions.last,
      current,
      reason:
          'schemaVersion was bumped without dumping the new schema into '
          'drift_schemas/ — run the two commands at the top of this file.',
    );
  });

  group('every old version upgrades to the current schema', () {
    for (final from in GeneratedHelper.versions.where((v) => v < current)) {
      test('v$from → v$current', () async {
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(db, current);
        await db.close();
      });
    }
  });

  group('data written by an old version survives', () {
    // What a user's phone could actually hold at each point.
    const accountSql =
        "INSERT INTO accounts (id, name, bank_name, last4, account_type) "
        "VALUES ('a1', 'HDFC Bank ••4921', 'HDFC', '4921', 'bank')";
    const categorySql =
        "INSERT INTO categories (id, name, icon, is_default) "
        "VALUES ('cat_food', 'Food', 'restaurant', 1)";
    String transactionSql(String id, int amount) =>
        'INSERT INTO transactions (id, account_id, amount_minor, merchant, '
        "source, category_id, date, type, user_edited) VALUES ('$id', 'a1', "
        "$amount, 'Swiggy', 'sms', 'cat_food', 1759000000, 'debit', 1)";

    for (final from in GeneratedHelper.versions.where((v) => v < current)) {
      test('transactions written at v$from', () async {
        final schema = await verifier.schemaAt(from);
        final old = schema.newConnection();
        final oldDb = GeneratedHelper().databaseForVersion(old, from);
        await oldDb.customStatement(accountSql);
        await oldDb.customStatement(categorySql);
        await oldDb.customStatement(transactionSql('t1', 45000));
        await oldDb.customStatement(transactionSql('t2', 99900));
        await oldDb.close();

        final db = AppDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(db, current);

        final rows = await (db.select(
          db.transactions,
        )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
        expect(rows.map((t) => t.id), ['t1', 't2']);
        expect(rows.map((t) => t.amountMinor), [45000, 99900]);
        expect(rows.first.merchant, 'Swiggy');
        expect(rows.first.userEdited, isTrue);
        expect(rows.first.categoryId, 'cat_food');
        expect(rows.first.accountId, 'a1');
        expect(rows.first.date, DateTime.fromMillisecondsSinceEpoch(1759000000 * 1000));

        // Columns added after the row was written read as their defaults.
        expect(rows.first.kind, 'normal');
        expect(rows.first.kindLocked, isFalse);
        expect(rows.first.refundOfId, isNull);

        final accounts = await db.select(db.accounts).get();
        expect(accounts.single.last4, '4921');

        // The upgraded database is healthy and usable.
        final integrity = await db
            .customSelect('PRAGMA integrity_check')
            .getSingle();
        expect(integrity.data.values.single, 'ok');
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'new',
                amountMinor: 100,
                merchant: 'After upgrade',
                source: 'manual',
                type: 'debit',
                date: DateTime(2026, 10, 1),
              ),
            );
        expect(await db.select(db.transactions).get(), hasLength(3));
        await db.close();
      });
    }

    test('budgets and lending entries from v7 keep their values', () async {
      final schema = await verifier.schemaAt(7);
      final oldDb = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        7,
      );
      await oldDb.customStatement(categorySql);
      await oldDb.customStatement(
        "INSERT INTO budgets (id, category_id, monthly_limit_minor) "
        "VALUES ('b1', 'cat_food', 500000)",
      );
      await oldDb.customStatement(
        "INSERT INTO lending_entries (id, person, direction, amount_minor, "
        "date, is_settled) VALUES ('l1', 'Rahul', 'lent', 250000, 1759000000, 0)",
      );
      await oldDb.customStatement(
        "INSERT INTO lending_payments (id, entry_id, amount_minor, date) "
        "VALUES ('p1', 'l1', 50000, 1759100000)",
      );
      await oldDb.close();

      final db = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, current);

      final budget = await db.select(db.budgets).getSingle();
      expect(budget.monthlyLimitMinor, 500000);
      // Added in v8: an existing budget applies to every month, as before.
      expect(budget.fromMonthKey, '0000-00');

      final entry = await db.select(db.lendingEntries).getSingle();
      expect(entry.person, 'Rahul');
      expect(entry.amountMinor, 250000);
      expect(entry.transactionId, isNull); // added in v10
      final payment = await db.select(db.lendingPayments).getSingle();
      expect(payment.amountMinor, 50000);
      await db.close();
    });

    test('settings from v2 are kept', () async {
      final schema = await verifier.schemaAt(2);
      final oldDb = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        2,
      );
      await oldDb.customStatement(
        "INSERT INTO app_settings (setting_key, setting_value) "
        "VALUES ('userName', 'Jayesh')",
      );
      await oldDb.close();
      final db = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, current);
      final row = await db.select(db.appSettings).getSingle();
      expect((row.settingKey, row.settingValue), ('userName', 'Jayesh'));
      await db.close();
    });
  });

  test('a new install is created at the current version with its indexes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final names = (await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name LIKE 'idx_txn_%'",
            )
            .get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(names, {
      'idx_txn_live_date',
      'idx_txn_account',
      'idx_txn_kind',
      'idx_txn_source_hash',
    });
    await db.close();
  });
}
