import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/analytics/spend_analytics.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/ingest/reconciler.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';
import 'package:local_ledger/features/transactions/transaction_title.dart';
import 'package:local_ledger/features/transactions/transactions_repository.dart';
import 'package:local_ledger/features/transactions/widgets/transaction_tile.dart';

class _FakeEncryption extends EncryptionService {
  @override
  Future<String> encryptString(String plainText) async => 'enc:$plainText';
  @override
  Future<String> decryptString(String encoded) async => encoded.substring(4);
}

const _cardDebit =
    'Your account 427xxxx2627 has been debited on 28/09/2026 by INR 921.00 towards Credit card repayment.Available Balance:INR 123.64 -StanChart';
const _swipe =
    'Rs 921.00 spent on HDFC Bank Credit Card XX9706 at SWIGGY on 20-SEP-26.';

void main() {
  group('the parser flags a bill payment', () {
    test('"towards Credit card repayment"', () {
      expect(parseBankSms(_cardDebit)!.cardPayment, isTrue);
    });

    test('other banks wording it differently', () {
      for (final sms in [
        'Rs 3,200.00 debited from A/c XX4921 towards your credit card payment. Thank you.',
        'INR 12,000.00 debited from A/c XX1234 on 05-OCT-26 towards HDFC Credit Card bill.',
        'Rs 7,500.00 debited from A/c XX1234 on 05-OCT-26 for Credit card payment. Avl bal Rs 9,000.',
      ]) {
        expect(parseBankSms(sms)?.cardPayment, isTrue, reason: sms);
      }
    });

    test('ordinary spending is not flagged, even on a card', () {
      for (final sms in [
        _swipe,
        'Rs 500 debited from A/c XX4921 on 05-OCT-26 to SHOP via UPI',
        'Rs 1,200.00 debited from A/c XX1234 on 05-SEP-26. Info: ACH D- TATA CAPITAL-123.',
      ]) {
        expect(parseBankSms(sms)?.cardPayment, isFalse, reason: sms);
      }
    });
  });

  group('stored and counted', () {
    late AppDatabase db;
    late TransactionIngestor ingestor;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      ingestor = TransactionIngestor(db, _FakeEncryption());
    });
    tearDown(() => db.close());

    Future<List<Transaction>> live() => (db.select(
      db.transactions,
    )..where((t) => t.isDeleted.equals(false))).get();

    Future<void> ingest(String body, DateTime date) async {
      final s = await ingestor.begin();
      await s.add(source: 'sms', sender: 'VM-HDFCBK-S', body: body, date: date);
      await s.finish();
    }

    test('listed, but not in the spending totals', () async {
      await ingest(_swipe, DateTime(2026, 9, 20, 12));
      await ingest(_cardDebit, DateTime(2026, 9, 28, 7, 34));

      final all = await live();
      expect(all, hasLength(2));
      final bill = all.singleWhere((t) => t.kind == 'card_payment');
      expect(bill.amountMinor, 92100);
      expect(bill.type, 'debit');

      // The swipe counts; the bill that settles it does not — once, not twice.
      final counted = spendingView(all);
      expect(counted, hasLength(1));
      expect(counted.single.id, isNot(bill.id));
      expect(counted.fold<int>(0, (a, t) => a + t.amountMinor), 92100);
    });

    test('older rows named "Credit card bill" are picked up', () async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'old',
              amountMinor: 50000,
              merchant: 'Credit card bill',
              source: 'sms',
              type: 'debit',
              date: DateTime(2026, 9, 1),
            ),
          );
      await Reconciler(db).run();
      expect((await live()).single.kind, 'card_payment');
      expect(spendingView(await live()), isEmpty);
    });

    test('a row the user locked as normal stays normal', () async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'mine',
              amountMinor: 50000,
              merchant: 'Credit card bill',
              source: 'sms',
              type: 'debit',
              date: DateTime(2026, 9, 1),
              kindLocked: const Value(true),
            ),
          );
      await Reconciler(db).run();
      expect((await live()).single.kind, 'normal');
      expect(spendingView(await live()), hasLength(1));
    });

    test('the user can switch it either way, and it sticks', () async {
      await ingest(_cardDebit, DateTime(2026, 9, 28, 7, 34));
      final id = (await live()).single.id;
      final repo = TransactionsRepository(db);

      await repo.setCardPayment(id, false);
      var row = (await live()).single;
      expect(row.kind, 'normal');
      expect(row.kindLocked, isTrue);
      expect(spendingView(await live()), hasLength(1));

      // Re-reading the same message must not undo the choice.
      await ingest(_cardDebit, DateTime(2026, 9, 28, 7, 34));
      expect((await live()).single.kind, 'normal');

      await repo.setCardPayment(id, true);
      row = (await live()).single;
      expect(row.kind, 'card_payment');
      expect(spendingView(await live()), isEmpty);
    });

    test('a manual entry can be marked as a card bill', () async {
      final repo = TransactionsRepository(db);
      await repo.addManualTransaction(
        amountMinor: 250000,
        merchant: 'HDFC card',
        categoryId: 'cat_bills',
        type: 'debit',
        date: DateTime(2026, 9, 30),
        isCardPayment: true,
      );
      expect((await live()).single.kind, 'card_payment');
      expect(spendingView(await live()), isEmpty);
    });

    test('credits and other debits are unaffected', () async {
      await ingest(
        'Rs 5,000.00 credited to your A/c XX4921 on 07-OCT-26 by UPI from RAHUL. Avl bal Rs 10,000.00',
        DateTime(2026, 10, 7),
      );
      await ingest(
        'Rs 500 debited from A/c XX4921 on 05-OCT-26 to SHOP via UPI',
        DateTime(2026, 10, 5),
      );
      final all = await live();
      expect(all.every((t) => t.kind == 'normal'), isTrue);
      expect(spendingView(all), hasLength(2));
    });
  });

  group('the note on screen', () {
    testWidgets('the list shows why it is not counted', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 't',
              amountMinor: 92100,
              merchant: 'Credit card bill',
              source: 'sms',
              type: 'debit',
              date: DateTime(2026, 9, 28),
              kind: const Value('card_payment'),
            ),
          );
      final row = await db.select(db.transactions).getSingle();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: TransactionTile(
                transaction: row,
                category: null,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Credit card bill'), findsOneWidget);
      expect(find.text('Card bill · not counted'), findsOneWidget);
      expect(find.textContaining('Not counted'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    });

    test('the explanation names the reason', () {
      expect(cardPaymentNote, contains('Not counted as spending'));
      expect(cardPaymentNote, contains('already counted'));
    });
  });
}
