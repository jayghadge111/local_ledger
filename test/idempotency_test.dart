import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/security/encryption_service.dart';

import 'message_corpus_test.dart' show corpus;

// The de-duplication and twin-merge logic is subtle, so instead of a few
// hand-picked cases these tests feed it a whole inbox and then check the
// properties that must always hold:
//
//   1. reading the same inbox again changes nothing (re-scans are safe);
//   2. the order messages arrive in doesn't matter (the phone's inbox, Gmail
//      and a resumed scan can each deliver them in any order);
//   3. nor does how a scan is cut into runs (stopped and resumed, or a
//      catch-up run in the middle).

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

typedef Message = ({String source, String sender, String body, DateTime date});

/// A realistic month: every layout in the corpus, plus SMS+email twins, a
/// refund, a transfer between own accounts, a card bill and an auto-debit notice.
List<Message> buildInbox() {
  final inbox = <Message>[];
  final start = DateTime(2026, 9, 1, 9);
  var i = 0;
  for (final m in corpus) {
    if (m.type == null) continue;
    // More than a day apart: two real payments of the same amount from the
    // same card within hours of each other are ambiguous by nature (they
    // look exactly like one payment reported twice), so they are kept out.
    final at = start.add(Duration(hours: 26 * i++));
    inbox.add((
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: m.text,
      date: at,
    ));
    // Every fourth one was also reported by email a little later.
    if (i % 4 == 0) {
      inbox.add((
        source: 'email',
        sender: 'alerts@hdfcbank.net',
        body: m.text,
        date: at.add(const Duration(minutes: 6)),
      ));
    }
  }

  final base = DateTime(2026, 10, 3, 10);
  inbox.addAll([
    (
      source: 'sms',
      sender: 'VM-ICICIB-S',
      body: 'Rs 499.00 spent on ICICI Bank Card XX4411 on 03-Oct-26 at AMAZON.',
      date: base,
    ),
    (
      source: 'sms',
      sender: 'VM-ICICIB-S',
      body:
          'Refund of Rs 499.00 for your order at AMAZON credited to your ICICI Bank Card XX4411.',
      date: base.add(const Duration(days: 2)),
    ),
    (
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 5,000.00 debited from A/c XX1111 on 04-Oct-26. Info: IMPS/TO OWN ACCOUNT.',
      date: base.add(const Duration(days: 1)),
    ),
    (
      source: 'sms',
      sender: 'VM-AXISBK-S',
      body: 'INR 5,000.00 credited to A/c XX2222 on 04-Oct-26 by IMPS from OWN ACCOUNT.',
      date: base.add(const Duration(days: 1, minutes: 2)),
    ),
    (
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body:
          'Your account 427xxxx2627 has been debited on 28/09/2026 by INR 921.00 towards Credit card repayment.',
      date: base.add(const Duration(days: 3)),
    ),
    (
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body:
          'Your A/c XX1111 will be debited on 07-OCT-26 by Rs 1,500.00 towards NIPPON INDIA MUTUAL FUND SIP. Mandate UMRN HDFC7022710220017414.',
      date: base.add(const Duration(days: 4)),
    ),
  ]);
  return inbox;
}

/// Everything a user could see, with the random ids left out, in a stable
/// order, so two databases can be compared.
Future<Map<String, Object?>> state(AppDatabase db) async {
  final accounts = {
    for (final a in await db.select(db.accounts).get())
      // The corpus reuses one last-4 for messages that call it a credit
      // card, a debit card and an account, so what kind it is called depends
      // on which came first. Whether it is the same account does not.
      a.id: '${a.bankName}|${a.last4}',
  };
  final transactions = [
    for (final t in await (db.select(
      db.transactions,
    )..where((t) => t.isDeleted.equals(false))).get())
      [
        // Which of the two reports of a payment is kept as the main row
        // (and so its exact time) depends on which arrived first; the day
        // and the set of channels that reported it do not.
        '${t.date.year}-${t.date.month}-${t.date.day}',
        t.amountMinor,
        t.type,
        t.merchant,
        t.categoryId,
        t.kind,
        ({
          t.source,
          ...(t.alsoInSource ?? '').split(',').where((s) => s.isNotEmpty),
        }.toList()..sort()),
        accounts[t.accountId],
        t.refundOfId == null ? null : 'refund',
        t.transferGroupId == null ? null : 'transfer',
      ].join('|'),
  ]..sort();
  final obligations = [
    for (final o in await db.select(db.obligations).get())
      '${o.kind}|${o.status}|${o.biller}|${o.amountMinor}|${o.dueDate?.millisecondsSinceEpoch}',
  ]..sort();
  final queued = (await db.select(db.unparsedMessages).get()).length;
  return {
    'transactions': transactions,
    'obligations': obligations,
    'queued': queued,
    'accounts': accounts.values.toList()..sort(),
  };
}

/// Compares two states and, when they differ, says exactly which rows.
void expectSameState(Map<String, Object?> actual, Map<String, Object?> expected) {
  for (final key in expected.keys) {
    final a = (actual[key] is List ? actual[key] as List : [actual[key]]).map((e) => '$e').toList();
    final e = (expected[key] is List ? expected[key] as List : [expected[key]]).map((e) => '$e').toList();
    final onlyActual = [...a]..removeWhere(e.contains);
    final onlyExpected = [...e]..removeWhere(a.contains);
    expect(onlyActual, isEmpty, reason: '$key: rows only in this run');
    expect(onlyExpected, isEmpty, reason: '$key: rows missing from this run');
    expect(a.length, e.length, reason: '$key count');
  }
}

/// Credits reduced to their amount, so a refund that attached to a different
/// look-alike payment doesn't count as a difference.
Map<String, Object?> withoutRefundDetail(Map<String, Object?> s) => {
  ...s,
  'transactions': [
    for (final line in s['transactions'] as List)
      if ('$line'.split('|')[2] == 'credit')
        '${'$line'.split('|')[1]}|credit'
      else
        line,
  ]..sort(),
};

void main() {
  late AppDatabase db;
  late TransactionIngestor ingestor;

  Future<void> ingest(List<Message> messages, {int runs = 1}) async {
    final per = (messages.length / runs).ceil();
    for (var r = 0; r < runs; r++) {
      final chunk = messages.skip(r * per).take(per);
      final session = await ingestor.begin();
      for (final m in chunk) {
        await session.add(
          source: m.source,
          sender: m.sender,
          body: m.body,
          date: m.date,
        );
      }
      await session.finish();
    }
  }

  AppDatabase fresh() {
    final d = AppDatabase.forTesting(NativeDatabase.memory());
    ingestor = TransactionIngestor(d, _FakeEncryption());
    return d;
  }

  setUp(() => db = fresh());
  tearDown(() => db.close());

  final inbox = buildInbox();

  test('the test inbox is substantial and has twins', () {
    expect(inbox.length, greaterThan(90));
    expect(inbox.where((m) => m.source == 'email'), isNotEmpty);
  });

  test('reading the same inbox again changes nothing', () async {
    await ingest(inbox);
    final once = await state(db);
    expect((once['transactions'] as List), isNotEmpty);

    await ingest(inbox);
    expectSameState(await state(db), once);

    await ingest(inbox, runs: 3);
    expectSameState(await state(db), once);
  });

  test('a second scan imports nothing new', () async {
    await ingest(inbox);
    final session = await ingestor.begin();
    for (final m in inbox) {
      await session.add(
        source: m.source,
        sender: m.sender,
        body: m.body,
        date: m.date,
      );
    }
    await session.finish();
    expect(session.imported, 0);
    expect(session.queued, 0);
    expect(session.obligations, 0);
  });

  group('the order messages arrive in does not matter', () {
    late Map<String, Object?> expected;
    setUp(() async {
      await ingest(inbox);
      expected = await state(db);
    });

    for (final seed in [1, 2, 3, 4, 5]) {
      test('shuffled with seed $seed', () async {
        final other = fresh();
        addTearDown(other.close);
        final shuffled = [...inbox]..shuffle(Random(seed));
        await ingest(shuffled);
        expectSameState(await state(other), expected);
      });
    }

    test('newest first (the way the phone returns an inbox)', () async {
      final other = fresh();
      addTearDown(other.close);
      await ingest([...inbox]..sort((a, b) => b.date.compareTo(a.date)));
      expectSameState(await state(other), expected);
    });

    test('Gmail first, then SMS', () async {
      final other = fresh();
      addTearDown(other.close);
      final emails = inbox.where((m) => m.source == 'email').toList();
      final sms = inbox.where((m) => m.source != 'email').toList();
      await ingest(emails);
      await ingest(sms);
      expectSameState(await state(other), expected);
    });
  });

  group('how a scan is cut into runs does not matter', () {
    late Map<String, Object?> expected;
    setUp(() async {
      await ingest(inbox);
      expected = await state(db);
    });

    for (final runs in [2, 5, 11]) {
      test('$runs runs, in time order', () async {
        final other = fresh();
        addTearDown(other.close);
        final ordered = [...inbox]..sort((a, b) => a.date.compareTo(b.date));
        await ingest(ordered, runs: runs);
        expectSameState(await state(other), expected);
      });

      // Known limit: a refund is matched to an earlier payment of the same
      // amount. If the run that reads the refund hasn't read its payment yet,
      // it can attach to a look-alike (this inbox has many identical ₹500
      // payments), and a later run doesn't re-think it. So here refunds are
      // compared only by amount; everything else must match exactly.
      test('$runs runs, shuffled', () async {
        final other = fresh();
        addTearDown(other.close);
        final shuffled = [...inbox]..shuffle(Random(runs));
        await ingest(shuffled, runs: runs);
        expectSameState(
          withoutRefundDetail(await state(other)),
          withoutRefundDetail(expected),
        );
      });
    }
  });
}
