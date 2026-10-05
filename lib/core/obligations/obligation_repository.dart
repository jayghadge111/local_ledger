import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import 'obligation_parser.dart';

abstract class ObligationStatus {
  /// A registered mandate that is in force.
  static const active = 'active';

  /// Waiting for its date.
  static const upcoming = 'upcoming';

  /// The real debit arrived and was matched to it.
  static const paid = 'paid';

  /// Its date passed and no matching debit was seen.
  static const missed = 'missed';

  /// The bank said the debit failed.
  static const failed = 'failed';
}

/// How long after its date a debit may still turn up (weekends, holidays,
/// banks that settle a few days late) before it is called missed.
const obligationGraceDays = 5;

// ---- matching rules (pure, so they can be tested without a database) ----

bool _datesSameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

bool _agree(String? a, String? b) => a == null || b == null || a == b;
bool _amountsAgree(int? a, int? b) => a == null || b == null || a == b;

String _firstToken(String s) {
  final m = RegExp(r'[a-z0-9]+').firstMatch(s.toLowerCase());
  return m?.group(0) ?? '';
}

/// Two names for the same biller: "BAJAJ FINANCE LTD" / "BAJAJ FINANCE LTD
/// EMI", or one unknown. Compared by first word, which is the brand.
bool billersAgree(String? a, String? b) {
  if (a == null || b == null) return true;
  final x = _firstToken(a);
  final y = _firstToken(b);
  return x.isEmpty || y.isEmpty || x == y;
}

const _scheduledDebits = {'pre_debit', 'emi_due'};

/// Whether [p] is another notice about the debit [o] already records — the
/// SMS and the email for one auto-debit, or a reminder after the first notice.
bool sameScheduledDebit(Obligation o, ParsedObligation p) {
  final bothDebits =
      _scheduledDebits.contains(o.kind) &&
      _scheduledDebits.contains(p.kind.key);
  final bothCards = o.kind == 'card_due' && p.kind == ObligationKind.cardDue;
  if (!bothDebits && !bothCards) return false;
  if (!_datesSameDay(o.dueDate, p.dueDate)) return false;
  if (!_amountsAgree(o.amountMinor, p.amountMinor)) return false;
  if (!_agree(o.accountLast4, p.accountLast4)) return false;
  if (bothCards && !_agree(o.refLast4, p.refLast4)) return false;
  return billersAgree(o.biller, p.biller);
}

/// Whether [p] (a mandate registration) describes mandate [o].
bool sameMandate(Obligation o, ParsedObligation p) {
  if (o.kind != 'mandate') return false;
  if (o.umrn != null && p.umrn != null) return o.umrn == p.umrn;
  if (o.umrn != null || p.umrn != null) return false;
  return billersAgree(o.biller, p.biller) &&
      _agree(o.accountLast4, p.accountLast4) &&
      _amountsAgree(o.amountMinor, p.amountMinor);
}

/// Whether the failure [p] is about the scheduled debit [o].
bool failureMatches(Obligation o, ParsedObligation p, DateTime when) {
  if (!_scheduledDebits.contains(o.kind)) return false;
  if (o.status != ObligationStatus.upcoming &&
      o.status != ObligationStatus.missed) {
    return false;
  }
  if (!_amountsAgree(o.amountMinor, p.amountMinor)) return false;
  if (!_agree(o.accountLast4, p.accountLast4)) return false;
  if (!_agree(o.refLast4, p.refLast4)) return false;
  if (!billersAgree(o.biller, p.biller)) return false;
  final due = o.dueDate;
  if (due == null) return false;
  final around = p.dueDate ?? when;
  return around.difference(due).inDays.abs() <= 7;
}

/// The transaction that settled [o], or null. A real debit of the same amount
/// (a card bill: between the minimum and the total) from a compatible account,
/// close to the date. Transactions in [used] already settled something else.
Transaction? matchPayment(
  Obligation o,
  Iterable<Transaction> transactions, {
  required Set<String> used,
  required String? Function(Transaction) last4Of,
}) {
  final due = o.dueDate;
  final amount = o.amountMinor;
  if (due == null || amount == null) return null;
  final isCard = o.kind == 'card_due';
  final from = due.subtract(Duration(days: isCard ? 12 : 2));
  final to = due.add(const Duration(days: obligationGraceDays));

  Transaction? best;
  Duration? bestGap;
  for (final t in transactions) {
    if (t.type != 'debit' || t.isDeleted || used.contains(t.id)) continue;
    if (t.date.isBefore(DateTime(from.year, from.month, from.day))) continue;
    if (t.date.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59))) {
      continue;
    }
    if (isCard) {
      final floor = o.minDueMinor ?? amount;
      if (t.amountMinor < floor || t.amountMinor > amount * 1.02) continue;
      if (!_looksLikeCardPayment(t, o)) continue;
    } else {
      if (t.amountMinor != amount) continue;
      if (!_agree(o.accountLast4, last4Of(t))) continue;
    }
    final gap = t.date.difference(due).abs();
    if (bestGap == null || gap < bestGap) {
      best = t;
      bestGap = gap;
    }
  }
  return best;
}

bool _looksLikeCardPayment(Transaction t, Obligation o) {
  final text = '${t.merchant} ${t.rawMerchant ?? ''}'.toLowerCase();
  if (RegExp(r'\b(?:card|cred|credit)\b').hasMatch(text)) return true;
  final brand = o.biller == null ? '' : _firstToken(o.biller!);
  return brand.length >= 3 && text.contains(brand);
}

// ---- storage ----

enum RecordOutcome { added, merged, duplicate }

final obligationsProvider = StreamProvider<List<Obligation>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.obligations,
  )..orderBy([(o) => OrderingTerm.asc(o.dueDate)])).watch();
});

final obligationsRepositoryProvider = Provider<ObligationsRepository>(
  (ref) => ObligationsRepository(ref.watch(databaseProvider)),
);

/// Scheduled debits and dues still ahead (or just past), soonest first.
final upcomingObligationsProvider = Provider<List<Obligation>>((ref) {
  final all = ref.watch(obligationsProvider).value ?? const <Obligation>[];
  return [
    for (final o in all)
      if (o.status == ObligationStatus.upcoming && o.dueDate != null) o,
  ]..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});

/// Auto-debits that failed in the last 30 days.
final recentFailuresProvider = Provider<List<Obligation>>((ref) {
  final all = ref.watch(obligationsProvider).value ?? const <Obligation>[];
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  return [
    for (final o in all)
      if (o.status == ObligationStatus.failed &&
          (o.dueDate ?? o.receivedAt).isAfter(cutoff))
        o,
  ]..sort(
    (a, b) => (b.dueDate ?? b.receivedAt).compareTo(a.dueDate ?? a.receivedAt),
  );
});

final activeMandatesProvider = Provider<List<Obligation>>((ref) {
  final all = ref.watch(obligationsProvider).value ?? const <Obligation>[];
  return [
    for (final o in all)
      if (o.kind == 'mandate' && o.status == ObligationStatus.active) o,
  ];
});

class ObligationsRepository {
  ObligationsRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Stores [p], merging it into what is already known about the same debit.
  Future<RecordOutcome> record(
    ParsedObligation p, {
    required String source,
    required String? sender,
    required String hash,
    required DateTime receivedAt,
  }) async {
    final seen = await (_db.select(
      _db.obligations,
    )..where((o) => o.sourceHash.equals(hash))).getSingleOrNull();
    if (seen != null) return RecordOutcome.duplicate;

    switch (p.kind) {
      case ObligationKind.mandate:
        return _recordMandate(p, source, sender, hash, receivedAt);
      case ObligationKind.bounce:
        return _recordBounce(p, source, sender, hash, receivedAt);
      case ObligationKind.preDebit:
      case ObligationKind.emiDue:
      case ObligationKind.cardDue:
        return _recordScheduled(p, source, sender, hash, receivedAt);
    }
  }

  Future<RecordOutcome> _recordMandate(
    ParsedObligation p,
    String source,
    String? sender,
    String hash,
    DateTime receivedAt,
  ) async {
    final mandates = await (_db.select(
      _db.obligations,
    )..where((o) => o.kind.equals('mandate'))).get();
    final existing = mandates.where((o) => sameMandate(o, p)).firstOrNull;
    if (existing != null) {
      await _fill(existing, p);
      return RecordOutcome.merged;
    }
    await _insert(p, ObligationStatus.active, source, sender, hash, receivedAt);
    return RecordOutcome.added;
  }

  Future<RecordOutcome> _recordScheduled(
    ParsedObligation p,
    String source,
    String? sender,
    String hash,
    DateTime receivedAt,
  ) async {
    final candidates = await (_db.select(
      _db.obligations,
    )..where((o) => o.kind.isIn(['pre_debit', 'emi_due', 'card_due']))).get();
    final existing = candidates
        .where((o) => sameScheduledDebit(o, p))
        .firstOrNull;
    if (existing != null) {
      await _fill(existing, p);
      return RecordOutcome.merged;
    }
    await _insert(
      p,
      ObligationStatus.upcoming,
      source,
      sender,
      hash,
      receivedAt,
    );
    return RecordOutcome.added;
  }

  Future<RecordOutcome> _recordBounce(
    ParsedObligation p,
    String source,
    String? sender,
    String hash,
    DateTime receivedAt,
  ) async {
    final open = await (_db.select(
      _db.obligations,
    )..where((o) => o.status.isIn(['upcoming', 'missed']))).get();
    final hits = open.where((o) => failureMatches(o, p, receivedAt)).toList()
      ..sort(
        (a, b) => a.dueDate!
            .difference(p.dueDate ?? receivedAt)
            .abs()
            .compareTo(b.dueDate!.difference(p.dueDate ?? receivedAt).abs()),
      );
    if (hits.isNotEmpty) {
      final o = hits.first;
      await (_db.update(
        _db.obligations,
      )..where((x) => x.id.equals(o.id))).write(
        ObligationsCompanion(
          status: const Value(ObligationStatus.failed),
          reason: Value(p.reason ?? o.reason),
          receivedAt: Value(receivedAt),
        ),
      );
      return RecordOutcome.merged;
    }

    // A failure we have no earlier notice for — unless we already recorded it
    // (the same bounce arriving by SMS and email).
    final failed = await (_db.select(
      _db.obligations,
    )..where((o) => o.status.equals(ObligationStatus.failed))).get();
    final twin = failed.where((o) {
      if (o.kind != 'bounce') return false;
      return _amountsAgree(o.amountMinor, p.amountMinor) &&
          _agree(o.accountLast4, p.accountLast4) &&
          _agree(o.refLast4, p.refLast4) &&
          billersAgree(o.biller, p.biller) &&
          o.receivedAt.difference(receivedAt).abs() < const Duration(days: 2);
    }).firstOrNull;
    if (twin != null) {
      await _fill(twin, p);
      return RecordOutcome.merged;
    }
    await _insert(p, ObligationStatus.failed, source, sender, hash, receivedAt);
    return RecordOutcome.added;
  }

  Future<void> _insert(
    ParsedObligation p,
    String status,
    String source,
    String? sender,
    String hash,
    DateTime receivedAt,
  ) async {
    await _db
        .into(_db.obligations)
        .insert(
          ObligationsCompanion.insert(
            id: _uuid.v4(),
            kind: p.kind.key,
            status: status,
            source: source,
            receivedAt: receivedAt,
            biller: Value(p.biller),
            amountMinor: Value(p.amountMinor),
            isMaxAmount: Value(p.isMaxAmount),
            minDueMinor: Value(p.minDueMinor),
            dueDate: Value(p.dueDate),
            umrn: Value(p.umrn),
            accountLast4: Value(p.accountLast4),
            refLast4: Value(p.refLast4),
            refType: Value(p.refType),
            frequency: Value(p.frequency),
            reason: Value(p.reason),
            senderCode: Value(sender),
            sourceHash: Value(hash),
          ),
        );
  }

  /// Fills what [o] lacks from [p] — never overwrites what is known.
  Future<void> _fill(Obligation o, ParsedObligation p) async {
    // A debit that is also a loan EMI is filed as the more specific kind.
    final kind = o.kind == 'pre_debit' && p.kind == ObligationKind.emiDue
        ? 'emi_due'
        : o.kind;
    await (_db.update(_db.obligations)..where((x) => x.id.equals(o.id))).write(
      ObligationsCompanion(
        kind: Value(kind),
        biller: Value(o.biller ?? p.biller),
        amountMinor: Value(o.amountMinor ?? p.amountMinor),
        minDueMinor: Value(o.minDueMinor ?? p.minDueMinor),
        dueDate: Value(o.dueDate ?? p.dueDate),
        umrn: Value(o.umrn ?? p.umrn),
        accountLast4: Value(o.accountLast4 ?? p.accountLast4),
        refLast4: Value(o.refLast4 ?? p.refLast4),
        refType: Value(o.refType ?? p.refType),
        frequency: Value(o.frequency ?? p.frequency),
        reason: Value(o.reason ?? p.reason),
      ),
    );
  }

  /// Settles what can be settled: an upcoming debit becomes [paid] once the
  /// real debit is in the transactions, and [missed] if its date has passed
  /// by more than [obligationGraceDays] with nothing found. Safe to run any
  /// number of times, in any order of arrival.
  Future<int> reconcile({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final open =
        await (_db.select(_db.obligations)..where(
              (o) =>
                  o.status.isIn(['upcoming', 'missed']) &
                  o.kind.isIn(['pre_debit', 'emi_due', 'card_due']),
            ))
            .get();
    if (open.isEmpty) return 0;

    final accounts = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.last4,
    };
    String? last4Of(Transaction t) =>
        t.accountId == null ? null : accounts[t.accountId];

    final taken = <String>{
      for (final o in await (_db.select(
        _db.obligations,
      )..where((o) => o.matchedTransactionId.isNotNull())).get())
        o.matchedTransactionId!,
    };
    final debits = await (_db.select(
      _db.transactions,
    )..where((t) => t.type.equals('debit') & t.isDeleted.equals(false))).get();

    var changed = 0;
    final ordered = [...open]
      ..sort(
        (a, b) =>
            (a.dueDate ?? a.receivedAt).compareTo(b.dueDate ?? b.receivedAt),
      );
    for (final o in ordered) {
      final match = matchPayment(o, debits, used: taken, last4Of: last4Of);
      if (match != null) {
        taken.add(match.id);
        await (_db.update(
          _db.obligations,
        )..where((x) => x.id.equals(o.id))).write(
          ObligationsCompanion(
            status: const Value(ObligationStatus.paid),
            matchedTransactionId: Value(match.id),
          ),
        );
        changed++;
        continue;
      }
      final due = o.dueDate;
      final overdue =
          due != null &&
          today.isAfter(due.add(const Duration(days: obligationGraceDays + 1)));
      final target = overdue
          ? ObligationStatus.missed
          : ObligationStatus.upcoming;
      if (target != o.status) {
        await (_db.update(_db.obligations)..where((x) => x.id.equals(o.id)))
            .write(ObligationsCompanion(status: Value(target)));
        changed++;
      }
    }
    return changed;
  }

  /// The user removes one (a stale mandate, a notice they don't want).
  Future<void> delete(String id) =>
      (_db.delete(_db.obligations)..where((o) => o.id.equals(id))).go();
}
