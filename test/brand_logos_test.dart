import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';
import 'package:local_ledger/shared/widgets/merchant_badge.dart';

void main() {
  logoAssetChecks();
  orderingChecks();
  group('brands are recognised by name', () {
    const expected = {
      'Swiggy': 'Swiggy',
      'Swiggy Instamart': 'Swiggy Instamart',
      'ZOMATO ORDER': 'Zomato',
      'Zepto': 'Zepto',
      'Blinkit': 'Blinkit',
      'Netflix.com': 'Netflix',
      'Amazon Prime Video': 'Prime Video',
      'Amazon Pay': 'Amazon Pay',
      'AMAZON SELLER': 'Amazon',
      'Airtel Postpaid': 'Airtel',
      'Reliance Jio': 'Jio',
      'Vi Prepaid Recharge': 'Vi',
      'Vodafone Idea': 'Vi',
      'PhonePe': 'PhonePe',
      'Google Pay': 'Google Pay',
      'Paytm Wallet': 'Paytm',
      'CRED': 'CRED',
      'HDFC Bank Credit Card': 'HDFC Bank',
      'ICICI Bank': 'ICICI Bank',
      'Standard Chartered Bank': 'Standard Chartered',
      'SBI Card': 'SBI',
    };
    expected.forEach((merchant, brand) {
      test(merchant, () => expect(brandFor(merchant)?.name, brand));
    });
  });

  test('look-alike words do not match a brand', () {
    expect(brandFor('Chocolate Room'), isNull); // "ola"
    expect(brandFor('Visakha Stores'), isNull); // "visa"
    expect(brandFor('Violet Cafe'), isNull); // "vi"
    expect(brandFor('Karthik Axisting'), isNull);
    expect(brandFor('Unknown merchant'), isNull);
  });

  test(
    'brands with a bundled logo draw it; the rest get colour and initial',
    () {
      expect(merchantBadgeFor('Swiggy')!.icon, isNotNull);
      expect(merchantBadgeFor('HDFC Bank')!.icon, isNotNull);
      final zepto = merchantBadgeFor('Zepto')!;
      expect(zepto.icon, isNull);
      expect(zepto.initial, 'Z');
    },
  );

  test('pale brand colours get a dark glyph, dark ones a white glyph', () {
    expect(
      merchantBadgeFor('Blinkit')!.foreground.computeLuminance(),
      lessThan(0.2),
    );
    expect(
      merchantBadgeFor('Uber')!.foreground.computeLuminance(),
      greaterThan(0.8),
    );
  });

  group('categories follow the brand', () {
    const expected = {
      'Swiggy': 'cat_food',
      'Zomato': 'cat_food',
      'Zepto': 'cat_groceries',
      'Blinkit': 'cat_groceries',
      'Swiggy Instamart': 'cat_groceries',
      'Netflix': 'cat_entertainment',
      'Amazon Prime Video': 'cat_entertainment',
      'Jio': 'cat_bills',
      'Airtel': 'cat_bills',
      'Vi Prepaid': 'cat_bills',
      'CRED': 'cat_bills',
      'PhonePe': 'cat_transfer',
      'Google Pay': 'cat_transfer',
      'Paytm': 'cat_transfer',
      'MakeMyTrip': 'cat_transport',
      'IndiGo': 'cat_transport',
      'Flipkart': 'cat_shopping',
      'PharmEasy': 'cat_health',
      'Zerodha': 'cat_investment',
    };
    expected.forEach((merchant, category) {
      test(merchant, () => expect(defaultCategoryFor(merchant), category));
    });
  });
}

// Every bundled logo file must exist and be listed in the credits.
void logoAssetChecks() {
  test('every logo asset in the catalog exists and is credited', () {
    final credits = File('assets/logos/CREDITS.md').readAsStringSync();
    final files = Directory('assets/logos')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    for (final f in files.where(
      (f) => f.endsWith('.png') || f.endsWith('.jpg') || f.endsWith('.webp'),
    )) {
      expect(credits, contains(f), reason: '$f is not in CREDITS.md');
    }
    for (final name in [
      'Zepto',
      'Ola',
      'Flipkart',
      'Myntra',
      'Rapido',
      'Amazon',
      'Apollo',
      'SBI',
      'Standard Chartered',
    ]) {
      final badge = merchantBadgeFor(name)!;
      expect(badge.asset ?? badge.icon, isNotNull, reason: '$name has no logo');
      if (badge.asset != null) {
        expect(File(badge.asset!).existsSync(), isTrue, reason: badge.asset);
      }
    }
  });
}

void orderingChecks() {
  test('more specific brands win over their parent', () {
    expect(brandFor('Apple Music')?.name, 'Apple Music');
    expect(brandFor('Apple')?.name, 'Apple');
    expect(brandFor('YouTube Music')?.name, 'YouTube Music');
    expect(brandFor('Swiggy Instamart')?.name, 'Swiggy Instamart');
  });

  test('Vi, Citi, Kotak, Bank of Baroda and Adani all resolve to a logo', () {
    expect(brandFor('Vi')?.name, 'Vi');
    expect(brandFor('VI')?.name, 'Vi');
    expect(brandFor('Vi Cafe'), isNull); // exact-name keyword only
    expect(brandFor('Vodafone Idea Ltd')?.name, 'Vi');
    expect(brandFor('Citi')?.name, 'Citi');
    expect(brandFor('Citibank N.A.')?.name, 'Citi');
    for (final n in [
      'Vi',
      'Citi',
      'Kotak Mahindra Bank',
      'Bank of Baroda',
      'Adani Electricity',
    ]) {
      final b = merchantBadgeFor(n)!;
      expect(b.asset ?? b.icon, isNotNull, reason: n);
    }
  });
}
