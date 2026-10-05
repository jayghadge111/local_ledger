import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

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

/// Non-deleted transactions, most recent first.
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.transactions)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();
});
