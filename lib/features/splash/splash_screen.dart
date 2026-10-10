import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/settings_repository.dart';
import '../../core/security/app_lock_providers.dart';
import '../../core/brand.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/glass_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );

    _controller.forward();
    // Long enough for the logo and name to settle (the animation is 900 ms),
    // short enough that nobody feels they are waiting for the app.
    Future.delayed(const Duration(milliseconds: 1000), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    final settings = ref.read(settingsRepositoryProvider);
    final onboardingComplete =
        (await settings.get(SettingsKeys.onboardingComplete)) == 'true';

    if (!onboardingComplete) {
      if (mounted) context.go('/onboarding');
      return;
    }

    final lockEnabled =
        (await settings.get(SettingsKeys.appLockEnabled)) == 'true';
    final hasPin = (await settings.get(SettingsKeys.pinHash)) != null;

    if (lockEnabled && hasPin) {
      if (mounted) context.go('/lock');
    } else {
      ref.read(isUnlockedProvider.notifier).setUnlocked(true);
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassBackground(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: const BrandMark(size: 132),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: _textFade.value,
                  child: Column(
                    children: [
                      Text(
                        kAppName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '100% OFFLINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
