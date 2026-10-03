import 'package:drift/drift.dart' show Value;
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

  test(
    'two genuinely different same-amount payments on one day both import',
    () async {
      final s = await ingestor.begin();
      await s.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: 'Rs 100 debited from A/c XX1234 to RAJU TEA. Ref 1',
        date: t0,
      );
      await s.add(
        source: 'sms',
        sender: 'VM-HDFCBK-S',
        body: 'Rs 100 debited from A/c XX1234 to RAJU TEA. Ref 2',
        date: t0.add(const Duration(hours: 3)),
      );
      expect(s.imported, 2);
    },
  );

  test('same transaction from SMS and email is stored once', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 500 debited from A/c XX1234 to AMAZON.',
      date: t0,
    );
    await s.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: 'Dear customer, Rs 500 has been debited from your account to AMAZON PAY',
      date: t0.add(const Duration(minutes: 1)),
    );
    expect(await all(), hasLength(1));
    expect(s.duplicates, 1);
  });

  test('a home-loan EMI debit is named and filed under Bills', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: 'Rs. 52,414.00 has been debited from account 0715 for your Home Loan EMI. Available at all times.',
      date: t0,
    );
    final t = (await all()).single;
    expect(t.merchant, 'Home Loan EMI');
    expect(t.categoryId, 'cat_emi');
    expect(t.amountMinor, 5241400);
  });

  test('re-scan corrects a row saved with the old wrong merchant', () async {
    const body =
        'Rs. 52,414.00 has been debited from account 0715 for your Home Loan EMI. Available at all times.';
    final first = await ingestor.begin();
    await first.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: body,
      date: t0,
    );
    await db
        .update(db.transactions)
        .write(
          const TransactionsCompanion(
            merchant: Value('All Times'),
            rawMerchant: Value('All Times'),
            categoryId: Value('cat_other'),
          ),
        );
    final again = await ingestor.begin();
    await again.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: body,
      date: t0,
    );
    expect(again.repaired, 1);
    final t = (await all()).single;
    expect(t.merchant, 'Home Loan EMI');
    expect(t.categoryId, 'cat_emi');
  });

  test('UPI email: clean merchant name and a category', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body: 'Rs.1800.00 has been debited from account 0715 to VPA shop.123456789012@hdfcbank SUNRISE WELLNESS AND SPA on 05-04-26.',
      date: t0,
    );
    final t = (await all()).single;
    expect(t.merchant, 'Sunrise Wellness And Spa');
    expect(t.categoryId, 'cat_health');
  });

  test('field-by-field UPI email imports as the payer\'s debit', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'email',
      sender: 'alerts@hdfcbank.net',
      body:
          'Your UPI payment has been successfully credited to the beneficiary. Payer Name: MR TEST USER '
          'Payee Name: SAMPLE PAYEE NAME Currency: INR Amount: 18000.00 Transaction Status: COMPLETED '
          'Transaction Type: DR',
      date: t0,
    );
    final t = (await all()).single;
    expect(t.type, 'debit');
    expect(t.amountMinor, 1800000);
    expect(t.merchant, 'Sample Payee Name');
  });

  group('SMS + email duplicates', () {
    const smsA =
        'Rs 100 debited from A/c XX1234 to RAJU TEA on 01-10-26. Ref 1';
    const emailA =
        'Dear Customer, Rs. 100.00 has been debited from account 1234 towards RAJU TEA on 02-10-26.';

    Future<List<Transaction>> run(
      List<(String, String, String, Duration)> msgs,
    ) async {
      final s = await ingestor.begin();
      for (final (source, sender, body, offset) in msgs) {
        await s.add(
          source: source,
          sender: sender,
          body: body,
          date: t0.add(offset),
        );
      }
      return all();
    }

    test(
      'one real payment seen on both channels is stored once, and says so',
      () async {
        final rows = await run([
          ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
          ('email', 'alerts@hdfcbank.net', emailA, const Duration(minutes: 3)),
        ]);
        expect(rows, hasLength(1));
        expect(rows.single.alsoInSource, 'email');
      },
    );

    test('works in either order (email first)', () async {
      final rows = await run([
        ('email', 'alerts@hdfcbank.net', emailA, Duration.zero),
        ('sms', 'VM-HDFCBK-S', smsA, const Duration(minutes: 2)),
      ]);
      expect(rows, hasLength(1));
      expect(rows.single.alsoInSource, 'sms');
    });

    test(
      'two real payments, each reported twice, stay two transactions',
      () async {
        final rows = await run([
          ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
          (
            'sms',
            'VM-HDFCBK-S',
            'Rs 100 debited from A/c XX1234 to RAJU TEA on 01-10-26. Ref 2',
            const Duration(minutes: 4),
          ),
          ('email', 'alerts@hdfcbank.net', emailA, const Duration(minutes: 1)),
          (
            'email',
            'alerts@hdfcbank.net',
            '$emailA Ref 2',
            const Duration(minutes: 5),
          ),
        ]);
        expect(rows, hasLength(2));
        expect(rows.every((r) => r.alsoInSource == 'email'), isTrue);
      },
    );

    test('one SMS but two emails: the second email is a real payment, not a duplicate', () async {
      final rows = await run([
        ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
        ('email', 'alerts@hdfcbank.net', emailA, const Duration(minutes: 1)),
        (
          'email',
          'alerts@hdfcbank.net',
          '$emailA Ref 2',
          const Duration(minutes: 6),
        ),
      ]);
      expect(rows, hasLength(2));
    });

    test('a different card (last 4) is never merged', () async {
      final rows = await run([
        ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
        (
          'email',
          'alerts@hdfcbank.net',
          emailA.replaceAll('1234', '9999'),
          const Duration(minutes: 1),
        ),
      ]);
      expect(rows, hasLength(2));
    });

    test('far apart in time is never merged', () async {
      final rows = await run([
        ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
        ('email', 'alerts@hdfcbank.net', emailA, const Duration(hours: 5)),
      ]);
      expect(rows, hasLength(2));
    });

    test('a debit and a credit of the same amount are never merged', () async {
      final rows = await run([
        ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
        (
          'email',
          'alerts@hdfcbank.net',
          'Rs. 100.00 has been credited to account 1234 by RAJU TEA on 02-10-26.',
          const Duration(minutes: 1),
        ),
      ]);
      expect(rows, hasLength(2));
    });

    test('a different amount is never merged', () async {
      final rows = await run([
        ('sms', 'VM-HDFCBK-S', smsA, Duration.zero),
        (
          'email',
          'alerts@hdfcbank.net',
          emailA.replaceAll('100.00', '101.00'),
          const Duration(minutes: 1),
        ),
      ]);
      expect(rows, hasLength(2));
    });

    test(
      'the second report fills in a merchant the first one lacked',
      () async {
        final rows = await run([
          (
            'sms',
            'VM-HDFCBK-S',
            'Rs 100 debited from A/c XX1234 on 01-10-26.',
            Duration.zero,
          ),
          ('email', 'alerts@hdfcbank.net', emailA, const Duration(minutes: 1)),
        ]);
        expect(rows, hasLength(1));
        expect(rows.single.merchant, 'Raju Tea');
      },
    );
  });

  test('transfer between two own accounts is linked and flagged', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'JM-ICICIT-S',
      body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.',
      date: t0.add(const Duration(minutes: 1)),
    );
    final result = await s.finish();
    expect(result.transfers, 2);
    final rows = await all();
    expect(rows.every((t) => t.kind == 'transfer'), isTrue);
    expect(rows.map((t) => t.transferGroupId).toSet(), hasLength(1));
  });

  test('refund is linked to the original debit', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 799.00 spent on card XX1234 at AMAZON on 01-10-26.',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Refund of Rs 799.00 credited to card XX1234 from AMAZON.',
      date: t0.add(const Duration(days: 5)),
    );
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
    await s.add(
      source: 'sms',
      sender: 'JM-ICICIT-T',
      body: 'USD 10.00 spent on ICICI Bank Card XX9999 on 01-Oct-26 at NETFLIX.COM.',
      date: t0,
    );
    final t = (await all()).single;
    expect(t.currency, 'USD');
    expect(t.isInternational, isTrue);
  });

  test('transaction-like but unreadable message goes to the review queue; OTP does not', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Alert: Rs 750.00 at SOME SHOP, card ending 4321',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: '123456 is your OTP for txn of Rs 500',
      date: t0,
    );
    expect(s.queued, 1);
    expect(await all(), isEmpty);
    expect(await db.select(db.unparsedMessages).get(), hasLength(1));
  });

  test('re-running the reconciler changes nothing further', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'JM-ICICIT-S',
      body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.',
      date: t0.add(const Duration(minutes: 1)),
    );
    await s.finish();
    final again = await Reconciler(db).run();
    expect(again.transfers, 0);
  });

  test('forex card message imports as a card debit', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'JM-ICICIT-T',
      body: 'SAR 3.00 using ICICI Bank Forex Prepaid Card XX1233 transacted at POS on 02-Oct-26. Bal SAR 733.42. Temporary Credit Bal SAR 0.',
      date: t0,
    );
    final t = (await all()).single;
    expect(t.type, 'debit');
    expect(t.merchant, 'Card payment');
    expect(t.currency, 'SAR');
    expect(t.amountMinor, 300);
    final account = (await db.select(db.accounts).get()).single;
    expect(account.accountType, 'forex');
    expect(account.name, 'ICICI Bank Forex Card •••• 1233');
    expect(t.accountId, account.id);
  });

  test(
    'an account first seen as a generic card is upgraded to forex',
    () async {
      final s = await ingestor.begin();
      await s.add(
        source: 'sms',
        sender: 'JM-ICICIT-T',
        body: 'Rs 50 spent on ICICI Bank Card XX1233 at SHOP.',
        date: t0,
      );
      await s.add(
        source: 'sms',
        sender: 'JM-ICICIT-T',
        body: 'SAR 3.00 using ICICI Bank Forex Prepaid Card XX1233 transacted at POS on 02-Oct-26.',
        date: t0.add(const Duration(days: 1)),
      );
      final accounts = await db.select(db.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.accountType, 'forex');
    },
  );

  test('re-scan repairs a row imported by an older, wrong parse', () async {
    const body =
        'SAR 3.00 using ICICI Bank Forex Prepaid Card XX1233 transacted at POS on 02-Oct-26. Bal SAR 733.42. Temporary Credit Bal SAR 0.';
    final first = await ingestor.begin();
    await first.add(source: 'sms', sender: 'JM-ICICIT-T', body: body, date: t0);
    // Simulate what the old parser stored.
    await db
        .update(db.transactions)
        .write(
          const TransactionsCompanion(
            type: Value('credit'),
            merchant: Value('UPI payment'),
          ),
        );

    final again = await ingestor.begin();
    await again.add(source: 'sms', sender: 'JM-ICICIT-T', body: body, date: t0);
    expect(again.repaired, 1);
    final t = (await all()).single;
    expect(t.type, 'debit');
    expect(t.merchant, 'Card payment');
  });

  test('a row the user edited is not touched by a re-scan', () async {
    const body = 'Rs 100 debited from A/c XX1234 to RAJU TEA on 01-10-26.';
    final first = await ingestor.begin();
    await first.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
    await db
        .update(db.transactions)
        .write(
          const TransactionsCompanion(
            merchant: Value('My chai'),
            userEdited: Value(true),
          ),
        );
    final again = await ingestor.begin();
    await again.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
    expect(again.repaired, 0);
    expect((await all()).single.merchant, 'My chai');
  });

  test('imports are auto-categorized from the merchant name', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 150 debited from A/c XX1234 to JOFREY CAFE on 01-10-26.',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 500 debited from A/c XX1234 to RAJU ENTERPRISES on 01-10-26.',
      date: t0.add(const Duration(hours: 5)),
    );
    final rows = await all();
    expect(
      rows.firstWhere((t) => t.amountMinor == 15000).categoryId,
      'cat_food',
    );
    expect(
      rows.firstWhere((t) => t.amountMinor == 50000).categoryId,
      'cat_other',
    );
  });

  test('re-scan categorizes older "Other" rows but never overrides a chosen category', () async {
    const body = 'Rs 150 debited from A/c XX1234 to JOFREY CAFE on 01-10-26.';
    final first = await ingestor.begin();
    await first.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
    await db
        .update(db.transactions)
        .write(const TransactionsCompanion(categoryId: Value('cat_other')));
    final again = await ingestor.begin();
    await again.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
    expect((await all()).single.categoryId, 'cat_food');

    await db
        .update(db.transactions)
        .write(const TransactionsCompanion(categoryId: Value('cat_health')));
    final third = await ingestor.begin();
    await third.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: t0);
    expect((await all()).single.categoryId, 'cat_health');
  });

  test('re-categorizing one teaches a rule and updates the rest', () async {
    final s = await ingestor.begin();
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 100 debited from A/c XX1234 to RAJU ENTERPRISES on 01-10-26. Ref 1',
      date: t0,
    );
    await s.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 120 debited from A/c XX1234 to RAJU ENTERPRISES on 02-10-26. Ref 2',
      date: t0.add(const Duration(days: 1)),
    );
    final first = (await all()).first;
    final repo = TransactionsRepository(db);
    final others = await repo.updateTransaction(
      first.id,
      amountMinor: first.amountMinor,
      merchant: first.merchant,
      categoryId: 'cat_groceries',
      type: first.type,
      date: first.date,
    );
    expect(others, 1);
    expect(
      (await all()).map((t) => t.categoryId),
      everyElement('cat_groceries'),
    );

    final s2 = await ingestor.begin();
    await s2.add(
      source: 'sms',
      sender: 'VM-HDFCBK-S',
      body: 'Rs 90 debited from A/c XX1234 to RAJU ENTERPRISES on 03-10-26. Ref 3',
      date: t0.add(const Duration(days: 2)),
    );
    expect(
      (await all()).where((t) => t.categoryId == 'cat_groceries'),
      hasLength(3),
    );
  });

  group('learning from corrections', () {
    test(
      'renaming one teaches an alias and renames the similar ones',
      () async {
        final s = await ingestor.begin();
        await s.add(
          source: 'sms',
          sender: 'VM-HDFCBK-S',
          body: 'Rs 100 debited from A/c XX1234 to RAJU TEA STALL on 01-10-26. Ref 1',
          date: t0,
        );
        await s.add(
          source: 'sms',
          sender: 'VM-HDFCBK-S',
          body: 'Rs 120 debited from A/c XX1234 to RAJU TEA STALL on 02-10-26. Ref 2',
          date: t0.add(const Duration(days: 1)),
        );
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
        expect(
          (await all()).map((t) => t.merchant),
          everyElement('Office chai'),
        );

        // A future import picks the alias up automatically.
        final s2 = await ingestor.begin();
        await s2.add(
          source: 'sms',
          sender: 'VM-HDFCBK-S',
          body: 'Rs 90 debited from A/c XX1234 to RAJU TEA STALL on 03-10-26. Ref 3',
          date: t0.add(const Duration(days: 2)),
        );
        expect(
          (await all()).where((t) => t.merchant == 'Office chai'),
          hasLength(3),
        );
      },
    );

    test(
      'un-marking a transfer releases the other half and locks the choice',
      () async {
        final s = await ingestor.begin();
        await s.add(
          source: 'sms',
          sender: 'VM-HDFCBK-S',
          body: 'Rs 5,000.00 debited from A/c XX1111 to JAYESH on 01-10-26.',
          date: t0,
        );
        await s.add(
          source: 'sms',
          sender: 'JM-ICICIT-S',
          body: 'Rs 5,000.00 credited to A/c XX2222 from JAYESH on 01-10-26.',
          date: t0.add(const Duration(minutes: 1)),
        );
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
      },
    );
  });
}
