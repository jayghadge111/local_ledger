import '../ui/undo.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'providers.dart';

final rulesProvider = StreamProvider<List<Rule>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.rules,
  )..orderBy([(r) => OrderingTerm.desc(r.priority)])).watch();
});

final rulesRepositoryProvider = Provider<RulesRepository>((ref) {
  return RulesRepository(ref.watch(databaseProvider));
});

class RulesRepository {
  RulesRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<void> addRule({required String pattern, required String categoryId}) {
    return _db
        .into(_db.rules)
        .insert(
          RulesCompanion.insert(
            id: _uuid.v4(),
            pattern: pattern.toLowerCase().trim(),
            categoryId: categoryId,
            source: 'user',
          ),
        );
  }

  /// Returns the way back.
  Future<UndoAction> deleteRule(String id) async {
    final row = await (_db.select(
      _db.rules,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    await (_db.delete(_db.rules)..where((r) => r.id.equals(id))).go();
    return () async {
      if (row != null) await _db.into(_db.rules).insertOnConflictUpdate(row);
    };
  }
}
