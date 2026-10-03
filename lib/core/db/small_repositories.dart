import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../security/encryption_providers.dart';
import 'app_database.dart';
import 'providers.dart';

const _uuid = Uuid();

// ---- Accounts ----

final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.accounts).watch();
});

final accountsByIdProvider = Provider<Map<String, Account>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
  return {for (final a in accounts) a.id: a};
});

// ---- Own identifiers (names / VPAs that mean "me") ----

final ownIdentifiersProvider = StreamProvider<List<OwnIdentifier>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.ownIdentifiers).watch();
});

final ownIdentifiersRepositoryProvider = Provider<OwnIdentifiersRepository>(
  (ref) => OwnIdentifiersRepository(ref.watch(databaseProvider)),
);

class OwnIdentifiersRepository {
  OwnIdentifiersRepository(this._db);
  final AppDatabase _db;

  Future<void> add(String value) {
    final v = value.trim().toLowerCase();
    if (v.length < 3) return Future.value();
    return _db.into(_db.ownIdentifiers).insert(
          OwnIdentifiersCompanion.insert(id: _uuid.v4(), value: v),
        );
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.ownIdentifiers)..where((t) => t.id.equals(id))).go();
}

// ---- Splits ----

final splitSharesProvider = StreamProvider<List<SplitShare>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.splitShares).watch();
});

/// Transaction id -> total the user is owed by others on it.
final othersShareByTxnProvider = Provider<Map<String, int>>((ref) {
  final shares = ref.watch(splitSharesProvider).value ?? const <SplitShare>[];
  final map = <String, int>{};
  for (final s in shares) {
    map.update(s.transactionId, (v) => v + s.shareMinor, ifAbsent: () => s.shareMinor);
  }
  return map;
});

/// All shares grouped by the transaction they belong to.
final splitsByTxnProvider = Provider<Map<String, List<SplitShare>>>((ref) {
  final shares = ref.watch(splitSharesProvider).value ?? const <SplitShare>[];
  final map = <String, List<SplitShare>>{};
  for (final s in shares) {
    map.putIfAbsent(s.transactionId, () => []).add(s);
  }
  return map;
});

final splitsRepositoryProvider = Provider<SplitsRepository>(
  (ref) => SplitsRepository(ref.watch(databaseProvider)),
);

class SplitsRepository {
  SplitsRepository(this._db);
  final AppDatabase _db;

  Future<void> addShare({
    required String transactionId,
    required String personName,
    required int shareMinor,
  }) {
    return _db.into(_db.splitShares).insert(
          SplitSharesCompanion.insert(
            id: _uuid.v4(),
            transactionId: transactionId,
            personName: personName.trim(),
            shareMinor: shareMinor,
          ),
        );
  }

  Future<void> setSettled(String id, bool settled) =>
      (_db.update(_db.splitShares)..where((t) => t.id.equals(id)))
          .write(SplitSharesCompanion(settled: Value(settled)));

  Future<void> delete(String id) =>
      (_db.delete(_db.splitShares)..where((t) => t.id.equals(id))).go();
}

// ---- Unparsed messages (review queue) ----

final unparsedMessagesProvider = StreamProvider<List<UnparsedMessage>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.unparsedMessages)
        ..where((t) => t.resolved.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
      .watch();
});

final unparsedRepositoryProvider = Provider<UnparsedRepository>(
  (ref) => UnparsedRepository(ref.watch(databaseProvider), ref),
);

class UnparsedRepository {
  UnparsedRepository(this._db, this._ref);
  final AppDatabase _db;
  final Ref _ref;

  Future<String> readBody(UnparsedMessage m) =>
      _ref.read(encryptionServiceProvider).decryptString(m.rawTextEncrypted);

  Future<void> resolve(String id) =>
      (_db.update(_db.unparsedMessages)..where((t) => t.id.equals(id)))
          .write(const UnparsedMessagesCompanion(resolved: Value(true)));
}
