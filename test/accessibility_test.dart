import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/mock_data_seeder.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/theme/app_theme.dart';
import 'package:local_ledger/features/alerts/alerts_screen.dart';
import 'package:local_ledger/features/budgets/budgets_screen.dart';
import 'package:local_ledger/features/calendar/calendar_screen.dart';
import 'package:local_ledger/features/dashboard/dashboard_screen.dart';
import 'package:local_ledger/features/lending/lending_screen.dart';
import 'package:local_ledger/features/splits/splits_ui.dart';
import 'package:local_ledger/features/settings/settings_screen.dart';
import 'package:local_ledger/features/transactions/transactions_screen.dart';

// People use big text, small phones and dark mode. Every main screen is built
// at the sizes that go wrong most often and must lay out without overflowing,
// and the colours must stay readable.

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('colours are readable (WCAG AA, 4.5:1 for text)', () {
    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      final s = theme.colorScheme;
      final pairs = <String, (Color, Color)>{
        'text on cards': (s.onSurface, s.surface),
        'text on the page': (s.onSurface, theme.scaffoldBackgroundColor),
        'secondary text on cards': (s.onSurfaceVariant, s.surface),
        'secondary text on the page': (
          s.onSurfaceVariant,
          theme.scaffoldBackgroundColor,
        ),
        'buttons': (s.onPrimary, s.primary),
        'chips': (s.onSecondary, s.secondary),
        'primary links on cards': (s.primary, s.surface),
        'errors on cards': (s.error, s.surface),
        'text on chips': (s.onSecondaryContainer, s.secondaryContainer),
      };
      pairs.forEach((label, p) {
        test('$name: $label', () {
          expect(
            contrast(p.$1, p.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${p.$1} on ${p.$2}',
          );
        });
      });
      test('$name: chart labels on their bars', () {
        final c = theme.extension<ChartColors>()!;
        expect(contrast(c.softText, c.soft), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('main screens survive big text on small phones', () {
    final screens = <String, Widget>{
      'Home': const DashboardScreen(),
      'Transactions': const TransactionsScreen(),
      'Alerts': const AlertsScreen(),
      'Split': const SplitsScreen(),
      'Settings': const SettingsScreen(),
      'Budgets': const BudgetsScreen(),
      'Lend & borrow': const LendingScreen(),
      'Calendar': const CalendarScreen(),
    };

    screens.forEach((name, screen) {
      testWidgets('$name: every control is 48dp and has a label for TalkBack', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(411 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await tester.runAsync(() => seedMockTransactions(db));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: ThemeData(colorScheme: AppTheme.light().colorScheme),
              home: Scaffold(body: screen),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
        await tester.runAsync(db.close);
      });

      for (final scale in [1.0, 1.5, 2.0]) {
        for (final width in [320.0, 411.0]) {
          testWidgets('$name at ${scale}x text, ${width.toInt()}px wide', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width * 3, 800 * 3);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            final db = AppDatabase.forTesting(NativeDatabase.memory());
            await tester.runAsync(() => seedMockTransactions(db));

            await tester.pumpWidget(
              ProviderScope(
                overrides: [databaseProvider.overrideWithValue(db)],
                child: MaterialApp(
                  // Fonts are not fetched in tests; the layout is what is
                  // being checked, with the app's colours.
                  theme: ThemeData(colorScheme: AppTheme.light().colorScheme),
                  darkTheme: ThemeData(
                    colorScheme: AppTheme.dark().colorScheme,
                  ),
                  themeMode: scale == 2.0 ? ThemeMode.dark : ThemeMode.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(body: screen),
                ),
              ),
            );
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)),
            );
            for (var i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            expect(tester.takeException(), isNull);

            // Unmount, let drift's stream clean-up timers fire, then close.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 50));
            await tester.runAsync(db.close);
          });
        }
      }
    });
  });
}
