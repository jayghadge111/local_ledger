import 'dart:io';

import 'package:another_telephony/telephony.dart' hide Value;
import 'package:drift/drift.dart' hide OrderBy;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../intelligence/rule_matcher.dart';
import '../security/encryption_service.dart';
import 'bank_sms_parser.dart';

class SmsImportResult {
  const SmsImportResult({required this.scanned, required this.imported});
  final int scanned;
  final int imported;
}

/// Reads the device's SMS inbox (Android only) and imports recognizable
/// bank transaction messages. Everything happens on-device: parsing runs
/// locally, and the original message is stored only as an AES-256-GCM
/// encrypted blob (see [EncryptionService]) for later reference.
class SmsImportService {
  SmsImportService(this._db, this._encryption);

  final AppDatabase _db;
  final EncryptionService _encryption;
  final _telephony = Telephony.instance;
  static const _uuid = Uuid();

  bool get isSupported => Platform.isAndroid;

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<SmsImportResult> importFromInbox() async {
    if (!isSupported) return const SmsImportResult(scanned: 0, imported: 0);

    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final rules = await _db.select(_db.rules).get();
    var imported = 0;

    for (final message in messages) {
      final sender = message.address;
      final body = message.body;
      if (sender == null || body == null) continue;
      if (!looksLikeBankSender(sender)) continue;

      final parsed = parseBankSms(body);
      if (parsed == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

      final alreadyImported = await (_db.select(_db.transactions)
            ..where((t) =>
                t.source.equals('sms') &
                t.amountMinor.equals(parsed.amountMinor) &
                t.date.equals(date)))
          .getSingleOrNull();
      if (alreadyImported != null) continue;

      final categoryId = matchCategoryForMerchant(parsed.merchant, rules) ?? 'cat_other';
      final encryptedBody = await _encryption.encryptString(body);

      await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: _uuid.v4(),
              amountMinor: parsed.amountMinor,
              merchant: parsed.merchant,
              rawTextEncrypted: Value(encryptedBody),
              source: 'sms',
              categoryId: Value(categoryId),
              type: parsed.type,
              date: date,
              isInternational: Value(parsed.isInternational),
            ),
          );
      imported++;
    }

    return SmsImportResult(scanned: messages.length, imported: imported);
  }
}
