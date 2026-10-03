import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

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
        },
      );

  /// Earlier versions learned a rule from any edit, including to generic
  /// labels like "UPI payment" — so one payment's category or name was pushed
  /// onto every such payment. This drops those rules and aliases, and undoes
  /// what they did to payments the user never edited themselves.
  Future<void> undoGenericLearning() async {
    for (final a in await select(merchantAliases).get()) {
      if (!isGenericMerchantLabel(a.pattern)) continue;
      final affected = await (select(transactions)
            ..where((t) => t.userEdited.equals(false) & t.merchant.equals(a.displayName)))
          .get();
      for (final t in affected) {
        if (t.rawMerchant?.toLowerCase() != a.pattern) continue;
        await (update(transactions)..where((x) => x.id.equals(t.id))).write(
          TransactionsCompanion(merchant: Value(normalizeMerchant(t.rawMerchant!))),
        );
      }
      await (delete(merchantAliases)..where((x) => x.id.equals(a.id))).go();
    }
    for (final r in await (select(rules)..where((x) => x.source.equals('user'))).get()) {
      if (!isGenericMerchantLabel(r.pattern)) continue;
      final affected = await (select(transactions)
            ..where((t) => t.userEdited.equals(false) & t.categoryId.equals(r.categoryId)))
          .get();
      for (final t in affected) {
        if (t.merchant.toLowerCase() != r.pattern) continue;
        await (update(transactions)..where((x) => x.id.equals(t.id))).write(
          TransactionsCompanion(
            categoryId: Value(
              defaultCategoryFor('${t.merchant} ${t.rawMerchant ?? ''}', isCredit: t.type == 'credit') ?? 'cat_other',
            ),
          ),
        );
      }
      await (delete(rules)..where((x) => x.id.equals(r.id))).go();
    }
  }

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
