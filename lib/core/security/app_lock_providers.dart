import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import 'app_lock_service.dart';
import 'hashing_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService());
final hashingServiceProvider = Provider<HashingService>((ref) => const HashingService());

final appLockEnabledProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingsKeys.appLockEnabled).map((v) => v == 'true');
});

final biometricEnabledProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingsKeys.biometricEnabled).map((v) => v == 'true');
});

final hasPinProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingsKeys.pinHash).map((v) => v != null);
});

final onboardingCompleteProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingsKeys.onboardingComplete).map((v) => v == 'true');
});

/// In-memory "is the app currently unlocked this session" flag. Starts
/// false every cold start; [AppLifecycleLockGate] also flips it back to
/// false whenever the app returns from the background.
class IsUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setUnlocked(bool value) => state = value;
}

final isUnlockedProvider = NotifierProvider<IsUnlockedNotifier, bool>(
  IsUnlockedNotifier.new,
);

class PinRepository {
  PinRepository(this._settings, this._hashing);
  final SettingsRepository _settings;
  final HashingService _hashing;

  Future<bool> hasPin() async {
    final hash = await _settings.get(SettingsKeys.pinHash);
    return hash != null;
  }

  Future<void> setPin(String pin) async {
    final salt = _hashing.generateSalt();
    final hash = _hashing.hash(pin, salt);
    await _settings.set(SettingsKeys.pinSalt, salt);
    await _settings.set(SettingsKeys.pinHash, hash);
    await _settings.set(SettingsKeys.appLockEnabled, 'true');
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _settings.get(SettingsKeys.pinSalt);
    final hash = await _settings.get(SettingsKeys.pinHash);
    if (salt == null || hash == null) return false;
    return _hashing.verify(pin, salt, hash);
  }

  Future<void> clearPin() async {
    await _settings.remove(SettingsKeys.pinHash);
    await _settings.remove(SettingsKeys.pinSalt);
    await _settings.set(SettingsKeys.appLockEnabled, 'false');
    await _settings.set(SettingsKeys.biometricEnabled, 'false');
  }
}

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  return PinRepository(
    ref.watch(settingsRepositoryProvider),
    ref.watch(hashingServiceProvider),
  );
});
