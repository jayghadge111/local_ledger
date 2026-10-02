import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/settings_repository.dart';
import '../router/app_router.dart';
import 'app_lock_providers.dart';

/// Re-locks the app whenever it returns from the background, if app lock
/// is enabled. Wrap the router's content with this once, near the root.
class AppLifecycleLockGate extends ConsumerStatefulWidget {
  const AppLifecycleLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleLockGate> createState() => _AppLifecycleLockGateState();
}

class _AppLifecycleLockGateState extends ConsumerState<AppLifecycleLockGate>
    with WidgetsBindingObserver {
  // A brief grace period before re-locking: switching to copy a one-time
  // code, checking a notification, or a quick app-switcher peek shouldn't
  // force a fresh PIN/biometric prompt every time. Only backgrounding
  // longer than this re-locks.
  static const _gracePeriod = Duration(seconds: 30);

  bool _wasBackgrounded = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Only `paused` means the app actually left the foreground. `inactive`
    // alone fires for all sorts of transient system UI — notification
    // banners, Control Center, and critically the native Face ID/Touch ID
    // sheet our own biometric unlock presents. Treating `inactive` as
    // "backgrounded" meant a successful biometric prompt would itself
    // trigger this gate to re-lock and race with (and sometimes undo) the
    // unlock it had just granted.
    if (state == AppLifecycleState.paused) {
      _wasBackgrounded = true;
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt != null && DateTime.now().difference(pausedAt) < _gracePeriod) {
        return;
      }

      final settings = ref.read(settingsRepositoryProvider);
      final lockEnabled = (await settings.get(SettingsKeys.appLockEnabled)) == 'true';
      final hasPin = (await settings.get(SettingsKeys.pinHash)) != null;
      if (!mounted) return;
      if (lockEnabled && hasPin) {
        ref.read(isUnlockedProvider.notifier).setUnlocked(false);
        final onboardingComplete =
            (await settings.get(SettingsKeys.onboardingComplete)) == 'true';
        // Uses the global router instance rather than GoRouter.maybeOf(context):
        // this widget sits in MaterialApp.router's `builder`, which is outside
        // the Router's own widget subtree, so the InheritedWidget lookup
        // silently returns null there and .go() would be a no-op.
        if (onboardingComplete) {
          appRouter.go('/lock');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
