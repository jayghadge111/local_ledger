import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

/// One real-world message layout and what the parser must make of it.
/// Layouts come from public samples and common bank templates; every
/// number, name and ID is made up. `type == null` means "not a
/// transaction" and the parser must return nothing.
class Msg {
  const Msg(
    this.label,
    this.text,
    this.type, {
    this.amount,
    this.merchant,
    this.last4,
    this.currency = 'INR',
  });
  final String label;
  final String text;
  final String? type;
  final int? amount; // minor units
  final String? merchant; // substring, case-insensitive
  final String? last4;
  final String currency;
}

const corpus = <Msg>[
  // ---- UPI: debits ----
  Msg(
    'HDFC UPI sent',
    'Sent Rs.500.00\nFrom HDFC Bank A/c *1234\nTo SUNRISE CAFE\nOn 02/10/26\nRef 600000000001\nNot You? Call 18002586161/SMS BLOCK UPI to 7308080808',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE CAFE',
    last4: '1234',
  ),
  Msg(
    'HDFC UPI info line',
    'UPDATE: INR 1,250.00 debited from HDFC Bank XX1234 on 02-OCT-26. Info: UPI/DR/600000000002/SUNRISE STORE/HDFC',
    'debit',
    amount: 125000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'SBI UPI "debited by" (no Rs)',
    'Dear UPI user A/C X1234 debited by 150.0 on date 05Mar24 trf to SUNRISE FOODS Refno 600000000003. If not u? call 1800111109. -SBI',
    'debit',
    amount: 15000,
    merchant: 'SUNRISE FOODS',
    last4: '1234',
  ),
  Msg(
    'SBI "debited@SBI UPI"',
    'Rs950.0 debited@SBI UPI frm A/cX1234 on 27Sep22 RefNo 600000000004',
    'debit',
    amount: 95000,
  ),
  Msg(
    'SBI "debited by Rs" transfer to',
    'Your A/c X1234-debited by Rs2500.0 on 29Sep22 transfer to SUNRISE STORE',
    'debit',
    amount: 250000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'SBI "is debited for Rs"',
    'Your a/c no. XXXXXXXX1234 is debited for Rs.4500.00 on 14-10-22',
    'debit',
    amount: 450000,
  ),
  Msg(
    'SBI "debit by transfer of"',
    'Your A/C XXXXX123456 has a debit by transfer of Rs 1,200.00 on 11/03/22.',
    'debit',
    amount: 120000,
  ),
  Msg(
    'SBI internet banking transfer',
    'Thx for INB txn of Rs.3,000.00 frm A/c x1234 to ICICI Bank.',
    'debit',
    amount: 300000,
  ),
  Msg(
    'Axis UPI P2M',
    'Debit INR 3456.05 A/c no. XX7904 29-11-21 14:36:48 UPI/P2M/600000000005/sunrise/HDFC BANK Bal INR 123 SMS BLOCKUPI Cust ID to 8691000002, if not you-Axis Bank',
    'debit',
    amount: 345605,
    merchant: 'sunrise',
    last4: '7904',
  ),
  Msg(
    'Axis UPI P2A',
    'INR 500.00 debited A/c no. XX1234 02-10-26, 20:30:00 UPI/P2A/600000000006/ASHA SAMPLE SMS BLOCKUPI Cust ID to 919951860002 if not you - Axis Bank',
    'debit',
    amount: 50000,
    merchant: 'ASHA SAMPLE',
  ),
  Msg(
    'Kotak UPI sent',
    'Sent Rs.500.00 from Kotak Bank AC X1234 to sunrise@upi on 02-10-26.UPI Ref 600000000007. Not you, https://kotak.com/KBANKT/Fraud',
    'debit',
    amount: 50000,
    merchant: 'sunrise@upi',
    last4: '1234',
  ),
  Msg(
    'PNB UPI',
    'A/c XX1234 debited INR 500.00 Dt 02-10-26 21:09 trf to SUNRISE STORE Ref No 600000000008 -PNB',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'BoB UPI Dr/Cr',
    'Rs.500.00 Dr. from A/C XXXXXX1234 and Cr. to sunrise@upi. Ref:600000000009. AvlBal:Rs.8000.00(2026:10:02 21:09:22) -Bank of Baroda',
    'debit',
    amount: 50000,
    merchant: 'sunrise@upi',
    last4: '1234',
  ),
  Msg(
    'Union Bank Rs: colon',
    'A/c *1234 Debited for Rs:500.00 on 02-10-2026 by UPI-Ref 600000000010 Avl Bal Rs:8000.00 -Union Bank of India',
    'debit',
    amount: 50000,
    last4: '1234',
  ),
  Msg(
    'IDFC UPI',
    'Dear Customer, INR 500.00 debited from your A/c XX1234 on 02-10-2026 20:30:00 for UPI-600000000011-SUNRISE STORE-sunrise@ybl. Balance INR 9,000.00',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Yes Bank UPI',
    'Rs.500.00 debited from A/c XX1234 on 02-10-26 to VPA sunrise@ybl. UPI Ref 600000000012.',
    'debit',
    amount: 50000,
    merchant: 'sunrise@ybl',
    last4: '1234',
  ),
  Msg(
    'ICICI account UPI',
    'ICICI Bank Acct XX123 debited for Rs 500.00 on 02-Oct-26; SUNRISE STORE credited. UPI:600000000013. Call 18002662 for dispute.',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'Paytm Payments Bank sent',
    'Rs.500.00 sent to sunrise@bankid from BANKNAME a/c 91XX1234. UPI Ref:600000000014.',
    'debit',
    amount: 50000,
    merchant: 'sunrise@bankid',
  ),
  Msg(
    'Paytm paid via a/c',
    'Paid Rs.500.00 via a/c 91XX1234 to Sunrise Store on 07-09-2022.',
    'debit',
    amount: 50000,
    merchant: 'Sunrise Store',
  ),
  Msg(
    'Federal UPI',
    'Rs 500.00 debited from your A/c XX1234 on 02-10-2026 via UPI to SUNRISE STORE Ref 600000000015',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),

  // ---- UPI: credits ----
  Msg(
    'HDFC UPI credit',
    'Credit Alert!\nRs.500.00 credited to HDFC Bank A/c XX1234 on 02-10-26 from VPA asha@okaxis (UPI 600000000016)',
    'credit',
    amount: 50000,
    merchant: 'asha@okaxis',
    last4: '1234',
  ),
  Msg(
    'SBI credited by',
    'Your a/c no. XXXXXXXX1234 is credited by Rs.5000.00 on 18-01-22 by transfer from ASHA SAMPLE',
    'credit',
    amount: 500000,
  ),
  Msg(
    'SBI credit by transfer of',
    'Your A/C XXXXX123456 has a credit by Transfer of Rs 25,000.00 on 13/07/22',
    'credit',
    amount: 2500000,
  ),
  Msg(
    'SBI credited INR',
    'Your A/C XXXXX123456 Credited INR 1500.00 on 15/03/22',
    'credit',
    amount: 150000,
  ),
  Msg(
    'Kotak UPI received',
    'Received Rs.500.00 in your Kotak Bank AC X1234 from asha@okaxis on 02-10-26.UPI Ref:600000000017',
    'credit',
    amount: 50000,
    merchant: 'asha@okaxis',
    last4: '1234',
  ),
  Msg(
    'ICICI credited with',
    'Dear Customer, Acct XX123 is credited with Rs 500.00 on 02-Oct-26 by ASHA SAMPLE. UPI:600000000018',
    'credit',
    amount: 50000,
    merchant: 'ASHA SAMPLE',
  ),
  Msg(
    'Axis credit',
    'INR 500.00 credited to A/c no. XX1234 on 02-10-26 UPI/P2A/600000000019/ASHA SAMPLE',
    'credit',
    amount: 50000,
    merchant: 'ASHA SAMPLE',
  ),
  Msg(
    'Paytm PB received',
    'Rs.500.00 received from ASHA SAMPLE in your Paytm Payments Bank a/c 91XX01234.',
    'credit',
    amount: 50000,
    merchant: 'ASHA SAMPLE',
  ),

  // ---- Credit cards ----
  Msg(
    'ICICI card at',
    'INR 1,234.00 spent on ICICI Bank Card XX1234 on 20-Oct-22 at SUNRISE STORE. Avl Lmt: INR 1,19,786.79. To dispute,call 18002662/SMS BLOCK 1234 to 9215676766',
    'debit',
    amount: 123400,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'ICICI card foreign on MERCHANT',
    'USD 12.50 spent using ICICI Bank Card XX1234 on 08-Jan-26 on SUNRISE SOFT. Avl Limit: INR 1,19,786.79.',
    'debit',
    amount: 1250,
    merchant: 'SUNRISE SOFT',
    currency: 'USD',
    last4: '1234',
  ),
  Msg(
    'ICICI card refund',
    'Dear Customer, refund of INR 799.00 from Sunrise Store has been credited to your ICICI Bank Credit Card XX1234 on 29-SEP-22 and will be adjusted in the coming statement.',
    'credit',
    amount: 79900,
    last4: '1234',
  ),
  // The card issuer confirming a bill payment the user already made from a
  // bank account: a receipt for money that left as a debit, not income.
  Msg(
    'ICICI card payment received',
    'Dear Customer, payment of INR 15,000.00 towards your ICICI Bank Credit Card XX1234 has been received through Click to Pay on 26-SEP-22.',
    null,
  ),
  Msg(
    'ICICI card payment via UPI',
    'Dear Customer, Payment of INR 5,000.00 has been received towards your ICICI Bank Credit Card XX1234 on 29-AUG-22 through UPI.',
    null,
  ),
  Msg(
    'HDFC card Spent..At..On',
    'Spent Rs.500 On HDFC Bank CREDIT Card xx1234 At SUNRISE STORE On 2026-10-02:12:30:00 .Avl Lmt Rs.99000',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'HDFC card spent on Card x',
    'Rs.1,234.00 spent on HDFC Bank Card x1234 at AMAZON on 02-Oct-26. Avl bal Rs.5000',
    'debit',
    amount: 123400,
    merchant: 'AMAZON',
    last4: '1234',
  ),
  Msg(
    'HDFC card "Thank you for using"',
    'Thank you for using HDFC Bank Card ending 1234 for Rs. 500 at SUNRISE STORE on 02-Oct-26.',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'SBI card spent',
    'Rs.500.00 spent on your SBI Credit Card ending 1234 at SUNRISE STORE on 02/10/26. Trxn. not done by you? Report immediately at 1800 1234',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'SBI card "was used for"',
    'Your SBI Credit Card ending 1234 was used for Rs.500.00 at SUNRISE STORE on 02/10/26.',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Axis card Spent..IST..Avl',
    'Spent INR 500 Axis Bank Card no. XX1234 02-10-26 20:30:00 IST SUNRISE STORE Avl Lmt INR 100000',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Amex spent',
    "Alert: You've spent INR 500.00 on your AMEX card ** 12345 at SUNRISE STORE on 2 October 2026 at 08:30 PM IST.",
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'Kotak card',
    'Rs.500.00 spent on your Kotak Credit Card ending 1234 at SUNRISE STORE on 02-OCT-26.',
    'debit',
    amount: 50000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Forex prepaid card',
    'SAR 3.00 using ICICI Bank Forex Prepaid Card XX1233 transacted at POS on 02-Oct-26. Bal SAR 733.42. Temporary Credit Bal SAR 0.',
    'debit',
    amount: 300,
    currency: 'SAR',
    last4: '1233',
  ),
  Msg(
    'Card with Avl Lmt before amount',
    'Avl Lmt INR 90,000. Transaction of INR 1,500.00 on ICICI Bank Card XX1234 at SUNRISE STORE.',
    'debit',
    amount: 150000,
    merchant: 'SUNRISE STORE',
  ),

  // ---- Debit card, ATM, NEFT/IMPS, other ----
  Msg(
    'ATM withdrawal',
    'Rs.2000 withdrawn at ATM SUNRISE ROAD on 04-09-2022 using Debit Card ending 1234.',
    'debit',
    amount: 200000,
    last4: '1234',
  ),
  Msg(
    'Debit card POS',
    'Rs.800.00 spent on your HDFC Bank Debit Card ending 1234 at SUNRISE STORE on 02-10-26.',
    'debit',
    amount: 80000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'IMPS debit',
    'Rs.5,000.00 debited from A/c XX1234 on 02-10-26 by IMPS to ASHA SAMPLE Ref 600000000020',
    'debit',
    amount: 500000,
    last4: '1234',
  ),
  Msg(
    'NEFT credit',
    'INR 25,000.00 credited to your A/c XX1234 on 02-10-26 through NEFT from ACME CORP. Ref 600000000021',
    'credit',
    amount: 2500000,
    last4: '1234',
  ),
  Msg(
    'Salary credit',
    'Rs 85,000.00 credited to your A/c XX1234 on 01-10-26 by ACME CORP SALARY. Avl bal Rs 90,000',
    'credit',
    amount: 8500000,
    merchant: 'ACME CORP SALARY',
  ),
  Msg(
    'Reversal of failed UPI',
    'Rs 500.00 reversed to your A/c XX1234 on 03-10-26 for failed UPI txn Ref 600000000022',
    'credit',
    amount: 50000,
  ),
  Msg(
    'Service charge',
    'Your AC XXXXX123456 Debited INR 118.00 on 13/07/22 -Service Charge for forex trans.',
    'debit',
    amount: 11800,
  ),
  Msg(
    'Standing instruction / loan EMI',
    'Rs.12,500.00 debited from A/c XX1234 on 05-10-26 towards LOAN EMI via NACH',
    'debit',
    amount: 1250000,
    merchant: 'LOAN EMI',
  ),
  Msg(
    'Lakh grouping',
    'Rs.1,25,000.00 debited from A/c XX1234 on 05-10-26 to SUNRISE BUILDERS',
    'debit',
    amount: 12500000,
    merchant: 'SUNRISE BUILDERS',
  ),
  Msg(
    'Rs/- style',
    'Rs.500/- debited from A/c XX1234 on 05-10-26 to SUNRISE STORE',
    'debit',
    amount: 50000,
  ),

  // ---- Prepaid cards, debit cards, wallets ----
  Msg(
    'Prepaid card spend',
    'Rs.250.00 spent on your Axis Bank Prepaid Card ending 1234 at SUNRISE STORE on 02-10-26. Avl bal Rs.750.00',
    'debit',
    amount: 25000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Prepaid card load',
    'Rs.5,000.00 has been loaded on your HDFC Bank Prepaid Card ending 1234 on 02-10-26.',
    'credit',
    amount: 500000,
    last4: '1234',
  ),
  Msg(
    'Forex card load',
    'INR 50,000.00 loaded on your ICICI Bank Forex Prepaid Card XX1233 on 02-Oct-26.',
    'credit',
    amount: 5000000,
    last4: '1233',
  ),
  Msg(
    'Debit card online purchase',
    'Rs 799.00 debited from A/c XX1234 on 02-10-26 for online purchase at SUNRISE ONLINE using Debit Card.',
    'debit',
    amount: 79900,
    merchant: 'SUNRISE ONLINE',
    last4: '1234',
  ),
  Msg(
    'Debit card PoS',
    'Txn of Rs.1,150.00 done on HDFC Bank Debit Card XX1234 at SUNRISE STORE on 02-10-26.',
    'debit',
    amount: 115000,
    merchant: 'SUNRISE STORE',
    last4: '1234',
  ),
  Msg(
    'Wallet payment',
    'Rs.100.00 paid to SUNRISE STORE using Paytm Wallet. Bal Rs.400.00',
    'debit',
    amount: 10000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'UPI Lite',
    'Rs.50.00 paid from UPI Lite to SUNRISE STORE on 02-10-26.',
    'debit',
    amount: 5000,
    merchant: 'SUNRISE STORE',
  ),
  Msg(
    'FASTag',
    'Rs.150.00 debited from your FASTag wallet for toll at SUNRISE PLAZA on 02-10-26.',
    'debit',
    amount: 15000,
    merchant: 'SUNRISE PLAZA',
  ),

  // ---- NEFT / IMPS / RTGS / cheque / cash ----
  Msg(
    'NEFT debit',
    'Rs.25,000.00 debited from A/c XX1234 on 02-10-26 NEFT to ASHA SAMPLE UTR SBIN600000000023',
    'debit',
    amount: 2500000,
    merchant: 'ASHA SAMPLE',
    last4: '1234',
  ),
  Msg(
    'RTGS debit',
    'INR 2,50,000.00 debited from A/c XX1234 on 02-10-26 by RTGS to ACME TRADERS UTR HDFCR600000000024',
    'debit',
    amount: 25000000,
    merchant: 'ACME TRADERS',
    last4: '1234',
  ),
  Msg(
    'IMPS credit',
    'IMPS Ref no 600000000025 credited Rs.5,000.00 to A/c XX1234 on 02-10-26 from ASHA SAMPLE',
    'credit',
    amount: 500000,
    merchant: 'ASHA SAMPLE',
    last4: '1234',
  ),
  Msg(
    'Cheque deposit',
    'Cheque no. 123456 for Rs.10,000.00 deposited in A/c XX1234 on 02-10-26.',
    'credit',
    amount: 1000000,
    last4: '1234',
  ),
  Msg(
    'Cheque debit',
    'Cheque no. 123457 of Rs.5,000.00 debited from A/c XX1234 on 02-10-26.',
    'debit',
    amount: 500000,
    last4: '1234',
  ),
  Msg(
    'Cash deposit CDM',
    'Rs.10,000.00 deposited in A/c XX1234 on 02-10-26 via CDM.',
    'credit',
    amount: 1000000,
    last4: '1234',
  ),
  Msg(
    'Unnamed NEFT credit',
    'Rs.40,000.00 credited to A/c XX1234 on 02-10-26 by NEFT.',
    'credit',
    amount: 4000000,
  ),

  // ---- Mandates, bills, investments, charges ----
  Msg(
    'UPI Autopay mandate debit',
    'Rs.499.00 debited from A/c XX1234 on 02-10-26 towards SUNRISE OTT via UPI Autopay mandate Ref 600000000026',
    'debit',
    amount: 49900,
    merchant: 'SUNRISE OTT',
    last4: '1234',
  ),
  Msg(
    'Mobile recharge',
    'Rs.399.00 debited from A/c XX1234 on 02-10-26 for recharge via BillPay.',
    'debit',
    amount: 39900,
    merchant: 'recharge',
  ),
  Msg(
    'Bill payment',
    'Rs.1,450.00 debited from A/c XX1234 on 02-10-26 for bill payment through BBPS.',
    'debit',
    amount: 145000,
    merchant: 'bill',
  ),
  Msg(
    'Mutual fund SIP',
    'Rs.5,000.00 debited from A/c XX1234 on 02-10-26 for SIP via NACH.',
    'debit',
    amount: 500000,
    merchant: 'SIP',
  ),
  Msg(
    'Insurance premium',
    'Rs.12,000.00 debited from A/c XX1234 on 02-10-26 towards insurance premium.',
    'debit',
    amount: 1200000,
  ),
  Msg(
    'Card bill payment (bank side)',
    'Rs.15,000.00 debited from A/c XX1234 on 02-10-26 towards ICICI Bank Credit Card payment.',
    'debit',
    amount: 1500000,
    merchant: 'Credit Card',
  ),
  Msg(
    'Interest credit',
    'Interest of Rs.1,200.00 credited to your A/c XX1234 on 30-09-26.',
    'credit',
    amount: 120000,
    merchant: 'Interest',
    last4: '1234',
  ),
  Msg(
    'Dividend credit',
    'Dividend of Rs 340.00 credited to your A/c XX1234 on 02-10-26.',
    'credit',
    amount: 34000,
    merchant: 'Dividend',
  ),
  Msg(
    'Tax refund',
    'Income tax refund of Rs 12,000.00 credited to A/c XX1234 on 02-10-26.',
    'credit',
    amount: 1200000,
  ),
  Msg(
    'Cashback credit',
    'Cashback of Rs.50.00 credited to your Credit Card XX1234 on 02-10-26.',
    'credit',
    amount: 5000,
    last4: '1234',
  ),
  Msg(
    'Bank charges',
    'Rs.236.00 debited from A/c XX1234 on 02-10-26 towards annual charges incl. GST.',
    'debit',
    amount: 23600,
  ),
  Msg(
    'EMI conversion',
    'Your transaction of Rs.12,000.00 at SUNRISE STORE on ICICI Bank Credit Card XX1234 has been converted to EMI.',
    null,
  ),

  // ---- Must NOT be transactions ----
  Msg(
    'OTP with amount',
    '123456 is your OTP for txn of Rs 500.00 at SUNRISE STORE. Do not share with anyone.',
    null,
  ),
  Msg(
    'OTP for card payment',
    'OTP is 482913 for payment of INR 1,500.00 on your ICICI Bank Card XX1234 at SUNRISE STORE. Valid for 10 min.',
    null,
  ),
  Msg(
    'Balance only',
    'Avl bal in A/c XX1234 is Rs 5,000.00 as on 02-10-26',
    null,
  ),
  Msg(
    'Statement due',
    'Dear Customer, statement for ICICI Bank Credit Card XX1234 has been sent. Total amount of Rs 12,000.00 or Minimum amount of Rs 600 is due by 30-AUG-22.',
    null,
  ),
  Msg(
    'Upcoming debit',
    'Rs 5000 will be debited from your A/c on 05-Oct for your EMI',
    null,
  ),
  Msg(
    'Mandate set up',
    'Your e-mandate of Rs.999.00 for SUNRISE OTT has been registered successfully.',
    null,
  ),
  Msg(
    'Failed UPI',
    'Your UPI txn of Rs 500.00 to SUNRISE STORE failed due to insufficient funds.',
    null,
  ),
  Msg(
    'Promo cashback',
    'Get Rs 500 cashback on your first transaction. Apply now! T&C apply.',
    null,
  ),
  Msg(
    'Pre-approved loan',
    'Pre-approved personal loan of Rs 5,00,000 for you. Click here to apply now.',
    null,
  ),
  Msg(
    'Login alert',
    'Your HDFC Bank NetBanking was accessed on 02-10-26 at 20:30. If not you, call 18002586161.',
    null,
  ),
];

void main() {
  for (final m in corpus) {
    test(m.label, () {
      final p = parseBankSms(m.text);
      if (m.type == null) {
        expect(p, isNull, reason: 'should not be a transaction: ${m.text}');
        return;
      }
      expect(p, isNotNull, reason: 'failed to parse: ${m.text}');
      expect(p!.type, m.type, reason: 'type for: ${m.text}');
      expect(p.amountMinor, m.amount, reason: 'amount for: ${m.text}');
      expect(p.currency, m.currency, reason: 'currency for: ${m.text}');
      if (m.merchant != null) {
        expect(
          p.merchant.toLowerCase(),
          contains(m.merchant!.toLowerCase()),
          reason: 'merchant for: ${m.text}',
        );
      }
      if (m.last4 != null) {
        expect(p.last4, m.last4, reason: 'last4 for: ${m.text}');
      }
    });
  }

  group('payee-less labels land in a sensible category', () {
    const expected = {
      'Mobile recharge': 'cat_bills',
      'Bill payment': 'cat_bills',
      'Insurance premium': 'cat_bills',
      'Loan EMI': 'cat_emi',
      'Home Loan EMI': 'cat_emi',
      'Mutual fund SIP': 'cat_investment',
      'FASTag toll': 'cat_transport',
    };
    expected.forEach((label, category) {
      test(label, () => expect(defaultCategoryFor(label), category));
    });
    test('interest and dividend credits are income', () {
      expect(defaultCategoryFor('Interest', isCredit: true), 'cat_income');
      expect(defaultCategoryFor('Dividend', isCredit: true), 'cat_income');
    });
  });
}
