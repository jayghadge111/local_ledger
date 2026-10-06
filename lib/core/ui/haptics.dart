import 'package:flutter/services.dart';

/// Small physical confirmations for the actions that matter. Silent on
/// devices without a vibration motor, and never allowed to fail an action.
class Haptics {
  const Haptics._();

  /// A key press or a toggle.
  static void tap() => _run(HapticFeedback.selectionClick);

  /// Something was saved or finished.
  static void success() => _run(HapticFeedback.lightImpact);

  /// Something was deleted or taken back.
  static void heavy() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() feedback) {
    try {
      feedback().catchError((_) {});
    } catch (_) {}
  }
}
