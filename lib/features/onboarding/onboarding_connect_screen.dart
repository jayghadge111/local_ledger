import 'package:flutter/material.dart';

import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../settings/widgets/email_connect_card.dart';
import '../settings/widgets/sms_connect_card.dart';

/// Last onboarding step: offer to import existing transactions
/// automatically. Entirely optional — [onDone] (manual entry only) is
/// just as prominent as the connect options, never buried.
class OnboardingConnectScreen extends StatelessWidget {
  const OnboardingConnectScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassBackground(
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
                    Text('Import your transactions?', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Optional, and you can change this anytime in Settings. Everything is '
                      'parsed on this device — nothing is ever sent to a server of ours.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    "Skip either (or both) — you can always add transactions manually.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onDone,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
