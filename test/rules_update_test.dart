import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:local_ledger/core/rules/bundled_rules.g.dart';
import 'package:local_ledger/core/rules/parser_rules.dart';
import 'package:local_ledger/core/rules/rules_config.dart';
import 'package:local_ledger/core/rules/rules_manager.dart';
import 'package:local_ledger/core/rules/rules_signing.dart';
import 'package:local_ledger/core/rules/rules_store.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

// Rules can change how every message is read, and they arrive over the
// network, so each way an update could be wrong or hostile is checked here:
// a bad signature, an unknown key, a format the app doesn't know, an old
// version, a pack that misreads its own sample messages, and a pack that
// stops the app starting.

void main() {
  late Directory tmp;
  late RulesStore store;
  late SimpleKeyPair key;
  late Map<String, Uint8List> trusted;
  final bundled = jsonDecode(kBundledRulesJson) as Map<String, dynamic>;
  final bundledVersion = bundled['packVersion'] as int;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('rules');
    store = RulesStore(Directory('${tmp.path}/rules'));
    key = await Ed25519().newKeyPair();
    trusted = {'k1': Uint8List.fromList((await key.extractPublicKey()).bytes)};
    ParserRules.use(null);
  });
  tearDown(() {
    ParserRules.use(null);
    tmp.deleteSync(recursive: true);
  });

  /// A rules pack: the bundled one, one version up, with a new bank.
  String pack({
    int? version,
    int? schema,
    String sender = 'NEWBNK',
    void Function(Map<String, dynamic>)? edit,
  }) {
    final j = jsonDecode(kBundledRulesJson) as Map<String, dynamic>;
    j['packVersion'] = version ?? bundledVersion + 1;
    if (schema != null) j['schemaVersion'] = schema;
    (j['senderCodes'] as List).add(sender);
    edit?.call(j);
    return jsonEncode(j);
  }

  Future<String> signed(String payload, {String keyId = 'k1', SimpleKeyPair? by}) =>
      signRules(payload: payload, keyId: keyId, keyPair: by ?? key);

  RulesManager manager(Future<String> Function() body, {int status = 200}) =>
      RulesManager(
        store: store,
        trustedKeys: trusted,
        url: Uri.parse('https://example.test/rules.signed.json'),
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(await body()), status),
        ),
      );

  group('signatures', () {
    test('a signed pack verifies and gives back its payload', () async {
      final payload = pack();
      expect(await verifySignedRules(await signed(payload), trusted), payload);
    });

    test('a single changed character is caught', () async {
      final env = jsonDecode(await signed(pack())) as Map<String, dynamic>;
      env['payload'] = (env['payload'] as String).replaceFirst('NEWBNK', 'EVILBK');
      expect(
        () => verifySignedRules(jsonEncode(env), trusted),
        throwsA(isA<RulesUpdateException>()),
      );
    });

    test('a pack signed by someone else is refused', () async {
      final stranger = await Ed25519().newKeyPair();
      expect(
        () async => verifySignedRules(await signed(pack(), by: stranger), trusted),
        throwsA(isA<RulesUpdateException>()),
      );
    });

    test('an unknown key id is refused', () async {
      expect(
        () async => verifySignedRules(await signed(pack(), keyId: 'nope'), trusted),
        throwsA(isA<RulesUpdateException>()),
      );
    });

    test('junk is refused', () async {
      for (final junk in ['', 'not json', '{}', '{"format":"other"}', '[]']) {
        expect(
          () => verifySignedRules(junk, trusted),
          throwsA(isA<RulesUpdateException>()),
          reason: junk,
        );
      }
    });
  });

  group('checking for an update', () {
    test('a valid newer pack is installed and takes effect', () async {
      expect(looksLikeBankSender('VM-NEWBNK-S'), isFalse);
      final result = await manager(() => signed(pack())).checkForUpdate();
      expect(result, isA<RulesUpdated>());
      expect(ParserRules.current.packVersion, bundledVersion + 1);
      expect(looksLikeBankSender('VM-NEWBNK-S'), isTrue);
      expect(store.readActive(), isNotNull);
    });

    test('the same version again is "up to date"', () async {
      final result = await manager(
        () => signed(pack(version: bundledVersion)),
      ).checkForUpdate();
      expect(result, isA<RulesUpToDate>());
      expect(looksLikeBankSender('VM-NEWBNK-S'), isFalse);
      expect(store.readActive(), isNull);
    });

    test('an older pack never replaces a newer one (no downgrade)', () async {
      final m = manager(() => signed(pack(version: bundledVersion + 5)));
      await m.checkForUpdate();
      final older = manager(() => signed(pack(version: bundledVersion + 2)));
      expect(await older.checkForUpdate(), isA<RulesUpToDate>());
      expect(ParserRules.current.packVersion, bundledVersion + 5);
    });

    test('a bad signature changes nothing', () async {
      final stranger = await Ed25519().newKeyPair();
      final result = await manager(
        () => signed(pack(), by: stranger),
      ).checkForUpdate();
      expect(result, isA<RulesRejected>());
      expect(ParserRules.current.packVersion, bundledVersion);
      expect(store.readActive(), isNull);
    });

    test('a format the app does not know waits for an app update', () async {
      final result = await manager(
        () => signed(pack(schema: 99)),
      ).checkForUpdate();
      expect((result as RulesRejected).reason, contains('newer app'));
      expect(ParserRules.current.packVersion, bundledVersion);
    });

    test('a pack that misreads its own sample messages is refused', () async {
      final bad = pack(
        edit: (j) => (j['canaries'] as List).add({
          'text': 'Rs 500.00 debited from A/c XX1234 at SHOP',
          'expect': {'type': 'credit'}, // the pack promises the wrong thing
        }),
      );
      final result = await manager(() => signed(bad)).checkForUpdate();
      expect((result as RulesRejected).reason, contains('sample messages'));
      expect(ParserRules.current.packVersion, bundledVersion);
    });

    test('a pack that is not valid rules is refused', () async {
      final result = await manager(
        () => signed(jsonEncode({'format': 'nativespend-rules', 'schemaVersion': 1})),
      ).checkForUpdate();
      expect(result, isA<RulesRejected>());
      expect(ParserRules.current.packVersion, bundledVersion);
    });

    test('no connection is reported as such', () async {
      final m = RulesManager(
        store: store,
        trustedKeys: trusted,
        client: MockClient((_) async => throw const SocketException('down')),
      );
      expect(await m.checkForUpdate(), isA<RulesOffline>());
    });

    test('nothing published yet (404) is not an error', () async {
      final m = manager(() async => 'Not Found', status: 404);
      expect(await m.checkForUpdate(), isA<RulesUpToDate>());
    });

    test('a server error is rejected, not trusted', () async {
      final m = manager(() async => 'oops', status: 500);
      expect(await m.checkForUpdate(), isA<RulesRejected>());
    });
  });

  group('keeping and rolling back', () {
    Future<void> install(int version) async {
      await manager(
        () => signed(pack(version: version, sender: 'BANK$version')),
      ).checkForUpdate();
    }

    test('the previous pack is kept and can be rolled back to', () async {
      await install(bundledVersion + 1);
      await install(bundledVersion + 2);
      final m = manager(() async => '');
      expect(m.status().packVersion, bundledVersion + 2);
      expect(m.status().canRollBack, isTrue);

      final after = await m.rollBack();
      expect(after.packVersion, bundledVersion + 1);
      expect(after.canRollBack, isFalse);
    });

    test('rolling back with nothing earlier returns to the built-in rules', () async {
      await install(bundledVersion + 1);
      final after = await manager(() async => '').rollBack();
      expect(after.packVersion, bundledVersion);
      expect(after.updated, isFalse);
    });

    test('"use built-in" forgets everything downloaded', () async {
      await install(bundledVersion + 1);
      final m = manager(() async => '');
      final s = m.useBuiltIn();
      expect(s.packVersion, bundledVersion);
      expect(store.readActive(), isNull);
      expect(store.readPrevious(), isNull);
    });
  });

  group('starting the app', () {
    test('a stored pack is verified again and used', () async {
      store.install(await signed(pack()));
      await manager(() async => '').activate();
      expect(ParserRules.current.packVersion, bundledVersion + 1);
    });

    test('a stored pack that was tampered with is dropped', () async {
      final env = jsonDecode(await signed(pack())) as Map<String, dynamic>;
      env['payload'] = (env['payload'] as String).replaceFirst('NEWBNK', 'EVILBK');
      store.install(jsonEncode(env));
      await manager(() async => '').activate();
      expect(ParserRules.current.packVersion, bundledVersion);
      expect(looksLikeBankSender('VM-EVILBK-S'), isFalse);
      expect(store.readActive(), isNull);
    });

    test('a corrupt stored file never stops the app', () async {
      store.install('{{{ not json');
      await manager(() async => '').activate();
      expect(ParserRules.current.packVersion, bundledVersion);
    });

    test('a pack older than the app\'s own rules is ignored', () async {
      store.install(await signed(pack(version: bundledVersion)));
      await manager(() async => '').activate();
      expect(store.readActive(), isNull);
      expect(ParserRules.current.packVersion, bundledVersion);
    });

    test('two failed start-ups in a row with new rules roll them back', () async {
      store.install(await signed(pack(version: bundledVersion + 1)));
      store.install(await signed(pack(version: bundledVersion + 2)));
      final m = manager(() async => '');

      await m.activate(); // start 1: uses +2, never reaches the first frame
      expect(ParserRules.current.packVersion, bundledVersion + 2);
      await m.activate(); // start 2: same
      expect(store.bootAttempts(), 2);

      await m.activate(); // start 3: the new rules are blamed and taken back
      expect(ParserRules.current.packVersion, bundledVersion + 1);
    });

    test('a start-up that reaches the first frame resets the count', () async {
      store.install(await signed(pack()));
      final m = manager(() async => '');
      await m.activate();
      await m.activate();
      m.bootSucceeded();
      expect(store.bootAttempts(), 0);
      await m.activate();
      expect(ParserRules.current.packVersion, bundledVersion + 1);
    });
  });

  test('the shipped signed file is valid for the key in the app', () async {
    final file = File('rules/rules.signed.json');
    if (!file.existsSync()) return; // not published yet
    final payload = await verifySignedRules(
      file.readAsStringSync(),
      // The real key list, not the test one.
      kTrustedRulesKeys,
    );
    final rules = ParserRules.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    expect(rules.packVersion, greaterThanOrEqualTo(bundledVersion));
  });
}
