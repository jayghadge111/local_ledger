import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/security/app_lifecycle_lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/ui/root_messenger.dart';

class LocalLedgerApp extends ConsumerWidget {
  const LocalLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Local Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: appRouter,
      builder: (context, child) => AppLifecycleLockGate(child: child!),
    );
  }
}
