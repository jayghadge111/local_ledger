import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../intelligence/merchant_normalizer.dart';
import '../intelligence/rule_matcher.dart';
import '../security/encryption_service.dart';
import '../sms/bank_names.dart';
import '../sms/bank_sms_parser.dart';
import 'reconciler.dart';

enum IngestOutcome { imported, duplicate, queued, skipped }

/// The one place SMS and email messages become stored transactions:
/// parse, drop duplicates, resolve the account, clean the merchant name,
/// categorize, encrypt the original text and insert.
class TransactionIngestor {
  TransactionIngestor(this._db, this._encryption);

  final AppDatabase _db;
  final EncryptionService _encryption;

  Future<IngestSession> begin() async {
    final rules = await _db.select(_db.rules).get();
    final aliasRows = await _db.select(_db.merchantAliases).get();
    final accounts = await _db.select(_db.accounts).get();
    return IngestSession._(
      this,
      rules,
      {for (final a in aliasRows) a.pattern: a.displayName},
      {for (final a in accounts) if (a.bankName != null && a.last4 != null) '${a.bankName}|${a.last4}': a},
    );
  }
}

class IngestSession {
  IngestSession._(this._owner, this._rules, this._aliases, this._accounts);

  final TransactionIngestor _owner;
  final List<Rule> _rules;
  final Map<String, String> _aliases;
  final Map<String, Account> _accounts;

  static const _uuid = Uuid();
  static const _placeholders = {'Credit', 'Unknown merchant'};

  int imported = 0;
  int duplicates = 0;
  int queued = 0;

  /// Existing rows corrected because the parser now reads them differently.
  int repaired = 0;

  AppDatabase get _db => _owner._db;

  String _hash(String source, String body, DateTime date) => sha512
      .convert(utf8.encode('$source|${body.trim()}|${date.millisecondsSinceEpoch}'))
      .toString();

  Future<IngestOutcome> add({
    required String source,
    required String sender,
    required String body,
    required DateTime date,
  }) async {
    final hash = _hash(source, body, date);
    final parsed = parseBankSms(body);

    if (parsed == null) {
      if (!looksLikeUnparsedTransaction(body)) return IngestOutcome.skipped;
      return _queue(source, sender, body, date, hash);
    }

    final raw = _placeholders.contains(parsed.merchant) ? null : parsed.merchant;
    final display = raw == null ? parsed.merchant : normalizeMerchant(raw, userAliases: _aliases);

    final sameHash = await (_db.select(_db.transactions)
          ..where((t) => t.sourceHash.equals(hash)))
        .getSingleOrNull();
    if (sameHash != null) {
      // Already imported. If the parser has improved since, correct the
      // stored row — unless the user has edited it themselves.
      if (!sameHash.userEdited) await _repair(sameHash, parsed, raw, display, sender, body);
      duplicates++;
      return IngestOutcome.duplicate;
    }

    // The same transaction reported by both SMS and email.
    final sameAmount = await (_db.select(_db.transactions)
          ..where((t) =>
              t.amountMinor.equals(parsed.amountMinor) &
              t.isDeleted.equals(false) &
              t.source.equals(source).not()))
        .get();
    final crossSource = sameAmount.any((t) =>
        t.type == parsed.type &&
        t.currency == parsed.currency &&
        t.date.difference(date).abs() <= const Duration(minutes: 5));
    if (crossSource) {
      duplicates++;
      return IngestOutcome.duplicate;
    }

    final categoryId = matchCategoryForMerchant(display, _rules) ??
        (raw == null ? null : matchCategoryForMerchant(raw, _rules)) ??
        'cat_other';

    await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            accountId: Value(await _accountFor(sender, parsed, body)),
            amountMinor: parsed.amountMinor,
            currency: Value(parsed.currency),
            merchant: display,
            rawMerchant: Value(raw),
            rawTextEncrypted: Value(await _owner._encryption.encryptString(body)),
            source: source,
            categoryId: Value(categoryId),
            type: parsed.type,
            date: date,
            isInternational: Value(parsed.isInternational),
            refundHint: Value(parsed.refundHint),
            sourceHash: Value(hash),
          ),
        );
    imported++;
    return IngestOutcome.imported;
  }

  Future<void> _repair(
    Transaction existing,
    ParsedSmsTransaction parsed,
    String? raw,
    String display,
    String sender,
    String body,
  ) async {
    final changed = existing.type != parsed.type ||
        existing.amountMinor != parsed.amountMinor ||
        existing.currency != parsed.currency ||
        existing.merchant != display ||
        existing.rawMerchant != raw ||
        existing.isInternational != parsed.isInternational;
    if (!changed) return;

    final typeChanged = existing.type != parsed.type;
    await (_db.update(_db.transactions)..where((t) => t.id.equals(existing.id))).write(
      TransactionsCompanion(
        type: Value(parsed.type),
        amountMinor: Value(parsed.amountMinor),
        currency: Value(parsed.currency),
        merchant: Value(display),
        rawMerchant: Value(raw),
        isInternational: Value(parsed.isInternational),
        refundHint: Value(parsed.refundHint),
        accountId: Value(await _accountFor(sender, parsed, body) ?? existing.accountId),
        // A flipped debit/credit invalidates any transfer/refund link made
        // from the wrong reading; the reconciler re-evaluates it.
        kind: typeChanged && !existing.kindLocked ? const Value('normal') : const Value.absent(),
        transferGroupId: typeChanged && !existing.kindLocked ? const Value(null) : const Value.absent(),
        refundOfId: typeChanged && !existing.kindLocked ? const Value(null) : const Value.absent(),
      ),
    );
    repaired++;
  }

  Future<IngestOutcome> _queue(
    String source,
    String sender,
    String body,
    DateTime date,
    String hash,
  ) async {
    final existing = await (_db.select(_db.unparsedMessages)
          ..where((t) => t.hash.equals(hash)))
        .getSingleOrNull();
    if (existing != null) return IngestOutcome.duplicate;
    await _db.into(_db.unparsedMessages).insert(
          UnparsedMessagesCompanion.insert(
            id: _uuid.v4(),
            source: source,
            senderCode: Value(bankCodeOf(sender)),
            rawTextEncrypted: await _owner._encryption.encryptString(body),
            hash: hash,
            receivedAt: date,
          ),
        );
    queued++;
    return IngestOutcome.queued;
  }

  static const _kindLabels = {
    'forex': 'Forex Card',
    'prepaid': 'Prepaid Card',
    'credit_card': 'Credit Card',
    'debit_card': 'Debit Card',
    'card': 'Card',
  };

  Future<String?> _accountFor(String sender, ParsedSmsTransaction parsed, String body) async {
    final last4 = parsed.last4;
    if (last4 == null) return null;
    final bank = bankDisplayName(sender);
    final key = '$bank|$last4';
    final kind = parsed.accountKind ?? 'bank';
    final label = _kindLabels[kind];
    final name = label == null ? '$bank •••• $last4' : '$bank $label •••• $last4';

    final existing = _accounts[key];
    if (existing != null) {
      // A later message may say what the account really is (e.g. a forex
      // card first seen as a generic card) — keep the most specific.
      final moreSpecific = kind != 'bank' && kind != 'card' && existing.accountType != kind;
      if (!moreSpecific) return existing.id;
      await (_db.update(_db.accounts)..where((a) => a.id.equals(existing.id)))
          .write(AccountsCompanion(name: Value(name), accountType: Value(kind)));
      _accounts[key] = existing.copyWith(name: name, accountType: kind);
      return existing.id;
    }

    final id = _uuid.v4();
    await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            id: id,
            name: name,
            accountType: kind,
            bankName: Value(bank),
            last4: Value(last4),
          ),
        );
    _accounts[key] = Account(
      id: id,
      name: name,
      bankName: bank,
      last4: last4,
      accountType: kind,
      createdAt: DateTime.now(),
    );
    return id;
  }

  /// Call once after the last [add]: links transfers and refunds.
  Future<ReconcileResult> finish() => Reconciler(_db).run();
}
