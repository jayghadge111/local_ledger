import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` so the rest of the app depends on a
/// small interface instead of the plugin directly.
class AppLockService {
  final _localAuth = LocalAuthentication();

  Future<bool> get canCheckBiometrics async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock LocalLedger'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('[AppLockService] biometric authenticate failed: $e');
      return false;
    }
  }
}
