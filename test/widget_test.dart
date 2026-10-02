import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:local_ledger/app.dart';

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

void main() {
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  testWidgets('Splash screen hands off to onboarding on a fresh install',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LocalLedgerApp()),
    );

    expect(find.text('LocalLedger'), findsOneWidget);

    // Not pumpAndSettle: the background gradient animates continuously by
    // design, so there's no "settled" state to wait for. Pump past the
    // splash screen's hand-off delay instead. A fresh install (no settings
    // row yet) should land on onboarding, not the home shell.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Your money, tracked locally'), findsOneWidget);
  });
}
