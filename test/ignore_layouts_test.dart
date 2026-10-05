import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';
import 'package:local_ledger/core/sms/parser_templates.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

// A message no built-in rule recognises as a receipt: it reads as money
// received, but it is only a lender's acknowledgement in its own words.
String receipt(String amount, String ref) =>
    'Greetings from Zeta Finserv! Rs $amount credited to your Zeta account '
    'ref $ref. Keep paying on time to enjoy rewards.';

String realCredit(String amount) =>
    'Rs $amount credited to your A/c XX4921 by UPI from RAHUL KUMAR. '
    'Avl bal Rs 10,000.00';

void main() {
  late AppDatabase db;
  late _FakeEncryption crypto;
  late TransactionIngestor ingestor;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    crypto = _FakeEncryption();
    ingestor = TransactionIngestor(db, crypto);
  });
  tearDown(() => db.close());

  Future<List<Transaction>> live() => (db.select(
    db.transactions,
  )..where((t) => t.isDeleted.equals(false))).get();

  Future<IngestSession> ingest(List<(String, DateTime)> messages) async {
    final s = await ingestor.begin();
    for (final (body, date) in messages) {
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: date);
    }
    await s.finish();
    return s;
  }

  final d1 = DateTime(2026, 10, 1, 10);

  test('before it is taught, the unfamiliar wording is stored as income', () {
    // The built-in rules cannot know every lender's words — hence the
    // safety net below.
    expect(parseBankSms(receipt('4,500.00', 'R1'))?.type, 'credit');
  });

  test('delete and ignore: that layout is dropped from then on', () async {
    await ingest([(receipt('4,500.00', 'R1'), d1)]);
    final stored = (await live()).single;

    final learned = await ParserTemplateStore(db, crypto).learn(
      body: receipt('4,500.00', 'R1'),
      type: ignoreTemplateType,
      amountMinor: stored.amountMinor,
    );
    expect(learned, isTrue);
    await (db.update(db.transactions)..where((t) => t.id.equals(stored.id)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));

    // The next receipts — different amounts and reference numbers — vanish.
    final s = await ingest([
      (receipt('1,250.00', 'R2'), DateTime(2026, 10, 8, 10)),
      (receipt('9,999.00', 'R3'), DateTime(2026, 10, 15, 10)),
    ]);
    expect(await live(), isEmpty);
    expect(s.imported, 0);
    expect(s.skipped, 2);
  });

  test('similar-looking real credits are not touched', () async {
    await ParserTemplateStore(db, crypto).learn(
      body: receipt('4,500.00', 'R1'),
      type: ignoreTemplateType,
      amountMinor: 450000,
    );
    await ingest([
      (receipt('1,250.00', 'R2'), d1),
      (realCredit('2,500.00'), DateTime(2026, 10, 2, 10)),
    ]);
    final rows = await live();
    expect(rows, hasLength(1));
    expect(rows.single.amountMinor, 250000);
  });

  test('a copy stored earlier goes when it is read again', () async {
    await ingest([(receipt('4,500.00', 'R1'), d1)]);
    expect(await live(), hasLength(1));

    await ParserTemplateStore(db, crypto).learn(
      body: receipt('4,500.00', 'R1'),
      type: ignoreTemplateType,
      amountMinor: 450000,
    );
    final s = await ingest([(receipt('4,500.00', 'R1'), d1)]);
    expect(await live(), isEmpty);
    expect(s.removed, 1);
  });

  test('one the user edited stays, whatever they told us', () async {
    await ingest([(receipt('4,500.00', 'R1'), d1)]);
    final t = (await live()).single;
    await (db.update(db.transactions)..where((x) => x.id.equals(t.id))).write(
      const TransactionsCompanion(userEdited: Value(true)),
    );
    await ParserTemplateStore(db, crypto).learn(
      body: receipt('4,500.00', 'R1'),
      type: ignoreTemplateType,
      amountMinor: 450000,
    );
    await ingest([(receipt('4,500.00', 'R1'), d1)]);
    expect(await live(), hasLength(1));
  });

  test('an ignore layout never reads a message as a transaction', () async {
    // A learned *debit/credit* layout still works; "ignore" is not one.
    await ParserTemplateStore(db, crypto).learn(
      body: receipt('4,500.00', 'R1'),
      type: ignoreTemplateType,
      amountMinor: 450000,
    );
    final templates = await ParserTemplateStore(db, crypto).loadAll();
    expect(templates.single.type, ignoreTemplateType);
  });
}
