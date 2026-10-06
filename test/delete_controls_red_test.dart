import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/theme/app_theme.dart';
import 'package:local_ledger/features/settings/widgets/backup_card.dart';

void main() {
  test('one red for delete controls, lighter on dark', () {
    expect(AppPalette.dangerLight, const Color(0xFFD32F2F));
    expect(AppPalette.dangerDark, const Color(0xFFFF6B6B));
  });

  testWidgets('Automatic backups: a red delete icon right after Restore', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final info = SnapshotInfo(
      file: File('/tmp/snap_1_manual.sqlite'),
      at: DateTime(2026, 10, 6, 17, 30),
      reason: 'manual',
      bytes: 2048,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          snapshotListProvider.overrideWith((ref) async => [info]),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: const Scaffold(body: BackupCard()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final restore = tester.getRect(find.text('Restore'));
    final del = find.widgetWithIcon(IconButton, Icons.delete_outline_rounded);
    expect(del, findsOneWidget);
    expect(tester.getRect(del).left, greaterThan(restore.right - 1));
    expect(tester.widget<IconButton>(del).color, AppPalette.dangerLight);
    expect(find.byTooltip('Delete backup'), findsOneWidget);

    // Asks first; Cancel keeps it.
    await tester.tap(del);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete this backup?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete this backup?'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(db.close);
  });
}
