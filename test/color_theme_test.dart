import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/theme/app_theme.dart';
import 'package:local_ledger/core/theme/color_theme_provider.dart';
import 'package:local_ledger/core/theme/color_themes.dart';
import 'package:local_ledger/features/settings/widgets/color_theme_picker.dart';

/// The theme the provider currently reports. Listens for the first value
/// (a bare `.future` read can stall because nothing keeps the stream alive).
Future<ColorTheme> currentTheme(ProviderContainer c) async {
  final done = Completer<ColorTheme>();
  final sub = c.listen<AsyncValue<ColorTheme>>(colorThemeProvider, (_, next) {
    if (next.hasValue && !done.isCompleted) done.complete(next.value);
  }, fireImmediately: true);
  addTearDown(sub.close);
  return done.future.timeout(const Duration(seconds: 5));
}

void main() {
  group('the three themes hold the agreed colours', () {
    test('Ice Sky & Jet Ink', () {
      final t = ColorTheme.iceSky.tokens;
      expect(t.scaffold, const Color(0xFFF8FCFF));
      expect(t.cardSurface, const Color(0xFFFFFFFF));
      expect(t.cardBorder, const Color(0xFFE0F2FE));
      expect(t.activeChip, const Color(0xFFBAE6FD));
      expect(t.inactiveChip, const Color(0xFFE0F2FE));
      expect(t.primaryText, const Color(0xFF000000));
      expect(t.secondaryText, const Color(0xFF64748B));
      expect(t.ctaBackground, const Color(0xFF000000));
      expect(t.ctaText, const Color(0xFFFFFFFF));
    });

    test('Powder Blue & Deep Navy', () {
      final t = ColorTheme.powderNavy.tokens;
      expect(t.scaffold, const Color(0xFFF0F9FF));
      expect(t.cardSurface, const Color(0xFFFFFFFF));
      expect(t.cardBorder, const Color(0xFFBAE6FD));
      expect(t.activeChip, const Color(0xFF0C4A6E));
      expect(t.inactiveChip, const Color(0xFFE0F2FE));
      expect(t.primaryText, const Color(0xFF0C4A6E));
      expect(t.secondaryText, const Color(0xFF64748B));
      expect(t.ctaBackground, const Color(0xFF0C4A6E));
      expect(t.ctaText, const Color(0xFFFFFFFF));
    });

    test('Sky Pill on Clean Grey', () {
      final t = ColorTheme.skyPill.tokens;
      expect(t.scaffold, const Color(0xFFFFFFFF));
      expect(t.cardSurface, const Color(0xFFF9FAFB));
      expect(t.cardBorder, const Color(0xFFE5E7EB));
      expect(t.activeChip, const Color(0xFFBAE6FD));
      expect(t.inactiveChip, const Color(0xFFF3F4F6));
      expect(t.primaryText, const Color(0xFF111827));
      expect(t.secondaryText, const Color(0xFF6B7280));
      expect(t.ctaBackground, const Color(0xFF38BDF8));
      expect(t.ctaText, const Color(0xFF000000));
    });
  });

  group('the app theme follows the chosen colours', () {
    for (final option in ColorTheme.values) {
      test(option.tokens.name, () {
        final t = option.tokens;
        final theme = AppTheme.light(option);
        final scheme = theme.colorScheme;
        expect(theme.scaffoldBackgroundColor, t.scaffold);
        expect(scheme.surface, t.cardSurface);
        expect(scheme.outlineVariant, t.cardBorder);
        expect(scheme.onSurface, t.primaryText);
        expect(scheme.onSurfaceVariant, t.secondaryText);
        expect(scheme.primary, t.ctaBackground);
        expect(scheme.onPrimary, t.ctaText);
        expect(scheme.secondary, t.activeChip);
        expect(theme.chipTheme.selectedColor, t.activeChip);
        expect(theme.chipTheme.backgroundColor, t.inactiveChip);
        expect(theme.navigationBarTheme.indicatorColor, t.activeChip);
        expect(theme.navigationBarTheme.backgroundColor, t.cardSurface);
      });
    }

    test('dark mode is the same whatever theme is chosen', () {
      final dark = AppTheme.dark();
      expect(dark.scaffoldBackgroundColor, AppPalette.pageDark);
      expect(dark.colorScheme.surface, AppPalette.cardDark);
      expect(dark.colorScheme.primary, AppPalette.white);
    });
  });

  test(
    'stored values map back; anything unknown falls back to the default',
    () {
      for (final o in ColorTheme.values) {
        expect(ColorThemeStorage.parse(o.storageKey), o);
      }
      expect(ColorThemeStorage.parse(null), defaultColorTheme);
      expect(ColorThemeStorage.parse('purple'), defaultColorTheme);
    },
  );

  group('choice is remembered', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    ProviderContainer open() =>
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);

    test('it survives the app being closed and opened again', () async {
      final first = open();
      await first
          .read(colorThemeControllerProvider)
          .setColorTheme(ColorTheme.powderNavy);
      first.dispose();

      // A fresh start: new container, same database file.
      final second = open();
      addTearDown(second.dispose);
      final theme = await currentTheme(second);
      expect(theme, ColorTheme.powderNavy);
    });

    test('nothing chosen yet means the default', () async {
      final c = open();
      addTearDown(c.dispose);
      expect(await currentTheme(c), defaultColorTheme);
    });

    testWidgets('tapping a theme in Settings selects and saves it', (
      tester,
    ) async {
      final container = open();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: const ColorThemePicker()),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      // All four are listed, the default one is ticked.
      for (final o in ColorTheme.values) {
        expect(find.text(o.tokens.name), findsOneWidget);
      }
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

      await tester.tap(find.text('Sky Pill on Clean Grey'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        await container.read(colorThemeProvider.future),
        ColorTheme.skyPill,
      );
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      // Unmount so Drift's stream timers finish.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    });
  });
}
