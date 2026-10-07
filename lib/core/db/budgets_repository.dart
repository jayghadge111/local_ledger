import '../ui/undo.dart';

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

  /// Sets the limit for [categoryId] from [fromMonth] onwards. Earlier months
  /// keep whatever applied to them, and later months carry this limit forward
  /// until a newer one starts. Setting it again for the same starting month
  /// replaces it. A one-month limit set for [fromMonth] is dropped, since this
  /// now covers it.
  Future<void> setBudgetFrom({
    required String categoryId,
    required DateTime fromMonth,
    required int limitMinor,
  }) {
    final key = monthKeyOf(fromMonth);
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.budgets)..where(
                (b) =>
                    b.categoryId.equals(categoryId) &
                    b.fromMonthKey.equals(key),
              ))
              .getSingleOrNull();
      await _db
          .into(_db.budgets)
          .insertOnConflictUpdate(
            BudgetsCompanion.insert(
              id: existing?.id ?? _uuid.v4(),
              categoryId: categoryId,
              monthlyLimitMinor: limitMinor,
              fromMonthKey: Value(key),
            ),
          );
      await clearMonthBudget(categoryId: categoryId, month: fromMonth);
    });
  }

  /// Sets the limit for [categoryId] in [month] only; other months keep the
  /// standing budget.
  Future<void> setMonthBudget({
    required String categoryId,
    required DateTime month,
    required int limitMinor,
  }) async {
    final key = monthKeyOf(month);
    final existing =
        await (_db.select(_db.budgetOverrides)..where(
              (o) => o.categoryId.equals(categoryId) & o.monthKey.equals(key),
            ))
            .getSingleOrNull();
    await _db
        .into(_db.budgetOverrides)
        .insertOnConflictUpdate(
          BudgetOverridesCompanion.insert(
            id: existing?.id ?? _uuid.v4(),
            categoryId: categoryId,
            monthKey: key,
            limitMinor: limitMinor,
          ),
        );
  }

  /// Back to the standing budget for that month.
  Future<void> clearMonthBudget({
    required String categoryId,
    required DateTime month,
  }) {
    final key = monthKeyOf(month);
    return (_db.delete(_db.budgetOverrides)..where(
          (o) => o.categoryId.equals(categoryId) & o.monthKey.equals(key),
        ))
        .go();
  }

  /// Takes the budget for [categoryId] away: for [month] only, or from
  /// [month] on (later months too; earlier ones keep theirs). A limit of 0 is
  /// how "no budget" is recorded where an earlier limit would otherwise carry
  /// forward. Returns the way back.
  Future<UndoAction> removeBudget({
    required String categoryId,
    required DateTime month,
    required bool fromHere,
  }) async {
    final key = monthKeyOf(month);
    final budgets = await (_db.select(
      _db.budgets,
    )..where((b) => b.categoryId.equals(categoryId))).get();
    final overrides = await (_db.select(
      _db.budgetOverrides,
    )..where((o) => o.categoryId.equals(categoryId))).get();

    await _db.transaction(() async {
      // The latest standing limit that has started before this month.
      final before = budgets
          .where((b) => b.fromMonthKey.compareTo(key) < 0)
          .fold<Budget?>(
            null,
            (a, b) => a == null || b.fromMonthKey.compareTo(a.fromMonthKey) > 0
                ? b
                : a,
          );
      final carriesIn = before != null && before.monthlyLimitMinor > 0;

      if (fromHere) {
        await (_db.delete(_db.budgets)..where(
              (b) =>
                  b.categoryId.equals(categoryId) &
                  b.fromMonthKey.isBiggerOrEqualValue(key),
            ))
            .go();
        await (_db.delete(_db.budgetOverrides)..where(
              (o) =>
                  o.categoryId.equals(categoryId) &
                  o.monthKey.isBiggerOrEqualValue(key),
            ))
            .go();
        if (carriesIn) {
          await _db
              .into(_db.budgets)
              .insert(
                BudgetsCompanion.insert(
                  id: _uuid.v4(),
                  categoryId: categoryId,
                  monthlyLimitMinor: 0,
                  fromMonthKey: Value(key),
                ),
              );
        }
        return;
      }

      // This month only. A standing limit that applies needs a "none" for
      // the month; otherwise the month's own limit is simply dropped.
      final inForce = budgets
          .where((b) => b.fromMonthKey.compareTo(key) <= 0)
          .fold<Budget?>(
            null,
            (a, b) => a == null || b.fromMonthKey.compareTo(a.fromMonthKey) > 0
                ? b
                : a,
          );
      final standingApplies = inForce != null && inForce.monthlyLimitMinor > 0;
      await clearMonthBudget(categoryId: categoryId, month: month);
      if (standingApplies) {
        await setMonthBudget(
          categoryId: categoryId,
          month: month,
          limitMinor: 0,
        );
      }
    });

    return () async {
      await _db.transaction(() async {
        await (_db.delete(
          _db.budgets,
        )..where((b) => b.categoryId.equals(categoryId))).go();
        await (_db.delete(
          _db.budgetOverrides,
        )..where((o) => o.categoryId.equals(categoryId))).go();
        for (final b in budgets) {
          await _db.into(_db.budgets).insert(b);
        }
        for (final o in overrides) {
          await _db.into(_db.budgetOverrides).insert(o);
        }
      });
    };
  }

  /// Returns the way back.
  Future<UndoAction> deleteBudget(String id) async {
    final row = await (_db.select(
      _db.budgets,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    await (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
    return () async {
      if (row != null) await _db.into(_db.budgets).insertOnConflictUpdate(row);
    };
  }
}

String monthKeyOf(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

final budgetOverridesProvider = StreamProvider<List<BudgetOverride>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.budgetOverrides).watch();
});

/// The budgets in force for [month]. For each category that is the latest
/// standing limit that has started by then (so later changes never touch
/// earlier months), replaced by its limit for that one month where the user
/// set one. A category can have a limit for just one month and none otherwise.
List<Budget> budgetsForMonth(
  List<Budget> standing,
  List<BudgetOverride> overrides,
  DateTime month,
) {
  final key = monthKeyOf(month);

  final latest = <String, Budget>{};
  for (final b in standing) {
    if (b.fromMonthKey.compareTo(key) > 0) continue; // not started yet
    final current = latest[b.categoryId];
    if (current == null || b.fromMonthKey.compareTo(current.fromMonthKey) > 0) {
      latest[b.categoryId] = b;
    }
  }

  final forMonth = {
    for (final o in overrides)
      if (o.monthKey == key) o.categoryId: o,
  };
  final result = <Budget>[];
  for (final b in standing) {
    if (!identical(latest[b.categoryId], b)) continue;
    final o = forMonth.remove(b.categoryId);
    result.add(
      o == null
          ? b
          : Budget(
              id: b.id,
              categoryId: b.categoryId,
              monthlyLimitMinor: o.limitMinor,
              fromMonthKey: b.fromMonthKey,
            ),
    );
  }
  for (final o in forMonth.values) {
    result.add(
      Budget(
        id: o.id,
        categoryId: o.categoryId,
        monthlyLimitMinor: o.limitMinor,
        fromMonthKey: key,
      ),
    );
  }
  // A limit of 0 means "no budget" (see [BudgetsRepository.removeBudget]).
  return [
    for (final b in result)
      if (b.monthlyLimitMinor > 0) b,
  ];
}

/// Whether [month] is over (before the month containing [now]). Its budgets
/// are locked behind an explicit "edit anyway".
bool isPastMonth(DateTime month, DateTime now) =>
    DateTime(month.year, month.month).isBefore(DateTime(now.year, now.month));

/// Budgets in force for a month, as Home, Budgets and the alerts see them.
final monthBudgetsProvider = Provider.family<List<Budget>, DateTime>((
  ref,
  month,
) {
  return budgetsForMonth(
    ref.watch(budgetsProvider).value ?? const <Budget>[],
    ref.watch(budgetOverridesProvider).value ?? const <BudgetOverride>[],
    month,
  );
});
