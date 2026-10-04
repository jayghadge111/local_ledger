import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/mock_data_seeder.dart';
import '../../core/db/providers.dart';
import '../../core/db/settings_repository.dart';
import '../../core/security/app_lock_providers.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/glass_switch_row.dart';
import '../lock/pin_setup_screen.dart';
import '../update/update_test_card.dart';
import 'widgets/backup_card.dart';
import 'widgets/email_connect_card.dart';
import 'widgets/profile_card.dart';
import 'widgets/sms_connect_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const FadeSlideIn(child: ProfileCard()),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 8),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref
                      .read(themeModeControllerProvider)
                      .setThemeMode(s.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 15),
          child: const _SecurityCard(),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 26),
          child: const BackupCard(),
        ),
        // Sample/test data tools exist only in debug builds.
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          const UpdateTestCard(),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 30),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Testing & sample data',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Populate the app with realistic sample transactions to try out the dashboard and transaction list, or clear everything to start fresh.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await seedMockTransactions(db);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample transactions added'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Load sample data'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmClear(context, ref),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear all transactions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: const SmsConnectCard(),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 55),
          child: const EmailConnectCard(),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text(
          'This removes every transaction from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await clearAllTransactions(db);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All transactions cleared')),
        );
      }
    }
  }
}

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasPin = ref.watch(hasPinProvider).value ?? false;
    final lockEnabled = ref.watch(appLockEnabledProvider).value ?? false;
    final biometricEnabled = ref.watch(biometricEnabledProvider).value ?? false;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            hasPin
                ? 'App lock is set up. Your PIN and biometric preference are stored only on this device.'
                : 'No PIN set — anyone with this device can open the app.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasPin)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PinSetupScreen(onDone: () => Navigator.of(context).pop()),
                ),
              ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Set up app lock'),
            )
          else ...[
            GlassSwitchRow(
              label: 'Require PIN to open app',
              value: lockEnabled,
              onChanged: (v) => ref
                  .read(settingsRepositoryProvider)
                  .set(SettingsKeys.appLockEnabled, v.toString()),
            ),
            FutureBuilder<bool>(
              future: ref.read(appLockServiceProvider).canCheckBiometrics,
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return GlassSwitchRow(
                  label: 'Biometric unlock',
                  value: biometricEnabled,
                  onChanged: (v) async {
                    // Prove biometrics work before turning the lock on, so a
                    // broken setup can't leave the user stuck on a prompt.
                    if (v) {
                      final ok = await ref
                          .read(appLockServiceProvider)
                          .authenticate(
                            reason: 'Confirm to enable biometric unlock',
                          );
                      if (!ok) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Biometric check failed — unlock stays PIN-only',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    await ref
                        .read(settingsRepositoryProvider)
                        .set(SettingsKeys.biometricEnabled, v.toString());
                  },
                );
              },
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PinSetupScreen(onDone: () => Navigator.of(context).pop()),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Change PIN'),
            ),
          ],
        ],
      ),
    );
  }
}
