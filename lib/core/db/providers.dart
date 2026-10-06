import 'package:drift/drift.dart' show OrderingTerm, TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'throttle.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.categories,
  )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
});

/// How often the transaction list is re-read while rows are being written.
const kTransactionsRefresh = Duration(milliseconds: 250);

/// Non-deleted transactions, most recent first. Every list, total and chart
/// in the app is built from this one stream, so it is re-read at most a few
/// times a second however fast rows arrive (see [throttleLatest]).
final transactionsProvider = StreamProvider<List<Transaction>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.transactions)
    ..where((t) => t.isDeleted.equals(false))
    ..orderBy([(t) => OrderingTerm.desc(t.date)]);
  yield await query.get();
  final changes = throttleLatest(
    db.tableUpdates(TableUpdateQuery.onTable(db.transactions)),
    kTransactionsRefresh,
  );
  await for (final _ in changes) {
    yield await query.get();
  }
});
