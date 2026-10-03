import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` so the rest of the app depends on a
/// small interface instead of the plugin directly.
class AppLockService {
  final _localAuth = LocalAuthentication();

  /// True only if the device has biometric hardware AND at least one
  /// fingerprint/face is enrolled. Hardware alone isn't enough: offering
  /// biometric unlock on a phone with nothing enrolled can only fail.
  Future<bool> get canCheckBiometrics async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported || !await _localAuth.canCheckBiometrics) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock NativeSpend'}) async {
    try {
      return await _localAuth
          .authenticate(
            localizedReason: reason,
            biometricOnly: true,
            persistAcrossBackgrounding: true,
          )
          // A prompt nobody answers must not block the app forever.
          .timeout(const Duration(seconds: 45), onTimeout: () => false);
    } catch (e) {
      debugPrint('[AppLockService] biometric authenticate failed: $e');
      return false;
    }
  }
}
