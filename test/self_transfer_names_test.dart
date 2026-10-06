import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/spend_analytics.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/security/encryption_providers.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';
import 'package:local_ledger/features/transactions/transaction_form_sheet.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

// The wording of a real UPI credit email: the same person on both sides.
const _self =
    'Alerts October 4, 2026, 09:58 AM Dear Valued Customer, UPI payment has been '
    'successfully credited to your bank account. UPI Ref. No. : 664323243391 '
    'From VPA : 9970900787@yescred Payer Name: JAYESH BHIKA GHADGE Payee Name: '
    'MR JAYESH BHIKA GHADGE To VPA : 9970900787@yescred To Account: Standard '
    'Chartered - XXXXXXX2627 Currency: INR Amount: 4000.00 Remarks: Paid via '
    'CRED Transaction Date: 04/10/2026 09:58:29 Transaction Status: COMPLETED '
    'Transaction Type: CR Reason for Failure : NA';

final _someoneElse = _self.replaceFirst(
  'Payer Name: JAYESH BHIKA GHADGE',
  'Payer Name: RAHUL SHARMA',
);

void main() {
  group('the same person as payer and payee', () {
    test('is read as a transfer between own accounts', () {
      final p = parseBankSms(_self)!;
      expect(p.type, 'credit');
      expect(p.amountMinor, 400000);
      expect(p.selfTransfer, isTrue);
    });

    test('different people are not', () {
      expect(parseBankSms(_someoneElse)!.selfTransfer, isFalse);
    });

    test('ordinary messages are not', () {
      for (final sms in [
        'Rs 500.00 debited from A/c XX1234 on 05-OCT-26 to SHOP via UPI',
        'Sent Rs.500.00\nFrom HDFC Bank A/c *1234\nTo SUNRISE CAFE\nOn 02/10/26',
        'Rs 5,000.00 credited to your A/c XX4921 by UPI from RAHUL. Avl bal Rs 10,000.00',
      ]) {
        expect(parseBankSms(sms)?.selfTransfer, isFalse, reason: sms);
      }
    });

    group('once stored', () {
      late AppDatabase db;
      late TransactionIngestor ingestor;
      setUp(() {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        ingestor = TransactionIngestor(db, _FakeEncryption());
      });
      tearDown(() => db.close());

      Future<void> ingest(String body) async {
        final s = await ingestor.begin();
        await s.add(
          source: 'email',
          sender: 'alerts@sc.com',
          body: body,
          date: DateTime(2026, 10, 4, 9, 58),
        );
        await s.finish();
      }

      test('it is a Self Transfer, counted nowhere', () async {
        await ingest(_self);
        final t = await db.select(db.transactions).getSingle();
        expect(t.kind, 'transfer');
        expect(t.categoryId, 'cat_self_transfer');
        expect(spendingView([t]), isEmpty);
      });

      test('one imported before this rule existed is put right on re-read', () async {
        await ingest(_self);
        await (db.update(db.transactions)).write(
          const TransactionsCompanion(
            kind: Value('normal'),
            categoryId: Value('cat_other'),
          ),
        );
        await ingest(_self);
        final t = await db.select(db.transactions).getSingle();
        expect((t.kind, t.categoryId), ('transfer', 'cat_self_transfer'));
      });

      test('a payment from someone else stays income', () async {
        await ingest(_someoneElse);
        final t = await db.select(db.transactions).getSingle();
        expect(t.kind, 'normal');
        expect(t.categoryId, isNot('cat_self_transfer'));
      });

      test('a hand-made choice is not overridden', () async {
        await ingest(_self);
        await (db.update(db.transactions)).write(
          const TransactionsCompanion(
            kind: Value('normal'),
            kindLocked: Value(true),
            userEdited: Value(true),
            categoryId: Value('cat_food'),
          ),
        );
        await ingest(_self);
        final t = await db.select(db.transactions).getSingle();
        expect((t.kind, t.categoryId), ('normal', 'cat_food'));
      });
    });
  });

  group('the edit form: the Self Transfer category is the only switch', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> open(WidgetTester tester, {required String kind}) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final existing = (await tester.runAsync(() async {
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 't1',
                amountMinor: 400000,
                merchant: 'Jayesh',
                source: 'email',
                type: 'credit',
                date: DateTime(2026, 10, 4),
                categoryId: const Value('cat_food'),
                kind: Value(kind),
              ),
            );
        return (db.select(db.transactions)).getSingle();
      }))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            encryptionServiceProvider.overrideWithValue(_FakeEncryption()),
          ],
          child: MaterialApp(
            home: Scaffold(body: TransactionFormSheet(existing: existing)),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> pickCategory(WidgetTester tester, String name) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(name).last);
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<Transaction> saved(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      return (await tester.runAsync(() => db.select(db.transactions).getSingle()))!;
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('there are no transfer or card-bill switches', (tester) async {
      await open(tester, kind: 'normal');
      expect(find.text('Transfer between my own accounts'), findsNothing);
      expect(find.textContaining('Credit card bill payment'), findsNothing);
      expect(find.text('International transaction'), findsOneWidget);
      await close(tester);
    });

    testWidgets('choosing Self Transfer makes it a transfer', (tester) async {
      await open(tester, kind: 'normal');
      await pickCategory(tester, 'Self Transfer');
      final t = await saved(tester);
      expect(t.kind, 'transfer');
      expect(t.categoryId, 'cat_self_transfer');
      await close(tester);
    });

    testWidgets('a transfer opens as Self Transfer, and moving it out frees it', (
      tester,
    ) async {
      await open(tester, kind: 'transfer');
      expect(find.text('Self Transfer'), findsWidgets);
      await pickCategory(tester, 'Groceries');
      final t = await saved(tester);
      expect(t.kind, 'normal');
      expect(t.categoryId, 'cat_groceries');
      await close(tester);
    });

    testWidgets('editing a credit-card bill payment keeps it one', (tester) async {
      await open(tester, kind: 'card_payment');
      await pickCategory(tester, 'Bills & utilities');
      final t = await saved(tester);
      expect(t.kind, 'card_payment');
      await close(tester);
    });
  });
}
