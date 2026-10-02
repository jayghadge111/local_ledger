import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';

ThemeMode _parse(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _encode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

final themeModeProvider =
    StreamProvider<ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingsKeys.themeMode).map(_parse);
});

final themeModeControllerProvider = Provider<ThemeModeController>((ref) {
  return ThemeModeController(ref.watch(settingsRepositoryProvider));
});

class ThemeModeController {
  ThemeModeController(this._repo);
  final SettingsRepository _repo;

  Future<void> setThemeMode(ThemeMode mode) {
    return _repo.set(SettingsKeys.themeMode, _encode(mode));
  }
}
