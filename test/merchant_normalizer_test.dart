import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/intelligence/merchant_normalizer.dart';

void main() {
  test('bundled aliases match whole words', () {
    expect(normalizeMerchant('SWIGGY INSTAMART'), 'Swiggy');
    expect(normalizeMerchant('AMZN MKTP IN'), 'Amazon');
    expect(normalizeMerchant('NETFLIX.COM'), 'Netflix');
  });

  test('"cred" does not match inside "credit"', () {
    expect(normalizeMerchant('CREDIT BILL PAYMENT'), isNot('CRED'));
    expect(normalizeMerchant('CRED'), 'CRED');
  });

  test('VPA uses the handle', () {
    expect(normalizeMerchant('swiggy@icici'), 'Swiggy');
    expect(normalizeMerchant('rahul.sharma42@okhdfcbank'), 'Rahul Sharma');
  });

  test('gateway plumbing is stripped', () {
    expect(normalizeMerchant('UPI/402910/PYMNT_RZP'), 'UPI payment');
    expect(normalizeMerchant('PYU*BLUE TOKAI COFFEE'), 'Blue Tokai Coffee');
  });

  test('POS-only text is a card payment, not UPI', () {
    expect(normalizeMerchant('POS'), 'Card payment');
    expect(normalizeMerchant('UPI/402910/PYMNT_RZP'), 'UPI payment');
  });

  test('user aliases win over bundled ones', () {
    expect(
      normalizeMerchant('swiggy@icici', userAliases: {'swiggy@icici': 'Office lunch'}),
      'Office lunch',
    );
  });

  test('unknown names are tidied, not lost', () {
    expect(normalizeMerchant('RAJU TEA STALL'), 'Raju Tea Stall');
  });
}
