import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../intelligence/rule_matcher.dart';
import '../security/encryption_service.dart';
import '../sms/bank_sms_parser.dart'; // parseBankSms works on any plain-text body, SMS or email.
import 'bank_email_matcher.dart';
import 'gmail_auth_service.dart';

class EmailImportResult {
  const EmailImportResult({required this.scanned, required this.imported});
  final int scanned;
  final int imported;
}

/// Fetches recent bank transaction emails directly from the Gmail REST API
/// — authenticated as the signed-in user, nothing passes through a server
/// of ours — and imports the ones that parse as transactions. Mirrors
/// [SmsImportService]'s shape closely.
class GmailImportService {
  GmailImportService(this._db, this._encryption, this._auth);

  final AppDatabase _db;
  final EncryptionService _encryption;
  final GmailAuthService _auth;
  static const _uuid = Uuid();

  static const _apiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';

  Future<EmailImportResult> importRecent({int maxMessages = 50}) async {
    final account = await _auth.currentAccount() ?? await _auth.signIn();
    final headers = await _auth.authHeaders(account);

    final listUri = Uri.parse(
      '$_apiBase/messages?maxResults=$maxMessages&q=${Uri.encodeQueryComponent('newer_than:90d (debited OR credited OR spent)')}',
    );
    final listResponse = await http.get(listUri, headers: headers);
    if (listResponse.statusCode != 200) {
      throw StateError('Gmail list request failed: ${listResponse.statusCode}');
    }
    final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final messageRefs = (listJson['messages'] as List? ?? []).cast<Map<String, dynamic>>();

    final rules = await _db.select(_db.rules).get();
    var imported = 0;

    for (final ref in messageRefs) {
      final id = ref['id'] as String;
      final detail = await _fetchMessage(id, headers);
      if (detail == null) continue;

      final (from, dateMillis, body) = detail;
      if (!looksLikeBankEmail(from)) continue;

      final parsed = parseBankSms(body);
      if (parsed == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);
      final alreadyImported = await (_db.select(_db.transactions)
            ..where((t) =>
                t.source.equals('email') &
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
              source: 'email',
              categoryId: Value(categoryId),
              type: parsed.type,
              date: date,
              isInternational: Value(parsed.isInternational),
            ),
          );
      imported++;
    }

    return EmailImportResult(scanned: messageRefs.length, imported: imported);
  }

  Future<(String, int, String)?> _fetchMessage(
    String id,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse('$_apiBase/messages/$id?format=full');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final payload = json['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    final messageHeaders = (payload['headers'] as List? ?? []).cast<Map<String, dynamic>>();
    final from = messageHeaders
            .firstWhere((h) => h['name'] == 'From', orElse: () => const {})['value']
        as String? ??
        '';
    final internalDate = int.tryParse(json['internalDate'] as String? ?? '') ?? 0;

    final body = _extractPlainText(payload) ?? (json['snippet'] as String? ?? '');
    return (from, internalDate, body);
  }

  String? _extractPlainText(Map<String, dynamic> part) {
    final mimeType = part['mimeType'] as String?;
    final body = part['body'] as Map<String, dynamic>?;
    final data = body?['data'] as String?;

    if (mimeType == 'text/plain' && data != null) {
      return utf8.decode(base64Url.decode(base64Url.normalize(data)));
    }

    final parts = (part['parts'] as List?)?.cast<Map<String, dynamic>>();
    if (parts != null) {
      for (final child in parts) {
        final found = _extractPlainText(child);
        if (found != null) return found;
      }
    }
    return null;
  }
}
