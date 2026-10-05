import 'package:go_router/go_router.dart';

import '../../features/lock/lock_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../responsive/app_shell.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
    GoRoute(path: '/home', builder: (context, state) => const AppShell()),
  ],
);
