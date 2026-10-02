import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/ingest/reconciler.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

void main() {
  late AppDatabase db;
  late TransactionIngestor ingestor;
  final t0 = DateTime(2026, 10, 1, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingestor = TransactionIngestor(db, _FakeEncryption());
  });
  tearDown(() => db.close());

  Future<List<Transaction>> all() => db.select(db.transactions).get();

  test('imports, creates the account, cleans the merchant', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Sent Rs.20.00\nFrom HDFC Bank A/c *1234\nTo SWIGGY\nOn 02/10/26\nRef 123',
      date: t0,
    );
    expect(s.imported, 1);
    final t = (await all()).single;
    expect(t.merchant, 'Swiggy');
    expect(t.rawMerchant, 'SWIGGY');
    expect(t.amountMinor, 2000);
    expect(t.rawTextEncrypted, startsWith('enc:'));
    final account = (await db.select(db.accounts).get()).single;
    expect(account.bankName, 'HDFC Bank');
    expect(account.last4, '1234');
    expect(t.accountId, account.id);
  });

  test('re-scanning the same inbox adds nothing', () async {
    const body = 'Rs 100 debited from A/c XX1234 to RAJU TEA on 01-10-26.';
    for (var i = 0; i < 2; i++) {
      final s = await ingestor.begin();
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
      if (i == 1) expect(s.duplicates, 1);
    }
    expect(await all(), hasLength(1));
  });

  test('two genuinely different same-amount payments on one day both import', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 100 debited from A/c XX1234 to RAJU TEA. Ref 1', date: t0);
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 100 debited from A/c XX1234 to RAJU TEA. Ref 2', date: t0.add(const Duration(hours: 3)));
    expect(s.imported, 2);
  });

  test('same transaction from SMS and email is stored once', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 500 debited from A/c XX1234 to AMAZON.', date: t0);
    await s.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: 'Dear customer, Rs 500 has been debited from your account to AMAZON PAY',
      date: t0.add(const Duration(minutes: 1)),
    );
    expect(await all(), hasLength(1));
    expect(s.duplicates, 1);
  });

  test('transfer between two own accounts is linked and flagged', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.', date: t0);
    await s.add(source: 'sms', sender: 'JM-ICICIT-S', body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.', date: t0.add(const Duration(minutes: 1)));
    final result = await s.finish();
    expect(result.transfers, 2);
    final rows = await all();
    expect(rows.every((t) => t.kind == 'transfer'), isTrue);
    expect(rows.map((t) => t.transferGroupId).toSet(), hasLength(1));
  });

  test('refund is linked to the original debit', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 799.00 spent on card XX1234 at AMAZON on 01-10-26.', date: t0);
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Refund of Rs 799.00 credited to card XX1234 from AMAZON.', date: t0.add(const Duration(days: 5)));
    final result = await s.finish();
    expect(result.refunds, 1);
    final rows = await all();
    final refund = rows.firstWhere((t) => t.type == 'credit');
    final spend = rows.firstWhere((t) => t.type == 'debit');
    expect(refund.kind, 'refund');
    expect(refund.refundOfId, spend.id);
  });

  test('USD spend keeps its currency and is international', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'JM-ICICIT-T', body: 'USD 10.00 spent on ICICI Bank Card XX9999 on 01-Oct-26 at NETFLIX.COM.', date: t0);
    final t = (await all()).single;
    expect(t.currency, 'USD');
    expect(t.isInternational, isTrue);
  });

  test('transaction-like but unreadable message goes to the review queue; OTP does not', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Alert: Rs 750.00 at SOME SHOP, card ending 4321', date: t0);
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: '123456 is your OTP for txn of Rs 500', date: t0);
    expect(s.queued, 1);
    expect(await all(), isEmpty);
    expect(await db.select(db.unparsedMessages).get(), hasLength(1));
  });

  test('re-running the reconciler changes nothing further', () async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.', date: t0);
    await s.add(source: 'sms', sender: 'JM-ICICIT-S', body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.', date: t0.add(const Duration(minutes: 1)));
    await s.finish();
    final again = await Reconciler(db).run();
    expect(again.transfers, 0);
  });

  group('learning from corrections', () {
    test('renaming one teaches an alias and renames the similar ones', () async {
      final s = await ingestor.begin();
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 100 debited from A/c XX1234 to RAJU TEA STALL on 01-10-26. Ref 1', date: t0);
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 120 debited from A/c XX1234 to RAJU TEA STALL on 02-10-26. Ref 2', date: t0.add(const Duration(days: 1)));
      final rows = await all();
      final repo = TransactionsRepository(db);
      final first = rows.first;
      final renamed = await repo.updateTransaction(
        first.id,
        amountMinor: first.amountMinor,
        merchant: 'Office chai',
        categoryId: 'cat_food',
        type: first.type,
        date: first.date,
      );
      expect(renamed, 1);
      expect((await all()).map((t) => t.merchant), everyElement('Office chai'));

      // A future import picks the alias up automatically.
      final s2 = await ingestor.begin();
      await s2.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 90 debited from A/c XX1234 to RAJU TEA STALL on 03-10-26. Ref 3', date: t0.add(const Duration(days: 2)));
      expect((await all()).where((t) => t.merchant == 'Office chai'), hasLength(3));
    });

    test('un-marking a transfer releases the other half and locks the choice', () async {
      final s = await ingestor.begin();
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.', date: t0);
      await s.add(source: 'sms', sender: 'JM-ICICIT-S', body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.', date: t0.add(const Duration(minutes: 1)));
      await s.finish();
      final repo = TransactionsRepository(db);
      final debit = (await all()).firstWhere((t) => t.type == 'debit');
      await repo.setTransfer(debit.id, false);
      await Reconciler(db).run();
      final rows = await all();
      expect(rows.firstWhere((t) => t.id == debit.id).kind, 'normal');
      expect(rows.firstWhere((t) => t.id == debit.id).kindLocked, isTrue);
      // The credit is free again but, with its partner locked, can't re-pair.
      expect(rows.firstWhere((t) => t.type == 'credit').kind, 'normal');
    });
  });
}
