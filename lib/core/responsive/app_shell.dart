import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import '../../features/alerts/alerts_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/manage/manage_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../shared/widgets/glass_background.dart';
import '../sms/sms_import_service.dart';
import '../sms/sms_providers.dart';

/// The app's single navigational shell.
///
/// [AdaptiveScaffold] switches between a bottom bar (phones, the cover
/// screen of a flip phone), a navigation rail (tablets, an unfolded
/// foldable), and a drawer (large/desktop widths) automatically based on
/// window size — no separate phone/tablet layouts to maintain.
///
/// [DisplayFeatureSubScreen] additionally keeps content clear of a
/// foldable's hinge, so nothing renders underneath it on a book-style fold.
///
/// [GlassBackground] sits once behind the whole shell — nav chrome is
/// themed transparent (see [AppTheme]) so every screen's [GlassCard]s blur
/// against the same animated gradient instead of each screen painting its
/// own backdrop.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSms());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncSms();
  }

  /// Silent catch-up on open/resume (Android, once SMS access is granted):
  /// picks up anything that arrived while the app wasn't running.
  Future<void> _syncSms() async {
    final service = ref.read(smsImportServiceProvider);
    try {
      final result = await service.syncIfDue();
      await service.listenForNewMessages(_announce);
      if (result != null) _announce(result);
    } catch (e) {
      debugPrint('[AppShell] SMS sync failed: $e');
    }
  }

  void _announce(SmsImportResult result) {
    if (!mounted || (result.imported == 0 && result.queued == 0)) return;
    final parts = [
      if (result.imported > 0) '${result.imported} new transaction${result.imported == 1 ? '' : 's'}',
      if (result.queued > 0) '${result.queued} message${result.queued == 1 ? '' : 's'} to review',
    ];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(parts.join(' · '))));
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.grid_view_rounded),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_rounded),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Transactions',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_rounded),
      selectedIcon: Icon(Icons.tune_rounded),
      label: 'Manage',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_rounded),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: 'Alerts',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_rounded),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ManageScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: DisplayFeatureSubScreen(
        child: AdaptiveScaffold(
          selectedIndex: _selectedIndex,
          onSelectedIndexChange: (index) => setState(() => _selectedIndex = index),
          destinations: _destinations,
          body: (_) => SafeArea(
            // Only the top inset: the nav bar/rail already sits flush with
            // the bottom edge and handles its own safe-area padding.
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
