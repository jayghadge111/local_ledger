import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<void> _addTx(AppDatabase db, String id) => db
    .into(db.transactions)
    .insert(
      TransactionsCompanion.insert(
        id: id,
        amountMinor: 100,
        merchant: 'Shop $id',
        source: 'manual',
        type: 'debit',
        date: DateTime(2026, 10, 1),
      ),
    );

int _countIn(File f) {
  final raw = sqlite.sqlite3.open(f.path, mode: sqlite.OpenMode.readOnly);
  try {
    return raw.select('SELECT COUNT(*) c FROM transactions').first['c'] as int;
  } finally {
    raw.close();
  }
}

void main() {
  late Directory tmp;
  late LocalSnapshots snaps;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = Directory.systemTemp.createTempSync('snap');
    snaps = LocalSnapshots(() async => Directory('${tmp.path}/snapshots'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('a copy holds exactly what the database held, even while it is open',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _addTx(db, 'a');
    await _addTx(db, 'b');

    final info = await snaps.create(db, 'before-sms-scan');
    expect(info, isNotNull);
    expect(info!.label, 'Before scanning SMS');
    expect(_countIn(info.file), 2);

    // The live database carries on, unaffected.
    await _addTx(db, 'c');
    expect(_countIn(info.file), 2);
    expect(await db.select(db.transactions).get(), hasLength(3));
  });

  test('only the latest copy is kept: each one replaces the last', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await snaps.create(db, 'manual');
    await _addTx(db, 'later');
    final second = (await snaps.create(db, 'before-sms-scan'))!;
    for (var i = 0; i < 3; i++) {
      await snaps.create(db, 'manual');
    }
    final list = await snaps.list();
    expect(list, hasLength(1));
    expect(LocalSnapshots.keep, 1);
    // …and it is the newest one, not an old one.
    expect(list.single.at.isBefore(second.at), isFalse);
    expect(_countIn(list.single.file), 1);
  });

  test('a later copy replaces even a pre-upgrade one', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await snaps.create(db, 'upgrade-v10');
    await snaps.create(db, 'before-gmail-scan');
    final list = await snaps.list();
    expect(list.map((s) => s.reason), ['before-gmail-scan']);
  });

  test('a copy that fails to be made leaves the last one in place', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final good = (await snaps.create(db, 'manual'))!;
    // Make the next copy fail: its target name already exists as a directory.
    final blockedDir = Directory('${tmp.path}/snapshots');
    expect(blockedDir.existsSync(), isTrue);
    await db.close();
    expect(await snaps.create(db, 'manual'), isNull);
    expect((await snaps.list()).single.file.path, good.file.path);
  });

  test('a database file that is not open can be copied (pre-upgrade)', () {
    final file = File('${tmp.path}/old.sqlite');
    final raw = sqlite.sqlite3.open(file.path)
      ..execute('PRAGMA user_version = 10')
      ..execute('CREATE TABLE transactions (id TEXT)')
      ..execute("INSERT INTO transactions VALUES ('x')");
    raw.close();

    final info = snaps.createFromFile(
      file,
      'upgrade-v10',
      Directory('${tmp.path}/snapshots'),
    );
    expect(info, isNotNull);
    expect(info!.label, 'Before an app update');
    expect(_countIn(info.file), 1);
  });

  test('a copy that cannot be made is reported, not thrown', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final blocked = File('${tmp.path}/file')..writeAsStringSync('x');
    final bad = LocalSnapshots(() async => Directory(blocked.path));
    expect(await bad.create(db, 'manual'), isNull);
  });

  test('a copy can be deleted', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final info = (await snaps.create(db, 'manual'))!;
    expect(snaps.delete(info), isTrue);
    expect(await snaps.list(), isEmpty);
    expect(snaps.delete(info), isTrue); // already gone is fine
  });

  test('garbage is not a usable copy', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final good = (await snaps.create(db, 'manual'))!;
    expect(snaps.isUsable(good), isTrue);

    final junk = File('${tmp.path}/snapshots/snap_1_manual.sqlite')
      ..writeAsStringSync('not a database');
    final info = SnapshotInfo(
      file: junk,
      at: DateTime.now(),
      reason: 'manual',
      bytes: 14,
    );
    expect(snaps.isUsable(info), isFalse);
  });

  group('restoring', () {
    late File dbFile;
    late ProviderContainer container;

    setUp(() {
      dbFile = File('${tmp.path}/live.sqlite');
      container = ProviderContainer(
        overrides: [
          databaseFileProvider.overrideWithValue(() async => dbFile),
          localSnapshotsProvider.overrideWithValue(snaps),
          databaseProvider.overrideWith((ref) {
            final db = AppDatabase.forTesting(NativeDatabase(dbFile));
            ref.onDispose(db.close);
            return db;
          }),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('goes back to the copy', () async {
      var db = container.read(databaseProvider);
      await _addTx(db, 'before');
      final service = container.read(snapshotServiceProvider);
      final saved = (await service.snapshot('manual'))!;

      await _addTx(db, 'after');
      expect(await db.select(db.transactions).get(), hasLength(2));

      expect(await service.restore(saved), isTrue);

      db = container.read(databaseProvider); // the reopened, restored database
      final rows = await db.select(db.transactions).get();
      expect(rows.map((t) => t.id), ['before']);

      // The one copy is still there (restoring doesn't add or remove any).
      expect((await snaps.list()).map((x) => x.reason), ['manual']);
    });

    test('an unreadable copy changes nothing', () async {
      final db = container.read(databaseProvider);
      await _addTx(db, 'keep');
      final junk = File('${tmp.path}/junk.sqlite')
        ..writeAsStringSync('not a database');
      final ok = await container
          .read(snapshotServiceProvider)
          .restore(
            SnapshotInfo(
              file: junk,
              at: DateTime.now(),
              reason: 'manual',
              bytes: 1,
            ),
          );
      expect(ok, isFalse);
      expect(await db.select(db.transactions).get(), hasLength(1));
    });
  });
}
