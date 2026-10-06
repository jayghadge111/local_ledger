import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/features/intro/intro_providers.dart';
import 'package:local_ledger/features/intro/intro_showcase.dart';
import 'package:local_ledger/shared/widgets/nav_svg_icon.dart';
import 'package:showcaseview/showcaseview.dart';

const _icons = ['home', 'transaction', 'split', 'lend', 'settings'];

/// A bottom bar built the way the app shell builds it during the tour.
class _Harness extends StatefulWidget {
  const _Harness({required this.onEnd});
  final VoidCallback onEnd;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final keys = [
    for (var i = 0; i < introSteps.length; i++)
      i == introBellStep ? introBellKey : GlobalKey(),
  ];

  @override
  void initState() {
    super.initState();
    registerIntroShowcase(onEnd: widget.onEnd);
  }

  @override
  void dispose() {
    endIntroShowcase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = NavigationBar(
      selectedIndex: 0,
      destinations: [
        for (final (i, n) in _icons.indexed)
          NavigationDestination(
            // Exactly as the app shell does it: the wrapper goes on the icon
            // that is actually drawn (selected item: `selectedIcon`).
            icon: i == 0
                ? NavSvgIcon(n)
                : introShowcase(
                    context: context,
                    index: introNavStep[i],
                    showcaseKey: keys[introNavStep[i]],
                    wide: false,
                    child: NavSvgIcon(n),
                  ),
            selectedIcon: i == 0
                ? introShowcase(
                    context: context,
                    index: introNavStep[i],
                    showcaseKey: keys[introNavStep[i]],
                    wide: false,
                    child: NavSvgIcon(n),
                  )
                : NavSvgIcon(n),
            label: n,
          ),
      ],
    );
    return Scaffold(
      body: Column(
        children: [
          // The alerts bell, as on Home, is the tour's second stop.
          Align(
            alignment: Alignment.centerRight,
            child: introShowcase(
              context: context,
              index: introBellStep,
              showcaseKey: introBellKey,
              wide: false,
              position: TooltipPosition.bottom,
              targetPadding: const EdgeInsets.all(8),
              targetShape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Alerts',
                onPressed: () {},
                icon: const NavSvgIcon('bell-ringing'),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: () => ShowcaseView.get().startShowCase(keys),
                child: const Text('Start tour'),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bar,
    );
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  testWidgets('walks through the six stops, then finishes', (tester) async {
    var ended = 0;
    await tester.pumpWidget(
      MaterialApp(home: _Harness(onEnd: () => ended++)),
    );
    await tester.tap(find.text('Start tour'));
    await settle(tester);

    for (final (i, step) in introSteps.indexed) {
      expect(find.text(step.title), findsOneWidget, reason: 'step ${i + 1}');
      expect(find.text('${i + 1} of 6'), findsOneWidget);
      expect(find.text(step.body), findsOneWidget);
      if (i < introSteps.length - 1) {
        expect(find.text('Skip'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await settle(tester);
      }
    }
    expect(ended, 0);
    expect(find.text('Skip'), findsNothing); // nothing to skip on the last one
    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(ended, 1);
    expect(find.text('Got it'), findsNothing);
  });

  for (final width in [320.0, 360.0, 402.0]) {
    testWidgets('no step overflows on a ${width.toInt()}px-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 874 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: _Harness(onEnd: () {})));
      await tester.tap(find.text('Start tour'));
      await settle(tester);
      for (var i = 0; i < introSteps.length; i++) {
        expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
        expect(find.text('${i + 1} of 6'), findsOneWidget);
        if (i < introSteps.length - 1) {
          await tester.tap(find.text('Next'));
          await settle(tester);
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Skip ends it at once', (tester) async {
    var ended = 0;
    await tester.pumpWidget(
      MaterialApp(home: _Harness(onEnd: () => ended++)),
    );
    await tester.tap(find.text('Start tour'));
    await settle(tester);
    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(ended, 1);
    expect(find.text('Home'), findsNothing); // the tooltip is gone
  });

  testWidgets('taps on the dimmed screen do not reach what is under it', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _Harness(onEnd: () {}),
        builder: (context, child) => child!,
      ),
    );
    // Something clickable underneath the overlay.
    await tester.tap(find.text('Start tour'));
    await settle(tester);
    await tester.tapAt(const Offset(400, 200));
    await settle(tester);
    // Still on the first step: the tour did not move or close.
    expect(find.text('1 of 6'), findsOneWidget);
    expect(pressed, 0);
  });

  group('when it is shown', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('only after onboarding flagged a fresh install', () async {
      final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      c.listen(introTourPendingProvider, (_, _) {});

      Future<bool> pending() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return c.read(introTourPendingProvider).value ?? false;
      }

      // An existing install never set the flag: no tour.
      expect(await pending(), isFalse);

      await SettingsRepository(db).set(SettingsKeys.introTourPending, 'true');
      expect(await pending(), isTrue);

      await SettingsRepository(db).set(SettingsKeys.introTourPending, 'false');
      expect(await pending(), isFalse);
    });
  });
}
