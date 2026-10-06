import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../db/app_database.dart';
import '../diagnostics/diagnostic_log.dart';

/// One saved copy of the whole database.
class SnapshotInfo {
  const SnapshotInfo({
    required this.file,
    required this.at,
    required this.reason,
    required this.bytes,
  });

  final File file;
  final DateTime at;

  /// A short machine slug: `upgrade-v10`, `before-sms-scan`, `manual`, …
  final String reason;
  final int bytes;

  /// A readable version of [reason].
  String get label {
    if (reason.startsWith('upgrade')) return 'Before an app update';
    return switch (reason) {
      'before-sms-scan' => 'Before scanning SMS',
      'before-gmail-scan' => 'Before scanning Gmail',
      'before-import' => 'Before importing a backup',
      'manual' => 'Backed up by you',
      _ => 'Automatic backup',
    };
  }
}

/// Automatic on-device copies of the database, so a bad update, an import
/// that went wrong or a mistaken bulk change can be rolled back with one tap.
///
/// A copy is made before every upgrade of the database structure and before
/// each large import (a full SMS or Gmail scan, or importing a backup file).
/// Only the latest copy is kept: each new one replaces the last.
///
/// Copies are made with SQLite's own `VACUUM INTO`, which writes a clean,
/// consistent file even while the app is reading and writing, and they live in
/// the app's private folder (excluded from Android/iOS backups, like the
/// database itself). They hold exactly what the database holds: the original
/// messages inside are still encrypted.
class LocalSnapshots {
  LocalSnapshots(this._directory);

  final Future<Directory> Function() _directory;

  static const keep = 1;
  static final _name = RegExp(r'^snap_(\d+)_([a-z0-9-]+)\.sqlite$');

  Future<Directory> _dir() async {
    final dir = await _directory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Copies the live database. Never throws: a failed copy is logged and
  /// returns null, because the thing the copy protects must still go ahead.
  Future<SnapshotInfo?> create(AppDatabase db, String reason) async {
    try {
      final dir = await _dir();
      final target = _targetFile(dir, reason);
      await db.customStatement('VACUUM INTO ?', [target.path]);
      prune(dir);
      return _info(target);
    } catch (error, stack) {
      DiagnosticLog.instance.record('backup', error, stack, 'snapshot $reason');
      return null;
    }
  }

  /// Copies a database that is not open through drift (used just before an
  /// upgrade, while the file is still in its old shape).
  SnapshotInfo? createFromFile(File dbFile, String reason, Directory dir) {
    try {
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final target = _targetFile(dir, reason);
      final raw = sqlite.sqlite3.open(dbFile.path);
      try {
        raw.execute('VACUUM INTO ?', [target.path]);
      } finally {
        raw.close();
      }
      prune(dir);
      return _info(target);
    } catch (error, stack) {
      DiagnosticLog.instance.record('backup', error, stack, 'snapshot $reason');
      return null;
    }
  }

  File _targetFile(Directory dir, String reason) {
    final slug = reason.toLowerCase().replaceAll(RegExp('[^a-z0-9-]'), '-');
    var at = DateTime.now().millisecondsSinceEpoch;
    // Two copies in the same millisecond must not overwrite each other.
    while (File(p.join(dir.path, 'snap_${at}_$slug.sqlite')).existsSync()) {
      at++;
    }
    return File(p.join(dir.path, 'snap_${at}_$slug.sqlite'));
  }

  SnapshotInfo? _info(File f) {
    final m = _name.firstMatch(p.basename(f.path));
    if (m == null || !f.existsSync()) return null;
    return SnapshotInfo(
      file: f,
      at: DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(1)!)),
      reason: m.group(2)!,
      bytes: f.lengthSync(),
    );
  }

  /// Newest first.
  Future<List<SnapshotInfo>> list() async => listIn(await _dir());

  List<SnapshotInfo> listIn(Directory dir) {
    if (!dir.existsSync()) return const [];
    final all = <SnapshotInfo>[];
    for (final e in dir.listSync()) {
      if (e is! File) continue;
      final info = _info(e);
      if (info != null) all.add(info);
    }
    all.sort((a, b) => b.at.compareTo(a.at));
    return all;
  }

  /// Deletes all but the newest [keep] (the one just made).
  void prune(Directory dir) {
    for (final s in listIn(dir).skip(keep)) {
      try {
        s.file.deleteSync();
      } catch (_) {}
    }
  }

  /// Deletes [snapshot]'s file. False if it couldn't be removed.
  bool delete(SnapshotInfo snapshot) {
    try {
      if (snapshot.file.existsSync()) snapshot.file.deleteSync();
      return true;
    } catch (error, stack) {
      DiagnosticLog.instance.record('backup', error, stack, 'deleting a copy');
      return false;
    }
  }

  /// Puts [snapshot] in place of the database file at [dbFile]. The database
  /// must be closed first. Leftover write-ahead files from the replaced
  /// database are removed so they can't be applied on top of the copy.
  Future<void> restoreInto(File dbFile, SnapshotInfo snapshot) async {
    final temp = File('${dbFile.path}.restoring');
    await snapshot.file.copy(temp.path);
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final extra = File('${dbFile.path}$suffix');
      if (extra.existsSync()) extra.deleteSync();
    }
    if (dbFile.existsSync()) dbFile.deleteSync();
    await temp.rename(dbFile.path);
  }

  /// Checks that [snapshot] is a readable database before it replaces
  /// anything.
  bool isUsable(SnapshotInfo snapshot) {
    try {
      final raw = sqlite.sqlite3.open(
        snapshot.file.path,
        mode: sqlite.OpenMode.readOnly,
      );
      try {
        final result = raw.select('PRAGMA integrity_check').first.values.first;
        return result == 'ok';
      } finally {
        raw.close();
      }
    } catch (_) {
      return false;
    }
  }
}
