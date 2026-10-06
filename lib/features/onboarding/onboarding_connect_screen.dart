import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_controller.dart';
import '../../core/ui/root_messenger.dart';

import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../settings/widgets/email_connect_card.dart';
import '../settings/widgets/sms_connect_card.dart';

/// Last onboarding step: offer to import existing transactions
/// automatically. Entirely optional — [onDone] (manual entry only) is
/// just as prominent as the connect options, never buried.
class OnboardingConnectScreen extends ConsumerWidget {
  const OnboardingConnectScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final running = sync.anyRunning;
    final ready = canLeaveOnboarding(sync);
    final percent = syncPercent(sync);
    // Not a Scaffold, so give the switches and ink in the cards below a
    // (see-through) Material to live on.
    return Material(
      type: MaterialType.transparency,
      child: GlassBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import your transactions?',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Optional. Change it anytime in Settings. '
                        'Your data stays on this phone and is never sent anywhere.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  children: [
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 40),
                      child: const SmsConnectCard(),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: const EmailConnectCard(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Text(
                      running
                          ? 'You can head to the app once the import passes $kOnboardingContinueAtPercent% — '
                                'it finishes in the background and your transactions appear as they arrive.'
                          : "Skip either (or both) — you can always add transactions manually.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: ready
                            ? () {
                                if (running) {
                                  showRootSnackBar(
                                    'Your import is still running in the background — '
                                    "we'll let you know when it's done.",
                                  );
                                }
                                onDone();
                              }
                            : null,
                        child: Text(
                          !running
                              ? 'Continue'
                              : ready
                              ? 'Continue — import keeps running'
                              : 'Importing… ${percent ?? 0}% (continue at $kOnboardingContinueAtPercent%)',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
