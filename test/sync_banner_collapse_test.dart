import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/import_progress.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/shared/widgets/glass_surface.dart';
import 'package:local_ledger/shared/widgets/sync_banner.dart';

class _Fixed extends SyncController {
  _Fixed(this._state);
  final SyncState _state;
  @override
  SyncState build() => _state;
}

Future<void> show(WidgetTester tester, SyncState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [syncControllerProvider.overrideWith(() => _Fixed(state))],
      child: const MaterialApp(home: Scaffold(body: SyncBanner())),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  const running = SyncState(
    gmail: SyncJob(
      status: SyncStatus.running,
      progress: ImportProgress(
        'Reading bank emails',
        done: 42,
        total: 100,
        found: 5,
      ),
    ),
  );

  testWidgets('a running scan is one small line until opened', (tester) async {
    await show(tester, running);

    // The small form: name, percentage, Stop — nothing else.
    expect(find.text('Syncing Gmail'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.textContaining('checked'), findsNothing);
    expect(find.textContaining('added so far'), findsNothing);
    expect(find.text('Keeps going if you leave this page.'), findsNothing);
    final collapsed = tester.getSize(find.byType(GlassCard)).height;

    await tester.tap(find.byTooltip('Show details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('42 of 100 checked · 58 left'), findsOneWidget);
    expect(find.text('5 transactions added so far'), findsOneWidget);
    expect(find.text('Keeps going if you leave this page.'), findsOneWidget);
    expect(
      tester.getSize(find.byType(GlassCard)).height,
      greaterThan(collapsed),
    );

    await tester.tap(find.byTooltip('Hide details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('checked'), findsNothing);
    expect(tester.getSize(find.byType(GlassCard)).height, collapsed);
  });

  testWidgets('Stop works from the small form', (tester) async {
    await show(tester, running);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Stop'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a paused scan keeps Resume in reach, Dismiss one tap away', (
    tester,
  ) async {
    await show(
      tester,
      const SyncState(
        gmail: SyncJob(
          status: SyncStatus.paused,
          resumable: true,
          progress: ImportProgress('Paused', done: 10, total: 100),
        ),
      ),
    );
    expect(find.text('Gmail sync paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Dismiss'), findsNothing);
    await tester.tap(find.byTooltip('Show details'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('the quiet catch-up says what it is doing', (tester) async {
    await show(
      tester,
      const SyncState(
        gmail: SyncJob(
          status: SyncStatus.running,
          background: true,
          progress: ImportProgress('Checking for new bank emails…'),
        ),
      ),
    );
    expect(find.text('Checking Gmail for new emails'), findsOneWidget);
  });

  testWidgets('fits a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncControllerProvider.overrideWith(() => _Fixed(running))],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(body: SyncBanner()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
