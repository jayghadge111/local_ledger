import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import 'color_themes.dart';

/// The chosen colour theme, read from (and kept in) local settings so it
/// survives the app being closed.
final colorThemeProvider = StreamProvider<ColorTheme>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsKeys.colorTheme)
      .map(ColorThemeStorage.parse);
});

final colorThemeControllerProvider = Provider<ColorThemeController>((ref) {
  return ColorThemeController(ref.watch(settingsRepositoryProvider));
});

class ColorThemeController {
  ColorThemeController(this._repo);
  final SettingsRepository _repo;

  Future<void> setColorTheme(ColorTheme theme) =>
      _repo.set(SettingsKeys.colorTheme, theme.storageKey);
}
