import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import '../diagnostics/diagnostic_log.dart';
import 'local_snapshots.dart';

/// Where the database file is; a provider so tests can point it elsewhere.
final databaseFileProvider = Provider<Future<File> Function()>(
  (ref) => databaseFile,
);

final localSnapshotsProvider = Provider<LocalSnapshots>(
  (ref) => LocalSnapshots(snapshotsDirectory),
);

final snapshotServiceProvider = Provider<SnapshotService>(
  SnapshotService.new,
);

/// The saved copies, newest first. Refreshed after each one is made.
final snapshotListProvider = FutureProvider.autoDispose<List<SnapshotInfo>>(
  (ref) => ref.read(localSnapshotsProvider).list(),
);

/// Making and restoring the automatic copies of the database.
class SnapshotService {
  SnapshotService(this._ref);
  final Ref _ref;

  LocalSnapshots get _snapshots => _ref.read(localSnapshotsProvider);

  /// Copies the live database. Safe to call at any time and never throws.
  Future<SnapshotInfo?> snapshot(String reason) async {
    final info = await _snapshots.create(_ref.read(databaseProvider), reason);
    if (_ref.mounted) _ref.invalidate(snapshotListProvider);
    return info;
  }

  /// Deletes a saved copy.
  bool delete(SnapshotInfo snapshot) {
    final ok = _snapshots.delete(snapshot);
    if (_ref.mounted) _ref.invalidate(snapshotListProvider);
    return ok;
  }

  /// Replaces the live data with [snapshot]. Returns false, changing nothing,
  /// if the copy is unreadable. (There is only ever one copy, so nothing is
  /// saved first: that would replace the very copy being restored.)
  Future<bool> restore(SnapshotInfo snapshot) async {
    try {
      if (!_snapshots.isUsable(snapshot)) return false;
      final db = _ref.read(databaseProvider);
      await db.close();
      final file = await _ref.read(databaseFileProvider)();
      await _snapshots.restoreInto(file, snapshot);

      // Everything that read the old database now opens the restored one
      // (and upgrades it, if the copy came from an older version of the app).
      _ref.invalidate(databaseProvider);
      _ref.invalidate(snapshotListProvider);
      return true;
    } catch (error, stack) {
      DiagnosticLog.instance.record('backup', error, stack, 'restore');
      _ref.invalidate(databaseProvider);
      return false;
    }
  }
}
