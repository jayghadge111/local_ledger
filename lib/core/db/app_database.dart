import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

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
            await m.addColumn(transactions, transactions.rawMerchant);
            await m.addColumn(transactions, transactions.kind);
            await m.addColumn(transactions, transactions.kindLocked);
            await m.addColumn(transactions, transactions.transferGroupId);
            await m.addColumn(transactions, transactions.refundOfId);
            await m.addColumn(transactions, transactions.refundHint);
            await m.addColumn(transactions, transactions.sourceHash);
            await m.createTable(ownIdentifiers);
            await m.createTable(merchantAliases);
            await m.createTable(splitShares);
            await m.createTable(unparsedMessages);
          }
          if (from < 4) {
            await m.addColumn(transactions, transactions.alsoInSource);
          }
        },
      );

  Future<void> _seedDefaultCategories() {
    return batch((b) {
      b.insertAll(
        categories,
        [
          for (final c in defaultCategories)
            CategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              icon: Value(c.iconKey),
              isDefault: const Value(true),
            ),
        ],
      );
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'local_ledger_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
