import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';

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
  }) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            amountMinor: amountMinor,
            merchant: merchant,
            categoryId: Value(categoryId),
            type: type,
            date: date,
            source: 'manual',
            userEdited: const Value(true),
            isInternational: Value(isInternational),
          ),
        );
  }

  Future<void> updateTransaction(
    String id, {
    required int amountMinor,
    required String merchant,
    required String categoryId,
    required String type,
    required DateTime date,
    bool isInternational = false,
  }) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        amountMinor: Value(amountMinor),
        merchant: Value(merchant),
        categoryId: Value(categoryId),
        type: Value(type),
        date: Value(date),
        userEdited: const Value(true),
        isInternational: Value(isInternational),
      ),
    );
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
