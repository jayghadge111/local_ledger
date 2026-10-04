import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import '../../features/alerts/alerts_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/manage/manage_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/nav_svg_icon.dart';
import '../../shared/widgets/sync_banner.dart';
import '../alerts/alert_watcher.dart';
import '../update/update_controller.dart';
import '../sync/sync_controller.dart';

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

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First look for an import that was cut short, so the catch-up below
      // doesn't start over something the user can resume.
      await ref.read(syncControllerProvider.notifier).checkInterrupted();
      _syncSms();
      ref.read(updateControllerProvider.notifier).check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSms();
      ref.read(updateControllerProvider.notifier).check();
    }
  }

  /// Silent catch-up on open/resume (Android, once SMS access is granted):
  /// picks up anything that arrived while the app wasn't running. The work
  /// is owned by the sync controller, so it isn't tied to this screen.
  void _syncSms() => ref.read(syncControllerProvider.notifier).syncSmsIfDue();

  static const _destinations = [
    NavigationDestination(icon: NavSvgIcon('home'), label: 'Home'),
    NavigationDestination(
      icon: NavSvgIcon('transaction', scale: 1.05),
      label: 'Transactions',
    ),
    NavigationDestination(
      icon: NavSvgIcon('filter', scale: 1.15),
      label: 'Manage',
    ),
    NavigationDestination(
      icon: NavSvgIcon('bell-ringing', scale: 1.15),
      label: 'Alerts',
    ),
    NavigationDestination(
      icon: NavSvgIcon('settings', scale: 0.98),
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
    // Budget alerts and lending reminders run while the app is open.
    ref.watch(alertWatcherProvider);
    return GlassBackground(
      child: DisplayFeatureSubScreen(
        child: AdaptiveScaffold(
          selectedIndex: _selectedIndex,
          onSelectedIndexChange: (index) =>
              setState(() => _selectedIndex = index),
          destinations: _destinations,
          body: (_) => SafeArea(
            // Only the top inset: the nav bar/rail already sits flush with
            // the bottom edge and handles its own safe-area padding.
            bottom: false,
            child: Column(
              children: [
                const SyncBanner(),
                Expanded(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
