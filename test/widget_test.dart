import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_ledger/core/brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:local_ledger/app.dart';
import 'package:local_ledger/features/onboarding/onboarding_screen.dart';
import 'package:local_ledger/shared/widgets/onboarding_illustration.dart';

/// drift_flutter needs `getApplicationDocumentsPath()` to open the database.
/// `flutter_tester` has no real platform channel for path_provider, so
/// without this every DB-backed screen hangs waiting on a Future that never
/// resolves. A temp directory is fine for a test run.
class _FakePathProviderPlatform extends PathProviderPlatform {
  final _dir = Directory.systemTemp.createTempSync('local_ledger_test').path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir;

  @override
  Future<String?> getTemporaryPath() async => _dir;
}

/// Several short frames — enough for a page animation to finish. (Not
/// pumpAndSettle: the background gradient animates continuously by design.)
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  testWidgets('Splash screen shows the TrueLedger brand', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrueLedgerApp()));

    expect(find.text('TrueLedger'), findsOneWidget);
    expect(find.text(kTagline), findsOneWidget);
    expect(find.text('100% OFFLINE'), findsOneWidget);

    // Leave the app running past the splash's hand-off timer so the test
    // doesn't end with a pending timer. (Not pumpAndSettle: the background
    // gradient animates continuously by design.)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'Onboarding opens on the zero-cloud promise and has pictures for every page',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );
      await pumpFrames(tester);

      expect(find.text('Your money, your device, zero cloud'), findsOneWidget);
      expect(find.byType(OnboardingIllustration), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await pumpFrames(tester);
      expect(find.text('Add transactions effortlessly'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await pumpFrames(tester);
      expect(find.text('Alerts that matter'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    },
  );
}
