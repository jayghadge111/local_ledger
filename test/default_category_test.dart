import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';

void main() {
  test('common merchants', () {
    expect(defaultCategoryFor('Swiggy'), 'cat_food');
    expect(defaultCategoryFor('Jofrey Cafe'), 'cat_food');
    expect(defaultCategoryFor('Amazon'), 'cat_shopping');
    expect(defaultCategoryFor('Uber'), 'cat_transport');
    expect(defaultCategoryFor('Netflix'), 'cat_entertainment');
    expect(defaultCategoryFor('Apollo Pharmacy'), 'cat_health');
    expect(defaultCategoryFor('BESCOM'), 'cat_bills');
    expect(defaultCategoryFor('Airtel recharge'), 'cat_bills');
  });

  test('specific names beat generic ones', () {
    expect(defaultCategoryFor('Swiggy Instamart'), 'cat_groceries');
    expect(defaultCategoryFor('BigBasket'), 'cat_groceries');
  });

  test('whole words only: "ola" is not inside "cola", "tea" not in "steam team"', () {
    expect(defaultCategoryFor('Cola Corner'), isNot('cat_transport'));
    expect(defaultCategoryFor('Dream Team'), isNull);
  });

  test('salary credits are income, but only for credits', () {
    expect(defaultCategoryFor('ACME CORP SALARY', isCredit: true), 'cat_income');
    expect(defaultCategoryFor('ACME CORP SALARY'), isNull);
  });

  test('unknown merchants stay unmatched', () {
    expect(defaultCategoryFor('Raju Enterprises'), isNull);
  });
}
