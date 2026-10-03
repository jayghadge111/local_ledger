import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/email/html_text.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

void main() {
  group('htmlToText', () {
    test('strips tags, scripts, styles and decodes entities', () {
      const html =
          '<html><head><style>p{color:red}</style></head><body>'
          '<p>Dear Customer,</p><p>Rs.&nbsp;1,250.00 has been <b>debited</b> from your account &amp; &#8377;5 fee.</p>'
          '<script>alert(1)</script></body></html>';
      final text = htmlToText(html);
      expect(text, contains('Dear Customer,'));
      expect(
        text,
        contains('Rs. 1,250.00 has been debited from your account & ₹5 fee.'),
      );
      expect(text, isNot(contains('color:red')));
      expect(text, isNot(contains('alert')));
    });

    test('table cells stay separated', () {
      final text = htmlToText(
        '<table><tr><td>Amount</td><td>Rs. 500.00</td></tr></table>',
      );
      expect(text, 'Amount Rs. 500.00');
    });
  });

  group('email bodies with boilerplate', () {
    const email =
        'Dear Customer, Greetings from the bank. '
        'Rs. 1,250.00 has been debited from account 1234 towards SWIGGY on 02-10-26. '
        'Your UPI reference number is 123456789012. '
        'If you did not authorise this transaction, click here to report it. '
        'Never share your OTP, PIN or password with anyone. Download our app. Terms apply.';

    test('the raw email is rejected because of its footer', () {
      expect(parseBankSms(email), isNull);
    });

    test('focusing on the transaction sentence parses it', () {
      final p = parseBankSms(focusTransactionText(email))!;
      expect(p.type, 'debit');
      expect(p.amountMinor, 125000);
      expect(p.merchant, 'SWIGGY');
    });

    test('credit alerts too', () {
      final p = parseBankSms(
        focusTransactionText(
          'Hello, Rs. 85,000.00 has been credited to your account XX1234 by ACME CORP. Do not share your OTP.',
        ),
      )!;
      expect(p.type, 'credit');
      expect(p.amountMinor, 8500000);
    });

    test('marketing email with no transaction stays unparsed', () {
      expect(
        parseBankSms(
          focusTransactionText(
            'Get a pre-approved loan of Rs. 5,00,000 today. Apply now!',
          ),
        ),
        isNull,
      );
    });
  });

  group('merchant false positives from email text', () {
    test('"at all times" is not a merchant', () {
      final p = parseBankSms(
        'Rs. 52,414.00 has been debited from account 0715 on 05-02-26. We are available at all times to assist you.',
      )!;
      expect(p.merchant, 'Unknown merchant');
    });

    test('the sending bank is not the payee', () {
      final p = parseBankSms(
        'Rs 224.00 credited to your A/c XX1234 from ICICI Bank on 12-01-26.',
      )!;
      expect(p.merchant, 'Credit');
    });

    test('a loan debit with no payee becomes a loan EMI', () {
      final p = parseBankSms(
        'Rs. 52,414.00 has been debited from account 0715 for your Home Loan EMI. Available at all times.',
      )!;
      expect(p.merchant, 'Home Loan EMI');
      final plain = parseBankSms(
        'Rs. 9,000.00 debited from account 0715 via NACH mandate. Reach us at your convenience.',
      )!;
      expect(plain.merchant, 'Loan EMI');
    });

    test('a named payee still wins over the loan fallback', () {
      final p = parseBankSms(
        'Rs. 1,250.00 debited from account 0715 towards BAJAJ FINANCE EMI on 05-02-26.',
      )!;
      expect(p.merchant, 'BAJAJ FINANCE EMI');
    });

    test('real merchants are unaffected', () {
      expect(
        parseBankSms('Rs 500 spent on card XX1234 at AMAZON on 01-10-26.')!
            .merchant,
        'AMAZON',
      );
      expect(
        parseBankSms(
          'Sent Rs.20.00 From HDFC Bank A/c *1234 To SWIGGY On 02/10/26',
        )!.merchant,
        'SWIGGY',
      );
    });
  });

  group('HDFC UPI debit email', () {
    const email =
        'Dear Customer, Rs.1800.00 has been debited from account 0715 to VPA '
        'shop.123456789012@hdfcbank SUNRISE WELLNESS AND SPA on 05-04-26. Your UPI transaction '
        'reference number is 600000000000. If you did not authorize this transaction, please '
        'report it immediately by calling 18002586161 Or SMS BLOCK UPI to 7308080808. Warm Regards, HDFC Bank';

    test('reads the merchant name that follows the UPI address', () {
      final p = parseBankSms(focusTransactionText(email))!;
      expect(p.type, 'debit');
      expect(p.amountMinor, 180000);
      expect(p.merchant, 'SUNRISE WELLNESS AND SPA');
      expect(p.last4, '0715');
    });

    test('names starting with "The" are kept', () {
      final p = parseBankSms(
        'Rs.500.00 has been debited from account 0715 to VPA x.1@hdfcbank THE COFFEE HOUSE on 05-04-26.',
      )!;
      expect(p.merchant, 'THE COFFEE HOUSE');
    });

    test('a UPI debit with only the UPI address still gets a payee', () {
      final p = parseBankSms(
        'Rs.200.00 has been debited from account 0715 to VPA rahul@okhdfcbank on 05-04-26.',
      )!;
      expect(p.merchant, contains('rahul@okhdfcbank'));
    });
  });

  group('HDFC UPI debit to a Google Pay business ID', () {
    const email =
        'Dear Customer, Rs.276.00 has been debited from account 0715 to VPA '
        'gpay-11111111111@okbizaxis SUNRISE MILK DAIRY on 07-04-26. Your UPI transaction '
        'reference number is 600000000001. If you did not authorize this transaction, please '
        'report it immediately by calling 18002586161 Or SMS BLOCK UPI to 7308080808. Warm Regards, HDFC Bank';

    test('reads the dairy name, not the gpay id', () {
      final p = parseBankSms(focusTransactionText(email))!;
      expect(p.amountMinor, 27600);
      expect(p.merchant, 'SUNRISE MILK DAIRY');
    });

    test('a dairy lands in Groceries', () {
      expect(defaultCategoryFor('Sunrise Milk Dairy'), 'cat_groceries');
    });
  });

  group('field-by-field UPI confirmation email', () {
    const email =
        'Dear Valued Customer,\n\n'
        'Your UPI payment has been successfully credited to the beneficiary bank account.\n\n'
        'UPI Ref. No. : 600000000002\nFrom VPA : 11111111@yescred\nPayer Name: MR TEST USER\n'
        'To VPA : 9000000000@ibl\nPayee Name: SAMPLE PAYEE NAME\nCurrency: INR\nAmount: 18000.00\n'
        'Remarks: Paid via CRED\nTransaction Date: 01/10/2026 23:56:31\nTransaction Status: COMPLETED\n'
        'Transaction Type: DR\nReason for Failure : NA\n\n'
        'For additional assistance kindly email us through our online banking channel.';

    test('is a debit for the payer, paid to the payee', () {
      final p = parseBankSms(focusTransactionText(email))!;
      expect(p.type, 'debit'); // despite "credited to the beneficiary"
      expect(p.amountMinor, 1800000);
      expect(p.currency, 'INR');
      expect(p.merchant, 'SAMPLE PAYEE NAME');
    });

    test('works on the raw email too', () {
      expect(parseBankSms(email)!.merchant, 'SAMPLE PAYEE NAME');
    });

    test('an incoming payment names the payer', () {
      final p = parseBankSms(
        'Payer Name: ASHA SAMPLE Payee Name: MR TEST USER Currency: INR Amount: 2,500.00 '
        'Transaction Status: COMPLETED Transaction Type: CR',
      )!;
      expect(p.type, 'credit');
      expect(p.amountMinor, 250000);
      expect(p.merchant, 'ASHA SAMPLE');
    });

    test('failed and pending records are not transactions', () {
      for (final status in ['FAILED', 'PENDING', 'DECLINED']) {
        final failed = email.replaceFirst('COMPLETED', status);
        expect(parseBankSms(failed), isNull, reason: status);
        expect(looksLikeUnparsedTransaction(failed), isFalse, reason: status);
      }
    });

    test('foreign currency is kept', () {
      final p = parseBankSms(
        'Payee Name: SAMPLE SHOP Currency: USD Amount: 12.50 Transaction Status: COMPLETED Transaction Type: DR',
      )!;
      expect(p.currency, 'USD');
      expect(p.isInternational, isTrue);
    });
  });
}
