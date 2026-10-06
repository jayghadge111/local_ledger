import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../diagnostics/diagnostic_log.dart';
import 'canary_tools.dart';
import 'parser_rules.dart';
import 'rules_config.dart';
import 'rules_signing.dart';
import 'rules_store.dart';

/// How a check for new rules ended.
sealed class RulesUpdateResult {
  const RulesUpdateResult();
}

class RulesUpToDate extends RulesUpdateResult {
  const RulesUpToDate(this.packVersion);
  final int packVersion;
}

class RulesUpdated extends RulesUpdateResult {
  const RulesUpdated(this.packVersion);
  final int packVersion;
}

class RulesOffline extends RulesUpdateResult {
  const RulesOffline();
}

/// A file was found but is not safe or usable; [reason] says why. Nothing
/// changed.
class RulesRejected extends RulesUpdateResult {
  const RulesRejected(this.reason);
  final String reason;
}

/// What is in force right now.
class RulesStatus {
  const RulesStatus({
    required this.packVersion,
    required this.updated,
    required this.canRollBack,
  });

  final int packVersion;

  /// A downloaded set is in use (rather than the one built into the app).
  final bool updated;

  /// An earlier downloaded set exists to go back to.
  final bool canRollBack;
}

/// Keeps the message-reading rules current without an app release, and safe:
///
/// * a downloaded set is used only if its signature verifies against a key
///   built into the app, it is in a format this build understands, it is
///   newer than what is in force, and every sample message in it is read as it
///   promises;
/// * the previous set is kept, so it can be rolled back to — by the user, or
///   automatically if the app fails to start twice running with new rules;
/// * anything wrong at start-up quietly falls back to the rules built in.
class RulesManager {
  RulesManager({
    required this.store,
    http.Client? client,
    Uri? url,
    Map<String, Uint8List>? trustedKeys,
    this.supportedSchema = kSupportedRulesSchema,
    // ignore: prefer_initializing_formals
  }) : _client = client,
       url = url ?? Uri.parse(kRulesUrl),
       trustedKeys = trustedKeys ?? kTrustedRulesKeys;

  final RulesStore store;
  final Uri url;
  final Map<String, Uint8List> trustedKeys;
  final int supportedSchema;
  final http.Client? _client;

  /// The app's own manager, set up by [initialise].
  static RulesManager? instance;

  /// Opens the on-device store and puts the right rules in force. Called once
  /// at start-up; never throws.
  static Future<RulesManager?> initialise() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final manager = RulesManager(
        store: RulesStore(Directory('${dir.path}/rules')),
      );
      instance = manager;
      await manager.activate();
      return manager;
    } catch (error, stack) {
      DiagnosticLog.instance.record('rules', error, stack, 'start-up');
      ParserRules.use(null);
      return null;
    }
  }

  /// The first screen was drawn: this start-up worked.
  void bootSucceeded() => store.resetBootAttempts();

  // ---------------------------------------------------------------- start-up

  /// Puts the best valid rules in force: the downloaded set if it holds up,
  /// else the previous one, else the ones built in.
  Future<void> activate() async {
    final bundledVersion = ParserRules.bundled().packVersion;

    // Two starts in a row that never reached the first screen, with
    // downloaded rules in use: take them back.
    var attempts = store.bootAttempts();
    if (store.readActive() != null && attempts >= 2) {
      DiagnosticLog.instance.record(
        'rules',
        'Rolling back updated rules after $attempts failed start-ups',
      );
      store.rollback();
      attempts = 0;
    }

    for (var round = 0; round < 2; round++) {
      final envelope = store.readActive();
      if (envelope == null) break;
      final rules = await _load(envelope);
      if (rules != null && rules.packVersion > bundledVersion) {
        ParserRules.use(rules);
        store.setBootAttempts(attempts + 1);
        return;
      }
      // Unusable, or older than what this app version ships: drop it.
      if (!store.rollback()) break;
    }
    ParserRules.use(null);
  }

  /// The rules inside a stored envelope if they still verify and hold up;
  /// null (and a log entry) if not.
  Future<ParserRules?> _load(String envelope) async {
    try {
      return await _validate(envelope);
    } catch (error, stack) {
      DiagnosticLog.instance.record(
        'rules',
        error,
        stack,
        'loading stored rules',
      );
      return null;
    }
  }

  /// Verifies and parses [envelope]; throws [RulesUpdateException] if unusable.
  Future<ParserRules> _validate(String envelope) async {
    final payload = await verifySignedRules(envelope, trustedKeys);
    final ParserRules rules;
    try {
      rules = ParserRules.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    } catch (e) {
      throw RulesUpdateException('rules could not be read ($e)');
    }
    if (rules.schemaVersion != supportedSchema) {
      throw RulesUpdateException(
        'rules format ${rules.schemaVersion} needs a newer app',
      );
    }
    final failing = failingCanaries(rules);
    if (failing.isNotEmpty) {
      throw RulesUpdateException(
        'sample messages not read as promised (${failing.first})',
      );
    }
    return rules;
  }

  // ------------------------------------------------------------------ update

  /// Downloads the published rules and, if they are valid and newer, puts them
  /// in force. Never throws.
  Future<RulesUpdateResult> checkForUpdate() async {
    final client = _client ?? http.Client();
    try {
      final http.Response response;
      try {
        response = await client
            .get(url, headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
      } on SocketException {
        return const RulesOffline();
      } on http.ClientException {
        return const RulesOffline();
      } on HandshakeException {
        return const RulesOffline();
      }
      if (response.statusCode == 404) {
        return RulesUpToDate(ParserRules.current.packVersion);
      }
      if (response.statusCode != 200) {
        return RulesRejected('server answered ${response.statusCode}');
      }
      if (response.bodyBytes.length > kMaxRulesBytes) {
        return const RulesRejected('file is too large');
      }
      final envelope = utf8.decode(response.bodyBytes);

      final ParserRules candidate;
      try {
        candidate = await _validate(envelope);
      } on RulesUpdateException catch (e) {
        DiagnosticLog.instance.record('rules', e, null, 'rejected an update');
        return RulesRejected(e.message);
      }

      final inForce = ParserRules.current.packVersion;
      if (candidate.packVersion <= inForce) return RulesUpToDate(inForce);

      store.install(envelope);
      ParserRules.use(candidate);
      store.setBootAttempts(1);
      return RulesUpdated(candidate.packVersion);
    } on RulesUpdateException catch (e) {
      return RulesRejected(e.message);
    } catch (error, stack) {
      DiagnosticLog.instance.record('rules', error, stack, 'update check');
      return RulesRejected('$error');
    } finally {
      if (_client == null) client.close();
    }
  }

  // ---------------------------------------------------------------- rollback

  /// Goes back to the previous downloaded rules, or to the built-in ones if
  /// there is no earlier set. Returns what is in force afterwards.
  Future<RulesStatus> rollBack() async {
    store.rollback();
    await activate();
    return status();
  }

  /// Drops every downloaded set; the rules built into the app apply.
  RulesStatus useBuiltIn() {
    store.clear();
    ParserRules.use(null);
    return status();
  }

  RulesStatus status() => RulesStatus(
    packVersion: ParserRules.current.packVersion,
    updated:
        store.readActive() != null &&
        ParserRules.current.packVersion > ParserRules.bundled().packVersion,
    canRollBack: store.readPrevious() != null,
  );
}
