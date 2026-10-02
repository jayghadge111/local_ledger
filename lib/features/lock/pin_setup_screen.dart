import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/settings_repository.dart';
import '../../core/security/app_lock_providers.dart';
import '../../shared/widgets/app_logo_mark.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/pin_pad.dart';

/// Create (or change) the app-lock PIN. Pops with `true` once a PIN has
/// been saved, or can be used as a named route (see [onDone]).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _firstEntry;
  String? _error;

  void _onSubmitted(String pin) async {
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _error = null;
      });
      _padKey.currentState?.clear();
      return;
    }

    if (pin != _firstEntry) {
      setState(() {
        _error = "PINs didn't match — try again";
        _firstEntry = null;
      });
      _padKey.currentState?.clear();
      return;
    }

    await ref.read(pinRepositoryProvider).setPin(pin);
    
    final appLockService = ref.read(appLockServiceProvider);
    if (await appLockService.canCheckBiometrics && mounted) {
      final useBiometric = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Biometric Login?'),
          content: const Text('Would you like to use your fingerprint or face to unlock the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (useBiometric == true && mounted) {
        await ref.read(settingsRepositoryProvider).set(SettingsKeys.biometricEnabled, 'true');
      }
    }

    ref.read(isUnlockedProvider.notifier).setUnlocked(true);
    if (widget.onDone != null) {
      widget.onDone!();
    } else if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirm = _firstEntry != null;

    return GlassBackground(
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoMark(size: 72),
              const SizedBox(height: 20),
              Text(
                isConfirm ? 'Confirm your PIN' : 'Set a PIN to lock the app',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Used to unlock LocalLedger — never leaves this device',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              PinPad(key: _padKey, length: 4, onSubmitted: _onSubmitted, errorText: _error),
            ],
          ),
        ),
      ),
    );
  }
}
