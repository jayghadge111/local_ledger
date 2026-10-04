import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/onboarding/onboarding_name_screen.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {double keyboard = 0}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 780),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: MaterialApp(home: OnboardingNameScreen(onDone: () {})),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('"Why we ask" sits directly above Continue', (tester) async {
    await pump(tester);
    final why = tester.getRect(find.text('Why we ask'));
    final button = tester.getRect(find.text('Continue'));
    final field = tester.getRect(find.byType(TextField));
    expect(why.bottom, lessThan(button.top));
    expect(button.top - why.bottom, lessThan(150));
    expect(why.top, greaterThan(field.bottom));
    await unmount(tester);
  });

  testWidgets('still fits with the keyboard open', (tester) async {
    await pump(tester, keyboard: 300);
    expect(tester.takeException(), isNull);
    expect(find.text('Why we ask'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await unmount(tester);
  });
}
