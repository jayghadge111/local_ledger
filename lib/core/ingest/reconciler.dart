import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/settings_repository.dart';
import '../intelligence/refund_matcher.dart';
import '../intelligence/transfer_detector.dart';

class ReconcileResult {
  const ReconcileResult({this.transfers = 0, this.refunds = 0});
  final int transfers;
  final int refunds;
}

/// Re-examines stored transactions for internal transfers and refunds and
/// writes what it finds. Safe to run any number of times: rows the user has
/// locked, or that are already classified, are left alone.
class Reconciler {
  Reconciler(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<ReconcileResult> run() async {
    final all = await (_db.select(
      _db.transactions,
    )..where((t) => t.isDeleted.equals(false))).get();
    final own = (await _db.select(_db.ownIdentifiers).get())
        .map((e) => e.value)
        .toList();

    final nameRow =
        await (_db.select(_db.appSettings)
              ..where((t) => t.settingKey.equals(SettingsKeys.userName)))
            .getSingleOrNull();
    final transfers = detectTransfers(
      all,
      own,
      userName: nameRow?.settingValue,
    );
    final transferIds = {
      for (final p in transfers.pairs) ...[p.debitId, p.creditId],
      ...transfers.singles,
    };
    final afterTransfers = [
      for (final t in all)
        transferIds.contains(t.id) ? t.copyWith(kind: 'transfer') : t,
    ];
    final refunds = detectRefunds(afterTransfers);

    if (transferIds.isEmpty && refunds.isEmpty) return const ReconcileResult();

    final byId = {for (final t in all) t.id: t};
    // A transfer between your own accounts belongs in Self Transfer — unless
    // the user already picked a category themselves.
    Value<String?> categoryFor(String id) {
      final t = byId[id];
      final unset =
          t != null &&
          !t.userEdited &&
          (t.categoryId == null ||
              t.categoryId == 'cat_other' ||
              t.categoryId == 'cat_transfer');
      return unset ? const Value('cat_self_transfer') : const Value.absent();
    }

    await _db.batch((b) {
      for (final pair in transfers.pairs) {
        final group = _uuid.v4();
        for (final id in [pair.debitId, pair.creditId]) {
          b.update(
            _db.transactions,
            TransactionsCompanion(
              kind: const Value('transfer'),
              transferGroupId: Value(group),
              categoryId: categoryFor(id),
            ),
            where: (t) => t.id.equals(id),
          );
        }
      }
      for (final id in transfers.singles) {
        b.update(
          _db.transactions,
          TransactionsCompanion(
            kind: const Value('transfer'),
            categoryId: categoryFor(id),
          ),
          where: (t) => t.id.equals(id),
        );
      }
      for (final r in refunds) {
        b.update(
          _db.transactions,
          TransactionsCompanion(
            kind: const Value('refund'),
            refundOfId: Value(r.debitId),
          ),
          where: (t) => t.id.equals(r.creditId),
        );
      }
    });

    return ReconcileResult(
      transfers: transferIds.length,
      refunds: refunds.length,
    );
  }
}
