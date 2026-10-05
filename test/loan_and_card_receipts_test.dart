import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

// The messages from a real phone.
const _bajajCredit1 =
    'Payment Update!\nPart Payment Rs. 59000.00 dated 11-Sep-26 successfully credited toward loan no. P405PSA3761027.Check your flexi limit here https://nbfl.in/BAJAJF/HLpMOV\nBajaj Finance Ltd';
const _bajajCredit2 =
    'Payment Update!\nPart payment of Rs. 59000.0 received for loan P405PSA3761027 with txn no. P26254HTRAJX8XOD will get adjusted within 48hrs (excluding bank holidays). If no overdues, full amount would be adjusted towards principal outstanding else overdues will be recovered from this amount.\nBajaj Finance Ltd';
const _cardReceipt =
    'We have received your payment of INR 921.00 towards your credit card number ending 9706. Thank you (Cheque/ECS Payment subject to realisation)-StanChart';
const _cardDebit =
    'Your account 427xxxx2627 has been debited on 28/09/2026 by INR 921.00 towards Credit card repayment.Available Balance:INR 123.64 -StanChart';
const _homeLoanSms =
    'UPDATE: INR 52,414.00 debited from HDFC Bank XX0715 on 05-SEP-26. Info: ACH D- HDFC BANK LTD-474875811. Avl bal:INR 70,703.19';
const _homeLoanEmail =
    'Dear Customer, Rs.52414.00 has been debited from HDFC Bank Account Number XXXXXXXXXX0715 towards HDFC LTD/680877098 with UMRN HDFC7022710220017414 on 05-Sep-2026. Assuring you of our best services at all times.';
const _bajajUpi =
    'Sent Rs.99500.00\nFrom HDFC Bank A/C *0715\nTo BAJAJ FINANCE LIMITED INT\nOn 23/09/26\nRef 663211244572\nNot You?\nCall 18002586161/SMS BLOCK UPI to 7308080808';

String _hash(String source, String body, DateTime date) => sha512
    .convert(
      utf8.encode('$source|${body.trim()}|${date.millisecondsSinceEpoch}'),
    )
    .toString();

void main() {
  group('a lender confirming your payment is not money received', () {
    test('Bajaj: both wordings', () {
      expect(parseBankSms(_bajajCredit1), isNull);
      expect(parseBankSms(_bajajCredit2), isNull);
      expect(isPaymentAcknowledgement(_bajajCredit1), isTrue);
      expect(isPaymentAcknowledgement(_bajajCredit2), isTrue);
    });

    test('a credit card issuer confirming your bill payment', () {
      expect(parseBankSms(_cardReceipt), isNull);
    });

    test('it is not asked about in the "messages to review" queue either', () {
      expect(looksLikeUnparsedTransaction(_bajajCredit1), isFalse);
      expect(looksLikeUnparsedTransaction(_cardReceipt), isFalse);
    });

    test('real money received is untouched', () {
      for (final sms in [
        'Rs 5,000.00 credited to your A/c XX4921 on 07-OCT-26 by UPI from RAHUL. Avl bal Rs 10,000.00',
        'INR 25,000.00 credited to A/c XX1234 on 01-OCT-26 salary from ACME LTD',
        'Dear Customer, your loan amount of Rs 1,00,000 has been credited to your A/c XX4921',
        'Refund of Rs 499.00 credited to your card ending 4411 for order 123',
      ]) {
        expect(parseBankSms(sms)?.type, 'credit', reason: sms);
      }
    });

    test('the payment you made still counts, once', () {
      final p = parseBankSms(_bajajUpi)!;
      expect(p.type, 'debit');
      expect(p.amountMinor, 9950000);
      expect(p.last4, '0715');
    });
  });

  group('the same mistake from any lender or card issuer', () {
    // Receipts for money the user paid toward a loan or a credit card, worded
    // the way different banks and NBFCs word them. None is income.
    const receipts = [
      'Payment of Rs. 12,450.00 has been received towards your HDFC Bank Credit Card ending 8210. Thank you.',
      'Rs 5,000.00 received on your ICICI Bank Credit Card XX2004 as payment on 05-OCT-26. Avl credit limit Rs 90,000.',
      'We have received payment of Rs 18,920.00 on your SBI Card ending 4412. Thank you for your payment.',
      'Payment of INR 3,200.00 credited to your Axis Bank Credit Card No XX1109 on 02-Oct-26.',
      'Thank you! Your payment of Rs. 8,450.00 towards Kotak Credit Card ending 3391 has been received.',
      'Dear Customer, we acknowledge receipt of Rs 11,490.00 against your Tata Capital loan A/c 7731.',
      'Your EMI payment of Rs 3,120.00 for Two Wheeler loan has been received. -L&T Finance',
      'Rs. 1,899.00 received towards your DMI Finance loan EMI on 05-Oct-26. Thank you for the payment.',
      'Instalment of Rs 2,850.00 for your loan 48BJA8291 has been credited. Thank you, Bajaj Finserv.',
      'Payment received: Rs 14,290.00 posted to your RBL Bank Credit Card ending 7012.',
      'Your repayment of Rs 7,000.00 has been credited to loan account 9012. -HDFC Bank',
      'EMI of Rs 2,000.00 received for your loan LAN12345 on 03-Oct-26. Hero FinCorp thanks you.',
    ];
    for (final sms in receipts) {
      test(sms.substring(0, 60), () {
        expect(parseBankSms(sms), isNull);
        expect(isPaymentAcknowledgement(sms), isTrue);
        expect(looksLikeUnparsedTransaction(sms), isFalse);
      });
    }

    // Credits that really are income, or really are a bank-account event, even
    // though they mention a card, a loan or a payment.
    const income = [
      'INR 45,000.00 credited to A/c XX1234 on 01-OCT-26 by NEFT from ACME LTD salary. Avl bal INR 60,000.',
      'Rs 2,500.00 credited to your A/c XX4921 by UPI from RAHUL KUMAR. Payment for dinner. Ref 1234.',
      'Dear Customer, your loan of Rs 5,00,000.00 has been disbursed and credited to your A/c XX4921.',
      'Refund of Rs 499.00 credited to your credit card ending 4411 against order 5521.',
      'Cashback of Rs 50.00 credited to your Axis Bank Credit Card No XX1109.',
      'Rs 120.50 interest credited to your A/c XX4921 for the quarter ending 30-SEP-26.',
      'Rs 800.00 received from AMAZON PAY in your A/c XX4921 on 04-OCT-26.',
    ];
    for (final sms in income) {
      test('stays a credit: ${sms.substring(0, 50)}', () {
        expect(parseBankSms(sms)?.type, 'credit');
      });
    }

    test('a debit is never taken for a receipt', () {
      const debits = [
        'Rs 3,200.00 debited from A/c XX4921 towards your credit card payment. Thank you.',
        'EMI payment of Rs 3,120.00 for your loan debited from A/c XX1234 on 06-OCT-26.',
      ];
      for (final sms in debits) {
        expect(isPaymentAcknowledgement(sms), isFalse, reason: sms);
        expect(parseBankSms(sms)?.type, 'debit', reason: sms);
      }
    });
  });

  group('account numbers and payee names, whatever the bank', () {
    test('a masked number is found wherever it sits', () {
      expect(
        parseBankSms(
          'Rs 500 debited from HDFC Bank XX0715 on 05-SEP-26 to SHOP',
        )?.last4,
        '0715',
      );
      expect(
        parseBankSms('INR 500.00 debited from xxxx2627 on 28-09-26 to SHOP')
            ?.last4,
        '2627',
      );
      expect(parseBankSms('Rs 500 debited a/c *4321 at SHOP')?.last4, '4321');
      expect(
        parseBankSms(
          'Your account 427xxxx2627 has been debited by INR 921.00 to SHOP',
        )?.last4,
        '2627',
      );
    });

    test('channel prefixes are not part of the payee', () {
      for (final prefix in ['ACH D-', 'NACH-', 'ECS D-', 'ACH:']) {
        final p = parseBankSms(
          'Rs 1,200.00 debited from A/c XX1234 on 05-SEP-26. Info: $prefix TATA CAPITAL FINANCIAL-12345678.',
        )!;
        expect(
          p.merchant.toLowerCase(),
          isNot(contains('ach')),
          reason: prefix,
        );
        expect(
          p.merchant.toLowerCase(),
          isNot(contains('12345678')),
          reason: prefix,
        );
      }
    });
  });

  group('paying a credit card bill', () {
    test('the debit says what it was for, and from which account', () {
      final p = parseBankSms(_cardDebit)!;
      expect(p.type, 'debit');
      expect(p.amountMinor, 92100);
      expect(p.merchant, 'Credit card bill');
      // The money left the savings account ending 2627 — not a credit card.
      expect(p.last4, '2627');
      expect(p.accountKind, isNot('credit_card'));
    });

    test('and is filed under Bills', () {
      expect(defaultCategoryFor('Credit card bill'), 'cat_bills');
    });
  });

  group('the HDFC home-loan debit', () {
    test('the SMS is read as a loan EMI from the right account', () {
      final p = parseBankSms(_homeLoanSms)!;
      expect(p.type, 'debit');
      expect(p.amountMinor, 5241400);
      expect(p.last4, '0715');
      expect(p.merchant, 'Loan EMI');
    });

    test('the email is the same debit, same account', () {
      final p = parseBankSms(_homeLoanEmail)!;
      expect(p.amountMinor, 5241400);
      expect(p.last4, '0715');
    });
  });

  group('storing them', () {
    late AppDatabase db;
    late TransactionIngestor ingestor;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      ingestor = TransactionIngestor(db, _FakeEncryption());
    });
    tearDown(() => db.close());

    Future<List<Transaction>> live() => (db.select(
      db.transactions,
    )..where((t) => t.isDeleted.equals(false))).get();

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

    ({String source, String sender, String body, DateTime date}) item(
      String source,
      String body,
      DateTime date,
    ) => (
      source: source,
      sender: source == 'sms' ? 'VM-HDFCBK-S' : 'alerts@hdfcbank.net',
      body: body,
      date: date,
    );

    test('a lender receipt is never stored as income', () async {
      await ingest([
        item('sms', _bajajCredit1, DateTime(2026, 9, 12, 16, 57)),
        item('sms', _bajajCredit2, DateTime(2026, 9, 11, 18, 9)),
        item('sms', _cardReceipt, DateTime(2026, 9, 28, 7, 34)),
      ]);
      expect(await live(), isEmpty);
    });

    test('the SMS and the email 5½ hours later are one debit', () async {
      final s = await ingest([
        item('sms', _homeLoanSms, DateTime(2026, 9, 5, 8, 15)),
        item('email', _homeLoanEmail, DateTime(2026, 9, 5, 13, 56)),
      ]);
      final rows = await live();
      expect(rows, hasLength(1));
      expect(rows.single.amountMinor, 5241400);
      expect(rows.single.alsoInSource, contains('email'));
      expect(s.duplicates, 1);
    });

    test('whichever order they arrive in', () async {
      await ingest([
        item('email', _homeLoanEmail, DateTime(2026, 9, 5, 13, 56)),
        item('sms', _homeLoanSms, DateTime(2026, 9, 5, 8, 15)),
      ]);
      expect(await live(), hasLength(1));
    });

    test('a different account is not the same debit', () async {
      await ingest([
        item('sms', _homeLoanSms, DateTime(2026, 9, 5, 8, 15)),
        item(
          'email',
          _homeLoanEmail.replaceAll('XXXXXXXXXX0715', 'XXXXXXXXXX9999'),
          DateTime(2026, 9, 5, 13, 56),
        ),
      ]);
      expect(await live(), hasLength(2));
    });

    test('more than a day apart is not the same debit', () async {
      await ingest([
        item('sms', _homeLoanSms, DateTime(2026, 9, 5, 8, 15)),
        item('email', _homeLoanEmail, DateTime(2026, 9, 7, 8, 15)),
      ]);
      expect(await live(), hasLength(2));
    });

    test('two genuine payments of the same amount stay two', () async {
      await ingest([
        item('sms', _homeLoanSms, DateTime(2026, 9, 5, 8, 15)),
        item(
          'sms',
          _homeLoanSms.replaceAll('474875811', '999999999'),
          DateTime(2026, 9, 5, 18, 0),
        ),
        item('email', _homeLoanEmail, DateTime(2026, 9, 5, 13, 56)),
        item(
          'email',
          _homeLoanEmail.replaceAll('680877098', '111111111'),
          DateTime(2026, 9, 5, 18, 2),
        ),
      ]);
      expect(await live(), hasLength(2));
    });

    test('duplicates and receipts already in the app are cleaned up', () async {
      // What an earlier version left behind: the receipt as "income", and the
      // SMS and email as two debits (the SMS with no account).
      final receiptDate = DateTime(2026, 9, 12, 16, 57);
      Future<void> insert({
        required String id,
        required String type,
        required int amount,
        required String source,
        required DateTime date,
        String? hash,
        String? accountId,
        bool edited = false,
        String merchant = 'x',
      }) => db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              amountMinor: amount,
              merchant: merchant,
              source: source,
              type: type,
              date: date,
              sourceHash: Value(hash),
              accountId: Value(accountId),
              userEdited: Value(edited),
            ),
          );
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'acc',
              name: 'HDFC Bank •••• 0715',
              accountType: 'bank',
              last4: const Value('0715'),
              bankName: const Value('HDFC Bank'),
            ),
          );
      await insert(
        id: 'receipt',
        type: 'credit',
        amount: 5900000,
        source: 'sms',
        date: receiptDate,
        hash: _hash('sms', _bajajCredit1, receiptDate),
      );
      await insert(
        id: 'edited-receipt',
        type: 'credit',
        amount: 5900000,
        source: 'sms',
        date: DateTime(2026, 9, 11, 18, 9),
        hash: _hash('sms', _bajajCredit2, DateTime(2026, 9, 11, 18, 9)),
        edited: true, // the user touched this one: it stays
      );
      await insert(
        id: 'sms-debit',
        type: 'debit',
        amount: 5241400,
        source: 'sms',
        date: DateTime(2026, 9, 5, 8, 15),
        accountId: 'acc',
      );
      await insert(
        id: 'email-debit',
        type: 'debit',
        amount: 5241400,
        source: 'email',
        date: DateTime(2026, 9, 5, 13, 56),
        accountId: 'acc',
      );

      // The next sync re-reads the receipts.
      final s = await ingest([
        item('sms', _bajajCredit1, receiptDate),
        item('sms', _bajajCredit2, DateTime(2026, 9, 11, 18, 9)),
      ]);

      final ids = {for (final t in await live()) t.id};
      expect(ids, isNot(contains('receipt')));
      expect(ids, contains('edited-receipt'));
      expect(ids.where((i) => i.endsWith('-debit')), hasLength(1));
      expect(s.removed, 1);
      expect(s.merged, 1);
    });
  });
}
