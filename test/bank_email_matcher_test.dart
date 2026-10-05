import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/email/bank_email_matcher.dart';

void main() {
  test('Gmail query selects bank domains only', () {
    final q = bankEmailSearchQuery('2025/10/01');
    expect(q, startsWith('after:2025/10/01 from:(bank.in OR '));
    expect(q, contains('hdfcbank.net'));
    expect(q, contains('sc.com'));
    // Transaction words, plus the wording of auto-debit notices.
    expect(q, contains('(debited OR credited OR spent OR mandate OR UMRN'));
    expect(q, contains('"auto-debit"'));
    expect(q, contains('"amount due"'));
    expect(q, endsWith('"EMI due")'));
  });

  group('looksLikeBankEmail', () {
    test('any .bank.in sender is a bank', () {
      for (final f in [
        'Axis Bank <alerts@axis.bank.in>',
        'alerts@hdfc.bank.in',
        'x@digital.axisbankmail.bank.in',
        'noreply@bankofbaroda.bank.in',
        'a@sbi.bank.in',
      ]) {
        expect(looksLikeBankEmail(f), isTrue, reason: f);
      }
    });

    test('legacy domains and their subdomains', () {
      for (final f in [
        'HDFC Bank InstaAlerts <alerts@hdfcbank.net>',
        'cbssbi.info@alerts.sbi.co.in',
        'ICICI Bank <credit_cards@icicibank.com>',
        'upi@sc.com',
        'Statements@sbicard.com',
      ]) {
        expect(looksLikeBankEmail(f), isTrue, reason: f);
      }
    });

    test('look-alikes and spoofed display names are rejected', () {
      for (final f in [
        'friend@gmail.com',
        'HDFC Bank <scam@gmail.com>',
        'alerts@hdfcbank.net.evil.com',
        'alerts@nothdfcbank.net',
        'x@fakebank.in',
        'no address here',
      ]) {
        expect(looksLikeBankEmail(f), isFalse, reason: f);
      }
    });
  });

  group('banks that still use older domains', () {
    test('examples from real customer-care sources', () {
      for (final f in [
        'upi@sc.com',
        'customercare@sbmbank.co.in',
        'customercare@bandhanbank.com',
        'info@ktkbank.com',
        'jkbcustomercare@jkbmail.com',
        'customersupport@kvbmail.com',
        'customercare@cityunionbank.in',
        'customercare@tmbank.in',
        'hocomplaints@mahabank.co.in',
        'nodalofficer@indianbank.co.in',
        'BOI.CallCentre@bankofindia.co.in',
        'customercare@centralbank.co.in',
        'uco.custcare@ucobank.co.in',
        'cybercell@iob.in',
        'customercare@idbi.co.in',
        'customercare@dhanbank.co.in',
        'indiaservice@citi.com',
        'Complaints.india@hsbc.co.in',
        'customercareindia@dbs.com',
        'customercare@esafbank.com',
        'customercare@aubank.in',
        'customerservicecentre@saraswatbank.com',
      ]) {
        expect(looksLikeBankEmail(f), isTrue, reason: f);
      }
    });

    test('co-operative banks, old domains and .bank.in', () {
      for (final f in [
        'jjsbl_jal@jjsbl.bank.in', // Jalgaon Janata
        'subhash.wani@jjsbl.co.in',
        'customercare@jpc.bank.in', // Jalgaon Peoples
        'info@mucbank.com',
        'info@kalupur.bank.in',
        'rtgs@nkgsb-bank.com',
        'cpd@apnabank.co.in',
        'info@dnsb.co.in',
        'admin@amcbank.in',
        'customerservicecentre@saraswatbank.com',
        'x@saraswat.bank.in',
        'x@cosmos.bank.in',
        'x@tjsb.bank.in',
      ]) {
        expect(looksLikeBankEmail(f), isTrue, reason: f);
      }
    });

    test('a domain the user added is accepted, others still are not', () {
      expect(looksLikeBankEmail('alerts@jalgaonbank.example'), isFalse);
      expect(
        looksLikeBankEmail(
          'alerts@jalgaonbank.example',
          extraDomains: ['jalgaonbank.example'],
        ),
        isTrue,
      );
      expect(
        looksLikeBankEmail(
          'x@gmail.com',
          extraDomains: ['jalgaonbank.example'],
        ),
        isFalse,
      );
      expect(
        bankEmailSearchQuery(
          '2025/10/01',
          extraDomains: ['jalgaonbank.example'],
        ),
        contains('jalgaonbank.example'),
      );
    });
  });

  group('normalizeSenderDomain', () {
    test('accepts addresses, domains and URLs', () {
      expect(normalizeSenderDomain(' Alerts@MyBank.co.in '), 'mybank.co.in');
      expect(normalizeSenderDomain('@mybank.co.in'), 'mybank.co.in');
      expect(normalizeSenderDomain('mybank.co.in'), 'mybank.co.in');
      expect(
        normalizeSenderDomain('https://www.mybank.co.in/contact'),
        'www.mybank.co.in',
      );
    });
    test('rejects junk', () {
      expect(normalizeSenderDomain(''), isNull);
      expect(normalizeSenderDomain('hello'), isNull);
      expect(normalizeSenderDomain('a b c'), isNull);
    });
  });
}
