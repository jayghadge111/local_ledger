import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/providers.dart';
import 'package:local_ledger/core/lending/lending_math.dart';
import 'package:local_ledger/core/lending/lending_messages.dart';
import 'package:local_ledger/core/lending/lending_repository.dart';
import 'package:local_ledger/core/lending/lending_share.dart';
import 'package:local_ledger/features/lending/lending_share_dialog.dart';
import 'package:local_ledger/features/lending/lending_status_card.dart';

final _today = DateTime(2026, 10, 20, 12);

LendingBalance balance({
  String direction = 'lent',
  String person = 'Ramesh Kumar',
  int amount = 500000,
  int paid = 200000,
  DateTime? due,
  bool settled = false,
  bool noDue = false,
}) => LendingBalance(
  entry: LendingEntry(
    id: 'e1',
    person: person,
    direction: direction,
    amountMinor: amount,
    date: DateTime(2026, 10, 5),
    dueDate: noDue ? null : (due ?? DateTime(2026, 11, 5)),
    isSettled: settled,
    createdAt: DateTime(2026, 10, 5),
  ),
  paidMinor: paid,
);

void main() {
  group('money in messages', () {
    test('whole rupees without paise, paise when there are some', () {
      expect(rupees(500000), '₹5,000');
      expect(rupees(500050), '₹5,000.50');
      expect(rupees(10000000), '₹1,00,000');
    });
  });

  group('percent paid', () {
    test('rounds down', () {
      expect(paidPercent(balance(paid: 200000)), 40);
      expect(paidPercent(balance(amount: 300000, paid: 100000)), 33);
    });

    test('never says 100 until it is really settled', () {
      expect(paidPercent(balance(paid: 499000)), 99);
      expect(paidPercent(balance(paid: 500000, settled: false)), 100);
      expect(paidPercent(balance(paid: 200000, settled: true)), 100);
    });

    test('a first small payment shows as at least 1%', () {
      expect(paidPercent(balance(amount: 10000000, paid: 100)), 1);
      expect(paidPercent(balance(paid: 0)), 0);
    });
  });

  group('status message', () {
    test('lent: what has come back and what is pending', () {
      expect(
        statusMessage(balance()),
        'Hi Ramesh, a quick update on the ₹5,000 I lent you on 5 Oct:\n\n'
        'Paid: ₹2,000 (40%)\nPending: ₹3,000\nDue: 5 Nov\n\nThanks!',
      );
    });

    test('borrowed: from the borrower\'s side', () {
      expect(
        statusMessage(
          balance(
            direction: 'borrowed',
            person: 'Priya',
            amount: 1000000,
            paid: 400000,
            due: DateTime(2026, 11, 15),
          ),
        ),
        'Hi Priya, an update on the ₹10,000 you lent me on 5 Oct:\n\n'
        'Paid back: ₹4,000 (40%)\nStill to pay: ₹6,000\nDue: 15 Nov\n\n'
        'I\'ll keep sending the rest. Thank you for waiting!',
      );
    });

    test('no due date means no due line', () {
      expect(statusMessage(balance(noDue: true)), isNot(contains('Due:')));
    });

    test('settled entries say so', () {
      expect(
        statusMessage(balance(paid: 500000, settled: true)),
        contains('fully paid'),
      );
      expect(
        statusMessage(
          balance(direction: 'borrowed', paid: 500000, settled: true),
        ),
        contains('paid back the full ₹5,000'),
      );
    });
  });

  group('reminders to someone who owes you', () {
    test('friendly, neutral and firm all carry the amounts and the date', () {
      for (final tone in ReminderTone.values) {
        final m = reminderMessage(balance(), tone, now: _today);
        expect(m, contains('₹3,000'), reason: '$tone');
        expect(m, contains('₹5,000'), reason: '$tone');
        expect(m, contains('5 Nov'), reason: '$tone');
        expect(
          m,
          startsWith(
            tone == ReminderTone.friendly ? 'Hey Ramesh' : 'Hi Ramesh',
          ),
        );
      }
    });

    test('tones differ', () {
      final texts = {
        for (final t in ReminderTone.values)
          reminderMessage(balance(), t, now: _today),
      };
      expect(texts, hasLength(3));
    });

    test('once overdue, they say it was due', () {
      final late = DateTime(2026, 11, 10);
      final due = DateTime(2026, 11, 5);
      for (final tone in ReminderTone.values) {
        final m = reminderMessage(balance(due: due), tone, now: late);
        expect(m, contains('was due'), reason: '$tone');
      }
      expect(
        reminderMessage(balance(), ReminderTone.firm, now: _today),
        contains('is due on 5 Nov'),
      );
    });

    test('no due date: no date in the message', () {
      for (final tone in ReminderTone.values) {
        expect(
          reminderMessage(balance(noDue: true), tone, now: _today),
          isNot(contains('Nov')),
          reason: '$tone',
        );
      }
    });
  });

  group('what a borrower tells the lender', () {
    final borrowed = balance(
      direction: 'borrowed',
      person: 'Priya',
      amount: 1000000,
      paid: 400000,
    );

    test('"where I stand" is the status', () {
      expect(
        borrowerUpdateMessage(borrowed, BorrowerUpdate.status),
        statusMessage(borrowed),
      );
    });

    test('"I\'ll pay on a date" names the date and what is left', () {
      final m = borrowerUpdateMessage(
        borrowed,
        BorrowerUpdate.payOnDate,
        date: DateTime(2026, 11, 25),
      );
      expect(m, contains('₹6,000'));
      expect(m, contains('by 25 Nov 2026'));
    });

    test('"need more time" asks, and offers a new date', () {
      final m = borrowerUpdateMessage(
        borrowed,
        BorrowerUpdate.needMoreTime,
        date: DateTime(2026, 12, 1),
      );
      expect(m, contains('a little more time'));
      expect(m, contains('1 Dec 2026'));
      expect(
        borrowerUpdateMessage(borrowed, BorrowerUpdate.needMoreTime),
        isNot(contains('Dec')),
      );
    });
  });

  group('right after a payment', () {
    test('lent: a receipt for what the other person paid', () {
      final m = paymentMessage(balance(paid: 300000), 100000);
      expect(m, contains('received your ₹1,000'));
      expect(m, contains('₹3,000 of ₹5,000'));
      expect(m, contains('₹2,000 to go'));
    });

    test('borrowed: telling the lender what was sent', () {
      final m = paymentMessage(
        balance(direction: 'borrowed', amount: 1000000, paid: 400000),
        100000,
      );
      expect(m, contains('sent you ₹1,000'));
      expect(m, contains('₹4,000 of ₹10,000'));
      expect(m, contains('₹6,000 to go'));
    });

    test('the last payment says the whole thing is done', () {
      expect(
        paymentMessage(balance(paid: 500000, settled: true), 200000),
        contains('clears the full ₹5,000'),
      );
      expect(
        paymentMessage(
          balance(direction: 'borrowed', paid: 500000, settled: true),
          200000,
        ),
        contains('full ₹5,000 paid back'),
      );
    });
  });

  group('the image card', () {
    testWidgets('shows the person, the pending amount and the percent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LendingStatusCard(balance: balance(), now: _today),
          ),
        ),
      );
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Lent to'), findsOneWidget);
      expect(find.text('₹3,000'), findsOneWidget); // pending, big
      expect(find.text('40% paid'), findsOneWidget);
      expect(find.text('Due 5 Nov'), findsOneWidget);
    });

    testWidgets('borrowed, overdue and settled read correctly', (tester) async {
      Future<void> show(LendingBalance b, DateTime now) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LendingStatusCard(balance: b, now: now),
          ),
        ),
      );
      await show(
        balance(direction: 'borrowed', due: DateTime(2026, 10, 10)),
        _today,
      );
      expect(find.text('Borrowed from'), findsOneWidget);
      expect(find.text('Still to pay'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      await show(balance(paid: 500000, settled: true), _today);
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('Fully paid'), findsOneWidget);
    });

    testWidgets('renders to a real PNG', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: LendingStatusCard(balance: balance(), now: _today),
              ),
            ),
          ),
        ),
      );
      final png = await tester.runAsync(() => captureCardPng(key));
      expect(png, isNotNull);
      // PNG signature, and a 3x-scale (1080 px wide) picture.
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
      final width = ByteData.sublistView(png).getUint32(16);
      expect(width, 1080);
    });
  });

  group('the share dialog', () {
    late AppDatabase db;
    late List<({String? text, Uint8List? png})> shared;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      shared = [];
    });
    tearDown(() => db.close());

    Future<String> seed(WidgetTester tester, String direction) async =>
        (await tester.runAsync(
          () => LendingRepository(db).addEntry(
            person: direction == 'lent' ? 'Ramesh Kumar' : 'Priya',
            direction: direction,
            amountMinor: 500000,
            date: DateTime(2026, 10, 5),
            dueDate: DateTime(2026, 11, 5),
          ),
        ))!;

    Future<void> open(
      WidgetTester tester,
      String id,
      LendingShareKind kind, {
      int paymentMinor = 0,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(
        () => LendingRepository(db)
            .addPayment(id, amountMinor: 200000, date: DateTime(2026, 10, 12)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            lendingShareProvider.overrideWithValue(
              ({String? text, Uint8List? png}) async =>
                  shared.add((text: text, png: png)),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LendingShareDialog(
                entryId: id,
                kind: kind,
                paymentMinor: paymentMinor,
                now: _today,
              ),
            ),
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

    String field(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('status is the image card with its message, no tabs', (
      tester,
    ) async {
      final id = await seed(tester, 'lent');
      await open(tester, id, LendingShareKind.status);
      // The card and the message are both there, with no Text / Image switch.
      expect(find.byType(LendingStatusCard), findsOneWidget);
      expect(find.text('Image card'), findsNothing);
      expect(find.text('Text'), findsNothing);
      expect(field(tester), contains('Paid: ₹2,000 (40%)'));
      expect(field(tester), contains('Pending: ₹3,000'));

      await tester.runAsync(() async {
        await tester.tap(find.text('Send via…'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pump();
      expect(shared, hasLength(1));
      expect(shared.single.png, isNotNull);
      expect(shared.single.png!.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
      expect(shared.single.text, contains('Pending: ₹3,000'));
      await unmount(tester);
    });

    testWidgets('an edited message is what goes with the picture', (
      tester,
    ) async {
      final id = await seed(tester, 'lent');
      await open(tester, id, LendingShareKind.status);
      await tester.enterText(
        find.byType(TextField),
        'Hi! Ramesh, ₹3,000 left.',
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Send via…'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pump();
      expect(shared.single.text, 'Hi! Ramesh, ₹3,000 left.');
      expect(shared.single.png, isNotNull);
      await unmount(tester);
    });

    testWidgets('lent reminder: the tone chips change the message', (
      tester,
    ) async {
      final id = await seed(tester, 'lent');
      await open(tester, id, LendingShareKind.message);
      expect(find.text('Remind Ramesh Kumar'), findsOneWidget);
      final friendly = field(tester);
      expect(friendly, startsWith('Hey Ramesh'));

      await tester.tap(find.text('Firm'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(field(tester), isNot(friendly));
      expect(field(tester), contains('Please make sure it reaches me'));

      // A reminder is text only: no card.
      expect(find.byType(LendingStatusCard), findsNothing);
      await unmount(tester);
    });

    testWidgets('borrowed update: three choices, dates where they matter', (
      tester,
    ) async {
      final id = await seed(tester, 'borrowed');
      await open(tester, id, LendingShareKind.message);
      expect(find.text('Update Priya'), findsOneWidget);
      expect(find.text('Where I stand'), findsOneWidget);
      // "Where I stand" is a status, so it goes with the picture.
      expect(find.byType(LendingStatusCard), findsOneWidget);
      expect(find.textContaining('Pay by'), findsNothing);

      await tester.tap(find.text("I'll pay on a date"));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Pay by'), findsOneWidget);
      expect(field(tester), contains("I'll pay it by"));
      expect(find.byType(LendingStatusCard), findsNothing);

      await tester.tap(find.text('Need more time'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(field(tester), contains('a little more time'));
      await unmount(tester);
    });

    testWidgets('after a payment: a ready message, and "Not now"', (
      tester,
    ) async {
      final id = await seed(tester, 'lent');
      await open(tester, id, LendingShareKind.payment, paymentMinor: 200000);
      expect(find.text('Tell Ramesh Kumar?'), findsOneWidget);
      expect(field(tester), contains('received your ₹2,000'));
      expect(find.text('Not now'), findsOneWidget);
      await unmount(tester);
    });
  });
}
