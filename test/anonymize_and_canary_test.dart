import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/rules/bundled_rules.g.dart';
import 'package:local_ledger/core/rules/canary_tools.dart';
import 'package:local_ledger/core/rules/parser_rules.dart';
import 'package:local_ledger/core/sms/anonymize.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

import 'message_corpus_test.dart' show corpus;

void main() {
  group('anonymizing a message keeps its layout and hides the person', () {
    test('account, reference, balance and phone numbers change', () {
      const original =
          'Dear Rahul Kumar, Rs 12,450.00 debited from A/c XX4921 on 05-OCT-26 '
          'to SHOP. UPI Ref 628419375012. Avl bal Rs 70,703.19. Not you? '
          'Call 9820012345 or mail help@hdfcbank.net';
      final out = anonymizeMessage(original);

      expect(out, isNot(contains('Rahul')));
      expect(out, isNot(contains('4921')));
      expect(out, isNot(contains('628419375012')));
      expect(out, isNot(contains('70,703.19')));
      expect(out, isNot(contains('9820012345')));
      expect(out, isNot(contains('hdfcbank.net')));
      // The transaction itself is untouched.
      expect(out, contains('Rs 12,450.00 debited'));
      // The balance keeps its shape.
      expect(out, matches(RegExp(r'Avl bal Rs \d\d,\d\d\d\.\d\d')));
    });

    test('UPI ids and loan numbers go', () {
      final out = anonymizeMessage(
        'Paid to rahul.k@okhdfcbank. Part payment Rs. 59000.00 toward loan no. P405PSA3761027.',
      );
      expect(out, isNot(contains('rahul')));
      expect(out, isNot(contains('P405PSA3761027')));
      expect(out, contains('Rs. 59000.00'));
    });

    test('the parser reads the anonymised text the same way', () {
      const original =
          'UPDATE: INR 1,250.00 debited from HDFC Bank XX4921 on 02-OCT-26. '
          'Info: UPI/DR/628419375012/SUNRISE STORE/HDFC. Avl bal:INR 9,999.50';
      final before = parseBankSms(original)!;
      final after = parseBankSms(anonymizeMessage(original))!;
      expect(after.type, before.type);
      expect(after.amountMinor, before.amountMinor);
      expect(after.merchant, before.merchant);
    });

    test('every message in the corpus still reads the same once anonymised', () {
      for (final m in corpus) {
        final before = parseBankSms(m.text);
        final after = parseBankSms(anonymizeMessage(m.text));
        expect(after?.type, before?.type, reason: m.label);
        expect(after?.amountMinor, before?.amountMinor, reason: m.label);
        expect(after?.currency, before?.currency, reason: m.label);
      }
    });

    test('an already harmless message is barely touched', () {
      const text = 'Your OTP is 481516. Do not share it.';
      expect(anonymizeMessage(text), text);
    });
  });

  group('a shared message becomes a regression test', () {
    final rulesText = kBundledRulesJson;
    final rules = jsonDecode(rulesText) as Map<String, dynamic>;

    test('the entry copied from the app has the rules-file shape', () {
      final json = jsonDecode(
        canaryJson(
          text: 'Rs 10.00 debited from A/c XX1234 to SHOP',
          type: 'debit',
          amountMinor: 1000,
          merchantContains: ' Shop ',
        ),
      );
      expect(json['text'], contains('SHOP'));
      expect(json['expect'], {
        'type': 'debit',
        'amountMinor': 1000,
        'merchantContains': 'shop',
      });
      expect(
        jsonDecode(canaryJson(text: 'OTP 1', type: null))['expect'],
        {'type': null},
      );
    });

    test('new entries are added, repeats and junk are not', () {
      final fresh = newCanaries(
        rules,
        parseSnippets('''
          {"text": "Rs 77.00 debited from A/c XX1234 to NEW CAFE",
           "expect": {"type": "debit", "amountMinor": 7700}}
          {"text": "Rs 77.00 debited from A/c XX1234 to NEW CAFE",
           "expect": {"type": "debit"}}
          {"text": "", "expect": {"type": "debit"}}
          {"nonsense": true}
        '''),
      );
      expect(fresh, hasLength(1));
      // One already in the file is skipped.
      final existing = (rules['canaries'] as List).first as Map<String, dynamic>;
      expect(newCanaries(rules, existing), isEmpty);
    });

    test('inserting touches only the end of the canaries list', () {
      final entry = {
        'text': 'Rs 77.00 debited from A/c XX1234 to NEW CAFE',
        'expect': {'type': 'debit', 'amountMinor': 7700},
      };
      final updated = insertCanaries(rulesText, [entry]);

      final before = jsonDecode(rulesText) as Map<String, dynamic>;
      final after = jsonDecode(updated) as Map<String, dynamic>;
      final b = (before['canaries'] as List);
      final a = (after['canaries'] as List);
      expect(a.length, b.length + 1);
      expect(a.last, entry);
      expect(a.sublist(0, b.length), b);
      // Everything outside the list is byte-for-byte what it was.
      final cut = rulesText.indexOf('"canaries"');
      expect(updated.substring(0, cut), rulesText.substring(0, cut));
      // …and the result is a valid rules file that reads the new message.
      expect(
        ParserRules.fromJson(after).canaries.last.text,
        entry['text'],
      );
    });
  });
}
