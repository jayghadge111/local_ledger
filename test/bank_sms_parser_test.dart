import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

void main() {
  group('amount + type', () {
    test('Rs.20.0 and INR 20.0 formats', () {
      expect(parseBankSms('Rs.20.0 debited from A/c XX1234')!.amountMinor, 2000);
      expect(parseBankSms('INR 20.0 debited from A/c XX1234')!.amountMinor, 2000);
    });

    test('rupee symbol and comma grouping', () {
      final p = parseBankSms('₹1,234.56 spent on card XX1234 at AMAZON.')!;
      expect(p.amountMinor, 123456);
      expect(p.type, 'debit');
    });

    test('"Hours 5" is not mistaken for Rs 5', () {
      expect(parseBankSms('Working Hours 5 debited'), isNull);
    });

    test('balance amounts are skipped', () {
      expect(parseBankSms('Avl bal in A/c XX1234 is Rs 5,000.00'), isNull);
      final p = parseBankSms('Rs 100 debited from A/c XX1234. Avl bal Rs 5,000.00')!;
      expect(p.amountMinor, 10000);
    });

    test('earliest strong keyword wins when both appear', () {
      final p = parseBankSms('ICICI Bank Acct XX123 debited for Rs 500.00; MERCHANT credited')!;
      expect(p.type, 'debit');
    });

    test('"Payment of Rs X received" is a credit', () {
      expect(parseBankSms('Payment of Rs 500 received on your card XX1234')!.type, 'credit');
    });
  });

  group('currency', () {
    test('foreign prefix currency is international and keeps its code', () {
      final p = parseBankSms(
        'USD 10.00 spent on ICICI Bank Card XX1234 on 02-Oct-26 at AMAZON.COM. Avl Limit: INR 50,000.00',
      )!;
      expect(p.currency, 'USD');
      expect(p.amountMinor, 1000);
      expect(p.isInternational, isTrue);
      expect(p.merchant, 'AMAZON.COM');
      expect(p.last4, '1234');
    });

    test('suffix currency form', () {
      final p = parseBankSms('You have spent 45.50 SAR at CARREFOUR using card ending 4321')!;
      expect(p.currency, 'SAR');
      expect(p.amountMinor, 4550);
      expect(p.last4, '4321');
    });

    test('INR stays domestic', () {
      expect(parseBankSms('Rs 100 debited from A/c XX1234')!.isInternational, isFalse);
    });
  });

  group('merchant + account', () {
    test('HDFC UPI "To" line', () {
      final p = parseBankSms(
        'Sent Rs.20.00\nFrom HDFC Bank A/c *1234\nTo SWIGGY\nOn 02/10/26\nRef 123456789012',
      )!;
      expect(p.type, 'debit');
      expect(p.merchant, 'SWIGGY');
      expect(p.last4, '1234');
    });

    test('credit skips "to your A/c" and finds the sender', () {
      final p = parseBankSms(
        'Rs 85,000.00 credited to your A/c XX1234 on 01-Oct-26 by ACME CORP SALARY. Avl bal Rs 90,000',
      )!;
      expect(p.type, 'credit');
      expect(p.merchant, 'ACME CORP SALARY');
    });

    test('credit "from" sender', () {
      final p = parseBankSms('Rs 500 credited to A/c XX1234 from RAHUL SHARMA on 02-10-26.')!;
      expect(p.merchant, 'RAHUL SHARMA');
    });
  });

  group('not a transaction', () {
    test('OTP quoting an amount', () {
      expect(parseBankSms('123456 is your OTP for txn of Rs 500.00 at AMAZON. Do not share.'), isNull);
    });

    test('upcoming debit reminder', () {
      expect(parseBankSms('Rs 5000 will be debited on 05-Oct for your EMI'), isNull);
    });

    test('failed payment', () {
      expect(parseBankSms('Your txn of Rs 500 failed due to insufficient funds'), isNull);
    });

    test('reversal of a failed payment is still a credit', () {
      final p = parseBankSms('Rs 500.00 reversed to your A/c XX1234 for failed UPI txn')!;
      expect(p.type, 'credit');
    });
  });

  group('review queue', () {
    test('transaction-like but unclassifiable messages are queued', () {
      expect(looksLikeUnparsedTransaction('Alert: Rs 750.00 at SOME SHOP, card ending 4321'), isTrue);
    });

    test('OTPs and parsed messages are not', () {
      expect(looksLikeUnparsedTransaction('Your OTP is 123 for Rs 500'), isFalse);
      expect(looksLikeUnparsedTransaction('Rs 100 debited from A/c XX1234'), isFalse);
    });
  });

  group('sender', () {
    test('your real sender IDs', () {
      for (final s in [
        'JM-HDFCBK-S', 'VM-HDFCBK-S', 'JM-ICICIT-T', 'AD-ICICIT-S', 'JM-SCBANK-S',
        'CP-EQUTAS-S', 'AD-SBMIND-S', 'JJSBNK', 'VM-JPCBNK-S',
      ]) {
        expect(looksLikeBankSender(s), isTrue, reason: s);
      }
      expect(looksLikeBankSender('+919876543210'), isFalse);
      expect(looksLikeBankSender('AD-AMAZON-P'), isFalse);
    });

    test('bankCodeOf', () {
      expect(bankCodeOf('VM-HDFCBK-S'), 'HDFCBK');
      expect(bankCodeOf('hdfcbk'), 'HDFCBK');
    });
  });
}
