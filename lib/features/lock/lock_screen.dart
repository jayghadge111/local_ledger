import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/app_lock_providers.dart';
import '../../shared/widgets/app_logo_mark.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _error;
  bool _checking = false;
  bool _biometricFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final biometricEnabled = await ref.read(biometricEnabledProvider.future);
    if (!biometricEnabled || !mounted) return;
    final ok = await ref.read(appLockServiceProvider).authenticate();
    if (ok && mounted) {
      _unlock();
    } else if (mounted) {
      setState(() => _biometricFailed = true);
    }
  }

  Future<void> _onSubmitted(String pin) async {
    setState(() => _checking = true);
    final ok = await ref.read(pinRepositoryProvider).verifyPin(pin);
    setState(() => _checking = false);
    if (ok) {
      _unlock();
    } else {
      setState(() => _error = 'Incorrect PIN');
      _padKey.currentState?.clear();
    }
  }

  void _unlock() {
    ref.read(isUnlockedProvider.notifier).setUnlocked(true);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biometricAsync = ref.watch(biometricEnabledProvider);

    // Don't default to "biometric off" while this is still loading — that
    // would flash the PIN pad for a frame even when biometric unlock is
    // enabled, before flipping to the biometric screen once the (near
    // instant, but not synchronous) settings read resolves.
    if (!biometricAsync.hasValue) {
      return const GlassBackground(child: SizedBox.shrink());
    }
    final biometricEnabled = biometricAsync.value!;
    final showPinPad = !biometricEnabled || _biometricFailed;

    return GlassBackground(
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoMark(size: 72),
              const SizedBox(height: 20),
              if (showPinPad) ...[
                Text('Enter your PIN', style: theme.textTheme.titleLarge),
                const SizedBox(height: 28),
                if (_checking)
                  const CircularProgressIndicator()
                else
                  PinPad(key: _padKey, length: 4, onSubmitted: _onSubmitted, errorText: _error),
                if (biometricEnabled) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use biometric unlock'),
                  ),
                ],
              ] else ...[
                Text('Unlock with Biometrics', style: theme.textTheme.titleLarge),
                const SizedBox(height: 28),
                const Icon(Icons.fingerprint, size: 64),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _biometricFailed = true),
                  child: const Text('Use PIN instead'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
