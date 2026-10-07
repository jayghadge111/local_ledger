import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/budgets_repository.dart';

void main() {
  late AppDatabase db;
  late BudgetsRepository repo;
  const cat = 'cat_other';
  final sep = DateTime(2026, 9);
  final oct = DateTime(2026, 10);
  final nov = DateTime(2026, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BudgetsRepository(db);
  });
  tearDown(() => db.close());

  Future<int?> limitIn(DateTime month) async {
    final all = budgetsForMonth(
      await db.select(db.budgets).get(),
      await db.select(db.budgetOverrides).get(),
      month,
    );
    return all.where((b) => b.categoryId == cat).firstOrNull?.monthlyLimitMinor;
  }

  test('removing from a month on keeps the earlier months', () async {
    await repo.setBudgetFrom(
      categoryId: cat,
      fromMonth: sep,
      limitMinor: 500000,
    );
    expect(await limitIn(nov), 500000);

    final undo = await repo.removeBudget(
      categoryId: cat,
      month: oct,
      fromHere: true,
    );
    expect(await limitIn(sep), 500000);
    expect(await limitIn(oct), isNull);
    expect(await limitIn(nov), isNull);

    await undo();
    expect(await limitIn(oct), 500000);
    expect(await limitIn(nov), 500000);
  });

  test('removing one month leaves the others', () async {
    await repo.setBudgetFrom(
      categoryId: cat,
      fromMonth: sep,
      limitMinor: 500000,
    );
    await repo.removeBudget(categoryId: cat, month: oct, fromHere: false);
    expect(await limitIn(sep), 500000);
    expect(await limitIn(oct), isNull);
    expect(await limitIn(nov), 500000);
  });

  test('removing a budget that starts this month leaves no trace', () async {
    await repo.setBudgetFrom(
      categoryId: cat,
      fromMonth: oct,
      limitMinor: 300000,
    );
    await repo.removeBudget(categoryId: cat, month: oct, fromHere: true);
    expect(await limitIn(oct), isNull);
    expect(await limitIn(nov), isNull);
    expect(await db.select(db.budgets).get(), isEmpty);
  });

  test('a limit set for one month only is dropped, not zeroed', () async {
    await repo.setMonthBudget(
      categoryId: cat,
      month: oct,
      limitMinor: 100000,
    );
    expect(await limitIn(oct), 100000);
    await repo.removeBudget(categoryId: cat, month: oct, fromHere: false);
    expect(await limitIn(oct), isNull);
    expect(await db.select(db.budgetOverrides).get(), isEmpty);
  });

  test('a month-only limit on top of a standing one can be removed', () async {
    await repo.setBudgetFrom(
      categoryId: cat,
      fromMonth: sep,
      limitMinor: 500000,
    );
    await repo.setMonthBudget(
      categoryId: cat,
      month: oct,
      limitMinor: 200000,
    );
    await repo.removeBudget(categoryId: cat, month: oct, fromHere: false);
    expect(await limitIn(oct), isNull);
    expect(await limitIn(nov), 500000);
  });
}
