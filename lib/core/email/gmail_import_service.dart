import 'dart:convert';

import 'package:http/http.dart' as http;

import '../import_window.dart';
import '../ingest/transaction_ingestor.dart';
import 'bank_email_matcher.dart';
import 'gmail_auth_service.dart';

class EmailImportResult {
  const EmailImportResult({required this.scanned, required this.imported, this.queued = 0});
  final int scanned;
  final int imported;
  final int queued;
}

/// Fetches recent bank transaction emails directly from the Gmail REST API
/// — authenticated as the signed-in user, nothing passes through a server
/// of ours — and imports the ones that parse as transactions. Mirrors
/// [SmsImportService]'s shape closely.
class GmailImportService {
  GmailImportService(this._ingestor, this._auth);

  final TransactionIngestor _ingestor;
  final GmailAuthService _auth;

  static const _apiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';

  /// Imports bank emails from [importCutoff] (1st of this month, a year
  /// ago) to now. Gmail returns at most 500 ids per page, so this follows
  /// `nextPageToken` until the window is exhausted or [maxMessages] is hit.
  Future<EmailImportResult> importRecent({int maxMessages = 1000}) async {
    final account = await _auth.currentAccount() ?? await _auth.signIn();
    final headers = await _auth.authHeaders(account);

    final cutoff = importCutoff();
    final afterDate =
        '${cutoff.year}/${cutoff.month.toString().padLeft(2, '0')}/${cutoff.day.toString().padLeft(2, '0')}';
    final query = Uri.encodeQueryComponent('after:$afterDate (debited OR credited OR spent)');

    final messageRefs = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final pageParam = pageToken == null ? '' : '&pageToken=$pageToken';
      final listUri = Uri.parse('$_apiBase/messages?maxResults=100&q=$query$pageParam');
      final listResponse = await http.get(listUri, headers: headers);
      if (listResponse.statusCode != 200) {
        throw StateError('Gmail list request failed: ${listResponse.statusCode}');
      }
      final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;
      messageRefs.addAll((listJson['messages'] as List? ?? []).cast<Map<String, dynamic>>());
      pageToken = listJson['nextPageToken'] as String?;
    } while (pageToken != null && messageRefs.length < maxMessages);

    final session = await _ingestor.begin();
    for (final ref in messageRefs) {
      final detail = await _fetchMessage(ref['id'] as String, headers);
      if (detail == null) continue;

      final (from, dateMillis, body) = detail;
      if (!looksLikeBankEmail(from)) continue;

      await session.add(
        source: 'email',
        sender: from,
        body: body,
        date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      );
    }
    await session.finish();

    return EmailImportResult(
      scanned: messageRefs.length,
      imported: session.imported,
      queued: session.queued,
    );
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
