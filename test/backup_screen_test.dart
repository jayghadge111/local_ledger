import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/features/settings/backup_screen.dart';
import 'package:local_ledger/features/settings/diagnostics_screen.dart';
import 'package:local_ledger/core/diagnostics/diagnostic_log.dart';
import 'package:local_ledger/shared/widgets/glass_surface.dart';

void main() {
  Future<void> run(WidgetTester tester, List<SnapshotInfo> copies) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          snapshotListProvider.overrideWith((ref) async => copies),
        ],
        child: MaterialApp(
          home: const Scaffold(body: SingleChildScrollView(child: BackupEntryCard())),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Save to a file'), findsNothing); // details are one tap away

    await tester.tap(find.byType(GlassCard));
    await tester.pump(); // builds the new route
    await tester.pump(const Duration(milliseconds: 600)); // …and its transition
    expect(find.text('Save to a file'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(db.close);
  }

  testWidgets('a card that opens the backup screen (no copy yet)', (
    tester,
  ) async {
    await run(tester, const []);
  });

  testWidgets('the card shows when the last copy was made', (tester) async {
    final info = SnapshotInfo(
      file: File('/tmp/snap_1_manual.sqlite'),
      at: DateTime(2026, 10, 6, 17, 30),
      reason: 'manual',
      bytes: 2048,
    );
    await run(tester, [info]);
  });

  testWidgets('Diagnostics is a card that opens its own screen', (tester) async {
    late Directory dir;
    late DiagnosticLog log;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('diag');
      log = DiagnosticLog.inDirectory(dir);
      await log.init();
      log.record('zone', StateError('boom'));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DiagnosticsEntryCard(log: log)),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.textContaining('1 problem noted'), findsOneWidget);
    expect(find.text('Email diagnostic log'), findsNothing);

    await tester.tap(find.byType(GlassCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Email diagnostic log'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
