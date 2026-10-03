import 'package:drift/drift.dart';
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

  /// Sets the limit for [categoryId] in [month] only; other months keep the
  /// standing budget.
  Future<void> setMonthBudget({
    required String categoryId,
    required DateTime month,
    required int limitMinor,
  }) async {
    final key = monthKeyOf(month);
    final existing = await (_db.select(_db.budgetOverrides)
          ..where((o) => o.categoryId.equals(categoryId) & o.monthKey.equals(key)))
        .getSingleOrNull();
    await _db.into(_db.budgetOverrides).insertOnConflictUpdate(
          BudgetOverridesCompanion.insert(
            id: existing?.id ?? _uuid.v4(),
            categoryId: categoryId,
            monthKey: key,
            limitMinor: limitMinor,
          ),
        );
  }

  /// Back to the standing budget for that month.
  Future<void> clearMonthBudget({required String categoryId, required DateTime month}) {
    final key = monthKeyOf(month);
    return (_db.delete(_db.budgetOverrides)
          ..where((o) => o.categoryId.equals(categoryId) & o.monthKey.equals(key)))
        .go();
  }

  Future<void> deleteBudget(String id) {
    return (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
  }
}

String monthKeyOf(DateTime month) => '${month.year}-${month.month.toString().padLeft(2, '0')}';

final budgetOverridesProvider = StreamProvider<List<BudgetOverride>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.budgetOverrides).watch();
});

/// The budgets in force for [month]: each category's standing limit, replaced
/// by its limit for that month where the user set one. A category can have a
/// limit for just one month and none otherwise.
List<Budget> budgetsForMonth(List<Budget> standing, List<BudgetOverride> overrides, DateTime month) {
  final key = monthKeyOf(month);
  final forMonth = {for (final o in overrides) if (o.monthKey == key) o.categoryId: o};
  final result = <Budget>[];
  for (final b in standing) {
    final o = forMonth.remove(b.categoryId);
    result.add(o == null ? b : Budget(id: b.id, categoryId: b.categoryId, monthlyLimitMinor: o.limitMinor));
  }
  for (final o in forMonth.values) {
    result.add(Budget(id: o.id, categoryId: o.categoryId, monthlyLimitMinor: o.limitMinor));
  }
  return result;
}

/// Budgets in force for a month, as Home, Budgets and the alerts see them.
final monthBudgetsProvider = Provider.family<List<Budget>, DateTime>((ref, month) {
  return budgetsForMonth(
    ref.watch(budgetsProvider).value ?? const <Budget>[],
    ref.watch(budgetOverridesProvider).value ?? const <BudgetOverride>[],
    month,
  );
});
