import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/theme/app_theme.dart';

void main() {
  group('light: Powder Blue & Deep Navy', () {
    final theme = AppTheme.light();
    final scheme = theme.colorScheme;

    test('uses the approved colours', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF0F9FF));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.outline, const Color(0xFFBAE6FD));
      expect(scheme.onSurface, const Color(0xFF0C4A6E));
      expect(scheme.onSurfaceVariant, const Color(0xFF64748B));
      expect(scheme.primary, const Color(0xFF0C4A6E));
      expect(scheme.onPrimary, const Color(0xFFFFFFFF));
      expect(scheme.secondary, const Color(0xFF0C4A6E));
      expect(scheme.onSecondary, const Color(0xFFFFFFFF));
      expect(scheme.secondaryContainer, const Color(0xFFE0F2FE));
    });

    test('charts and progress are navy on pale blue', () {
      final chart = theme.extension<ChartColors>()!;
      expect(chart.accent, const Color(0xFF0C4A6E));
      expect(chart.soft, const Color(0xFFE0F2FE));
    });
  });

  group('dark: the same navy, at night', () {
    final theme = AppTheme.dark();
    final scheme = theme.colorScheme;

    test('is a dark navy scheme, not black or grey', () {
      expect(scheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF06131F));
      expect(scheme.surface, const Color(0xFF0C2234));
      // Every surface leans blue.
      for (final c in [theme.scaffoldBackgroundColor, scheme.surface]) {
        expect(c.b, greaterThan(c.r));
      }
    });

    test('reuses the light theme\'s sky blue for buttons and chips', () {
      expect(scheme.primary, const Color(0xFFBAE6FD));
      expect(scheme.onPrimary, const Color(0xFF082F49));
      expect(scheme.secondary, const Color(0xFFBAE6FD));
      expect(scheme.onSecondary, const Color(0xFF0C4A6E));
    });

    test('text is readable on every surface', () {
      double contrast(Color a, Color b) {
        final l1 = a.computeLuminance();
        final l2 = b.computeLuminance();
        final hi = l1 > l2 ? l1 : l2;
        final lo = l1 > l2 ? l2 : l1;
        return (hi + 0.05) / (lo + 0.05);
      }

      expect(
        contrast(scheme.onSurface, theme.scaffoldBackgroundColor),
        greaterThan(7),
      );
      expect(contrast(scheme.onSurface, scheme.surface), greaterThan(7));
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThan(4.5),
      );
      expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(7));
      expect(contrast(scheme.onSecondary, scheme.secondary), greaterThan(7));
    });
  });

  test('light and dark use the same roles with different values', () {
    final l = AppTheme.light().colorScheme;
    final d = AppTheme.dark().colorScheme;
    expect(l.primary, isNot(d.primary));
    expect(l.surface, isNot(d.surface));
    expect(AppTheme.light().extension<ChartColors>(), isNotNull);
    expect(AppTheme.dark().extension<ChartColors>(), isNotNull);
  });
}
