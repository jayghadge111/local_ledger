import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'providers.dart';

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.budgets).watch();
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(databaseProvider));
});

class BudgetsRepository {
  BudgetsRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Upserts by category: a category has at most one budget, so setting it
  /// again updates the existing row instead of creating a duplicate.
  Future<void> setBudget({
    required String categoryId,
    required int monthlyLimitMinor,
  }) async {
    final existing = await (_db.select(_db.budgets)
          ..where((b) => b.categoryId.equals(categoryId)))
        .getSingleOrNull();

    await _db.into(_db.budgets).insertOnConflictUpdate(
          BudgetsCompanion.insert(
            id: existing?.id ?? _uuid.v4(),
            categoryId: categoryId,
            monthlyLimitMinor: monthlyLimitMinor,
          ),
        );
  }

  Future<void> deleteBudget(String id) {
    return (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }
}
