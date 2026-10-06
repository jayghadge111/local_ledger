import 'dart:convert';

import 'bundled_rules.g.dart';

/// Thrown when a rules document is malformed or contains an unusable pattern.
class RulesFormatException implements Exception {
  RulesFormatException(this.message);
  final String message;
  @override
  String toString() => 'RulesFormatException: $message';
}

/// A bank/merchant-name rule: any text matching [regex] is shown as [name].
class AliasRule {
  const AliasRule(this.regex, this.name);
  final RegExp regex;
  final String name;
}

/// One keyword group of the built-in categoriser.
class CategoryKeywords {
  const CategoryKeywords(this.categoryId, this.words);
  final String categoryId;
  final List<String> words;
}

/// A recognised brand: how to spot it in a merchant name and how to draw it.
/// Colours and image names are plain data; the UI layer turns [iconKey] into
/// a glyph and [logoAsset] into an image.
class BrandRule {
  BrandRule({
    required this.name,
    required this.keywords,
    required this.colorValue,
    required this.initial,
    required this.iconKey,
    required this.logoAsset,
    required this.logoIsWordmark,
  }) : regex = _brandRegex(keywords);

  final String name;
  final List<String> keywords;

  /// 0xAARRGGBB.
  final int colorValue;
  final String initial;
  final String? iconKey;
  final String? logoAsset;
  final bool logoIsWordmark;
  final RegExp regex;
}

/// One entry of the "what was this payment for" list.
class PurposeLabel {
  const PurposeLabel({this.label, this.regex, this.isLoan = false});
  final String? label;
  final RegExp? regex;

  /// Marks the spot where the loan/EMI wording check runs.
  final bool isLoan;
}

/// Every regular expression the SMS/email parser uses, compiled.
class ParserPatterns {
  ParserPatterns._(Map<String, dynamic> p, Map<String, String> vars)
    : senderCode = _re(p['senderCode'], vars),
      prefixAmount = _re(p['prefixAmount'], vars),
      suffixAmount = _re(p['suffixAmount'], vars),
      verbAmount = _re(p['verbAmount'], vars),
      balanceContext = _re(p['balanceContext'], vars),
      balanceClause = _re(p['balanceClause'], vars),
      strongDebit = _re(p['strongDebit'], vars),
      strongCredit = _re(p['strongCredit'], vars),
      weakDebit = _re(p['weakDebit'], vars),
      weakCredit = _re(p['weakCredit'], vars),
      notTransaction = _re(p['notTransaction'], vars),
      paymentAcknowledgement = _re(p['paymentAcknowledgement'], vars),
      cardPaymentPhrase = _re(p['cardPaymentPhrase'], vars),
      failedWords = _re(p['failedWords'], vars),
      merchantPatterns = [
        for (final m in _list(p['merchantPatterns'])) _re(m, vars),
      ],
      creditFrom = _re(p['creditFrom'], vars),
      notMerchant = _re(p['notMerchant'], vars),
      genericPhrase = _re(p['genericPhrase'], vars),
      refundWords = _re(p['refundWords'], vars),
      forexWords = _re(p['forexWords'], vars),
      prepaidWords = _re(p['prepaidWords'], vars),
      creditCardWords = _re(p['creditCardWords'], vars),
      debitCardWords = _re(p['debitCardWords'], vars),
      cardWords = _re(p['cardWords'], vars),
      internationalKeywords = _re(p['internationalKeywords'], vars),
      last4 = _re(p['last4'], vars),
      last4Masked = _re(p['last4Masked'], vars),
      loanKind = _re(p['loanKind'], vars),
      loanWords = _re(p['loanWords'], vars),
      emailFooter = _re(p['emailFooter'], vars),
      stripVpa = _re(p['merchantCleanup']['stripVpa'], vars),
      stripChannel = _re(p['merchantCleanup']['stripChannel'], vars),
      numericOnly = _re(p['merchantCleanup']['numericOnly'], vars),
      stripTrailingRef = _re(p['merchantCleanup']['stripTrailingRef'], vars),
      structuredType = _re(p['structured']['type'], vars),
      structuredAmount = _re(p['structured']['amount'], vars),
      structuredCurrency = _re(p['structured']['currency'], vars),
      structuredStatus = _re(p['structured']['status'], vars),
      structuredOkStatuses = {
        for (final s in _list(p['structured']['okStatuses'])) s as String,
      },
      structuredFieldTemplate = p['structured']['fieldTemplate'] as String,
      structuredFieldLabels = vars['fieldLabels']!,
      debitPartyLabels = [
        for (final s in _list(p['structured']['debitPartyLabels'])) s as String,
      ],
      creditPartyLabels = [
        for (final s in _list(p['structured']['creditPartyLabels']))
          s as String,
      ],
      partyTitle = _re(p['structured']['partyTitle'], vars),
      debitPurposes = _purposes(p['purposeLabels']['debit'], vars),
      creditPurposes = _purposes(p['purposeLabels']['credit'], vars);

  final RegExp senderCode;
  final RegExp prefixAmount;
  final RegExp suffixAmount;
  final RegExp verbAmount;
  final RegExp balanceContext;
  final RegExp balanceClause;
  final RegExp strongDebit;
  final RegExp strongCredit;
  final RegExp weakDebit;
  final RegExp weakCredit;
  final RegExp notTransaction;

  /// "Your payment was received toward your loan / credit card": the lender
  /// or card issuer confirming money the user sent. Not income.
  final RegExp paymentAcknowledgement;

  /// "…towards Credit card repayment": the card is who is being paid, not the
  /// account the money left.
  final RegExp cardPaymentPhrase;
  final RegExp failedWords;

  /// Tried in order; the first usable capture wins.
  final List<RegExp> merchantPatterns;
  final RegExp creditFrom;
  final RegExp notMerchant;
  final RegExp genericPhrase;
  final RegExp refundWords;
  final RegExp forexWords;
  final RegExp prepaidWords;
  final RegExp creditCardWords;
  final RegExp debitCardWords;
  final RegExp cardWords;
  final RegExp internationalKeywords;
  final RegExp last4;

  /// A masked number anywhere (`XX0715`, `xxxx2627`) when no "a/c"-style
  /// word introduces it.
  final RegExp last4Masked;
  final RegExp loanKind;
  final RegExp loanWords;
  final RegExp emailFooter;
  final RegExp stripVpa;
  final RegExp stripChannel;
  final RegExp numericOnly;
  final RegExp stripTrailingRef;
  final RegExp structuredType;
  final RegExp structuredAmount;
  final RegExp structuredCurrency;
  final RegExp structuredStatus;
  final Set<String> structuredOkStatuses;
  final String structuredFieldTemplate;
  final String structuredFieldLabels;
  final List<String> debitPartyLabels;
  final List<String> creditPartyLabels;
  final RegExp partyTitle;
  final List<PurposeLabel> debitPurposes;
  final List<PurposeLabel> creditPurposes;
}

/// The patterns that recognise and read auto-debit related messages: mandate
/// registrations, pre-debit notices, EMI and card dues, and bounces. None of
/// these is a spend — they are upcoming or failed obligations.
class ObligationPatterns {
  ObligationPatterns._(Map<String, dynamic> j)
    : bounce = _re(j['classify']['bounce'], const {}),
      setup = _re(j['classify']['setup'], const {}),
      preDebit = _re(j['classify']['preDebit'], const {}),
      cardStatement = _re(j['classify']['cardStatement'], const {}),
      cardDue = _re(j['classify']['cardDue'], const {}),
      emiDue = _re(j['classify']['emiDue'], const {}),
      totalDueWords = _re(j['classify']['totalDueWords'], const {}),
      emiWords = _re(j['classify']['emiWords'], const {}),
      cardWords = _re(j['classify']['cardWords'], const {}),
      amount = _re(j['extract']['amount'], const {}),
      maxAmount = _re(j['extract']['maxAmount'], const {}),
      totalDue = _re(j['extract']['totalDue'], const {}),
      minDue = _re(j['extract']['minDue'], const {}),
      umrn = _re(j['extract']['umrn'], const {}),
      mandateId = _re(j['extract']['mandateId'], const {}),
      account = _re(j['extract']['account'], const {}),
      loanRef = _re(j['extract']['loanRef'], const {}),
      card = _re(j['extract']['card'], const {}),
      frequency = _re(j['extract']['frequency'], const {}),
      reason = _re(j['extract']['reason'], const {}),
      date = _re(j['extract']['date'], const {}),
      dueDateLead = _re(j['extract']['dueDateLead'], const {}),
      nextDebitLead = _re(j['extract']['nextDebitLead'], const {}),
      billers = [
        for (final b in _list(j['extract']['billers'])) _re(b, const {}),
      ],
      billerFallback = _re(j['extract']['billerFallback'], const {}),
      billerRejectStart = _re(j['extract']['billerRejectStart'], const {}),
      billerRejectEnd = _re(j['extract']['billerRejectEnd'], const {}),
      billerTrim = _re(j['extract']['billerTrim'], const {}),
      cardIssuer = _re(j['extract']['cardIssuer'], const {}),
      signature = _re(j['extract']['signature'], const {}),
      yourLoan = _re(j['extract']['yourLoan'], const {}),
      loanTypeWord = _re(j['extract']['loanTypeWord'], const {});

  final RegExp bounce;
  final RegExp setup;
  final RegExp preDebit;
  final RegExp cardStatement;
  final RegExp cardDue;
  final RegExp emiDue;
  final RegExp totalDueWords;
  final RegExp emiWords;
  final RegExp cardWords;
  final RegExp amount;
  final RegExp maxAmount;
  final RegExp totalDue;
  final RegExp minDue;
  final RegExp umrn;
  final RegExp mandateId;
  final RegExp account;
  final RegExp loanRef;
  final RegExp card;
  final RegExp frequency;
  final RegExp reason;
  final RegExp date;
  final RegExp dueDateLead;
  final RegExp nextDebitLead;

  /// Tried in order; the first usable capture wins.
  final List<RegExp> billers;

  /// Looser "for NAME" pattern, used only for mandates and pre-debits.
  final RegExp billerFallback;
  final RegExp billerRejectStart;
  final RegExp billerRejectEnd;
  final RegExp billerTrim;
  final RegExp cardIssuer;
  final RegExp signature;
  final RegExp yourLoan;
  final RegExp loanTypeWord;
}

/// All the text-matching rules the app uses to recognise banks, read
/// transactions and name merchants, loaded from one JSON document.
///
/// The app ships a built-in document ([kBundledRulesJson], generated from
/// `rules/rules.bundled.json`). [current] is what the rest of the code reads;
/// [use] swaps it, which is the hook for loading rules from somewhere else
/// later (see `docs/remote-rules-plan.md`).
class ParserRules {
  ParserRules._({
    required this.schemaVersion,
    required this.packVersion,
    required this.senderCodes,
    required this.bankNames,
    required this.emailSuffix,
    required this.emailDomains,
    required this.categoryKeywords,
    required this.incomeWords,
    required this.brands,
    required this.aliases,
    required this.noiseWords,
    required this.acronyms,
    required this.genericLabels,
    required this.loanEmiLabel,
    required this.nameTitles,
    required this.parser,
    required this.obligations,
    required this.canaries,
  });

  factory ParserRules.fromJson(Map<String, dynamic> json) {
    try {
      if (json['format'] != 'nativespend-rules') {
        throw RulesFormatException('not a rules document');
      }
      final parserJson = json['parser'] as Map<String, dynamic>;
      final vars = {
        for (final e in (parserJson['vars'] as Map<String, dynamic>).entries)
          e.key: e.value as String,
      };
      final mn = json['merchantNormalizer'] as Map<String, dynamic>;
      final email = json['emailDomains'] as Map<String, dynamic>;
      return ParserRules._(
        schemaVersion: json['schemaVersion'] as int,
        packVersion: json['packVersion'] as int,
        senderCodes: {for (final c in _list(json['senderCodes'])) c as String},
        bankNames: [
          for (final b in _list(json['bankNames']))
            (prefix: b['prefix'] as String, name: b['name'] as String),
        ],
        emailSuffix: email['suffix'] as String,
        emailDomains: [for (final d in _list(email['domains'])) d as String],
        categoryKeywords: [
          for (final c in _list(json['categoryKeywords']))
            CategoryKeywords(c['category'] as String, [
              for (final w in _list(c['words'])) w as String,
            ]),
        ],
        incomeWords: [for (final w in _list(json['incomeWords'])) w as String],
        brands: [
          for (final b in _list(json['brands']))
            BrandRule(
              name: b['name'] as String,
              keywords: [for (final k in _list(b['keywords'])) k as String],
              colorValue:
                  0xFF000000 |
                  int.parse((b['color'] as String).substring(1), radix: 16),
              initial: b['initial'] as String,
              iconKey: b['icon'] as String?,
              logoAsset:
                  (b['logo'] as Map<String, dynamic>?)?['asset'] as String?,
              logoIsWordmark:
                  ((b['logo'] as Map<String, dynamic>?)?['wordmark']
                      as bool?) ??
                  false,
            ),
        ],
        aliases: [
          for (final a in _list(json['merchantAliases']))
            AliasRule(
              RegExp(
                r'(?<![a-z0-9])' +
                    RegExp.escape(a['match'] as String) +
                    r'(?![a-z0-9])',
                caseSensitive: false,
              ),
              a['name'] as String,
            ),
        ],
        noiseWords: {for (final w in _list(mn['noiseWords'])) w as String},
        acronyms: {for (final w in _list(mn['acronyms'])) w as String},
        genericLabels: {
          for (final w in _list(mn['genericLabels'])) w as String,
        },
        loanEmiLabel: _re(mn['loanEmiLabel'], const {}),
        nameTitles: {for (final w in _list(json['nameTitles'])) w as String},
        parser: ParserPatterns._(parserJson, vars),
        obligations: ObligationPatterns._(
          json['obligations'] as Map<String, dynamic>,
        ),
        canaries: [
          for (final c in _list(json['canaries']))
            RuleCanary(
              text: c['text'] as String,
              type: (c['expect'] as Map<String, dynamic>)['type'] as String?,
              amountMinor:
                  (c['expect'] as Map<String, dynamic>)['amountMinor'] as int?,
              merchantContains:
                  (c['expect'] as Map<String, dynamic>)['merchantContains']
                      as String?,
            ),
        ],
      );
    } on RulesFormatException {
      rethrow;
    } catch (e) {
      throw RulesFormatException('$e');
    }
  }

  /// The rules built into this version of the app.
  factory ParserRules.bundled() => ParserRules.fromJson(
    jsonDecode(kBundledRulesJson) as Map<String, dynamic>,
  );

  static ParserRules? _current;

  /// The rules in force. Starts as the built-in set.
  static ParserRules get current => _current ??= ParserRules.bundled();

  /// Replaces the rules in force (null restores the built-in set).
  static void use(ParserRules? rules) => _current = rules;

  final int schemaVersion;
  final int packVersion;

  /// SMS sender IDs (the `HDFCBK` of `VM-HDFCBK-S`) that are banks.
  final Set<String> senderCodes;

  /// Sender-ID prefix → display name, first match wins.
  final List<({String prefix, String name})> bankNames;

  /// Any `@x.<suffix>` sender is a bank (RBI's `bank.in`).
  final String emailSuffix;
  final List<String> emailDomains;

  /// Keyword groups in priority order (first match wins).
  final List<CategoryKeywords> categoryKeywords;
  final List<String> incomeWords;

  final List<BrandRule> brands;
  final List<AliasRule> aliases;
  final Set<String> noiseWords;
  final Set<String> acronyms;
  final Set<String> genericLabels;
  final RegExp loanEmiLabel;
  final Set<String> nameTitles;
  final ParserPatterns parser;
  final ObligationPatterns obligations;

  /// Sample messages with the result they must produce — a safety net for
  /// anyone changing the rules.
  final List<RuleCanary> canaries;

  /// Each keyword as a whole-word pattern, in priority order, paired with the
  /// category it points to.
  late final List<(RegExp, String)> categoryMatchers = [
    for (final group in categoryKeywords)
      for (final w in group.words)
        (
          RegExp(
            r'(?<![a-z0-9])' + RegExp.escape(w) + r'(?![a-z0-9])',
            caseSensitive: false,
          ),
          group.categoryId,
        ),
  ];

  /// Words that make a credit "Income" rather than "Other".
  late final RegExp incomePattern = RegExp(
    r'(?<![a-z0-9])(?:' + incomeWords.join('|') + r')(?![a-z0-9])',
    caseSensitive: false,
  );
}

class RuleCanary {
  const RuleCanary({
    required this.text,
    this.type,
    this.amountMinor,
    this.merchantContains,
  });
  final String text;
  final String? type;
  final int? amountMinor;
  final String? merchantContains;
}

List<dynamic> _list(Object? v) => v as List<dynamic>;

RegExp _re(Object? spec, Map<String, String> vars) {
  final m = spec as Map<String, dynamic>;
  var pattern = m['pattern'] as String;
  vars.forEach((k, v) => pattern = pattern.replaceAll('{$k}', v));
  final flags = (m['flags'] as String?) ?? '';
  try {
    return RegExp(
      pattern,
      caseSensitive: !flags.contains('i'),
      multiLine: flags.contains('m'),
      dotAll: flags.contains('s'),
    );
  } on FormatException catch (e) {
    throw RulesFormatException('bad pattern "$pattern": ${e.message}');
  }
}

List<PurposeLabel> _purposes(Object? spec, Map<String, String> vars) => [
  for (final e in _list(spec))
    (e as Map<String, dynamic>)['special'] == 'loan'
        ? const PurposeLabel(isLoan: true)
        : PurposeLabel(
            label: e['label'] as String,
            regex: _re({'pattern': e['pattern']}, vars),
          ),
];

RegExp _brandRegex(List<String> keywords) {
  final loose = [
    for (final k in keywords)
      if (!k.startsWith('=')) RegExp.escape(k),
  ];
  final exact = [
    for (final k in keywords)
      if (k.startsWith('=')) RegExp.escape(k.substring(1)),
  ];
  return RegExp(
    [
      if (loose.isNotEmpty) '(?<![a-z0-9])(?:${loose.join('|')})(?![a-z0-9])',
      if (exact.isNotEmpty) '^\\s*(?:${exact.join('|')})\\s*\$',
    ].join('|'),
    caseSensitive: false,
  );
}
