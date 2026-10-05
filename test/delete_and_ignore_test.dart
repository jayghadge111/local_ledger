import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/security/encryption_providers.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/parser_templates.dart';
import 'package:local_ledger/features/transactions/transaction_form_sheet.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

const _body =
    'Greetings from Zeta Finserv! Rs 4,500.00 credited to your Zeta account '
    'ref R1. Keep paying on time to enjoy rewards.';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Transaction> seed({required bool fromMessage}) async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't1',
            amountMinor: 450000,
            merchant: 'Credit',
            source: 'sms',
            type: 'credit',
            date: DateTime(2026, 10, 1),
            categoryId: const Value('cat_other'),
            rawTextEncrypted: Value(fromMessage ? 'enc:$_body' : null),
          ),
        );
    return (db.select(
      db.transactions,
    )..where((t) => t.id.equals('t1'))).getSingle();
  }

  Future<void> open(WidgetTester tester, Transaction t) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          encryptionServiceProvider.overrideWithValue(_FakeEncryption()),
        ],
        child: MaterialApp(
          home: Scaffold(body: TransactionFormSheet(existing: t)),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('"Delete and ignore similar" deletes and teaches the layout', (
    tester,
  ) async {
    final t = await tester.runAsync(() => seed(fromMessage: true));
    await open(tester, t!);
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete this transaction?'), findsOneWidget);
    await tester.tap(find.text('Delete and ignore similar'));
    await settle(tester);

    final row = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((x) => x.id.equals('t1'))).getSingle(),
    ))!;
    expect(row.isDeleted, isTrue);
    final templates = await tester.runAsync(
      () => db.select(db.parserTemplates).get(),
    );
    expect(templates, hasLength(1));
    expect(templates!.single.type, ignoreTemplateType);
    await unmount(tester);
  });

  testWidgets('plain Delete deletes and teaches nothing', (tester) async {
    final t = await tester.runAsync(() => seed(fromMessage: true));
    await open(tester, t!);
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await settle(tester);

    final row = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((x) => x.id.equals('t1'))).getSingle(),
    ))!;
    expect(row.isDeleted, isTrue);
    expect(
      await tester.runAsync(() => db.select(db.parserTemplates).get()),
      isEmpty,
    );
    await unmount(tester);
  });

  testWidgets('Cancel keeps the transaction', (tester) async {
    final t = await tester.runAsync(() => seed(fromMessage: true));
    await open(tester, t!);
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cancel').last);
    await settle(tester);
    final row = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((x) => x.id.equals('t1'))).getSingle(),
    ))!;
    expect(row.isDeleted, isFalse);
    await unmount(tester);
  });

  testWidgets('a hand-entered transaction deletes straight away', (
    tester,
  ) async {
    final t = await tester.runAsync(() => seed(fromMessage: false));
    await open(tester, t!);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Delete this transaction?'), findsNothing);
    final row = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((x) => x.id.equals('t1'))).getSingle(),
    ))!;
    expect(row.isDeleted, isTrue);
    await unmount(tester);
  });
}
