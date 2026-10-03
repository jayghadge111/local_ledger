import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/email/bank_email_matcher.dart';

void main() {
  test('Gmail query only selects mail from known bank domains', () {
    final q = bankEmailSearchQuery('2025/10/01');
    expect(q, startsWith('after:2025/10/01 from:('));
    expect(q, contains('hdfcbank.net'));
    expect(q, contains('icicibank.com'));
    expect(q, endsWith('(debited OR credited OR spent)'));
  });

  test('sender check', () {
    expect(looksLikeBankEmail('HDFC Bank <alerts@hdfcbank.net>'), isTrue);
    expect(looksLikeBankEmail('friend@gmail.com'), isFalse);
  });
}
