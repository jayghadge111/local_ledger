import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/core/email/email_providers.dart';
import 'package:local_ledger/core/email/gmail_auth_service.dart';
import 'package:local_ledger/core/backup/local_snapshots.dart';
import 'package:local_ledger/core/backup/snapshot_providers.dart';
import 'package:local_ledger/core/sync/connectivity.dart';
import 'package:local_ledger/core/sync/sync_controller.dart';
import 'package:local_ledger/features/settings/widgets/email_connect_card.dart';

/// Records every call into Google. Any of them means the app reached out to
/// Google — which must only ever happen after the user taps something.
class _SpyAuth extends GmailAuthService {
  final calls = <String>[];

  @override
  Future<GoogleSignInAccount?> currentAccount() async {
    calls.add('currentAccount');
    return null;
  }

  @override
  Future<GoogleSignInAccount> signIn() async {
    calls.add('signIn');
    throw StateError('sign-in must not run in this test');
  }

  @override
  Future<GoogleSignInAccount> signInFresh() async {
    calls.add('signInFresh');
    throw StateError('sign-in must not run in this test');
  }

  @override
  Future<void> disconnect() async => calls.add('disconnect');
}

class _NoSnapshots implements SnapshotService {
  @override
  Future<SnapshotInfo?> snapshot(String reason) async => null;
  @override
  Future<bool> restore(SnapshotInfo snapshot) async => false;
  @override
  bool delete(SnapshotInfo snapshot) => false;
}

void main() {
  late AppDatabase db;
  late _SpyAuth auth;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    auth = _SpyAuth();
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          gmailAuthServiceProvider.overrideWithValue(auth),
          internetCheckProvider.overrideWithValue(() async => true),
          snapshotServiceProvider.overrideWithValue(_NoSnapshots()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: EmailConnectCard()),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('just showing the card never contacts Google', (tester) async {
    await pump(tester);
    expect(auth.calls, isEmpty);
    expect(find.text('Connect Gmail'), findsOneWidget);
    expect(find.textContaining('Connected as'), findsNothing);
    await unmount(tester);
  });

  testWidgets('an account connected earlier shows, still without Google', (
    tester,
  ) async {
    await tester.runAsync(
      () =>
          SettingsRepository(db)
              .set(SettingsKeys.gmailAccount, 'jayesh@example.com'),
    );
    await pump(tester);
    expect(find.text('Connected as jayesh@example.com'), findsOneWidget);
    expect(find.text('Scan now'), findsOneWidget);
    expect(auth.calls, isEmpty);
    await unmount(tester);
  });

  testWidgets('only a tap on Connect reaches Google', (tester) async {
    await pump(tester);
    expect(auth.calls, isEmpty);
    await tester.tap(find.text('Connect Gmail'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(auth.calls, ['signInFresh']);
    await unmount(tester);
  });

  testWidgets('Disconnect forgets the saved account', (tester) async {
    await tester.runAsync(
      () =>
          SettingsRepository(db)
              .set(SettingsKeys.gmailAccount, 'jayesh@example.com'),
    );
    await pump(tester);
    await tester.tap(find.text('Disconnect'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Connect Gmail'), findsOneWidget);
    final saved = await tester.runAsync(
      () => SettingsRepository(db).get(SettingsKeys.gmailAccount),
    );
    expect(saved, anyOf(isNull, isEmpty));

    // Coming back to the page later does not bring it back.
    await pump(tester);
    expect(find.text('Connect Gmail'), findsOneWidget);
    await unmount(tester);
  });

  test('the sync controller itself never asks Google on start', () async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        gmailAuthServiceProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(c.dispose);
    await c.read(syncControllerProvider.notifier).restoreGmailAccount();
    expect(auth.calls, isEmpty);
    expect(c.read(syncControllerProvider).gmailAccount, isNull);
  });
}
