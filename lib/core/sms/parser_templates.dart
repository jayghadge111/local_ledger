import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/providers.dart';
import '../security/encryption_providers.dart';
import '../security/encryption_service.dart';
import 'template_learning.dart';

/// A stored template, decrypted and compiled, ready to try on a message.
class CompiledTemplate {
  const CompiledTemplate({
    required this.id,
    required this.senderCode,
    required this.type,
    required this.regex,
  });

  final String id;
  final String? senderCode;
  final String type;
  final RegExp regex;
}

final parserTemplateStoreProvider = Provider<ParserTemplateStore>(
  (ref) => ParserTemplateStore(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
  ),
);

final parserTemplateCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.parserTemplates).watch().map((rows) => rows.length);
});

/// The message layouts the user has taught the parser. Patterns are stored
/// encrypted (the fixed text around the amount can include names or account
/// details) and decrypted only to be matched.
class ParserTemplateStore {
  ParserTemplateStore(this._db, this._encryption);

  final AppDatabase _db;
  final EncryptionService _encryption;
  static const _uuid = Uuid();

  Future<List<CompiledTemplate>> loadAll() async {
    final rows = await _db.select(_db.parserTemplates).get();
    final list = <CompiledTemplate>[];
    for (final r in rows) {
      try {
        final pattern = await _encryption.decryptString(r.patternEncrypted);
        list.add(
          CompiledTemplate(
            id: r.id,
            senderCode: r.senderCode,
            type: r.type,
            regex: compileTemplate(pattern),
          ),
        );
      } catch (_) {
        // A template that can't be read is skipped, never fatal.
      }
    }
    return list;
  }

  /// Learns the layout of [body] given the right answer. Returns true if a
  /// new template was stored (false if the message is too generic to learn
  /// from, the layout is already known, or [requireMerchant] couldn't be met).
  Future<bool> learn({
    required String body,
    required String type,
    required int amountMinor,
    String? merchant,
    String? senderCode,
    bool requireMerchant = false,
  }) async {
    final pattern = buildTemplatePattern(
      body: body,
      amountMinor: amountMinor,
      merchant: merchant,
    );
    if (pattern == null) return false;
    if (requireMerchant && !pattern.contains('(?<m>')) return false;

    final rows = await _db.select(_db.parserTemplates).get();
    for (final r in rows) {
      try {
        if (await _encryption.decryptString(r.patternEncrypted) == pattern &&
            r.type == type) {
          return false;
        }
      } catch (_) {}
    }
    await _db
        .into(_db.parserTemplates)
        .insert(
          ParserTemplatesCompanion.insert(
            id: _uuid.v4(),
            senderCode: Value(senderCode),
            patternEncrypted: await _encryption.encryptString(pattern),
            type: type,
          ),
        );
    return true;
  }

  Future<void> recordHits(Map<String, int> hits) async {
    for (final e in hits.entries) {
      await _db.customStatement(
        'UPDATE parser_templates SET hits = hits + ? WHERE id = ?',
        [e.value, e.key],
      );
    }
  }

  Future<void> clearAll() => _db.delete(_db.parserTemplates).go();
}
