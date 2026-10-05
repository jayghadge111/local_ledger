import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/obligations/obligation_repository.dart';
import 'package:local_ledger/core/security/encryption_service.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

const _hdfc = 'VM-HDFCBK-S';
const _preDebit =
    'Reminder: Your A/c ending 4921 will be debited for Rs 5,000.00 on 07-OCT-26 towards UMRN HDFC7029104820194812 (NIPPON INDIA MUTUAL FUND). Ensure sufficient balance. -HDFC Bank';
const _realDebit =
    'Rs 5,000.00 debited from A/c XX4921 on 07-OCT-26 towards NIPPON INDIA MUTUAL FUND UMRN HDFC7029104820194812. Avl Bal Rs 20,000.00';

void main() {
  late AppDatabase db;
  late TransactionIngestor ingestor;
  final oct5 = DateTime(2026, 10, 5, 9);
  final oct7 = DateTime(2026, 10, 7, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingestor = TransactionIngestor(db, _FakeEncryption());
  });
  tearDown(() => db.close());

  Future<List<Obligation>> obligations() => db.select(db.obligations).get();
  Future<List<Transaction>> transactions() => db.select(db.transactions).get();

  Future<IngestSession> ingest(
    List<({String source, String sender, String body, DateTime date})> items,
  ) async {
    final s = await ingestor.begin();
    for (final i in items) {
      await s.add(
        source: i.source,
        sender: i.sender,
        body: i.body,
        date: i.date,
      );
    }
    await s.finish();
    return s;
  }

  ({String source, String sender, String body, DateTime date}) sms(
    String body,
    DateTime date,
  ) => (source: 'sms', sender: _hdfc, body: body, date: date);

  group('a pre-debit notice is not spending', () {
    test('it is kept as an upcoming debit, never as a transaction', () async {
      final s = await ingest([sms(_preDebit, oct5)]);
      expect(s.imported, 0);
      expect(s.obligations, 1);
      expect(await transactions(), isEmpty);

      final o = (await obligations()).single;
      expect(o.kind, 'pre_debit');
      expect(o.status, ObligationStatus.upcoming);
      expect(o.amountMinor, 500000);
      expect(o.dueDate, DateTime(2026, 10, 7));
      expect(o.biller, 'NIPPON INDIA MUTUAL FUND');
      expect(o.accountLast4, '4921');
      expect(o.umrn, 'HDFC7029104820194812');
    });

    test('reading the same message again adds nothing', () async {
      await ingest([sms(_preDebit, oct5)]);
      final again = await ingest([sms(_preDebit, oct5)]);
      expect(again.obligations, 0);
      expect(again.duplicates, 1);
      expect(await obligations(), hasLength(1));
    });

    test('the SMS and the email about one debit are one obligation', () async {
      await ingest([
        sms(_preDebit, oct5),
        (
          source: 'email',
          sender: 'alerts@hdfcbank.net',
          body: 'Scheduled Auto-Debit Advice. Your HDFC Bank Account ending 4921 is scheduled for an automated debit. Beneficiary: NIPPON INDIA MUTUAL FUND UMRN: HDFC7029104820194812 Scheduled Date: 07-Oct-2026 Amount: INR 5,000.00',
          date: oct5.add(const Duration(minutes: 3)),
        ),
      ]);
      expect(await obligations(), hasLength(1));
    });

    test('two different debits the same day stay separate', () async {
      await ingest([
        sms(_preDebit, oct5),
        sms(
          'Axis Bank Alert: Auto-debit of Rs 5,000.00 towards STAR HEALTH INSURANCE is scheduled from A/c ending 8812 on 07-OCT-26. UMRN: UTIB0001928471928401.',
          oct5,
        ),
      ]);
      expect(await obligations(), hasLength(2));
    });
  });

  group('the real debit settles its notice', () {
    test('notice first, debit later: paid, counted once', () async {
      await ingest([sms(_preDebit, oct5)]);
      await ingest([sms(_realDebit, oct7)]);

      final txns = await transactions();
      expect(txns, hasLength(1)); // the real debit, once
      expect(txns.single.amountMinor, 500000);
      final o = (await obligations()).single;
      expect(o.status, ObligationStatus.paid);
      expect(o.matchedTransactionId, txns.single.id);
    });

    test(
      'debit first, notice later (a full scan reads newest first)',
      () async {
        await ingest([sms(_realDebit, oct7), sms(_preDebit, oct5)]);
        final o = (await obligations()).single;
        expect(o.status, ObligationStatus.paid);
        expect((await transactions()), hasLength(1));
      },
    );

    test('a different amount does not settle it', () async {
      await ingest([
        sms(_preDebit, oct5),
        sms(
          'Rs 4,999.00 debited from A/c XX4921 on 07-OCT-26 towards SHOP. Avl Bal Rs 20,000.00',
          oct7,
        ),
      ]);
      expect((await obligations()).single.status, ObligationStatus.upcoming);
    });

    test('a debit from another account does not settle it', () async {
      await ingest([
        sms(_preDebit, oct5),
        sms(
          'Rs 5,000.00 debited from A/c XX1111 on 07-OCT-26 towards SHOP. Avl Bal Rs 20,000.00',
          oct7,
        ),
      ]);
      expect((await obligations()).single.status, ObligationStatus.upcoming);
    });

    test('one debit settles only one of two same-amount notices', () async {
      await ingest([
        sms(_preDebit, oct5),
        sms(
          'Kotak Bank: Rs 5,000.00 is scheduled for auto debit on 07-OCT-26 from A/c ending 4921 for ADITYA BIRLA FINANCE. UMRN: KKBK0001928472910482.',
          oct5,
        ),
        sms(_realDebit, oct7),
      ]);
      final statuses = (await obligations()).map((o) => o.status).toList()
        ..sort();
      expect(statuses, [ObligationStatus.paid, ObligationStatus.upcoming]);
    });

    test('no debit within the grace period: missed', () async {
      await ingest([sms(_preDebit, oct5)]);
      final repo = ObligationsRepository(db);
      await repo.reconcile(now: DateTime(2026, 10, 9));
      expect((await obligations()).single.status, ObligationStatus.upcoming);
      await repo.reconcile(now: DateTime(2026, 10, 15));
      expect((await obligations()).single.status, ObligationStatus.missed);

      // The debit turns up late (a bank holiday week): still settled.
      await ingest([sms(_realDebit, DateTime(2026, 10, 10))]);
      expect((await obligations()).single.status, ObligationStatus.paid);
    });
  });

  group('bounces', () {
    const bounce =
        'e-Mandate debit of Rs 5,000.00 towards NIPPON INDIA MUTUAL FUND failed on your A/c XX4921 due to Insufficient Funds. Return charges applicable. -HDFC Bank';

    test('a failed debit marks the upcoming one failed', () async {
      await ingest([sms(_preDebit, oct5), sms(bounce, oct7)]);
      final o = (await obligations()).single;
      expect(o.status, ObligationStatus.failed);
      expect(o.reason, 'Insufficient Funds');
      expect(await transactions(), isEmpty);
    });

    test('a failure with no earlier notice is still recorded', () async {
      await ingest([sms(bounce, oct7)]);
      final o = (await obligations()).single;
      expect(o.kind, 'bounce');
      expect(o.status, ObligationStatus.failed);
      expect(o.amountMinor, 500000);
    });

    test('the same failure by SMS and email is recorded once', () async {
      await ingest([
        sms(bounce, oct7),
        (
          source: 'email',
          sender: 'alerts@hdfcbank.net',
          body: bounce.replaceFirst('-HDFC Bank', ''),
          date: oct7.add(const Duration(minutes: 2)),
        ),
      ]);
      expect(await obligations(), hasLength(1));
    });

    test('a failed debit never counts as spending', () async {
      await ingest([
        sms(
          'ECS/NACH debit for Loan A/C 9012 of Rs 32,450.00 returned unpaid on 05-OCT-26. Please pay immediately.',
          oct5,
        ),
      ]);
      expect(await transactions(), isEmpty);
      expect((await obligations()).single.status, ObligationStatus.failed);
    });
  });

  group('mandates and dues', () {
    test('a registration is kept as an active mandate', () async {
      await ingest([
        sms(
          'Dear Customer, e-Mandate with UMRN HDFC7029104820194812 for Rs 5,000.00 has been successfully registered on your A/C XX4921 towards NIPPON INDIA MUTUAL FUND. Frequency: Monthly. -HDFC Bank',
          DateTime(2026, 10, 1),
        ),
      ]);
      final o = (await obligations()).single;
      expect(o.kind, 'mandate');
      expect(o.status, ObligationStatus.active);
      expect(o.frequency, 'Monthly');
      expect(await transactions(), isEmpty);
    });

    test('the same mandate announced twice is one mandate', () async {
      await ingest([
        sms(
          'e-Mandate with UMRN HDFC7029104820194812 for Rs 5,000.00 has been successfully registered on your A/C XX4921 towards NIPPON INDIA MUTUAL FUND.',
          DateTime(2026, 10, 1),
        ),
        (
          source: 'email',
          sender: 'alerts@hdfcbank.net',
          body: 'Successful Registration of e-Mandate - UMRN HDFC7029104820194812. Beneficiary: NIPPON INDIA MUTUAL FUND Maximum Cap Amount: INR 5,000.00 Frequency: Monthly',
          date: DateTime(2026, 10, 1, 9),
        ),
      ]);
      final list = await obligations();
      expect(list, hasLength(1));
      expect(list.single.frequency, 'Monthly'); // filled in from the second
    });

    test(
      'a statement and its due-tomorrow reminder are one card bill',
      () async {
        await ingest([
          sms(
            'Total Due on your SBI Card ending 4412 is Rs 18,920.00 and Min Due is Rs 950.00 due by 18/10/2026. Avoid late fees by paying now.',
            DateTime(2026, 10, 3),
          ),
          sms(
            'Urgent: Payment of Rs 18,920.00 on SBI Card ending 4412 is due tomorrow (18/10/2026). Pay today to avoid interest and late fees.',
            DateTime(2026, 10, 17),
          ),
        ]);
        final list = await obligations();
        expect(list, hasLength(1));
        expect(list.single.kind, 'card_due');
        expect(list.single.amountMinor, 1892000);
        expect(list.single.minDueMinor, 95000);
      },
    );

    test('paying the card bill settles it', () async {
      await ingest([
        sms(
          'Statement for HDFC Bank Credit Card ending 8210: Total Amt Due: Rs 44,210.50, Min Amt Due: Rs 2,210.00, Due Date: 22-OCT-26.',
          DateTime(2026, 10, 3),
        ),
        sms(
          'Rs 44,210.50 debited from A/c XX4921 on 20-OCT-26 towards HDFC BANK CREDIT CARD 8210 via NEFT. Avl Bal Rs 1,00,000.00',
          DateTime(2026, 10, 20),
        ),
      ]);
      expect((await obligations()).single.status, ObligationStatus.paid);
    });

    test(
      'an EMI the notice never attributes goes under the sending bank',
      () async {
        await ingest([
          sms(
            'Dear Customer, your EMI of Rs 32,450.00 for Loan A/C ending 9012 is due on 05-OCT-26.',
            DateTime(2026, 10, 3),
          ),
        ]);
        final o = (await obligations()).single;
        expect(o.kind, 'emi_due');
        expect(o.biller, 'HDFC Bank');
        expect(o.refType, 'loan');
      },
    );
  });

  group('what must still be a transaction', () {
    test('a real debit that mentions its mandate', () async {
      final s = await ingest([sms(_realDebit, oct7)]);
      expect(s.imported, 1);
      expect(s.obligations, 0);
      expect(await obligations(), isEmpty);
    });

    test('an ordinary UPI payment', () async {
      final s = await ingest([
        sms(
          'Sent Rs.500.00\nFrom HDFC Bank A/c *1234\nTo SUNRISE CAFE\nOn 02/10/26\nRef 600000000001',
          oct5,
        ),
      ]);
      expect(s.imported, 1);
      expect(await obligations(), isEmpty);
    });
  });
}
