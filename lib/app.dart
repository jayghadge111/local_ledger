import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/brand.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lifecycle_lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/ui/root_messenger.dart';

// Built once: ThemeData is large, and constructing both on every rebuild of
// the app root (a theme-mode change) is wasted work.
final _lightTheme = AppTheme.light();
final _darkTheme = AppTheme.dark();

class TrueLedgerApp extends ConsumerWidget {
  const TrueLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: appRouter,
      builder: (context, child) => AppLifecycleLockGate(child: child!),
    );
  }
}
