import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'providers.dart';

/// Keys used in the AppSettings key-value table.
abstract class SettingsKeys {
  static const themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const onboardingComplete = 'onboarding_complete'; // 'true' | 'false'
  static const appLockEnabled = 'app_lock_enabled'; // 'true' | 'false'
  static const biometricEnabled = 'biometric_enabled'; // 'true' | 'false'
  static const pinHash = 'pin_hash';
  static const pinSalt = 'pin_salt';
  static const smsLastSyncedAt = 'sms_last_synced_at'; // ISO-8601
  static const customBankEmailDomains =
      'custom_bank_email_domains'; // comma-separated
  static const smsAutoSync = 'sms_auto_sync'; // 'true' | 'false'
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> set(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(settingKey: key, settingValue: value),
        );
  }

  Future<void> remove(String key) {
    return (_db.delete(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).go();
  }

  /// Watches a single setting value, emitting null if unset.
  Stream<String?> watch(String key) {
    return (_db.select(_db.appSettings)..where((t) => t.settingKey.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.settingValue);
  }
}

/// Sender domains the user added for banks the built-in list doesn't cover.
final customBankEmailDomainsProvider = StreamProvider<List<String>>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsKeys.customBankEmailDomains)
      .map((v) => (v ?? '').split(',').where((d) => d.isNotEmpty).toList());
});
