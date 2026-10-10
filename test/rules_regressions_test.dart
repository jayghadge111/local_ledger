import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/db/app_database.dart';
import 'package:local_ledger/core/db/settings_repository.dart';
import 'package:local_ledger/core/ingest/transaction_ingestor.dart';
import 'package:local_ledger/core/intelligence/name_match.dart';
import 'package:local_ledger/core/security/encryption_service.dart';
import 'package:local_ledger/core/sms/bank_sms_parser.dart';

class _Enc extends EncryptionService {
  @override
  Future<String> encryptString(String p) async => 'enc:$p';
  @override
  Future<String> decryptString(String e) async => e.substring(4);
}

/// Messages that were misread on a real phone, kept as they came in.
const _googlePlay =
    'Dear Customer, recurring payment of Rs. 299.00 for Google Play has been '
    'processed on your Standard Chartered Bank Card XXXXXXXXXXXX9706 on '
    '03/10/2026. Manage your recurring payment with ID YAog8xtibf via '
    'https://www.sihub.in/managesi/scb. T&C apply';

const _credGold =
    'UPI Mandate:\nSent Rs.50.00\nfrom HDFC Bank A/c 0715\nTo CRED GOLD\n'
    '10/10/26\nRef 628312340810\nNot You? Call 18002586161/SMS BLOCK UPI to 7308080808';

const _toSelfTruncated =
    'INR 1,000.00 debited from Equitas-7719 via UPI -Ref:C1234567891 to '
    'JAYESH BHIKA GHA on 29-09-26.Bal INR 1,23,456.94.Not U?SMS BLOCK UPI to 7045030000';

void main() {
  late AppDatabase db;
  late TransactionIngestor ingestor;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SettingsRepository(db).set(SettingsKeys.userName, 'Jayesh Bhika Ghadge');
    ingestor = TransactionIngestor(db, _Enc());
  });
  tearDown(() => db.close());

  Future<Transaction> ingest(String body, String sender) async {
    final s = await ingestor.begin();
    await s.add(source: 'sms', sender: sender, body: body, date: DateTime(2026, 10, 3, 17, 22));
    await s.finish();
    return db.select(db.transactions).getSingle();
  }

  group('what the phone got wrong', () {
    test('a recurring Google Play payment is named and filed under Bills', () async {
      final t = await ingest(_googlePlay, 'VM-SCBANK-S');
      expect(t.merchant, 'Google Play');
      expect(t.categoryId, 'cat_bills');
      expect(t.amountMinor, 29900);
    });

    test('a CRED GOLD UPI mandate is an investment, not a bill', () async {
      final t = await ingest(_credGold, 'VM-HDFCBK-S');
      expect(t.merchant, 'CRED Gold');
      expect(t.categoryId, 'cat_investment');
    });

    test('a payment to your own name the bank cut short is a Self Transfer', () async {
      final t = await ingest(_toSelfTruncated, 'VM-EQUTAS-S');
      expect(t.kind, 'transfer');
      expect(t.categoryId, 'cat_self_transfer');
    });
  });

  group('text that is not a payee', () {
    test('"check for current balance" and "the app" are not merchants', () {
      for (final body in [
        'Dear Customer, INR 1,000.00 has been credited to your Equitas SFB A/c XX7719 on 07-10-2026. To check for current balance, login to the Equitas app.',
        'INR 1,000.00 credited to Equitas A/c 7719 on 07-10-26. Please login to check for current balance. Avl Bal INR 51,058.69',
      ]) {
        final m = parseBankSms(body)!.merchant.toLowerCase();
        expect(m, isNot(contains('balance')), reason: body);
        expect(m, isNot(contains('app')), reason: body);
      }
    });

    test('"UPI-Online Refun" (cut short) is read as a refund', () {
      final p = parseBankSms(
        'INR 1,000.00 credited to Equitas A/c 7719 .Ref 123456789/16-08-2026/UPI-Online Refun on 07-10-26 . Avl Bal is INR 51,058.69.',
      )!;
      expect(p.refundHint, isTrue);
    });
  });

  group('names the bank shortened', () {
    const user = 'Jayesh Bhika Ghadge';
    test('a last word cut to two or three letters still matches', () {
      expect(isSameName(user, 'JAYESH BHIKA GHA'), isTrue);
      expect(isSameName(user, 'JAYESH BHIKA GH'), isTrue);
      expect(isSameName(user, 'JAYESH BHIKA G'), isTrue);
      expect(isSameName(user, 'Mr JAYESH BHIKA GHAD'), isTrue);
    });

    test('but two whole words must still agree', () {
      expect(isSameName(user, 'JAYESH GHA'), isFalse);
      expect(isSameName(user, 'JAYESH'), isFalse);
      expect(isSameName(user, 'RAHUL BHIKA GHA'), isFalse);
      expect(isSameName(user, 'JAYESH PATIL GHA'), isFalse);
    });

    test('only the last word may be a stub', () {
      expect(isSameName(user, 'JAY BHIKA GHADGE'), isFalse);
    });
  });
}
