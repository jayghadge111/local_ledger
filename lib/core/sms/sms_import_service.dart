import 'dart:io';

import 'package:another_telephony/telephony.dart' hide Value;
import 'package:permission_handler/permission_handler.dart';

import '../db/settings_repository.dart';
import '../import_progress.dart';
import '../import_window.dart';
import '../sync/import_checkpoints.dart';
import '../ingest/transaction_ingestor.dart';
import 'bank_sms_parser.dart';

class SmsImportResult {
  const SmsImportResult({
    required this.scanned,
    required this.imported,
    this.queued = 0,
    this.obligations = 0,
    this.cancelled = false,
  });
  final int scanned;
  final int imported;

  /// Auto-debit notices kept as upcoming debits (not spending).
  final int obligations;

  /// Bank messages that looked like transactions but couldn't be read —
  /// waiting in the review queue.
  final int queued;

  /// The user stopped the scan before it finished.
  final bool cancelled;
}

/// Reads the device's SMS inbox (Android only) and imports recognizable
/// bank transaction messages. Everything happens on-device: parsing runs
/// locally, and the original message is stored only as an AES-256-GCM
/// encrypted blob for later reference.
///
/// Syncing is incremental: each run records when it finished, and the next
/// one re-reads from a day before that. So a phone that kills background
/// work never leaves a gap — opening the app catches up on everything still
/// in the inbox.
class SmsImportService {
  SmsImportService(this._ingestor, this._settings);

  final TransactionIngestor _ingestor;
  final SettingsRepository _settings;
  final _telephony = Telephony.instance;

  bool _listening = false;
  bool _syncing = false;

  static const _minSyncGap = Duration(minutes: 10);
  static const _overlap = Duration(days: 1);

  bool get isSupported => Platform.isAndroid;

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<bool> get hasPermission async =>
      isSupported && await Permission.sms.isGranted;

  Future<DateTime?> lastSyncedAt() async {
    final raw = await _settings.get(SettingsKeys.smsLastSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Full import of the 1-year window — what the "Scan SMS inbox" button runs.
  ///
  /// [resume] carries on from where a stopped or interrupted scan got to.
  Future<SmsImportResult> importFromInbox({
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
    bool resume = false,
  }) => _import(
    since: null,
    onProgress: onProgress,
    cancel: cancel,
    resume: resume,
  );

  /// Silent catch-up for app start/resume: does nothing unless SMS access is
  /// already granted, auto-sync isn't switched off, and the last sync wasn't
  /// just now. Returns null when it didn't run.
  Future<SmsImportResult?> syncIfDue({
    bool force = false,
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
  }) async {
    if (!isSupported || _syncing) return null;
    if (await _settings.get(SettingsKeys.smsAutoSync) == 'false') return null;
    if (!await hasPermission) return null;

    final last = await lastSyncedAt();
    // A full scan the user stopped waits for them to resume it; opening the
    // app must not quietly start it over.
    if (last == null && await CheckpointStore(_settings).sms() != null) {
      return null;
    }
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minSyncGap) {
      return null;
    }

    return _import(since: last, onProgress: onProgress, cancel: cancel);
  }

  /// While the app is open, a newly arrived SMS triggers a sync straight
  /// away. (There is deliberately no background receiver — see class docs.)
  Future<void> listenForNewMessages(
    void Function(SmsImportResult) onImported,
  ) async {
    if (!isSupported || _listening || !await hasPermission) return;
    _listening = true;
    _telephony.listenIncomingSms(
      listenInBackground: false,
      onNewMessage: (_) async {
        final result = await syncIfDue(force: true);
        if (result != null && result.imported > 0) onImported(result);
      },
    );
  }

  Future<SmsImportResult> _import({
    required DateTime? since,
    ImportProgressCallback? onProgress,
    ImportCancelToken? cancel,
    bool resume = false,
  }) async {
    if (!isSupported) return const SmsImportResult(scanned: 0, imported: 0);
    _syncing = true;
    try {
      final windowStart = importCutoff();
      final from =
          since == null || since.subtract(_overlap).isBefore(windowStart)
          ? windowStart
          : since.subtract(_overlap);

      // Only a full scan is resumable; a catch-up is short enough to redo.
      final store = CheckpointStore(_settings);
      final fullScan = since == null;
      final previous = fullScan && resume ? await store.sms() : null;
      if (fullScan && !resume) await store.clearSms();
      final startedAt = previous?.startedAt ?? DateTime.now();

      onProgress?.call(const ImportProgress('Reading your messages…'));
      var filter = SmsFilter.where(SmsColumn.DATE)
          .greaterThanOrEqualTo(from.millisecondsSinceEpoch.toString());
      if (previous != null) {
        filter = filter
            .and(SmsColumn.DATE)
            .lessThanOrEqualTo(previous.beforeMillis.toString());
      }
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: filter,
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final offset = previous?.done ?? 0;
      final foundBefore = previous?.found ?? 0;
      final total = offset + messages.length;
      final session = await _ingestor.begin();
      var done = 0;
      var lastMillis = previous?.beforeMillis ?? 0;
      var cancelled = false;
      for (final message in messages) {
        done++;
        lastMillis = message.date ?? lastMillis;
        // Most messages aren't from banks and are skipped instantly, so
        // report (and let the UI redraw) every so often rather than per item.
        if (done % 150 == 0) {
          onProgress?.call(
            ImportProgress(
              'Scanning messages',
              done: offset + done,
              total: total,
              found: foundBefore + session.imported,
            ),
          );
          if (fullScan) {
            await store.saveSms(
              SmsCheckpoint(
                beforeMillis: lastMillis,
                done: offset + done,
                total: total,
                found: foundBefore + session.imported,
                startedAt: startedAt,
                savedAt: DateTime.now(),
              ),
            );
          }
          await Future<void>.delayed(Duration.zero);
          if (cancel?.isCancelled == true) {
            cancelled = true;
            break;
          }
        }
        final sender = message.address;
        final body = message.body;
        if (sender == null || body == null) continue;
        if (!looksLikeBankSender(sender)) continue;
        await session.add(
          source: 'sms',
          sender: sender,
          body: body,
          date: DateTime.fromMillisecondsSinceEpoch(message.date ?? 0),
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

      if (!cancelled) {
        await store.clearSms();
        // A resumed scan reads on from where the first one began, so the
        // next catch-up covers messages that arrived while it was paused.
        await _settings.set(
          SettingsKeys.smsLastSyncedAt,
          (fullScan ? startedAt : DateTime.now()).toIso8601String(),
        );
      }
      return SmsImportResult(
        scanned: offset + messages.length,
        imported: session.imported,
        queued: session.queued,
        obligations: session.obligations,
        cancelled: cancelled,
      );
    } finally {
      _syncing = false;
    }
  }
}
