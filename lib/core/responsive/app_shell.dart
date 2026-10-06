import 'package:showcaseview/showcaseview.dart';

import '../../features/intro/intro_providers.dart';
import '../../features/intro/intro_showcase.dart';
import '../rules/rules_providers.dart';
import '../diagnostics/app_guard.dart';
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

  /// The tour was just finished or skipped; hides it before the saved
  /// setting has had time to come back.
  bool _tourEnded = false;
  bool _tourStarted = false;
  final _tourKeys = List.generate(introSteps.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    registerIntroShowcase(onEnd: _onTourEnded);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First look for an import that was cut short, so the catch-up below
      // doesn't start over something the user can resume.
      await guarded(
        'checking for an interrupted import',
        ref.read(syncControllerProvider.notifier).checkInterrupted,
      );
      _syncSms();
      guarded(
        'update check',
        () async => ref.read(updateControllerProvider.notifier).check(),
      );
      guarded('rules check', ref.read(rulesControllerProvider.notifier).maybeCheck);
    });
  }

  @override
  void dispose() {
    endIntroShowcase();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      guarded('rules check', ref.read(rulesControllerProvider.notifier).maybeCheck);
      _syncSms();
      guarded(
        'update check',
        () async => ref.read(updateControllerProvider.notifier).check(),
      );
    }
  }

  /// Silent catch-up on open/resume (Android, once SMS access is granted):
  /// picks up anything that arrived while the app wasn't running. The work
  /// is owned by the sync controller, so it isn't tied to this screen.
  void _syncSms() => guarded(
    'SMS catch-up',
    ref.read(syncControllerProvider.notifier).syncSmsIfDue,
  );

  void _onTourEnded() {
    if (!mounted) return;
    setState(() => _tourEnded = true);
    markIntroTourSeen(ref);
  }

  static const _navItems = [
    (icon: 'home', scale: 1.0, label: 'Home'),
    (icon: 'transaction', scale: 1.05, label: 'Transactions'),
    (icon: 'filter', scale: 1.15, label: 'Manage'),
    (icon: 'bell-ringing', scale: 1.15, label: 'Alerts'),
    (icon: 'settings', scale: 0.98, label: 'Settings'),
  ];

  /// The five navigation items. While the first-visit tour runs each icon is
  /// wrapped so it can be lit up. The bar draws `selectedIcon` for the
  /// selected item and `icon` for the others, so the wrapper goes on whichever
  /// is drawn (a target must appear exactly once).
  List<NavigationDestination> _destinations(
    BuildContext context, {
    required bool touring,
  }) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return [
      for (final (i, item) in _navItems.indexed)
        NavigationDestination(
          icon: touring && i != _selectedIndex
              ? introShowcase(
                  context: context,
                  index: i,
                  showcaseKey: _tourKeys[i],
                  wide: wide,
                  child: NavSvgIcon(item.icon, scale: item.scale),
                )
              : NavSvgIcon(item.icon, scale: item.scale),
          selectedIcon: touring && i == _selectedIndex
              ? introShowcase(
                  context: context,
                  index: i,
                  showcaseKey: _tourKeys[i],
                  wide: wide,
                  child: NavSvgIcon(item.icon, scale: item.scale),
                )
              : (touring ? NavSvgIcon(item.icon, scale: item.scale) : null),
          label: item.label,
        ),
    ];
  }

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
    // A new install is walked through the five sections, once, on Home.
    final showTour =
        !_tourEnded &&
        _selectedIndex == 0 &&
        (ref.watch(introTourPendingProvider).value ?? false);
    if (showTour && !_tourStarted) {
      _tourStarted = true;
      // Let Home settle (and the icons wrap themselves) before it begins.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (mounted && !_tourEnded) {
            ShowcaseView.get().startShowCase(_tourKeys);
          }
        });
      });
    }
    return GlassBackground(
      child: DisplayFeatureSubScreen(
        child: AdaptiveScaffold(
          selectedIndex: _selectedIndex,
          onSelectedIndexChange: (index) =>
              setState(() => _selectedIndex = index),
          destinations: _destinations(context, touring: showTour),
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
