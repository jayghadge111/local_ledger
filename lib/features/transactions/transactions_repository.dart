import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/ingest/reconciler.dart';
import '../../core/intelligence/merchant_normalizer.dart';
import '../../core/ui/undo.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(databaseProvider));
});

class TransactionsRepository {
  TransactionsRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Returns the new transaction's id.
  Future<String> addManualTransaction({
    required int amountMinor,
    required String merchant,
    required String categoryId,
    required String type,
    required DateTime date,
    bool isInternational = false,
    String? accountId,
    bool isTransfer = false,
    bool isCardPayment = false,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            accountId: Value(accountId),
            amountMinor: amountMinor,
            merchant: merchant,
            categoryId: Value(categoryId),
            type: type,
            date: date,
            source: 'manual',
            userEdited: const Value(true),
            isInternational: Value(isInternational),
            kind: Value(
              isTransfer
                  ? 'transfer'
                  : (isCardPayment && type == 'debit'
                        ? 'card_payment'
                        : 'normal'),
            ),
            kindLocked: Value(isTransfer || isCardPayment),
          ),
        );
    await Reconciler(_db).run();
    return id;
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
    bool? isCardPayment,
  }) async => (await updateTransactionUndoable(
    id,
    amountMinor: amountMinor,
    merchant: merchant,
    categoryId: categoryId,
    type: type,
    date: date,
    isInternational: isInternational,
    accountId: accountId,
    isTransfer: isTransfer,
    isCardPayment: isCardPayment,
  )).applied;

  /// Like [updateTransaction], also returning how to take back the part that
  /// touched *other* transactions (see [updateTransaction]).
  Future<({int applied, UndoAction? undo})> updateTransactionUndoable(
    String id, {
    required int amountMinor,
    required String merchant,
    required String categoryId,
    required String type,
    required DateTime date,
    bool isInternational = false,
    String? accountId,
    bool? isTransfer,
    bool? isCardPayment,

    /// Teach the app from this edit: remember the merchant name and category
    /// and apply them to similar transactions. Off for a one-off correction.
    bool learn = true,

    /// Run the transfer/refund re-check in the background instead of before
    /// returning (it reads every transaction).
    bool deferReconcile = false,
  }) async {
    final existing = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingle();
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
    if (isTransfer != true &&
        isCardPayment != null &&
        isCardPayment != (existing.kind == 'card_payment')) {
      await setCardPayment(id, isCardPayment && type == 'debit');
    }

    var learned = learn
        ? await _learnAlias(existing, newMerchant, categoryId)
        : (applied: 0, undo: null as UndoAction?);
    if (learn && learned.applied == 0) {
      learned = await _learnCategory(existing, newMerchant, categoryId);
    }
    if (deferReconcile) {
      unawaited(
        Reconciler(_db).run().then<void>((_) {}, onError: (Object _) {}),
      );
    } else {
      await Reconciler(_db).run();
    }
    return learned;
  }

  /// Teaches the app that [existing]'s raw bank text means [newMerchant],
  /// and applies that to every other not-yet-edited transaction with the
  /// same raw text.
  Future<({int applied, UndoAction? undo})> _learnAlias(
    Transaction existing,
    String newMerchant,
    String categoryId,
  ) async {
    const none = (applied: 0, undo: null);
    final raw = existing.rawMerchant?.trim();
    if (raw == null || raw.isEmpty || newMerchant == existing.merchant) {
      return none;
    }
    // "UPI payment", "NEFT transfer"… are shared by unrelated payments; the
    // user's rename describes this one payment, not all of them.
    if (isGenericMerchantLabel(raw)) return none;

    final pattern = raw.toLowerCase();
    Expression<bool> affectedFilter($TransactionsTable t) =>
        t.rawMerchant.lower().equals(pattern) &
        t.id.equals(existing.id).not() &
        t.userEdited.equals(false);
    final before = await (_db.select(
      _db.transactions,
    )..where(affectedFilter)).get();
    final previousAliases = await (_db.select(
      _db.merchantAliases,
    )..where((a) => a.pattern.equals(pattern))).get();

    await (_db.delete(
      _db.merchantAliases,
    )..where((a) => a.pattern.equals(pattern))).go();
    final aliasId = _uuid.v4();
    await _db
        .into(_db.merchantAliases)
        .insert(
          MerchantAliasesCompanion.insert(
            id: aliasId,
            pattern: pattern,
            displayName: newMerchant,
          ),
        );

    final applied =
        await (_db.update(_db.transactions)..where(affectedFilter)).write(
          TransactionsCompanion(
            merchant: Value(newMerchant),
            categoryId: existing.categoryId != categoryId
                ? Value(categoryId)
                : const Value.absent(),
          ),
        );
    if (applied == 0) return (applied: 0, undo: null);

    return (
      applied: applied,
      undo: () async {
        await (_db.delete(
          _db.merchantAliases,
        )..where((a) => a.id.equals(aliasId))).go();
        for (final a in previousAliases) {
          await _db.into(_db.merchantAliases).insertOnConflictUpdate(a);
        }
        await _restoreLabels(before);
      },
    );
  }

  /// Puts each of [rows] back to the merchant and category it had.
  Future<void> _restoreLabels(List<Transaction> rows) async {
    await _db.batch((b) {
      for (final t in rows) {
        b.update(
          _db.transactions,
          TransactionsCompanion(
            merchant: Value(t.merchant),
            categoryId: Value(t.categoryId),
          ),
          where: (x) => x.id.equals(t.id),
        );
      }
    });
  }

  /// The user re-categorized a merchant: remember it as a rule for future
  /// imports and apply it to the other, not-yet-edited transactions of the
  /// same merchant. Returns how many others changed, and how to take it back.
  Future<({int applied, UndoAction? undo})> _learnCategory(
    Transaction existing,
    String merchant,
    String categoryId,
  ) async {
    const none = (applied: 0, undo: null);
    if (existing.categoryId == categoryId) return none;
    final pattern = merchant.toLowerCase();
    if (pattern.length < 3) return none;
    // Same reason: a category chosen for one "UPI payment" says nothing about
    // the next one — only a named payee is worth learning.
    if (isGenericMerchantLabel(merchant)) return none;

    Expression<bool> affectedFilter($TransactionsTable t) =>
        t.merchant.lower().equals(pattern) &
        t.id.equals(existing.id).not() &
        t.userEdited.equals(false);
    final before = await (_db.select(
      _db.transactions,
    )..where(affectedFilter)).get();

    final known = await (_db.select(
      _db.rules,
    )..where((r) => r.pattern.equals(pattern))).get();
    String? newRuleId;
    if (known.isEmpty) {
      newRuleId = _uuid.v4();
      await _db
          .into(_db.rules)
          .insert(
            RulesCompanion.insert(
              id: newRuleId,
              pattern: pattern,
              categoryId: categoryId,
              source: 'user',
            ),
          );
    } else {
      await (_db.update(_db.rules)..where((r) => r.pattern.equals(pattern)))
          .write(RulesCompanion(categoryId: Value(categoryId)));
    }

    final applied =
        await (_db.update(_db.transactions)..where(affectedFilter)).write(
          TransactionsCompanion(categoryId: Value(categoryId)),
        );
    if (applied == 0) return (applied: 0, undo: null);

    return (
      applied: applied,
      undo: () async {
        if (newRuleId != null) {
          await (_db.delete(_db.rules)..where((r) => r.id.equals(newRuleId!)))
              .go();
        }
        for (final r in known) {
          await _db.into(_db.rules).insertOnConflictUpdate(r);
        }
        await _restoreLabels(before);
      },
    );
  }

  /// Marks a debit as a credit-card bill payment (shown, but not counted as
  /// spending) or back to a normal expense. Locked so re-reading the message
  /// can't undo the user's choice.
  Future<void> setCardPayment(String id, bool isCardPayment) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        kind: Value(isCardPayment ? 'card_payment' : 'normal'),
        kindLocked: const Value(true),
        transferGroupId: const Value(null),
      ),
    );
  }

  /// Marks a transaction as a transfer between the user's own accounts (or
  /// back to normal). Either way the choice is locked in so auto-detection
  /// won't overrule it. Un-marking also releases the other half of a pair,
  /// locked as normal too — rejecting the pair shouldn't let that half be
  /// re-read as a refund.
  Future<void> setTransfer(String id, bool isTransfer) async {
    final tx = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingle();
    await _db.transaction(() async {
      if (!isTransfer && tx.transferGroupId != null) {
        await (_db.update(_db.transactions)..where(
              (t) =>
                  t.transferGroupId.equals(tx.transferGroupId!) &
                  t.id.equals(id).not(),
            ))
            .write(
              const TransactionsCompanion(
                kind: Value('normal'),
                kindLocked: Value(true),
                transferGroupId: Value(null),
              ),
            );
      }
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          kind: Value(isTransfer ? 'transfer' : 'normal'),
          kindLocked: const Value(true),
          categoryId:
              isTransfer &&
                  !tx.userEdited &&
                  (tx.categoryId == null || tx.categoryId == 'cat_other')
              ? const Value('cat_self_transfer')
              : const Value.absent(),
          transferGroupId: isTransfer
              ? const Value.absent()
              : const Value(null),
        ),
      );
    });
  }

  /// The "Cash" account, created on first use.
  Future<String> cashAccountId() async {
    final existing = await (_db.select(
      _db.accounts,
    )..where((a) => a.accountType.equals('cash'))).getSingleOrNull();
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(id: id, name: 'Cash', accountType: 'cash'),
        );
    return id;
  }

  /// Soft delete — keeps the row (and its original raw SMS/email text, if
  /// any) so it can be recovered or audited later, just hides it from the
  /// normal transaction list.
  ///
  /// Returns the way back.
  Future<UndoAction> softDelete(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(isDeleted: Value(true)),
    );
    return () => restoreDeleted(id);
  }

  /// Brings a soft-deleted transaction back.
  Future<void> restoreDeleted(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(isDeleted: Value(false)),
    );
    await Reconciler(_db).run();
  }
}
