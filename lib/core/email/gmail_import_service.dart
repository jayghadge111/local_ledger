import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInAccount;
import 'package:http/http.dart' as http;

import '../diagnostics/diagnostic_log.dart';
import '../import_window.dart';
import '../db/settings_repository.dart';
import '../import_progress.dart';
import '../sync/import_checkpoints.dart';
import '../obligations/obligation_parser.dart';
import '../sms/bank_sms_parser.dart';
import 'html_text.dart';
import '../ingest/transaction_ingestor.dart';
import 'bank_email_matcher.dart';
import 'gmail_auth_service.dart';

class EmailImportResult {
  const EmailImportResult({
    required this.scanned,
    required this.imported,
    this.queued = 0,
    this.obligations = 0,
    this.notRecognised = 0,
    this.unreadable = 0,
    this.duplicates = 0,
    this.cancelled = false,
  });
  final int scanned;
  final int imported;

  /// Looked like a transaction but couldn't be read — in the review queue.
  final int queued;

  /// Auto-debit notices kept as upcoming debits (not spending).
  final int obligations;

  /// Read fine but isn't a transaction alert (OTP, promo, statement notice).
  final int notRecognised;

  /// Couldn't be downloaded or had no readable text.
  final int unreadable;

  /// Already in the app (imported earlier, or also seen by SMS).
  final int duplicates;

  /// The user stopped the import before it finished.
  final bool cancelled;
}

/// Fetches recent bank transaction emails directly from the Gmail REST API
/// — authenticated as the signed-in user, nothing passes through a server
/// of ours — and imports the ones that parse as transactions. Mirrors
/// [SmsImportService]'s shape closely.
class GmailImportService {
  GmailImportService(this._ingestor, this._auth, this._settings);

  final TransactionIngestor _ingestor;
  final GmailAuthService _auth;
  final SettingsRepository _settings;

  static const _fetchBatchSize = 8;
  static const _requestTimeout = Duration(seconds: 30);
  static const _apiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';

  /// Imports bank emails from [importCutoff] (1st of this month, a year
  /// ago) to now. Gmail returns at most 500 ids per page, so this follows
  /// `nextPageToken` until the window is exhausted or [maxMessages] is hit.
  Future<EmailImportResult> importRecent({
    GoogleSignInAccount? account,
    int maxMessages = 1000,
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,

    /// Carry on from where a stopped or interrupted run left off, skipping
    /// the emails it already handled.
    bool resume = false,

    /// Only mail from about this time on (a catch-up), not the whole window.
    DateTime? since,

    /// A scan the user didn't ask for: shows no Google screen, and keeps no
    /// checkpoint (it is short, and not worth a "resume" card).
    bool quiet = false,
  }) async {
    onProgress?.call(
      ImportProgress(quiet ? 'Checking for new bank emails…' : 'Signing in to Google…'),
    );
    final signedIn =
        account ?? await _auth.currentAccount() ?? await _auth.signIn();
    var headers = await _auth.authHeaders(signedIn, interactive: !quiet);

    var cutoff = importCutoff();
    if (since != null) {
      // Gmail's `after:` works on whole days; a day of overlap is harmless
      // because anything already stored is recognised and skipped.
      final from = DateTime(since.year, since.month, since.day - 1);
      if (from.isAfter(cutoff)) cutoff = from;
    }
    final afterDate =
        '${cutoff.year}/${cutoff.month.toString().padLeft(2, '0')}/${cutoff.day.toString().padLeft(2, '0')}';
    final extraDomains =
        ((await _settings.get(SettingsKeys.customBankEmailDomains)) ?? '')
            .split(',')
            .where((d) => d.isNotEmpty)
            .toList();
    final query = Uri.encodeQueryComponent(
      bankEmailSearchQuery(afterDate, extraDomains: extraDomains),
    );

    final messageRefs = <Map<String, dynamic>>[];
    String? pageToken;
    var reauthorized = false;
    do {
      final pageParam = pageToken == null ? '' : '&pageToken=$pageToken';
      final listUri = Uri.parse(
        '$_apiBase/messages?maxResults=100&q=$query$pageParam',
      );
      var listResponse = await http
          .get(listUri, headers: headers)
          .timeout(_requestTimeout);

      // A 401/403 right after sign-in usually means the token was issued
      // before the Gmail permission took effect: ask again, once, then retry.
      if ((listResponse.statusCode == 401 || listResponse.statusCode == 403) &&
          !reauthorized) {
        reauthorized = true;
        headers = await _auth.authHeaders(signedIn, interactive: !quiet);
        await Future<void>.delayed(const Duration(seconds: 2));
        listResponse = await http
            .get(listUri, headers: headers)
            .timeout(_requestTimeout);
      }

      if (listResponse.statusCode == 401) {
        throw const GmailAccessException('401');
      }
      if (listResponse.statusCode != 200) {
        throw StateError(
          'Gmail list request failed (${listResponse.statusCode}: ${_errorReason(listResponse)})',
        );
      }
      final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;
      messageRefs.addAll(
        (listJson['messages'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
      pageToken = listJson['nextPageToken'] as String?;
      onProgress?.call(
        ImportProgress(
          'Searching your inbox… ${messageRefs.length} bank emails found',
        ),
      );
    } while (pageToken != null && messageRefs.length < maxMessages);

    final total = messageRefs.length;
    final store = CheckpointStore(_settings);
    final previous = resume && !quiet ? await store.gmail() : null;
    if (!resume && !quiet) await store.clearGmail();
    final doneIds = <String>{...?previous?.doneIds};
    final pending = [
      for (final r in messageRefs)
        if (!doneIds.contains(r['id'])) r,
    ];
    final alreadyDone = total - pending.length;
    final foundBefore = previous?.found ?? 0;
    onProgress?.call(
      ImportProgress(
        'Reading bank emails',
        done: alreadyDone,
        total: total,
        found: foundBefore,
      ),
    );

    var unreadable = 0;
    var cancelled = false;
    final session = await _ingestor.begin();
    // Fetch a handful of messages at a time — much faster than one by one —
    // then store them in order.
    for (var i = 0; i < pending.length; i += _fetchBatchSize) {
      if (cancel?.isCancelled == true) {
        cancelled = true;
        break;
      }
      final chunk = pending.skip(i).take(_fetchBatchSize).toList();
      final details = await Future.wait(
        chunk.map((ref) => _fetchMessage(ref['id'] as String, headers)),
      );
      for (final detail in details) {
        if (detail == null) {
          unreadable++;
          continue;
        }
        final (from, dateMillis, body) = detail;
        if (!looksLikeBankEmail(from, extraDomains: extraDomains)) continue;
        await session.add(
          source: 'email',
          sender: from,
          body: body,
          date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
        );
      }
      doneIds.addAll(chunk.map((r) => r['id'] as String));
      if (!quiet) {
        await store.saveGmail(
          GmailCheckpoint(
            doneIds: doneIds,
            total: total,
            found: foundBefore + session.imported,
            savedAt: DateTime.now(),
          ),
        );
      }
      onProgress?.call(
        ImportProgress(
          'Reading bank emails',
          done: doneIds.length.clamp(0, total),
          total: total,
          found: foundBefore + session.imported,
        ),
      );
    }
    if (!cancelled) {
      onProgress?.call(
        ImportProgress(
          'Finishing up…',
          done: total,
          total: total,
          found: foundBefore + session.imported,
        ),
      );
    }
    await session.finish();
    if (!cancelled && !quiet) await store.clearGmail();

    return EmailImportResult(
      cancelled: cancelled,
      scanned: messageRefs.length,
      imported: session.imported,
      queued: session.queued,
      obligations: session.obligations,
      notRecognised: session.skipped,
      unreadable: unreadable,
      duplicates: session.duplicates,
    );
  }

  /// The quiet catch-up for app open: reads only mail that arrived since
  /// [since], using the sign-in Google already holds. Returns null when it
  /// can't do that without asking the user (no saved sign-in), and throws
  /// [GmailAccessException] when Google now wants consent again — it never
  /// shows a sign-in or consent screen itself.
  Future<EmailImportResult?> importSince(
    DateTime since, {
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
  }) async {
    final account = await _auth.currentAccount();
    if (account == null) return null;
    return importRecent(
      account: account,
      since: since,
      quiet: true,
      onProgress: onProgress,
      cancel: cancel,
    );
  }

  /// Google's own explanation of an error (e.g. `accessNotConfigured`,
  /// `insufficientPermissions`, `rateLimitExceeded`). Contains no mail content.
  String _errorReason(http.Response response) {
    try {
      final error =
          (jsonDecode(response.body) as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      final errors = (error['errors'] as List?)?.cast<Map<String, dynamic>>();
      final reason = errors != null && errors.isNotEmpty
          ? errors.first['reason']
          : error['status'];
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
        response = await http
            .get(uri, headers: headers)
            .timeout(_requestTimeout);
      } catch (_) {
        response = null; // timeout / network blip — try again
      }
      if (response != null && response.statusCode == 200) break;
      // The sign-in stopped working part-way (access revoked, token expired):
      // stop and say so, rather than counting every remaining email as
      // unreadable.
      if (response != null && response.statusCode == 401) {
        throw const GmailAccessException('401');
      }
      final rateLimited =
          response != null &&
          (response.statusCode == 429 ||
              (response.statusCode == 403 &&
                  _errorReason(response).toLowerCase().contains('rate')));
      if (response != null && !rateLimited && response.statusCode < 500) {
        return null; // a real refusal (e.g. message deleted) — skip it
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
    }
    if (response == null || response.statusCode != 200) return null;

    try {
      return _readMessage(response.body);
    } catch (error, stack) {
      // One email in an unexpected shape must not stop the import.
      DiagnosticLog.instance.record(
        'gmail',
        error,
        stack,
        'reading an email ($id)',
      );
      return null;
    }
  }

  (String, int, String)? _readMessage(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final payload = json['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    final messageHeaders = (payload['headers'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final from =
        messageHeaders.firstWhere(
              (h) => h['name'] == 'From',
              orElse: () => const {},
            )['value']
            as String? ??
        '';
    final internalDate =
        int.tryParse(json['internalDate'] as String? ?? '') ?? 0;

    final plain = _extractPart(payload, 'text/plain');
    final html = _extractPart(payload, 'text/html');
    final snippet = json['snippet'] as String? ?? '';
    final subject =
        messageHeaders.firstWhere(
              (h) => h['name'] == 'Subject',
              orElse: () => const {},
            )['value']
            as String? ??
        '';

    // An auto-debit notice (mandate set-up, pre-debit advice, EMI or card
    // bill) has no single "transaction sentence" to focus on, and its subject
    // often carries the key fact ("Successful Registration of e-Mandate -
    // UMRN …"). Keep the subject and the whole readable body.
    final notice = _noticeText(subject, plain, html, snippet);
    if (notice != null) return (from, internalDate, notice);

    // Prefer the plain part; many bank alerts are HTML-only, so fall back to
    // the HTML turned into text. Keep just the sentence that reports the
    // transaction — the rest is greeting and footer boilerplate.
    var body = focusTransactionText(
      plain ?? (html != null ? htmlToText(html) : snippet),
    );
    if (parseBankSms(body) == null && html != null) {
      final fromHtml = focusTransactionText(htmlToText(html));
      if (parseBankSms(fromHtml) != null) body = fromHtml;
    }
    if (body.isEmpty) return null;
    return (from, internalDate, body);
  }

  static const _noticeLimit = 2500;

  String? _noticeText(
    String subject,
    String? plain,
    String? html,
    String snippet,
  ) {
    for (final text in [plain, if (html != null) htmlToText(html), snippet]) {
      if (text == null || text.trim().isEmpty) continue;
      final flat = '$subject. $text'.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (classifyObligation(flat) != null) {
        return flat.length > _noticeLimit
            ? flat.substring(0, _noticeLimit)
            : flat;
      }
    }
    return null;
  }

  String? _extractPart(Map<String, dynamic> part, String wantedMime) {
    final mimeType = part['mimeType'] as String?;
    final data = (part['body'] as Map<String, dynamic>?)?['data'] as String?;
    if (mimeType == wantedMime && data != null) {
      return utf8.decode(
        base64Url.decode(base64Url.normalize(data)),
        allowMalformed: true,
      );
    }
    for (final child
        in (part['parts'] as List?)?.cast<Map<String, dynamic>>() ?? const []) {
      final found = _extractPart(child, wantedMime);
      if (found != null) return found;
    }
    return null;
  }
}
