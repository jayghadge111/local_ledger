import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../backup/local_snapshots.dart';
import '../diagnostics/diagnostic_log.dart';

import '../intelligence/default_category_rules.dart';
import '../intelligence/merchant_normalizer.dart';
import 'default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single local database for the app. Nothing in here is ever
/// transmitted anywhere — it's read and written entirely on-device.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Rules,
    RecurringGroups,
    Alerts,
    Budgets,
    AppSettings,
    OwnIdentifiers,
    MerchantAliases,
    SplitShares,
    UnparsedMessages,
    LendingEntries,
    LendingPayments,
    ParserTemplates,
    BudgetOverrides,
    Obligations,
    MergedMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => kSchemaVersion;

  /// Adds [column] unless the table already has it. A table created earlier in
  /// the same upgrade is created from today's definition, which already holds
  /// every column added since — adding it again would stop the upgrade with
  /// "duplicate column name" (this broke any upgrade from before v7).
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    if (existing.any((r) => r.read<String>('name') == column.name)) return;
    await m.addColumn(table, column);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(budgets);
        await m.createTable(appSettings);
      }
      if (from < 3) {
        await _addColumnIfMissing(m, transactions, transactions.rawMerchant);
        await _addColumnIfMissing(m, transactions, transactions.kind);
        await _addColumnIfMissing(m, transactions, transactions.kindLocked);
        await _addColumnIfMissing(m, transactions, transactions.transferGroupId);
        await _addColumnIfMissing(m, transactions, transactions.refundOfId);
        await _addColumnIfMissing(m, transactions, transactions.refundHint);
        await _addColumnIfMissing(m, transactions, transactions.sourceHash);
        await m.createTable(ownIdentifiers);
        await m.createTable(merchantAliases);
        await m.createTable(splitShares);
        await m.createTable(unparsedMessages);
      }
      if (from < 4) {
        await _addColumnIfMissing(m, transactions, transactions.alsoInSource);
      }
      if (from < 5) {
        // Self Transfer, EMI, SIP / Investment, Lending, Borrowing.
        for (final c in defaultCategories) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              icon: Value(c.iconKey),
              isDefault: const Value(true),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
      if (from < 6) await undoGenericLearning();
      if (from < 7) {
        await m.createTable(lendingEntries);
        await m.createTable(lendingPayments);
        await m.createTable(parserTemplates);
        await m.createTable(budgetOverrides);
      }
      if (from < 8) {
        // Existing rows get the default "0000-00": in force for every
        // month, exactly as before.
        await _addColumnIfMissing(m, budgets, budgets.fromMonthKey);
      }
      if (from < 9) await m.createTable(obligations);
      if (from < 10) {
        await _addColumnIfMissing(m, lendingEntries, lendingEntries.transactionId);
      }
      if (from < 11) {
        await m.createIndex(idxTxnLiveDate);
        await m.createIndex(idxTxnAccount);
        await m.createIndex(idxTxnKind);
        await m.createIndex(idxTxnSourceHash);
        await m.createTable(mergedMessages);
      }
    },
  );

  /// Earlier versions learned a rule from any edit, including to generic
  /// labels like "UPI payment" — so one payment's category or name was pushed
  /// onto every such payment. This drops those rules and aliases, and undoes
  /// what they did to payments the user never edited themselves.
  Future<void> undoGenericLearning() async {
    for (final a in await select(merchantAliases).get()) {
      if (!isGenericMerchantLabel(a.pattern)) continue;
      final affected =
          await (select(transactions)..where(
                (t) =>
                    t.userEdited.equals(false) &
                    t.merchant.equals(a.displayName),
              ))
              .get();
      for (final t in affected) {
        if (t.rawMerchant?.toLowerCase() != a.pattern) continue;
        await (update(transactions)..where((x) => x.id.equals(t.id))).write(
          TransactionsCompanion(
            merchant: Value(normalizeMerchant(t.rawMerchant!)),
          ),
        );
      }
      await (delete(merchantAliases)..where((x) => x.id.equals(a.id))).go();
    }
    for (final r in await (select(
      rules,
    )..where((x) => x.source.equals('user'))).get()) {
      if (!isGenericMerchantLabel(r.pattern)) continue;
      final affected =
          await (select(transactions)..where(
                (t) =>
                    t.userEdited.equals(false) &
                    t.categoryId.equals(r.categoryId),
              ))
              .get();
      for (final t in affected) {
        if (t.merchant.toLowerCase() != r.pattern) continue;
        await (update(transactions)..where((x) => x.id.equals(t.id))).write(
          TransactionsCompanion(
            categoryId: Value(
              defaultCategoryFor(
                    '${t.merchant} ${t.rawMerchant ?? ''}',
                    isCredit: t.type == 'credit',
                  ) ??
                  'cat_other',
            ),
          ),
        );
      }
      await (delete(rules)..where((x) => x.id.equals(r.id))).go();
    }
  }

  Future<void> _seedDefaultCategories() {
    return batch((b) {
      b.insertAll(categories, [
        for (final c in defaultCategories)
          CategoriesCompanion.insert(
            id: c.id,
            name: c.name,
            icon: Value(c.iconKey),
            isDefault: const Value(true),
          ),
      ]);
    });
  }
}

/// The database structure version. Bump together with a new `onUpgrade` step,
/// then dump the schema (see test/migration_test.dart).
const kSchemaVersion = 11;

const _databaseName = 'local_ledger_db';

/// Where the database file lives (drift's default location, spelled out so the
/// snapshot and restore code can reach the same file).
Future<File> databaseFile() async => File(
  p.join((await getApplicationDocumentsDirectory()).path, '$_databaseName.sqlite'),
);

/// Where automatic copies of the database are kept.
Future<Directory> snapshotsDirectory() async => Directory(
  p.join((await getApplicationSupportDirectory()).path, 'snapshots'),
);

QueryExecutor _openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final file = await databaseFile();
      await _snapshotBeforeUpgrade(file);
      return driftDatabase(
        name: _databaseName,
        native: DriftNativeOptions(databasePath: () async => file.path),
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.dart.js'),
        ),
      );
    }),
  );
}

/// If the database on disk is older than this version of the app, it is about
/// to be upgraded in place. Copy it first, so that a faulty upgrade can never
/// cost the user their data: the copy can be restored from Settings.
Future<void> _snapshotBeforeUpgrade(File file) async {
  try {
    if (!file.existsSync() || file.lengthSync() == 0) return;
    final raw = sqlite.sqlite3.open(file.path);
    int version;
    try {
      version = raw.select('PRAGMA user_version').first.values.first as int;
    } finally {
      raw.close();
    }
    if (version <= 0 || version >= kSchemaVersion) return;
    LocalSnapshots(snapshotsDirectory).createFromFile(
      file,
      'upgrade-v$version',
      await snapshotsDirectory(),
    );
  } catch (error, stack) {
    DiagnosticLog.instance.record('backup', error, stack, 'pre-upgrade copy');
  }
}
