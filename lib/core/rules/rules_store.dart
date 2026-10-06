import 'dart:io';

import 'package:path/path.dart' as p;

/// The rules downloaded earlier, kept on the device: the one in use and the
/// one before it (to roll back to), plus a count of start-ups that did not get
/// as far as drawing the first screen.
///
/// What is stored is the signed envelope exactly as downloaded, so it is
/// checked again every time it is loaded.
class RulesStore {
  RulesStore(this.directory);

  final Directory directory;

  File get _active => File(p.join(directory.path, 'rules_active.json'));
  File get _previous => File(p.join(directory.path, 'rules_previous.json'));
  File get _boot => File(p.join(directory.path, 'rules_boot.txt'));

  String? readActive() => _read(_active);
  String? readPrevious() => _read(_previous);

  String? _read(File f) {
    try {
      return f.existsSync() ? f.readAsStringSync() : null;
    } catch (_) {
      return null;
    }
  }

  void _ensure() {
    if (!directory.existsSync()) directory.createSync(recursive: true);
  }

  /// Makes [envelope] the active rules; what was active becomes the previous.
  void install(String envelope) {
    _ensure();
    final current = readActive();
    // Write the new file before touching the old ones, so a crash part-way
    // leaves a usable set.
    final incoming = File('${_active.path}.new')
      ..writeAsStringSync(envelope, flush: true);
    if (current != null) _previous.writeAsStringSync(current, flush: true);
    incoming.renameSync(_active.path);
    resetBootAttempts();
  }

  /// Brings the previous rules back as the active ones and drops the faulty
  /// ones. False if there is no previous set.
  bool rollback() {
    final previous = readPrevious();
    if (previous == null) {
      clear();
      return false;
    }
    _ensure();
    _active.writeAsStringSync(previous, flush: true);
    try {
      _previous.deleteSync();
    } catch (_) {}
    resetBootAttempts();
    return true;
  }

  /// Forgets every downloaded set; the rules built into the app apply.
  void clear() {
    for (final f in [_active, _previous, _boot]) {
      try {
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  /// Start-ups since the last one that completed.
  int bootAttempts() {
    try {
      return _boot.existsSync()
          ? int.tryParse(_boot.readAsStringSync().trim()) ?? 0
          : 0;
    } catch (_) {
      return 0;
    }
  }

  void setBootAttempts(int n) {
    try {
      _ensure();
      _boot.writeAsStringSync('$n', flush: true);
    } catch (_) {}
  }

  void resetBootAttempts() => setBootAttempts(0);
}
