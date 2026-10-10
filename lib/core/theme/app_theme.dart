import 'package:flutter/material.dart';

/// The brand font, bundled with the app (`assets/fonts/`, declared in
/// pubspec.yaml; Nunito, SIL Open Font License). Nothing is downloaded at
/// runtime, so text is right on the very first frame and works offline.
const _brandFontFamily = 'Nunito';

/// Colours for charts and progress bars (sky blue tones on navy / ice).
class ChartColors extends ThemeExtension<ChartColors> {
  const ChartColors({
    required this.accent,
    required this.soft,
    required this.softText,
  });

  /// Strong: the current bar, the biggest slice, a filled progress bar.
  final Color accent;

  /// Soft: other bars, the smallest slices.
  final Color soft;

  /// Text / icons drawn on [soft].
  final Color softText;

  /// Falls back to the text / chip colours when a theme doesn't set them.
  static ChartColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChartColors>() ??
        ChartColors(
          accent: theme.colorScheme.onSurface,
          soft: theme.colorScheme.surfaceContainerHighest,
          softText: theme.colorScheme.onSurface,
        );
  }

  @override
  ChartColors copyWith({Color? accent, Color? soft, Color? softText}) =>
      ChartColors(
        accent: accent ?? this.accent,
        soft: soft ?? this.soft,
        softText: softText ?? this.softText,
      );

  @override
  ChartColors lerp(ChartColors? other, double t) => other == null
      ? this
      : ChartColors(
          accent: Color.lerp(accent, other.accent, t)!,
          soft: Color.lerp(soft, other.soft, t)!,
          softText: Color.lerp(softText, other.softText, t)!,
        );
}

/// The app's colours: "Powder Blue & Deep Navy" for light, with a deep-navy
/// night version for dark. Each is a set of named roles; [AppTheme] maps them
/// onto widgets, so a palette is data, not code.
class AppPalette {
  const AppPalette._();

  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Text buttons: blue by default, red for destructive ones (Stop, Delete…).
  static const linkLight = Color(0xFF1A66D6);
  static const linkDark = Color(0xFF6CA6FF);
  static const dangerLight = Color(0xFFD32F2F);
  static const dangerDark = Color(0xFFFF6B6B);

  /// Light: powder-blue page, deep-navy text, buttons and active chips.
  static const light = _Tokens(
    scaffold: Color(0xFFF0F9FF),
    cardSurface: white,
    cardBorder: Color(0xFFBAE6FD),
    activeChip: Color(0xFF0C4A6E),
    activeChipText: white,
    inactiveChip: Color(0xFFE0F2FE),
    primaryText: Color(0xFF0C4A6E),
    // Slate, darkened a touch from #64748B so secondary text also reaches
    // 4.5:1 on the pale-blue page background, not only on white cards.
    secondaryText: Color(0xFF586A7E),
    ctaBackground: Color(0xFF0C4A6E),
    ctaText: white,
    chartAccent: Color(0xFF0C4A6E),
    chartSoft: Color(0xFFE0F2FE),
    chartSoftText: Color(0xFF0C4A6E),
    switchOffTrack: Color(0xFFC7D7E3),
  );

  /// Dark: the same navy, as night. Deep-navy page, lifted navy cards, ice
  /// text, and the light theme's sky blue as the button and active chip.
  static const dark = _Tokens(
    scaffold: Color(0xFF06131F),
    cardSurface: Color(0xFF0C2234),
    cardBorder: Color(0xFF17364D),
    activeChip: Color(0xFFBAE6FD),
    activeChipText: Color(0xFF0C4A6E),
    inactiveChip: Color(0xFF123049),
    primaryText: Color(0xFFE6F4FB),
    secondaryText: Color(0xFF8DA8BC),
    ctaBackground: Color(0xFFBAE6FD),
    ctaText: Color(0xFF082F49),
    chartAccent: Color(0xFF7DD3FC),
    chartSoft: Color(0xFF17364D),
    chartSoftText: Color(0xFFBAE6FD),
    switchOffTrack: Color(0xFF2B4A62),
  );
}

/// One palette's colours, by role.
class _Tokens {
  const _Tokens({
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
    required this.chartAccent,
    required this.chartSoft,
    required this.chartSoftText,
    required this.switchOffTrack,
  });

  final Color scaffold;
  final Color cardSurface;
  final Color cardBorder;
  final Color activeChip;
  final Color activeChipText;
  final Color inactiveChip;
  final Color primaryText;
  final Color secondaryText;
  final Color ctaBackground;
  final Color ctaText;
  final Color chartAccent;
  final Color chartSoft;
  final Color chartSoftText;
  final Color switchOffTrack;
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, _Tokens t) {
    final isDark = brightness == Brightness.dark;
    final pageColor = t.scaffold;
    final cardColor = t.cardSurface;
    final borderColor = t.cardBorder;
    final textColor = t.primaryText;
    final mutedColor = t.secondaryText;
    final activeChip = t.activeChip;
    final activeChipText = t.activeChipText;
    final inactiveChip = t.inactiveChip;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: t.ctaBackground,
      onPrimary: t.ctaText,
      secondary: activeChip,
      onSecondary: activeChipText,
      secondaryContainer: inactiveChip,
      onSecondaryContainer: textColor,
      // The standard red is too dim on dark navy (3.3:1); use a lighter one
      // there.
      error: isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F),
      onError: AppPalette.white,
      surface: cardColor,
      onSurface: textColor,
      surfaceContainerHighest: inactiveChip,
      onSurfaceVariant: mutedColor,
      outline: borderColor,
      outlineVariant: borderColor,
      tertiary: mutedColor,
      onTertiary: t.scaffold,
    );

    // Field outlines sit a step darker than card borders so inputs read as inputs.
    final inputBorderColor = Color.lerp(borderColor, mutedColor, 0.5)!;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [
        ChartColors(
          accent: t.chartAccent,
          soft: t.chartSoft,
          softText: t.chartSoftText,
        ),
      ],
      fontFamily: _brandFontFamily,
      scaffoldBackgroundColor: pageColor,
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
        backgroundColor: cardColor,
        elevation: 0,
        indicatorColor: activeChip,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? activeChipText
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        elevation: 0,
        indicatorColor: activeChip,
        selectedIconTheme: IconThemeData(color: activeChipText),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: cardColor, elevation: 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
      ),
      // Outlined, unfilled fields — the same hairline-border look as the
      // app's cards. The border darkens on focus rather than tinting.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              : t.switchOffTrack,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inactiveChip,
        selectedColor: activeChip,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(
          color: activeChipText,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: activeChipText,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? activeChip
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? activeChipText
                : textColor,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
        ),
      ),
    );
  }
}
