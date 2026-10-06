import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import '../ui/undo.dart';
import 'lending_math.dart';

final lendingEntriesProvider = StreamProvider<List<LendingEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.lendingEntries).watch();
});

final lendingPaymentsProvider = StreamProvider<List<LendingPayment>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.lendingPayments).watch();
});

/// Every entry with its repayments, open ones first.
final lendingBalancesProvider = Provider<List<LendingBalance>>((ref) {
  final entries =
      ref.watch(lendingEntriesProvider).value ?? const <LendingEntry>[];
  final payments =
      ref.watch(lendingPaymentsProvider).value ?? const <LendingPayment>[];
  return lendingBalances(entries, payments);
});

final lendingTotalsProvider = Provider<LendingTotals>(
  (ref) => lendingTotals(ref.watch(lendingBalancesProvider)),
);

final lendingRepositoryProvider = Provider<LendingRepository>(
  (ref) => LendingRepository(ref.watch(databaseProvider)),
);

enum LendingSync { none, created, updated, removed, keptWithPayments }

/// Hand-entered lending and borrowing. Nothing here touches transactions or
/// spending totals — it is a separate record of who owes whom.
class LendingRepository {
  LendingRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<String> addEntry({
    required String person,
    required String direction,
    required int amountMinor,
    required DateTime date,
    DateTime? dueDate,
    String? note,
    String? transactionId,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.lendingEntries)
        .insert(
          LendingEntriesCompanion.insert(
            id: id,
            person: person.trim(),
            direction: direction,
            amountMinor: amountMinor,
            date: date,
            dueDate: Value(dueDate),
            note: Value(
              note == null || note.trim().isEmpty ? null : note.trim(),
            ),
            transactionId: Value(transactionId),
          ),
        );
    return id;
  }

  /// The entry made from [transactionId], if any.
  Future<LendingEntry?> entryForTransaction(String transactionId) =>
      (_db.select(
        _db.lendingEntries,
      )..where((e) => e.transactionId.equals(transactionId))).getSingleOrNull();

  /// Keeps the Lend & borrow page in step with a transaction the user marked
  /// as lending or borrowing money.
  ///
  /// With a [direction] (see `lendingDirectionFor`) the entry is created, or
  /// updated if this transaction already made one — so editing the amount or
  /// the due date never adds a second entry. With none (the category was
  /// changed away) the entry goes, unless repayments were already recorded
  /// against it: that history is kept and the entry is just detached.
  Future<LendingSync> syncFromTransaction({
    required String transactionId,
    required String? direction,
    required String person,
    required int amountMinor,
    required DateTime date,
    DateTime? dueDate,
  }) async {
    final existing = await entryForTransaction(transactionId);

    if (direction == null) {
      if (existing == null) return LendingSync.none;
      final payments = await (_db.select(
        _db.lendingPayments,
      )..where((p) => p.entryId.equals(existing.id))).get();
      if (payments.isEmpty) {
        await deleteEntry(existing.id);
        return LendingSync.removed;
      }
      await (_db.update(_db.lendingEntries)
            ..where((e) => e.id.equals(existing.id)))
          .write(const LendingEntriesCompanion(transactionId: Value(null)));
      return LendingSync.keptWithPayments;
    }

    if (existing == null) {
      await addEntry(
        person: person,
        direction: direction,
        amountMinor: amountMinor,
        date: date,
        dueDate: dueDate,
        transactionId: transactionId,
      );
      return LendingSync.created;
    }
    await updateEntry(
      existing.id,
      person: person,
      direction: direction,
      amountMinor: amountMinor,
      date: date,
      dueDate: dueDate,
      note: existing.note,
    );
    return LendingSync.updated;
  }

  Future<void> updateEntry(
    String id, {
    required String person,
    required String direction,
    required int amountMinor,
    required DateTime date,
    DateTime? dueDate,
    String? note,
  }) {
    return (_db.update(
      _db.lendingEntries,
    )..where((e) => e.id.equals(id))).write(
      LendingEntriesCompanion(
        person: Value(person.trim()),
        direction: Value(direction),
        amountMinor: Value(amountMinor),
        date: Value(date),
        dueDate: Value(dueDate),
        note: Value(note == null || note.trim().isEmpty ? null : note.trim()),
      ),
    );
  }

  /// Records a repayment. When it brings the balance to zero the entry is
  /// marked settled.
  Future<void> addPayment(
    String entryId, {
    required int amountMinor,
    required DateTime date,
    String? note,
  }) async {
    await _db
        .into(_db.lendingPayments)
        .insert(
          LendingPaymentsCompanion.insert(
            id: _uuid.v4(),
            entryId: entryId,
            amountMinor: amountMinor,
            date: date,
            note: Value(
              note == null || note.trim().isEmpty ? null : note.trim(),
            ),
          ),
        );
    final entry = await (_db.select(
      _db.lendingEntries,
    )..where((e) => e.id.equals(entryId))).getSingle();
    final payments = await (_db.select(
      _db.lendingPayments,
    )..where((p) => p.entryId.equals(entryId))).get();
    final paid = payments.fold<int>(0, (s, p) => s + p.amountMinor);
    if (paid >= entry.amountMinor) await setSettled(entryId, true);
  }

  Future<void> setSettled(String id, bool settled) {
    return (_db.update(_db.lendingEntries)..where((e) => e.id.equals(id)))
        .write(LendingEntriesCompanion(isSettled: Value(settled)));
  }

  /// Removes a repayment; an entry that was settled by it is reopened.
  /// Returns the way back.
  Future<UndoAction> deletePayment(String id) async {
    final payment = await (_db.select(
      _db.lendingPayments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (payment == null) return () async {};
    final entryBefore = await (_db.select(
      _db.lendingEntries,
    )..where((e) => e.id.equals(payment.entryId))).getSingleOrNull();
    await (_db.delete(_db.lendingPayments)..where((p) => p.id.equals(id))).go();
    final entry = entryBefore;
    if (entry != null && entry.isSettled) {
      final left = await (_db.select(
        _db.lendingPayments,
      )..where((p) => p.entryId.equals(entry.id))).get();
      if (left.fold<int>(0, (s, p) => s + p.amountMinor) < entry.amountMinor) {
        await setSettled(entry.id, false);
      }
    }
    return () async {
      await _db.into(_db.lendingPayments).insertOnConflictUpdate(payment);
      if (entryBefore != null) await setSettled(entryBefore.id, entryBefore.isSettled);
    };
  }

  /// Removes an entry and its repayments. Returns the way back.
  Future<UndoAction> deleteEntry(String id) async {
    final entry = await (_db.select(
      _db.lendingEntries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    final payments = await (_db.select(
      _db.lendingPayments,
    )..where((p) => p.entryId.equals(id))).get();
    await (_db.delete(
      _db.lendingPayments,
    )..where((p) => p.entryId.equals(id))).go();
    await (_db.delete(_db.lendingEntries)..where((e) => e.id.equals(id))).go();
    return () => _putBack(entry, payments);
  }

  Future<void> _putBack(LendingEntry? entry, List<LendingPayment> payments) async {
    if (entry == null) return;
    await _db.transaction(() async {
      await _db.into(_db.lendingEntries).insertOnConflictUpdate(entry);
      for (final p in payments) {
        await _db.into(_db.lendingPayments).insertOnConflictUpdate(p);
      }
    });
  }

  /// Notes what [transactionId]'s loan entry looks like now, so that
  /// deleting the transaction (which removes or detaches that entry) can be
  /// taken back as a whole.
  Future<UndoAction> captureForTransaction(String transactionId) async {
    final entry = await entryForTransaction(transactionId);
    if (entry == null) return () async {};
    final payments = await (_db.select(
      _db.lendingPayments,
    )..where((p) => p.entryId.equals(entry.id))).get();
    return () => _putBack(entry, payments);
  }
}
