import 'dart:convert';

import 'package:http/http.dart' as http;

import '../import_window.dart';
import '../import_progress.dart';
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

  static const _fetchBatchSize = 8;
  static const _requestTimeout = Duration(seconds: 30);
  static const _apiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';

  /// Imports bank emails from [importCutoff] (1st of this month, a year
  /// ago) to now. Gmail returns at most 500 ids per page, so this follows
  /// `nextPageToken` until the window is exhausted or [maxMessages] is hit.
  Future<EmailImportResult> importRecent({
    int maxMessages = 1000,
    ImportProgressCallback? onProgress,
  }) async {
    onProgress?.call(const ImportProgress('Signing in to Google…'));
    final account = await _auth.currentAccount() ?? await _auth.signIn();
    var headers = await _auth.authHeaders(account);

    final cutoff = importCutoff();
    final afterDate =
        '${cutoff.year}/${cutoff.month.toString().padLeft(2, '0')}/${cutoff.day.toString().padLeft(2, '0')}';
    final query = Uri.encodeQueryComponent(bankEmailSearchQuery(afterDate));

    final messageRefs = <Map<String, dynamic>>[];
    String? pageToken;
    var reauthorized = false;
    do {
      final pageParam = pageToken == null ? '' : '&pageToken=$pageToken';
      final listUri = Uri.parse('$_apiBase/messages?maxResults=100&q=$query$pageParam');
      var listResponse = await http.get(listUri, headers: headers).timeout(_requestTimeout);

      // A 401/403 right after sign-in usually means the token was issued
      // before the Gmail permission took effect: ask again, once, then retry.
      if ((listResponse.statusCode == 401 || listResponse.statusCode == 403) && !reauthorized) {
        reauthorized = true;
        headers = await _auth.authHeaders(account);
        await Future<void>.delayed(const Duration(seconds: 2));
        listResponse = await http.get(listUri, headers: headers).timeout(_requestTimeout);
      }

      if (listResponse.statusCode != 200) {
        throw StateError(
          'Gmail list request failed (${listResponse.statusCode}: ${_errorReason(listResponse)})',
        );
      }
      final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;
      messageRefs.addAll((listJson['messages'] as List? ?? []).cast<Map<String, dynamic>>());
      pageToken = listJson['nextPageToken'] as String?;
      onProgress?.call(ImportProgress('Searching your inbox… ${messageRefs.length} bank emails found'));
    } while (pageToken != null && messageRefs.length < maxMessages);

    final total = messageRefs.length;
    onProgress?.call(ImportProgress('Reading bank emails', total: total));

    final session = await _ingestor.begin();
    // Fetch a handful of messages at a time — much faster than one by one —
    // then store them in order.
    for (var i = 0; i < total; i += _fetchBatchSize) {
      final chunk = messageRefs.skip(i).take(_fetchBatchSize);
      final details = await Future.wait(
        chunk.map((ref) => _fetchMessage(ref['id'] as String, headers)),
      );
      for (final detail in details) {
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
      onProgress?.call(ImportProgress(
        'Reading bank emails',
        done: (i + _fetchBatchSize).clamp(0, total),
        total: total,
        found: session.imported,
      ));
    }
    onProgress?.call(ImportProgress('Finishing up…', done: total, total: total, found: session.imported));
    await session.finish();

    return EmailImportResult(
      scanned: messageRefs.length,
      imported: session.imported,
      queued: session.queued,
    );
  }

  /// Google's own explanation of an error (e.g. `accessNotConfigured`,
  /// `insufficientPermissions`, `rateLimitExceeded`). Contains no mail content.
  String _errorReason(http.Response response) {
    try {
      final error = (jsonDecode(response.body) as Map<String, dynamic>)['error'] as Map<String, dynamic>;
      final errors = (error['errors'] as List?)?.cast<Map<String, dynamic>>();
      final reason = errors != null && errors.isNotEmpty ? errors.first['reason'] : error['status'];
      return '$reason';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<(String, int, String)?> _fetchMessage(
    String id,
    Map<String, String> headers,
  ) async {
    final uri = Uri.parse('$_apiBase/messages/$id?format=full');
    http.Response? response;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        response = await http.get(uri, headers: headers).timeout(_requestTimeout);
      } catch (_) {
        response = null; // timeout / network blip — try again
      }
      if (response != null && response.statusCode == 200) break;
      final rateLimited = response != null &&
          (response.statusCode == 429 ||
              (response.statusCode == 403 && _errorReason(response).toLowerCase().contains('rate')));
      if (response != null && !rateLimited && response.statusCode < 500) {
        return null; // a real refusal (e.g. message deleted) — skip it
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
    }
    if (response == null || response.statusCode != 200) return null;

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
