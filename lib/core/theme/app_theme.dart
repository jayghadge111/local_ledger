import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placeholder brand font — swap the font passed to `GoogleFonts.x()` here
/// to change the whole app's typography later. Deliberately not Roboto
/// (the Flutter/Material default).
///
/// Applied via `fontFamily`/`fontFamilyFallback` rather than
/// `GoogleFonts.xTextTheme()` because the latter now returns a `TextTheme`
/// from the `material_ui` package, which isn't assignable to Flutter SDK's
/// own `ThemeData.textTheme`.
final _brandFont = GoogleFonts.inter();

class AppTheme {
  const AppTheme._();

  static const _seedColor = Color(0xFF152447); // deep navy, from the app mark
  static const _accentColor = Color(0xFFF2B33D); // gold accent, from the app mark

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          secondary: _accentColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          secondary: _accentColor,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _build(ColorScheme colorScheme) {
    // The nav chrome and page transitions are tuned to sit on top of
    // GlassBackground: transparent containers so the blur underneath shows
    // through, and a gentle fade+scale between screens instead of the
    // platform-default slide.
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _brandFont.fontFamily,
      fontFamilyFallback: _brandFont.fontFamilyFallback,
      // Transparent so every screen's GlassBackground (set once, in
      // AppShell) shows through Scaffold's own background — both the one
      // AdaptiveScaffold builds internally and any a feature screen adds.
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.secondary.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.secondary.withValues(alpha: 0.25),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
