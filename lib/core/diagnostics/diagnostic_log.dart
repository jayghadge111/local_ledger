import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../brand.dart';

/// One recorded problem.
class DiagnosticEntry {
  const DiagnosticEntry({
    required this.at,
    required this.source,
    required this.message,
    this.stack,
    this.note,
  });

  final DateTime at;

  /// Where it was caught: `flutter`, `platform`, `zone`, `ingest`, …
  final String source;
  final String message;
  final String? stack;
  final String? note;

  Map<String, Object?> toJson() => {
    't': at.toIso8601String(),
    's': source,
    'm': message,
    if (stack != null) 'k': stack,
    if (note != null) 'n': note,
  };

  static DiagnosticEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['t']}');
    if (at == null) return null;
    return DiagnosticEntry(
      at: at,
      source: '${json['s']}',
      message: '${json['m']}',
      stack: json['k'] as String?,
      note: json['n'] as String?,
    );
  }
}

/// A small on-device error log, so a crash or a swallowed error can be looked
/// at (and sent by the user on purpose) after the fact.
///
/// It is a plain file rather than a database table because the problems worth
/// logging include the database failing to open. It never touches the
/// network; the only way anything leaves the phone is the user pressing
/// "Email diagnostic log".
///
/// What is kept is the error text and stack trace only. Anything that looks
/// like a phone/account number, an email address or an amount is blanked out
/// first, since an exception message can quote the text it choked on.
///
/// [record] never throws, whatever state the log is in.
class DiagnosticLog {
  DiagnosticLog._();
  static final DiagnosticLog instance = DiagnosticLog._();

  /// A fresh log in [dir], for tests.
  DiagnosticLog.inDirectory(Directory dir) : _dir = dir;

  static const _fileName = 'diagnostics.jsonl';
  static const maxEntries = 100;
  static const _maxBytes = 200 * 1024;
  static const _maxMessage = 400;
  static const _maxStackLines = 25;

  Directory? _dir;
  File? _file;
  bool _initialising = false;
  final _before = <DiagnosticEntry>[];
  String? _lastSignature;
  DateTime? _lastAt;

  /// Finds the log file. Safe to call more than once; errors that arrive
  /// before it finishes are kept in memory and written once it has.
  Future<void> init() async {
    if (_file != null || _initialising) return;
    _initialising = true;
    try {
      final dir = _dir ?? await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      _file = File(p.join(dir.path, _fileName));
      for (final e in _before) {
        _append(e);
      }
      _before.clear();
    } catch (e) {
      debugPrint('Diagnostic log unavailable: $e');
    } finally {
      _initialising = false;
    }
  }

  /// Notes a problem. Identical errors repeated within a couple of seconds
  /// (a widget failing on every frame, say) are written once.
  void record(String source, Object error, [StackTrace? stack, String? note]) {
    try {
      final message = redact('$error', maxLength: _maxMessage);
      final trace = stack == null ? null : _shortStack(stack);
      final signature = '$source|$message|${trace?.split('\n').first}';
      final now = DateTime.now();
      if (signature == _lastSignature &&
          _lastAt != null &&
          now.difference(_lastAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastSignature = signature;
      _lastAt = now;

      final entry = DiagnosticEntry(
        at: now,
        source: source,
        message: message,
        stack: trace,
        note: note == null ? null : redact(note, maxLength: 200),
      );
      debugPrint('[diagnostic:$source] $message');
      if (_file == null) {
        if (_before.length < maxEntries) _before.add(entry);
        return;
      }
      _append(entry);
    } catch (_) {
      // Logging must never be the thing that fails.
    }
  }

  void _append(DiagnosticEntry entry) {
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
      if (file.lengthSync() > _maxBytes) _trim(file);
    } catch (_) {}
  }

  void _trim(File file) {
    final lines = file
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final keep = lines.length > maxEntries / 2
        ? lines.sublist(lines.length - maxEntries ~/ 2)
        : lines;
    file.writeAsStringSync('${keep.join('\n')}\n', flush: true);
  }

  /// Newest first.
  Future<List<DiagnosticEntry>> entries() async {
    final all = <DiagnosticEntry>[..._before];
    final file = _file;
    if (file != null && file.existsSync()) {
      try {
        for (final line in await file.readAsLines()) {
          if (line.trim().isEmpty) continue;
          try {
            final e = DiagnosticEntry.fromJson(jsonDecode(line));
            if (e != null) all.add(e);
          } catch (_) {}
        }
      } catch (_) {}
    }
    all.sort((a, b) => b.at.compareTo(a.at));
    return all.length > maxEntries ? all.sublist(0, maxEntries) : all;
  }

  Future<void> clear() async {
    _before.clear();
    _lastSignature = null;
    try {
      final file = _file;
      if (file != null && file.existsSync()) await file.writeAsString('');
    } catch (_) {}
  }

  /// The text the user shares. [extra] is for lines the caller knows (app
  /// version, database version…).
  Future<String> report({Map<String, String> extra = const {}}) async {
    final list = await entries();
    final b = StringBuffer()
      ..writeln('$kAppName diagnostic log')
      ..writeln('Created: ${DateTime.now().toIso8601String()}')
      ..writeln(
        'Platform: ${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion}',
      )
      ..writeln('Locale: ${Platform.localeName}');
    extra.forEach((k, v) => b.writeln('$k: $v'));
    b
      ..writeln('Entries: ${list.length}')
      ..writeln()
      ..writeln(
        'This file holds error messages and stack traces only. Numbers, '
        'emails and amounts are blanked out. It has no transactions, '
        'messages or account details.',
      )
      ..writeln();
    for (final e in list) {
      b.writeln('--- ${e.at.toIso8601String()}  [${e.source}]');
      b.writeln(e.message);
      if (e.note != null) b.writeln('Context: ${e.note}');
      if (e.stack != null) b.writeln(e.stack);
      b.writeln();
    }
    return b.toString();
  }

  String _shortStack(StackTrace stack) {
    final lines = stack
        .toString()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(_maxStackLines);
    return redact(lines.join('\n'));
  }
}

final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
final _longNumber = RegExp(r'\d{5,}');
final _amount = RegExp(
  r'(?:rs\.?|inr|₹)\s*\d[\d,]*(?:\.\d+)?',
  caseSensitive: false,
);
final _maskedAccount = RegExp(r'[xX*]{2,}\d{2,}');

/// Blanks out what could identify the user or their money. Line numbers in
/// stack frames are 1-4 digits, so they survive.
String redact(String text, {int? maxLength}) {
  var out = text
      .replaceAll(_email, '<email>')
      .replaceAll(_amount, '<amount>')
      .replaceAll(_maskedAccount, '<acct>')
      .replaceAll(_longNumber, '<num>');
  if (maxLength != null && out.length > maxLength) {
    out = '${out.substring(0, maxLength)}…';
  }
  return out;
}
