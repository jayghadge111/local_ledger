import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/budgets_repository.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/budgets/budgets_screen.dart';

void main() {
  testWidgets('a row with a budget has a red remove icon that confirms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final short = DateFormat('MMM').format(month);
    await tester.runAsync(
      () => BudgetsRepository(db).setBudgetFrom(
        categoryId: 'cat_other',
        fromMonth: month,
        limitMinor: 500000,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final remove = find.byIcon(
      Icons.delete_outline_rounded,
      skipOffstage: false,
    );
    expect(remove, findsOneWidget); // only the category that has a budget

    await tester.ensureVisible(remove);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(remove);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Remove'), findsOneWidget); // one button, this month only
    expect(find.text('Only $short'), findsNothing);
    expect(find.text('$short on'), findsNothing);

    await tester.tap(find.text('Remove'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(remove, findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });

  testWidgets('removing for this month only does not leave an "only" badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final short = DateFormat('MMM').format(month);
    final repo = BudgetsRepository(db);
    await tester.runAsync(() async {
      await repo.setBudgetFrom(
        categoryId: 'cat_other',
        fromMonth: DateTime(now.year, now.month - 1),
        limitMinor: 500000,
      );
      await repo.removeBudget(
        categoryId: 'cat_other',
        month: month,
        fromHere: false,
      );
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: BudgetsScreen()),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('$short only', skipOffstage: false), findsNothing);
    expect(
      find.byIcon(Icons.delete_outline_rounded, skipOffstage: false),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}
