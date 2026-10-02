import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/ingest/reconciler.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(databaseProvider));
});

class TransactionsRepository {
  TransactionsRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<void> addManualTransaction({
    required int amountMinor,
    required String merchant,
    required String categoryId,
    required String type,
    required DateTime date,
    bool isInternational = false,
    String? accountId,
    bool isTransfer = false,
  }) async {
    await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            accountId: Value(accountId),
            amountMinor: amountMinor,
            merchant: merchant,
            categoryId: Value(categoryId),
            type: type,
            date: date,
            source: 'manual',
            userEdited: const Value(true),
            isInternational: Value(isInternational),
            kind: Value(isTransfer ? 'transfer' : 'normal'),
            kindLocked: Value(isTransfer),
          ),
        );
    await Reconciler(_db).run();
  }

  /// Returns how many *other* transactions were relabelled because the
  /// user's merchant correction was learned as an alias.
  Future<int> updateTransaction(
    String id, {
    required int amountMinor,
    required String merchant,
    required String categoryId,
    required String type,
    required DateTime date,
    bool isInternational = false,
    String? accountId,
    bool? isTransfer,
  }) async {
    final existing =
        await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingle();
    final newMerchant = merchant.trim();

    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amountMinor: Value(amountMinor),
        merchant: Value(newMerchant),
        categoryId: Value(categoryId),
        type: Value(type),
        date: Value(date),
        userEdited: const Value(true),
        isInternational: Value(isInternational),
        accountId: accountId == null ? const Value.absent() : Value(accountId),
      ),
    );

    if (isTransfer != null && isTransfer != (existing.kind == 'transfer')) {
      await setTransfer(id, isTransfer);
    }

    var applied = await _learnAlias(existing, newMerchant, categoryId);
    if (applied == 0) applied = await _learnCategory(existing, newMerchant, categoryId);
    await Reconciler(_db).run();
    return applied;
  }

  /// Teaches the app that [existing]'s raw bank text means [newMerchant],
  /// and applies that to every other not-yet-edited transaction with the
  /// same raw text.
  Future<int> _learnAlias(Transaction existing, String newMerchant, String categoryId) async {
    final raw = existing.rawMerchant?.trim();
    if (raw == null || raw.isEmpty || newMerchant == existing.merchant) return 0;

    final pattern = raw.toLowerCase();
    await (_db.delete(_db.merchantAliases)..where((a) => a.pattern.equals(pattern))).go();
    await _db.into(_db.merchantAliases).insert(
          MerchantAliasesCompanion.insert(
            id: _uuid.v4(),
            pattern: pattern,
            displayName: newMerchant,
          ),
        );

    return (_db.update(_db.transactions)
          ..where((t) =>
              t.rawMerchant.lower().equals(pattern) &
              t.id.equals(existing.id).not() &
              t.userEdited.equals(false)))
        .write(TransactionsCompanion(
      merchant: Value(newMerchant),
      categoryId: existing.categoryId != categoryId ? Value(categoryId) : const Value.absent(),
    ));
  }

  /// The user re-categorized a merchant: remember it as a rule for future
  /// imports and apply it to the other, not-yet-edited transactions of the
  /// same merchant. Returns how many others changed.
  Future<int> _learnCategory(Transaction existing, String merchant, String categoryId) async {
    if (existing.categoryId == categoryId) return 0;
    final pattern = merchant.toLowerCase();
    if (pattern.length < 3) return 0;

    final known = await (_db.select(_db.rules)..where((r) => r.pattern.equals(pattern))).get();
    if (known.isEmpty) {
      await _db.into(_db.rules).insert(
            RulesCompanion.insert(
              id: _uuid.v4(),
              pattern: pattern,
              categoryId: categoryId,
              source: 'user',
            ),
          );
    } else {
      await (_db.update(_db.rules)..where((r) => r.pattern.equals(pattern)))
          .write(RulesCompanion(categoryId: Value(categoryId)));
    }

    return (_db.update(_db.transactions)
          ..where((t) =>
              t.merchant.lower().equals(pattern) &
              t.id.equals(existing.id).not() &
              t.userEdited.equals(false)))
        .write(TransactionsCompanion(categoryId: Value(categoryId)));
  }

  /// Marks a transaction as a transfer between the user's own accounts (or
  /// back to normal). Either way the choice is locked in so auto-detection
  /// won't overrule it. Un-marking also releases the other half of a pair,
  /// locked as normal too — rejecting the pair shouldn't let that half be
  /// re-read as a refund.
  Future<void> setTransfer(String id, bool isTransfer) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingle();
    await _db.transaction(() async {
      if (!isTransfer && tx.transferGroupId != null) {
        await (_db.update(_db.transactions)
              ..where((t) => t.transferGroupId.equals(tx.transferGroupId!) & t.id.equals(id).not()))
            .write(const TransactionsCompanion(
          kind: Value('normal'),
          kindLocked: Value(true),
          transferGroupId: Value(null),
        ));
      }
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          kind: Value(isTransfer ? 'transfer' : 'normal'),
          kindLocked: const Value(true),
          transferGroupId: isTransfer ? const Value.absent() : const Value(null),
        ),
      );
    });
  }

  /// The "Cash" account, created on first use.
  Future<String> cashAccountId() async {
    final existing = await (_db.select(_db.accounts)
          ..where((a) => a.accountType.equals('cash')))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(id: id, name: 'Cash', accountType: 'cash'),
        );
    return id;
  }

  /// Soft delete — keeps the row (and its original raw SMS/email text, if
  /// any) so it can be recovered or audited later, just hides it from the
  /// normal transaction list.
  Future<void> softDelete(String id) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(isDeleted: Value(true)),
    );
  }
}
