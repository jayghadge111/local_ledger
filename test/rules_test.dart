import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/email/bank_email_matcher.dart';
import 'package:local_ledger/core/intelligence/default_category_rules.dart';
import 'package:local_ledger/core/intelligence/merchant_normalizer.dart';
import 'package:local_ledger/core/rules/bundled_rules.g.dart';
import 'package:local_ledger/core/rules/parser_rules.dart';
import 'package:local_ledger/core/sms/bank_names.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';
import 'package:local_ledger/shared/widgets/brand_icons.dart';
import 'package:local_ledger/shared/widgets/merchant_badge.dart';

Map<String, dynamic> loadJson() =>
    jsonDecode(File('rules/rules.bundled.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  tearDown(() => ParserRules.use(null));

  group('the built-in rules', () {
    test('the generated Dart file matches rules/rules.bundled.json', () {
      // If this fails: dart run tool/gen_bundled_rules.dart
      expect(jsonDecode(kBundledRulesJson), loadJson());
    });

    test(
      'load, and hold what the app relied on before the rules moved to JSON',
      () {
        final r = ParserRules.bundled();
        expect(r.schemaVersion, 1);
        expect(r.senderCodes.length, greaterThan(1400));
        expect(
          r.senderCodes,
          containsAll(['HDFCBK', 'ICICIT', 'SCBANK', 'SBMIND', 'EQUTAS']),
        );
        expect(r.bankNames.length, 37);
        expect(r.emailSuffix, 'bank.in');
        expect(r.emailDomains.length, greaterThan(85));
        expect(r.emailDomains, contains('hdfcbank.net'));
        expect(
          r.categoryKeywords.map((c) => c.categoryId),
          containsAll([
            'cat_food',
            'cat_groceries',
            'cat_bills',
            'cat_emi',
            'cat_investment',
          ]),
        );
        expect(r.brands.length, 124);
        expect(r.aliases.length, 44);
        expect(r.parser.merchantPatterns.length, 9);
      },
    );

    test('every glyph a brand names exists in the icon table', () {
      for (final b in ParserRules.bundled().brands) {
        if (b.iconKey != null) {
          expect(brandIcons, contains(b.iconKey), reason: b.name);
        }
      }
    });

    test('every logo image a brand names exists', () {
      for (final b in ParserRules.bundled().brands) {
        if (b.logoAsset != null) {
          expect(
            File(b.logoAsset!).existsSync(),
            isTrue,
            reason: '${b.name}: ${b.logoAsset}',
          );
        }
      }
    });

    test('shared pattern fragments are filled in', () {
      final p = ParserRules.bundled().parser;
      expect(p.prefixAmount.pattern, contains('usd|sar|eur'));
      expect(p.prefixAmount.pattern, isNot(contains('{currencyCodes}')));
      expect(
        p.merchantPatterns.any((m) => m.pattern.contains(r'\s+on\b')),
        isTrue,
      );
      expect(
        p.merchantPatterns.any((m) => m.pattern.contains('{nameEnd}')),
        isFalse,
      );
    });

    test('canaries: the sample messages in the rules read as promised', () {
      final canaries = ParserRules.bundled().canaries;
      expect(canaries, isNotEmpty);
      for (final c in canaries) {
        final parsed = parseBankSms(c.text);
        if (c.type == null) {
          expect(parsed, isNull, reason: c.text);
          continue;
        }
        expect(parsed, isNotNull, reason: c.text);
        expect(parsed!.type, c.type, reason: c.text);
        if (c.amountMinor != null) {
          expect(parsed.amountMinor, c.amountMinor, reason: c.text);
        }
        if (c.merchantContains != null) {
          expect(
            parsed.merchant.toLowerCase(),
            contains(c.merchantContains!.toLowerCase()),
            reason: c.text,
          );
        }
      }
    });
  });

  group('swapping the rules changes behaviour without touching code', () {
    Map<String, dynamic> edited(void Function(Map<String, dynamic>) change) {
      final j = loadJson();
      change(j);
      return j;
    }

    test('a new bank sender code is recognised', () {
      expect(looksLikeBankSender('VM-NEWBNK-S'), isFalse);
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) => (j['senderCodes'] as List).add('NEWBNK')),
        ),
      );
      expect(looksLikeBankSender('VM-NEWBNK-S'), isTrue);
    });

    test('a new bank name and email domain', () {
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) {
            (j['bankNames'] as List).add({
              'prefix': 'NEWBNK',
              'name': 'New Bank',
            });
            ((j['emailDomains'] as Map)['domains'] as List).add(
              'newbank.example',
            );
          }),
        ),
      );
      expect(bankDisplayName('VM-NEWBNK-S'), 'New Bank');
      expect(looksLikeBankEmail('alerts@newbank.example'), isTrue);
    });

    test('a new category keyword and merchant alias', () {
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) {
            final cats = j['categoryKeywords'] as List;
            final food = cats.firstWhere(
              (c) => c['category'] == 'cat_food',
            ) as Map<String, dynamic>;
            (food['words'] as List).add('zingycafe');
            (j['merchantAliases'] as List).add({
              'match': 'zcafe',
              'name': 'Zingy Cafe',
            });
          }),
        ),
      );
      expect(defaultCategoryFor('ZINGYCAFE MUMBAI'), 'cat_food');
      expect(normalizeMerchant('UPI/123/ZCAFE/HDFC'), 'Zingy Cafe');
    });

    test('a changed parser pattern is used', () {
      const msg = 'Alert: INR 120.00 yeeted at CORNER SHOP on 03-10-26';
      expect(parseBankSms(msg), isNull);
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) {
            final p = j['parser'] as Map<String, dynamic>;
            p['strongDebit'] = {
              'pattern': r'\b(debited|yeeted)\b',
              'flags': 'i',
            };
          }),
        ),
      );
      final parsed = parseBankSms(msg)!;
      expect(parsed.type, 'debit');
      expect(parsed.amountMinor, 12000);
    });

    test('a new brand shows up with its colour', () {
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) {
            (j['brands'] as List).insert(0, {
              'name': 'Zingy Cafe',
              'keywords': ['zingy cafe'],
              'color': '#112233',
              'initial': 'Z',
              'icon': null,
              'logo': null,
            });
          }),
        ),
      );
      final badge = merchantBadgeFor('Zingy Cafe Mumbai')!;
      expect(badge.name, 'Zingy Cafe');
      expect(badge.color.toARGB32(), 0xFF112233);
    });

    test('restoring the built-in rules undoes it', () {
      ParserRules.use(
        ParserRules.fromJson(
          edited((j) => (j['senderCodes'] as List).add('NEWBNK')),
        ),
      );
      ParserRules.use(null);
      expect(looksLikeBankSender('VM-NEWBNK-S'), isFalse);
    });
  });

  group('bad documents are refused', () {
    test('not a rules document', () {
      expect(
        () => ParserRules.fromJson({'format': 'something-else'}),
        throwsA(isA<RulesFormatException>()),
      );
    });

    test('a pattern that is not a valid regex', () {
      final j = loadJson();
      (j['parser'] as Map<String, dynamic>)['strongDebit'] = {
        'pattern': r'(unclosed',
        'flags': 'i',
      };
      expect(
        () => ParserRules.fromJson(j),
        throwsA(isA<RulesFormatException>()),
      );
    });

    test('a missing section', () {
      final j = loadJson()..remove('senderCodes');
      expect(
        () => ParserRules.fromJson(j),
        throwsA(isA<RulesFormatException>()),
      );
    });
  });
}
