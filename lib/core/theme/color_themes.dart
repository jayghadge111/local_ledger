import 'package:flutter/painting.dart';

/// The selectable colour themes for the light appearance. Each one is a set of
/// named roles ([ThemeTokens]); the app theme maps those roles onto widgets,
/// so a theme is data, not code. Dark mode keeps its own colours.
enum ColorTheme {
  /// Pale ice-blue page, jet-black text and buttons, soft-sky active chips.
  iceSky,

  /// Powder-blue page with deep-navy text, buttons and active chips.
  powderNavy,

  /// Clean white page, off-white cards, a sky-blue button and chips.
  skyPill,

  /// The original black / white / grey look, kept for comparison.
  classic,
}

/// One theme's colours, by role.
class ThemeTokens {
  const ThemeTokens({
    required this.name,
    required this.summary,
    required this.scaffold,
    required this.cardSurface,
    required this.cardBorder,
    required this.activeChip,
    required this.activeChipText,
    required this.inactiveChip,
    required this.primaryText,
    required this.secondaryText,
    required this.ctaBackground,
    required this.ctaText,
  });

  final String name;
  final String summary;

  /// Page background.
  final Color scaffold;
  final Color cardSurface;
  final Color cardBorder;

  /// Selected chip / pill / navigation indicator, and the text on it.
  final Color activeChip;
  final Color activeChipText;
  final Color inactiveChip;
  final Color primaryText;

  /// Meta text, captions, hints.
  final Color secondaryText;

  /// Primary call-to-action button and the text on it.
  final Color ctaBackground;
  final Color ctaText;
}

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

const Map<ColorTheme, ThemeTokens> colorThemeTokens = {
  ColorTheme.iceSky: ThemeTokens(
    name: 'Ice Sky & Jet Ink',
    summary: 'Ice-white page, black text and buttons, soft-sky chips',
    scaffold: Color(0xFFF8FCFF),
    cardSurface: _white,
    cardBorder: Color(0xFFE0F2FE),
    activeChip: Color(0xFFBAE6FD),
    activeChipText: _black,
    inactiveChip: Color(0xFFE0F2FE),
    primaryText: _black,
    secondaryText: Color(0xFF64748B),
    ctaBackground: _black,
    ctaText: _white,
  ),
  ColorTheme.powderNavy: ThemeTokens(
    name: 'Powder Blue & Deep Navy',
    summary: 'Powder-blue page, deep-navy text, buttons and chips',
    scaffold: Color(0xFFF0F9FF),
    cardSurface: _white,
    cardBorder: Color(0xFFBAE6FD),
    activeChip: Color(0xFF0C4A6E),
    activeChipText: _white,
    inactiveChip: Color(0xFFE0F2FE),
    primaryText: Color(0xFF0C4A6E),
    secondaryText: Color(0xFF64748B),
    ctaBackground: Color(0xFF0C4A6E),
    ctaText: _white,
  ),
  ColorTheme.skyPill: ThemeTokens(
    name: 'Sky Pill on Clean Grey',
    summary: 'White page, off-white cards, sky-blue button and chips',
    scaffold: _white,
    cardSurface: Color(0xFFF9FAFB),
    cardBorder: Color(0xFFE5E7EB),
    activeChip: Color(0xFFBAE6FD),
    activeChipText: Color(0xFF111827),
    inactiveChip: Color(0xFFF3F4F6),
    primaryText: Color(0xFF111827),
    secondaryText: Color(0xFF6B7280),
    ctaBackground: Color(0xFF38BDF8),
    ctaText: _black,
  ),
  ColorTheme.classic: ThemeTokens(
    name: 'Classic Slate (original)',
    summary: 'The original black, white and grey look',
    scaffold: Color(0xFFF5F5F7),
    cardSurface: _white,
    cardBorder: Color(0xFFE8E8E8),
    activeChip: _black,
    activeChipText: _white,
    inactiveChip: Color(0xFFE8E8E8),
    primaryText: _black,
    secondaryText: Color(0xFF6E6E73),
    ctaBackground: _black,
    ctaText: _white,
  ),
};

/// The theme used until the user picks one. (The "recommended" option.)
const ColorTheme defaultColorTheme = ColorTheme.iceSky;

extension ColorThemeStorage on ColorTheme {
  ThemeTokens get tokens => colorThemeTokens[this]!;

  /// The value saved in settings.
  String get storageKey => name;

  static ColorTheme parse(String? value) {
    for (final t in ColorTheme.values) {
      if (t.name == value) return t;
    }
    return defaultColorTheme;
  }
}
