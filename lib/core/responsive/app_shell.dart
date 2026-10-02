import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

import '../../features/alerts/alerts_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../shared/widgets/glass_background.dart';

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
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
    NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined), label: 'Transactions'),
    NavigationDestination(
        icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
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
