import 'package:local_ledger/core/db/app_database.dart';

/// Builds a [Transaction] with sensible defaults for tests.
Transaction tx(
  String id, {
  required int amount,
  String type = 'debit',
  String merchant = 'Shop',
  String? rawMerchant,
  DateTime? date,
  String currency = 'INR',
  String? accountId,
  String kind = 'normal',
  bool kindLocked = false,
  String? transferGroupId,
  String? refundOfId,
  String source = 'sms',
  String? categoryId,
  bool isDeleted = false,
  bool refundHint = false,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    amountMinor: amount,
    currency: currency,
    merchant: merchant,
    source: source,
    categoryId: categoryId,
    date: date ?? DateTime(2026, 10, 1, 12),
    type: type,
    isRecurring: false,
    isInternational: false,
    isFlaggedUnusual: false,
    isDeleted: isDeleted,
    userEdited: false,
    createdAt: DateTime(2026, 10, 1),
    rawMerchant: rawMerchant,
    kind: kind,
    kindLocked: kindLocked,
    transferGroupId: transferGroupId,
    refundOfId: refundOfId,
    refundHint: refundHint,
  );
}
