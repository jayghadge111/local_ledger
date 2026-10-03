import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/spend_analytics.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/default_categories.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/intelligence/name_match.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

void main() {
  group('isSameName', () {
    const me = 'Jayesh Bhika Ghadge';

    test('matches the bank\'s decorated versions of the same name', () {
      expect(isSameName(me, 'MR JAYESH BHIKA GHADGE'), isTrue);
      expect(isSameName(me, 'JAYESH BHIKA GHADGE (VPA'), isTrue);
      expect(isSameName(me, 'Ghadge Jayesh Bhika'), isTrue);
      expect(isSameName(me, 'JAYESH B GHADGE'), isTrue);
      expect(isSameName(me, 'JAYESH GHADGE'), isTrue);
      expect(isSameName(me, 'JAYESH BHIKA GHAD'), isTrue);
      expect(isSameName('Jayesh Ghadge', 'MR JAYESH BHIKA GHADGE'), isTrue);
    });

    test('does not match other people who share part of the name', () {
      expect(isSameName(me, 'JAYESH PATIL'), isFalse);
      expect(isSameName(me, 'RAHUL GHADGE'), isFalse);
      expect(isSameName(me, 'JAYESH'), isFalse);
      expect(isSameName(me, 'J B G'), isFalse);
      expect(isSameName(me, 'SWIGGY'), isFalse);
      expect(isSameName(me, null), isFalse);
      expect(isSameName(null, me), isFalse);
      expect(isSameName('', me), isFalse);
    });
  });

  test('the "Sender:" line of a credit email names who paid', () {
    final p = parseBankSms(
      'HDFC BANK Dear Customer, Greetings from HDFC Bank! We\'re writing to inform you that '
      'Rs.72000.00 has been successfully credited to your HDFC Bank account ending in 0715. '
      'Transaction Details: a. Date: 30-09-26 b. Sender: MR JAYESH BHIKA GHADGE '
      '(VPA: 9970900787@yescred) c. UPI Reference No.: 663917524572 Need Help?',
    )!;
    expect(p.type, 'credit');
    expect(p.merchant, 'MR JAYESH BHIKA GHADGE');
  });

  group('pipeline', () {
    late AppDatabase db;
    late TransactionIngestor ingestor;
    final t0 = DateTime(2026, 9, 30, 20, 8);

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      ingestor = TransactionIngestor(db, _FakeEncryption());
    });
    tearDown(() => db.close());

    Future<void> setName(String name) =>
        SettingsRepository(db).set(SettingsKeys.userName, name);

    Future<List<Transaction>> all() => db.select(db.transactions).get();

    const selfPay =
        'Dear Valued Customer, Your UPI payment has been successfully credited to the beneficiary '
        'bank account. UPI Ref. No. : 663927522641 From VPA : 9970900787@yescred '
        'Payer Name: MR JAYESH BHIKA GHADGE To VPA : 9970900787@yescred '
        'Payee Name: JAYESH BHIKA GHADGE Currency: INR Amount: 2500.00 Remarks: Paid via CRED '
        'Transaction Date: 30/09/2026 22:38:07 Transaction Status: COMPLETED Transaction Type: DR';

    const selfCredit =
        'We\'re writing to inform you that Rs.72000.00 has been successfully credited to your '
        'HDFC Bank account ending in 0715. Transaction Details: a. Date: 30-09-26 '
        'b. Sender: MR JAYESH BHIKA GHADGE (VPA: 9970900787@yescred) c. UPI Reference No.: 663917524572';

    test('payments to and from yourself become Self Transfer and drop out of totals', () async {
      await setName('Jayesh Bhika Ghadge');
      final s = await ingestor.begin();
      await s.add(
        source: 'email',
        sender: 'alerts@hdfcbank.bank.in',
        body: selfPay,
        date: t0,
      );
      await s.add(
        source: 'email',
        sender: 'alerts@hdfcbank.bank.in',
        body: selfCredit,
        date: t0.add(const Duration(hours: 5)),
      );
      await s.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: 'Sent Rs.500.00 From HDFC Bank A/c *0715 To RAHUL PATIL On 30/09/26 Ref 111',
        date: t0.add(const Duration(hours: 6)),
      );
      await s.finish();

      final rows = await all();
      final self = rows.where((t) => t.kind == 'transfer').toList();
      expect(
        self.map((t) => t.amountMinor),
        unorderedEquals([250000, 7200000]),
      );
      expect(self.every((t) => t.categoryId == 'cat_self_transfer'), isTrue);

      final other = rows.singleWhere(
        (t) => t.merchant.toLowerCase().contains('rahul'),
      );
      expect(other.kind, 'normal');

      final counted = spendingView(rows);
      expect(counted.map((t) => t.amountMinor), [50000]);
    });

    test('without a saved name nothing is guessed', () async {
      final s = await ingestor.begin();
      await s.add(
        source: 'email',
        sender: 'alerts@hdfcbank.bank.in',
        body: selfPay,
        date: t0,
      );
      await s.finish();
      expect((await all()).single.kind, 'normal');
    });

    test(
      'saving the name later reclassifies what was already imported',
      () async {
        final s = await ingestor.begin();
        await s.add(
          source: 'email',
          sender: 'alerts@hdfcbank.bank.in',
          body: selfCredit,
          date: t0,
        );
        await s.finish();
        expect((await all()).single.kind, 'normal');

        await setName('Jayesh Bhika Ghadge');
        await (await ingestor.begin()).finish();
        expect((await all()).single.kind, 'transfer');
      },
    );
  });

  test(
    'the five new categories exist for new and upgraded databases',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ids = (await db.select(db.categories).get())
          .map((c) => c.id)
          .toSet();
      for (final id in [
        'cat_self_transfer',
        'cat_emi',
        'cat_investment',
        'cat_lending',
        'cat_borrowing',
      ]) {
        expect(ids, contains(id));
        expect(defaultCategories.map((c) => c.id), contains(id));
      }
    },
  );
}
