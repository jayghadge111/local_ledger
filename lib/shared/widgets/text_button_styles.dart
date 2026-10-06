import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Red [TextButton] style for stopping or removing something (Stop,
/// Disconnect, Delete). Every other text button is blue by default — see
/// `textButtonTheme` in [AppTheme]. Outlined and filled buttons are unaffected.
/// The red used for anything that deletes or removes (see [dangerTextButtonStyle]).
Color dangerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppPalette.dangerDark
    : AppPalette.dangerLight;

ButtonStyle dangerTextButtonStyle(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextButton.styleFrom(
    foregroundColor: dark ? AppPalette.dangerDark : AppPalette.dangerLight,
  );
}
