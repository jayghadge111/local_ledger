import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/obligations/obligation_parser.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

/// Reads [sms] and checks only the fields given.
void check(
  String sms, {
  required ObligationKind kind,
  int? amount,
  bool? isMax,
  int? minDue,
  DateTime? due,
  String? biller,
  String? umrn,
  String? account,
  String? ref,
  String? refType,
  String? frequency,
  String? reason,
  String? sender,
}) {
  final o = parseObligation(sms, sender: sender);
  expect(o, isNotNull, reason: 'not recognised: $sms');
  expect(o!.kind, kind, reason: sms);
  if (amount != null) expect(o.amountMinor, amount, reason: 'amount: $sms');
  if (isMax != null) expect(o.isMaxAmount, isMax, reason: 'isMax: $sms');
  if (minDue != null) expect(o.minDueMinor, minDue, reason: 'min: $sms');
  if (due != null) expect(o.dueDate, due, reason: 'due: $sms');
  if (biller != null) expect(o.biller, biller, reason: 'biller: $sms');
  if (umrn != null) expect(o.umrn, umrn, reason: 'umrn: $sms');
  if (account != null) expect(o.accountLast4, account, reason: 'acct: $sms');
  if (ref != null) expect(o.refLast4, ref, reason: 'ref: $sms');
  if (refType != null) expect(o.refType, refType, reason: 'refType: $sms');
  if (frequency != null) expect(o.frequency, frequency, reason: sms);
  if (reason != null) expect(o.reason, reason, reason: sms);
}

void main() {
  group('mandate / e-NACH / UPI AutoPay registration', () {
    test('banks', () {
      check(
        'Dear Customer, e-Mandate with UMRN HDFC7029104820194812 for Rs 5,000.00 has been successfully registered on your A/C XX4921 towards NIPPON INDIA MUTUAL FUND. Frequency: Monthly. -HDFC Bank',
        kind: ObligationKind.mandate,
        umrn: 'HDFC7029104820194812',
        account: '4921',
        amount: 500000,
        biller: 'NIPPON INDIA MUTUAL FUND',
        frequency: 'Monthly',
      );
      check(
        'NACH mandate with UMRN ICIC0002918401928410 registered on your ICICI Bank A/c ending 1042 for BAJAJ FINANCE LTD for max amt Rs 25,000.00 on 04-OCT-26.',
        kind: ObligationKind.mandate,
        umrn: 'ICIC0002918401928410',
        account: '1042',
        amount: 2500000,
        isMax: true,
        biller: 'BAJAJ FINANCE LTD',
      );
      check(
        'e-NACH Mandate UMRN SBIN0000004928174921 registered successfully in A/C XXXXX12345 in favour of TATA AIA LIFE INSURANCE CO for amount up to Rs 12,000.00. -SBI',
        kind: ObligationKind.mandate,
        umrn: 'SBIN0000004928174921',
        account: '2345',
        amount: 1200000,
        isMax: true,
        biller: 'TATA AIA LIFE INSURANCE CO',
      );
      check(
        'Mandate registered successfully. UMRN: BARB0001928374659281. Biller: HDFC LIFE. A/c: ...4321. Max Limit: INR 8,500.00. Periodicity: As and when presented. -Bank of Baroda',
        kind: ObligationKind.mandate,
        umrn: 'BARB0001928374659281',
        biller: 'HDFC LIFE',
        account: '4321',
        amount: 850000,
        isMax: true,
      );
      check(
        'Dear Customer, Standing Instruction/NACH mandate registered in your A/c ...9876 with UMRN PUNB9821039482910482 for Rs. 3,500.00 favouring ZERODHA BROKING. -PNB',
        kind: ObligationKind.mandate,
        umrn: 'PUNB9821039482910482',
        account: '9876',
        amount: 350000,
        biller: 'ZERODHA BROKING',
      );
      check(
        'Mandate setup successful on A/c ending 8812. UMRN: UTIB0001928471928401 for MOTILAL OSWAL MF. Max Debit Amount: Rs 10000.00. Validity: 01-OCT-2026 to 31-DEC-2035. -Axis Bank',
        kind: ObligationKind.mandate,
        umrn: 'UTIB0001928471928401',
        account: '8812',
        biller: 'MOTILAL OSWAL MF',
        amount: 1000000,
        isMax: true,
      );
      check(
        'e-Mandate created: UMRN KKBK0001928472910482 on Kotak Bank A/c ending 6652 for ADITYA BIRLA FINANCE for max amount Rs 18,250.00. -Kotak Bank',
        kind: ObligationKind.mandate,
        umrn: 'KKBK0001928472910482',
        account: '6652',
        biller: 'ADITYA BIRLA FINANCE',
        amount: 1825000,
        isMax: true,
      );
      check(
        'Federal Bank: Mandate registered under UMRN FDRL0000291847192830 for your A/c ending 3341 in favour of KOTAK MAHINDRA LIFE for Rs 4,500.00.',
        kind: ObligationKind.mandate,
        umrn: 'FDRL0000291847192830',
        account: '3341',
        biller: 'KOTAK MAHINDRA LIFE',
        amount: 450000,
      );
      check(
        'Mandate setup approved. UMRN IDFB0009218471928401 on IDFC FIRST Bank A/c ending 1928. Beneficiary: HDFC ERGO GENERAL INSURANCE. Max Amount: INR 6,200.00.',
        kind: ObligationKind.mandate,
        umrn: 'IDFB0009218471928401',
        account: '1928',
        biller: 'HDFC ERGO GENERAL INSURANCE',
        amount: 620000,
        isMax: true,
      );
      check(
        'Canara Bank Alert: NACH Mandate UMRN CNRB0000192847192841 registered for A/C ...5512 towards LIC OF INDIA. Max limit: Rs. 7,850.00.',
        kind: ObligationKind.mandate,
        umrn: 'CNRB0000192847192841',
        account: '5512',
        biller: 'LIC OF INDIA',
        amount: 785000,
        isMax: true,
      );
      check(
        'Dear Customer, eNACH mandate with UMRN AUBL0000192837461928 registered on your AU Small Finance Bank A/c XX8192 towards BAJAJ HOUSING FINANCE. Max Limit: Rs 35,000.00.',
        kind: ObligationKind.mandate,
        umrn: 'AUBL0000192837461928',
        account: '8192',
        biller: 'BAJAJ HOUSING FINANCE',
        amount: 3500000,
        isMax: true,
      );
      check(
        'Dear Customer, ECS/NACH Mandate registered for A/c ...7812 for MAHINDRA FINANCE with UMRN BUPB0001928471928491. Max Amount Rs 8,500.00.',
        kind: ObligationKind.mandate,
        umrn: 'BUPB0001928471928491',
        account: '7812',
        biller: 'MAHINDRA FINANCE',
        amount: 850000,
        isMax: true,
      );
    });

    test('UPI AutoPay apps', () {
      check(
        'UPI AutoPay created on A/C XX9012 for NETFLIX ENTERTAINMENT with Max Amount Rs 649.00. Mandate ID: 4892019481028391. Manage via your UPI app -BHIM/NPCI.',
        kind: ObligationKind.mandate,
        umrn: '4892019481028391',
        account: '9012',
        biller: 'NETFLIX ENTERTAINMENT',
        amount: 64900,
        isMax: true,
      );
      check(
        'AutoPay setup successful for Spotify India on PhonePe. Rs 119.00 will be debited automatically every month from Bank A/c XX4021.',
        kind: ObligationKind.mandate,
        biller: 'Spotify India',
        amount: 11900,
        account: '4021',
        frequency: 'Monthly',
      );
      check(
        "You've set up an automatic payment of up to Rs 2,500.00 to Zerodha on Google Pay. Next debit date: 05-NOV-26.",
        kind: ObligationKind.mandate,
        biller: 'Zerodha',
        amount: 250000,
        isMax: true,
        due: d(2026, 11, 5),
      );
      check(
        'AutoPay has been activated for JioFiber on Paytm. Maximum debit limit: Rs 1,179.00 from A/c ending 3301.',
        kind: ObligationKind.mandate,
        biller: 'JioFiber',
        amount: 117900,
        isMax: true,
        account: '3301',
      );
      check(
        'CRED AutoPay initiated for credit card bill on HDFC Bank A/c ending 4921. UMRN: CRED0001928471928401. Max Limit: Rs 1,00,000.00.',
        kind: ObligationKind.mandate,
        umrn: 'CRED0001928471928401',
        account: '4921',
        amount: 10000000,
        isMax: true,
      );
    });

    test('registration email (subject + table text)', () {
      check(
        'Successful Registration of e-Mandate - UMRN UTIB0001928471928401. Your Mandate has been successfully registered on your Axis Bank Account XX8812. Mandate Reference (UMRN): UTIB0001928471928401 Beneficiary: MOTILAL OSWAL MUTUAL FUND Maximum Cap Amount: INR 10,000.00 Frequency: Monthly',
        kind: ObligationKind.mandate,
        umrn: 'UTIB0001928471928401',
        account: '8812',
        biller: 'MOTILAL OSWAL MUTUAL FUND',
        amount: 1000000,
        isMax: true,
        frequency: 'Monthly',
      );
    });
  });

  group('pre-debit notices (24–48 hours ahead)', () {
    test('banks', () {
      check(
        'Reminder: Your A/c ending 4921 will be debited for Rs 5,000.00 on 07-OCT-26 towards UMRN HDFC7029104820194812 (NIPPON INDIA MUTUAL FUND). Ensure sufficient balance. -HDFC Bank',
        kind: ObligationKind.preDebit,
        amount: 500000,
        due: d(2026, 10, 7),
        account: '4921',
        umrn: 'HDFC7029104820194812',
        biller: 'NIPPON INDIA MUTUAL FUND',
      );
      check(
        'Reminder: Auto debit of Rs 1,999.00 will be processed on 08-OCT-26 from your A/C XXXXX12345 towards TATA AIA LIFE INSURANCE under UMRN SBIN0000004928174921. -SBI',
        kind: ObligationKind.preDebit,
        amount: 199900,
        due: d(2026, 10, 8),
        account: '2345',
        umrn: 'SBIN0000004928174921',
        biller: 'TATA AIA LIFE INSURANCE',
      );
      check(
        'Axis Bank Alert: Auto-debit of Rs 2,499.00 towards STAR HEALTH INSURANCE is scheduled from A/c ending 8812 on 08-OCT-26. UMRN: UTIB0001928471928401.',
        kind: ObligationKind.preDebit,
        amount: 249900,
        due: d(2026, 10, 8),
        account: '8812',
        biller: 'STAR HEALTH INSURANCE',
      );
      check(
        'Upcoming Debit Alert: Rs 8,500.00 will be auto-debited from A/c ...4321 on 09-OCT-26 for HDFC LIFE. Maintain sufficient balance. -Bank of Baroda',
        kind: ObligationKind.preDebit,
        amount: 850000,
        due: d(2026, 10, 9),
        account: '4321',
        biller: 'HDFC LIFE',
      );
      check(
        'Kotak Bank: Rs 18,250.00 is scheduled for auto debit on 07-OCT-26 from A/c ending 6652 for ADITYA BIRLA FINANCE. UMRN: KKBK0001928472910482.',
        kind: ObligationKind.preDebit,
        amount: 1825000,
        due: d(2026, 10, 7),
        account: '6652',
        biller: 'ADITYA BIRLA FINANCE',
      );
      check(
        'IndusInd Alert: Auto debit of Rs 4,120.00 towards CHOLAMANDALAM FINANCE from A/c XX9921 scheduled for 08-Oct-26. UMRN: INDB0001928471928401.',
        kind: ObligationKind.preDebit,
        amount: 412000,
        due: d(2026, 10, 8),
        account: '9921',
        biller: 'CHOLAMANDALAM FINANCE',
      );
      check(
        'Union Bank of India: Your A/c ending ...7712 will be debited for Rs. 2,150.00 on 10-OCT-26 towards LIC ECS Mandate. -Union Bank',
        kind: ObligationKind.preDebit,
        amount: 215000,
        due: d(2026, 10, 10),
        account: '7712',
        biller: 'LIC',
      );
      check(
        'Dear Customer, scheduled debit of INR 35,000.00 towards BAJAJ HOUSING FINANCE on your AU Bank A/c XX8192 will occur on 06-OCT-26. -AU Small Finance Bank',
        kind: ObligationKind.preDebit,
        amount: 3500000,
        due: d(2026, 10, 6),
        account: '8192',
        biller: 'BAJAJ HOUSING FINANCE',
      );
      check(
        'UPI AutoPay reminder: Rs 499.00 will be auto-debited from your A/c XX3021 on 07-OCT-26 towards DISNEY+ HOTSTAR. Manage in your UPI app.',
        kind: ObligationKind.preDebit,
        amount: 49900,
        due: d(2026, 10, 7),
        account: '3021',
        biller: 'DISNEY+ HOTSTAR',
      );
    });

    test('a loan EMI auto-debit is filed as an EMI', () {
      check(
        'Dear Customer, your ICICI Bank Account ending 1042 is scheduled for auto debit of Rs 14,520.00 on 06-Oct-26 towards BAJAJ FINANCE LTD EMI.',
        kind: ObligationKind.emiDue,
        amount: 1452000,
        due: d(2026, 10, 6),
        account: '1042',
        biller: 'BAJAJ FINANCE LTD',
      );
    });

    test('email (subject + list text)', () {
      check(
        'Scheduled Auto-Debit Advice for your ICICI Bank Account ending 1042. Your ICICI Bank Account ending 1042 is scheduled for an automated debit under e-Mandate regulations: Beneficiary: BAJAJ FINANCE LTD UMRN: ICIC0002918401928410 Scheduled Date: 06-Oct-2026 Amount: INR 14,520.00',
        kind: ObligationKind.preDebit,
        amount: 1452000,
        due: d(2026, 10, 6),
        account: '1042',
        umrn: 'ICIC0002918401928410',
        biller: 'BAJAJ FINANCE LTD',
      );
    });
  });

  group('loan EMI and instalment reminders', () {
    test('lenders', () {
      check(
        'Dear Customer, your EMI of Rs 32,450.00 for Loan A/C ending 9012 is due on 05-OCT-26. Please maintain sufficient balance in your linked account to avoid bounce charges. -HDFC Bank',
        kind: ObligationKind.emiDue,
        amount: 3245000,
        due: d(2026, 10, 5),
        ref: '9012',
        refType: 'loan',
        biller: 'HDFC Bank',
      );
      check(
        'Dear Jayesh, EMI of Rs 2,850.00 for your loan 48BJA8291 is due on 05-Oct-2026. Keep your bank account funded for ECS clearing. -Bajaj Finserv',
        kind: ObligationKind.emiDue,
        amount: 285000,
        due: d(2026, 10, 5),
        ref: '48BJA8291',
        biller: 'Bajaj Finserv',
      );
      check(
        'Reminder: EMI of Rs 11,490.00 towards Tata Capital Loan ending 7731 is due on 07-OCT-26. Kindly maintain balance in your registered bank account.',
        kind: ObligationKind.emiDue,
        amount: 1149000,
        due: d(2026, 10, 7),
        ref: '7731',
        biller: 'Tata Capital',
      );
      check(
        'Dear Customer, your Two Wheeler loan EMI Rs. 3,120.00 is due on 06-OCT-26. Please ensure sufficient funds in A/c ...3312. -L&T Finance',
        kind: ObligationKind.emiDue,
        amount: 312000,
        due: d(2026, 10, 6),
        account: '3312',
        biller: 'L&T Finance',
      );
      check(
        'Your DMI Finance loan EMI Rs 1,899.00 is scheduled for NACH debit on 05-Oct-26. Keep your bank account funded to avoid NACH bounce fee.',
        kind: ObligationKind.emiDue,
        amount: 189900,
        due: d(2026, 10, 5),
        biller: 'DMI Finance',
      );
      check(
        'Dear Customer, interest of Rs 1,450.00 on Gold Loan GL-99210 is due on 10-OCT-26. Pay online to avoid overdue interest. -Muthoot Finance',
        kind: ObligationKind.emiDue,
        amount: 145000,
        due: d(2026, 10, 10),
        ref: 'GL-99210',
        biller: 'Muthoot Finance',
      );
    });

    test('the lender is the sending bank when the text does not say', () {
      check(
        'Dear Customer, your EMI of Rs 32,450.00 for Loan A/C ending 9012 is due on 05-OCT-26.',
        kind: ObligationKind.emiDue,
        biller: 'HDFC Bank',
        sender: 'VM-HDFCBK-S',
      );
    });

    test('email', () {
      check(
        'Reminder: Upcoming EMI Due for Loan Account 7731. Your Monthly Installment of INR 11,490.00 towards Loan Account 7731 is due for payment on 07-Oct-2026 via NACH.',
        kind: ObligationKind.emiDue,
        amount: 1149000,
        due: d(2026, 10, 7),
        ref: '7731',
      );
    });
  });

  group('credit card bills', () {
    test('statements', () {
      check(
        'Statement for HDFC Bank Credit Card ending 8210: Total Amt Due: Rs 44,210.50, Min Amt Due: Rs 2,210.00, Due Date: 22-OCT-26. Pay easily via NetBanking or UPI.',
        kind: ObligationKind.cardDue,
        amount: 4421050,
        minDue: 221000,
        due: d(2026, 10, 22),
        ref: '8210',
        refType: 'card',
        biller: 'HDFC Bank Credit Card',
      );
      check(
        'Total Due on your SBI Card ending 4412 is Rs 18,920.00 and Min Due is Rs 950.00 due by 18/10/2026. Avoid late fees by paying now: sbicard.com/pay',
        kind: ObligationKind.cardDue,
        amount: 1892000,
        minDue: 95000,
        due: d(2026, 10, 18),
        ref: '4412',
        biller: 'SBI Credit Card',
      );
      check(
        'Your ICICI Bank Credit Card XX2004 statement for SEP-26 is generated. Total Amt Due: INR 31,500.00, Min Amt: INR 1,575.00, Due Date: 20-OCT-2026.',
        kind: ObligationKind.cardDue,
        amount: 3150000,
        minDue: 157500,
        due: d(2026, 10, 20),
        ref: '2004',
        biller: 'ICICI Bank Credit Card',
      );
      check(
        'Axis Bank Card ending 1109 bill generated. Total Due: Rs 12,400.00, Minimum Due: Rs 620.00, Payment Due Date: 19-OCT-26.',
        kind: ObligationKind.cardDue,
        amount: 1240000,
        minDue: 62000,
        due: d(2026, 10, 19),
        ref: '1109',
      );
      check(
        'Statement generated for Kotak Credit Card ending 3391. Total Due: Rs 8,450.00, Min Due: Rs 500.00, Due Date: 16-OCT-2026.',
        kind: ObligationKind.cardDue,
        amount: 845000,
        minDue: 50000,
        due: d(2026, 10, 16),
        ref: '3391',
      );
      check(
        'Your RBL Bank Credit Card ending 7012 bill: Total Amt Due Rs. 14,290.00, Min Amt Due Rs. 715.00, Due Date 21-Oct-26.',
        kind: ObligationKind.cardDue,
        amount: 1429000,
        minDue: 71500,
        due: d(2026, 10, 21),
        ref: '7012',
      );
      check(
        'Your OneCard statement is generated! Total Due: INR 9,840.00, Min Due: INR 492.00. Payment Due Date: 24 Oct 2026.',
        kind: ObligationKind.cardDue,
        amount: 984000,
        minDue: 49200,
        due: d(2026, 10, 24),
        biller: 'OneCard',
      );
      check(
        'Scapia Federal Card bill generated! Total Due: Rs 16,320.00. Minimum Due: Rs 816.00. Due date: 23-OCT-26.',
        kind: ObligationKind.cardDue,
        amount: 1632000,
        minDue: 81600,
        due: d(2026, 10, 23),
        biller: 'Scapia',
      );
    });

    test('statement email', () {
      check(
        'Statement for your HDFC Bank Credit Card ending 8210 for Sep 2026. Total Amount Due: Rs. 44,210.50 Minimum Amount Due: Rs. 2,210.00 Payment Due Date: 22-Oct-2026 Card Number: XXXX-XXXX-XXXX-8210',
        kind: ObligationKind.cardDue,
        amount: 4421050,
        minDue: 221000,
        due: d(2026, 10, 22),
        ref: '8210',
      );
    });

    test('auto-debit and due-tomorrow warnings', () {
      check(
        'Reminder: Auto-Debit of Total Amt Due Rs 44,210.50 for your HDFC Bank Credit Card ending 8210 is scheduled on 22-OCT-26 from your A/c ending 4921. Maintain balance.',
        kind: ObligationKind.cardDue,
        amount: 4421050,
        due: d(2026, 10, 22),
        ref: '8210',
        account: '4921',
      );
      check(
        'Urgent: Payment of Rs 18,920.00 on SBI Card ending 4412 is due tomorrow (18/10/2026). Pay today to avoid interest and late fees.',
        kind: ObligationKind.cardDue,
        amount: 1892000,
        due: d(2026, 10, 18),
        ref: '4412',
      );
    });
  });

  group('failed and returned debits', () {
    test('bounces', () {
      check(
        'e-Mandate debit of Rs 5,000.00 towards NIPPON INDIA MUTUAL FUND failed on your A/c XX4921 due to Insufficient Funds. Return charges applicable. -HDFC Bank',
        kind: ObligationKind.bounce,
        amount: 500000,
        account: '4921',
        biller: 'NIPPON INDIA MUTUAL FUND',
        reason: 'Insufficient Funds',
      );
      check(
        'ECS/NACH debit for Loan A/C 9012 of Rs 32,450.00 returned unpaid on 05-OCT-26. Please pay immediately via link to avoid negative CIBIL impact.',
        kind: ObligationKind.bounce,
        amount: 3245000,
        due: d(2026, 10, 5),
        ref: '9012',
        reason: 'Returned unpaid',
      );
      check(
        'Standing Instruction execution failed for A/C ...12345 on 05-OCT-26 towards SBI LIFE due to balance below threshold.',
        kind: ObligationKind.bounce,
        account: '2345',
        due: d(2026, 10, 5),
        biller: 'SBI LIFE',
        reason: 'balance below threshold',
      );
    });
  });

  group('messages that must NOT be read as auto-debit notices', () {
    const notNotices = [
      // A debit that already happened is a transaction.
      'Rs 5,000.00 debited from A/c XX4921 on 07-OCT-26 towards NIPPON INDIA MUTUAL FUND UMRN HDFC7029104820194812. Avl Bal Rs 20,000.00',
      'Rs 14,520.00 debited from A/c 1042 towards BAJAJ FINANCE LTD EMI on 06-Oct-26. UMRN ICIC0002918401928410',
      'Rs 99 debited from A/c XX4921 for NETFLIX via UPI AutoPay on 05-OCT-26. Mandate ID 4892019481028391',
      'Sent Rs.500.00 From HDFC Bank A/c *1234 To SUNRISE CAFE On 02/10/26 Ref 600000000001',
      'Rs 2,000.00 spent on HDFC Bank Credit Card ending 8210 at AMAZON on 05-10-26. Avl limit Rs 90,000',
      'Dear Customer, Rs 1,200.00 credited to your A/c XX4921 on 07-OCT-26. Avl bal Rs 10,000.00',
      // A one-off failed payment is not a bounced mandate.
      'Your UPI payment of Rs 500 to SHOP failed. Amount will be refunded.',
      // Noise.
      'Your OTP for AutoPay mandate is 123456. Do not share.',
      'Pre-approved loan of Rs 5,00,000 for you! Apply now. EMI starts at Rs 9,999.',
      'Convert your purchase to EMI. Click here.',
      // Marketing for AutoPay with nothing to act on.
      'Set up AutoPay today and never miss a bill!',
    ];
    for (final sms in notNotices) {
      test(sms.length > 50 ? sms.substring(0, 50) : sms, () {
        expect(parseObligation(sms), isNull);
      });
    }
  });

  group('dates', () {
    test('every format the banks use', () {
      DateTime? first(String s) => findDates(s).firstOrNull?.date;
      expect(first('on 07-OCT-26'), d(2026, 10, 7));
      expect(first('on 05-Oct-2026 by'), d(2026, 10, 5));
      expect(first('due by 18/10/2026'), d(2026, 10, 18));
      expect(first('Payment Due Date: 24 Oct 2026.'), d(2026, 10, 24));
      expect(first('on date 05Mar24 trf'), d(2024, 3, 5));
      expect(first('dated 5-10-26'), d(2026, 10, 5));
    });

    test('not an account number, an amount or an impossible date', () {
      expect(
        findDates('A/c ending 4921 will be debited for Rs 5,000.00'),
        isEmpty,
      );
      expect(findDates('Rs 1,00,000.00 limit'), isEmpty);
      expect(findDates('31-02-26'), isEmpty);
      expect(findDates('statement for SEP-26'), isEmpty);
    });
  });

  test('the ordinary parser still reads real transactions', () {
    // The new reader must not have changed what the old one does.
    expect(
      parseBankSms(
        'UPDATE: INR 1,250.00 debited from HDFC Bank XX1234 on 02-OCT-26. Info: UPI/DR/600000000002/SUNRISE STORE/HDFC',
      )?.type,
      'debit',
    );
  });
}
