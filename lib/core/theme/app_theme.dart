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
final _brandFont = GoogleFonts.nunito();

/// "Uber Slate" — a strict black / white / gray palette. Charts, chips,
/// buttons and nav chrome all stay monochrome; the only color left in the
/// app is merchant brand badges (see `merchant_badge.dart`), which need
/// their real brand hues to stay recognizable at a glance.
class AppPalette {
  const AppPalette._();

  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const neutral = Color(0xFFE8E8E8);

  // Text buttons: blue by default, red for destructive ones (Stop, Delete…).
  static const linkLight = Color(0xFF1A66D6);
  static const linkDark = Color(0xFF6CA6FF);
  static const dangerLight = Color(0xFFD32F2F);
  static const dangerDark = Color(0xFFFF6B6B);

  // Light theme surfaces.
  static const pageLight = Color(0xFFF5F5F7);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8E8E8);
  static const mutedTextLight = Color(0xFF6E6E73);

  // Dark theme surfaces — true-black page (matches Uber's dark mode), slate
  // (not pure black) cards so content still reads as "elevated."
  static const pageDark = Color(0xFF000000);
  static const cardDark = Color(0xFF1C1C1E);
  static const borderDark = Color(0xFF2C2C2E);
  static const mutedTextDark = Color(0xFF9A9AA1);
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppPalette.white : AppPalette.black,
      onPrimary: isDark ? AppPalette.black : AppPalette.white,
      secondary: isDark ? AppPalette.white : AppPalette.black,
      onSecondary: isDark ? AppPalette.black : AppPalette.white,
      error: const Color(0xFFD32F2F),
      onError: AppPalette.white,
      surface: isDark ? AppPalette.cardDark : AppPalette.cardLight,
      onSurface: isDark ? AppPalette.white : AppPalette.black,
      surfaceContainerHighest: isDark ? AppPalette.borderDark : AppPalette.neutral,
      onSurfaceVariant: isDark ? AppPalette.mutedTextDark : AppPalette.mutedTextLight,
      outline: isDark ? AppPalette.borderDark : AppPalette.borderLight,
      outlineVariant: isDark ? AppPalette.borderDark : AppPalette.borderLight,
      tertiary: isDark ? AppPalette.mutedTextDark : AppPalette.mutedTextLight,
      onTertiary: isDark ? AppPalette.black : AppPalette.white,
    );

    final inputBorderColor = isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _brandFont.fontFamily,
      fontFamilyFallback: _brandFont.fontFamilyFallback,
      scaffoldBackgroundColor: isDark ? AppPalette.pageDark : AppPalette.pageLight,
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
        backgroundColor: isDark ? AppPalette.cardDark : AppPalette.cardLight,
        elevation: 0,
        indicatorColor: colorScheme.primary,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppPalette.cardDark : AppPalette.cardLight,
        elevation: 0,
        indicatorColor: colorScheme.primary,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppPalette.cardDark : AppPalette.cardLight,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppPalette.cardDark : AppPalette.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppPalette.borderDark : AppPalette.borderLight),
        ),
      ),
      // Outlined, unfilled fields — the same hairline-border look as the
      // app's cards. The border darkens on focus rather than tinting.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: colorScheme.onSurface),
        border: _inputBorder(inputBorderColor),
        enabledBorder: _inputBorder(inputBorderColor),
        disabledBorder: _inputBorder(inputBorderColor.withValues(alpha: 0.5)),
        focusedBorder: _inputBorder(colorScheme.onSurface, width: 1.5),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppPalette.cardDark : AppPalette.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? AppPalette.borderDark : AppPalette.borderLight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppPalette.linkDark : AppPalette.linkLight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: isDark ? AppPalette.borderDark : AppPalette.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      // Thumb stays white when off (grey made it look disabled); the off
      // track is darker than the card so the white thumb still reads.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : AppPalette.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC)),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppPalette.borderDark : AppPalette.neutral,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}
