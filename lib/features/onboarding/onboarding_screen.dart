import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/settings_repository.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../core/responsive/adaptive_scale.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/onboarding_illustration.dart';
import '../lock/pin_setup_screen.dart';
import 'onboarding_connect_screen.dart';
import 'onboarding_name_screen.dart';

class _Page {
  const _Page(this.illustration, this.title, this.body);
  final String illustration;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    'assets/illustrations/onboarding_private.svg',
    'Your money, your device, zero cloud',
    'Every transaction stays on this phone. No account, no cloud sync, no third party ever sees your data.',
  ),
  _Page(
    'assets/illustrations/onboarding_import.svg',
    'Add transactions effortlessly',
    'Import automatically from SMS or Gmail, or add transactions by hand — your choice, and parsing always happens on-device.',
  ),
  _Page(
    'assets/illustrations/onboarding_alerts.svg',
    'Alerts that matter',
    'Reminders for recurring bills, and flags for unusual or international transactions — computed locally, never sent anywhere.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _completeOnboarding() async {
    final settings = ref.read(settingsRepositoryProvider);
    // A fresh install gets the walkthrough of the five sections once, when it
    // first reaches Home.
    if (await settings.get(SettingsKeys.onboardingComplete) != 'true') {
      await settings.set(SettingsKeys.introTourPending, 'true');
    }
    await settings.set(SettingsKeys.onboardingComplete, 'true');
  }

  /// Skipping the intro still asks for the name when there isn't one yet —
  /// it's what lets payments to yourself be told apart from spending.
  Future<void> _skip() async {
    await _completeOnboarding();
    if (!mounted) return;
    final name = await ref
        .read(settingsRepositoryProvider)
        .get(SettingsKeys.userName);
    if (!mounted) return;
    if (name != null && name.trim().isNotEmpty) {
      context.go('/home');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingNameScreen(onDone: () => context.go('/home')),
      ),
    );
  }

  Future<void> _next() async {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingNameScreen(
          onDone: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PinSetupScreen(
                  onDone: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => OnboardingConnectScreen(
                          onDone: () => context.go('/home'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _pages.length - 1;
    final boost = focusedBoost(context);

    return GlassBackground(
      maxContentWidth: kFocusedMaxWidth,
      child: FocusedBoost(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    // On a tall tablet the picture takes a share of the
                    // height instead of staying phone-sized in the middle.
                    final room = MediaQuery.sizeOf(context).height;
                    final pictureHeight = (210 * boost)
                        .clamp(210.0, room * 0.34)
                        .toDouble();
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28 * boost),
                      child: Center(
                        child: FadeSlideIn(
                          key: ValueKey(i),
                          child: GlassCard(
                            padding: EdgeInsets.fromLTRB(
                              20 * boost,
                              20 * boost,
                              20 * boost,
                              26 * boost,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OnboardingIllustration(
                                  asset: page.illustration,
                                  height: pictureHeight,
                                ),
                                SizedBox(height: 22 * boost),
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  page.body,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.all(24 * boost),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16 * boost),
                    ),
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
