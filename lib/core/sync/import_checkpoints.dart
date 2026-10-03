import 'dart:convert';

import '../db/settings_repository.dart';

/// A checkpoint older than this is ignored: the user would rather re-scan
/// than resume something started last month.
const _maxAge = Duration(days: 7);

/// Where an interrupted Gmail import got to: the messages already handled.
class GmailCheckpoint {
  const GmailCheckpoint({
    required this.doneIds,
    required this.total,
    required this.found,
    required this.savedAt,
  });

  final Set<String> doneIds;
  final int total;

  /// Transactions added by the run(s) so far.
  final int found;
  final DateTime savedAt;

  String encode() => jsonEncode({
    'ids': doneIds.toList(),
    'total': total,
    'found': found,
    'at': savedAt.toIso8601String(),
  });

  static GmailCheckpoint? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(m['at'] as String);
      if (DateTime.now().difference(at) > _maxAge) return null;
      return GmailCheckpoint(
        doneIds: (m['ids'] as List).cast<String>().toSet(),
        total: m['total'] as int,
        found: m['found'] as int,
        savedAt: at,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Where an interrupted full SMS scan got to. Messages are read newest
/// first, so resuming means "everything at or before [beforeMillis]".
class SmsCheckpoint {
  const SmsCheckpoint({
    required this.beforeMillis,
    required this.done,
    required this.total,
    required this.found,
    required this.startedAt,
    required this.savedAt,
  });

  final int beforeMillis;
  final int done;
  final int total;
  final int found;

  /// When the scan first began; the catch-up afterwards starts from here so
  /// messages that arrived while it was paused aren't missed.
  final DateTime startedAt;
  final DateTime savedAt;

  String encode() => jsonEncode({
    'before': beforeMillis,
    'done': done,
    'total': total,
    'found': found,
    'started': startedAt.toIso8601String(),
    'at': savedAt.toIso8601String(),
  });

  static SmsCheckpoint? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(m['at'] as String);
      if (DateTime.now().difference(at) > _maxAge) return null;
      return SmsCheckpoint(
        beforeMillis: m['before'] as int,
        done: m['done'] as int,
        total: m['total'] as int,
        found: m['found'] as int,
        startedAt: DateTime.parse(m['started'] as String),
        savedAt: at,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Reads and writes import checkpoints in the local settings table, so a
/// stopped or killed import can carry on instead of starting over.
class CheckpointStore {
  CheckpointStore(this._settings);
  final SettingsRepository _settings;

  Future<GmailCheckpoint?> gmail() async =>
      GmailCheckpoint.decode(await _settings.get(SettingsKeys.gmailCheckpoint));
  Future<void> saveGmail(GmailCheckpoint c) =>
      _settings.set(SettingsKeys.gmailCheckpoint, c.encode());
  Future<void> clearGmail() => _settings.remove(SettingsKeys.gmailCheckpoint);

  Future<SmsCheckpoint?> sms() async =>
      SmsCheckpoint.decode(await _settings.get(SettingsKeys.smsCheckpoint));
  Future<void> saveSms(SmsCheckpoint c) =>
      _settings.set(SettingsKeys.smsCheckpoint, c.encode());
  Future<void> clearSms() => _settings.remove(SettingsKeys.smsCheckpoint);
}
