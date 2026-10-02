import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

class _MockTxn {
  const _MockTxn(
    this.merchant,
    this.categoryId,
    this.amountMinor,
    this.daysAgo,
    this.type, {
    this.isInternational = false,
    this.isFlaggedUnusual = false,
    this.isRecurring = false,
  });

  final String merchant;
  final String categoryId;
  final int amountMinor;
  final int daysAgo;
  final String type;
  final bool isInternational;
  final bool isFlaggedUnusual;
  final bool isRecurring;
}

const _mockTransactions = [
  _MockTxn('Swiggy', 'cat_food', 48700, 0, 'debit'),
  _MockTxn('Starbucks Coffee', 'cat_food', 41000, 0, 'debit'),
  _MockTxn('Zomato', 'cat_food', 35650, 3, 'debit'),
  _MockTxn('BigBasket', 'cat_groceries', 214500, 4, 'debit'),
  _MockTxn('Uber', 'cat_transport', 21500, 1, 'debit'),
  _MockTxn('Ola', 'cat_transport', 18000, 6, 'debit'),
  _MockTxn('Amazon India', 'cat_shopping', 199900, 8, 'debit'),
  _MockTxn('Myntra', 'cat_shopping', 249900, 13, 'debit'),
  _MockTxn(
    'BESCOM Electricity',
    'cat_bills',
    145000,
    18,
    'debit',
    isRecurring: true,
  ),
  _MockTxn('Airtel Postpaid', 'cat_bills', 59900, 16, 'debit', isRecurring: true),
  _MockTxn('Netflix', 'cat_entertainment', 64900, 2, 'debit', isRecurring: true),
  _MockTxn(
    'Netflix',
    'cat_entertainment',
    64900,
    32,
    'debit',
    isRecurring: true,
  ),
  _MockTxn('BookMyShow', 'cat_entertainment', 76000, 10, 'debit'),
  _MockTxn('Apollo Pharmacy', 'cat_health', 54000, 5, 'debit'),
  _MockTxn('Practo Consultation', 'cat_health', 50000, 23, 'debit'),
  _MockTxn('Salary - Acme Corp', 'cat_income', 8500000, 1, 'credit'),
  _MockTxn(
    'Amazon.com (US)',
    'cat_shopping',
    820000,
    12,
    'debit',
    isInternational: true,
  ),
  _MockTxn(
    'Unknown Merchant 7291',
    'cat_other',
    1500000,
    4,
    'debit',
    isFlaggedUnusual: true,
  ),
  _MockTxn('UPI - Rahul Sharma', 'cat_transfer', 200000, 2, 'debit'),
  _MockTxn('UPI - Priya Nair', 'cat_transfer', 150000, 6, 'credit'),
];

/// Inserts a realistic spread of sample transactions for exercising the
/// app end to end — manual CRUD, dashboard aggregation, and the
/// international/unusual flags — without hand-typing each one. Entirely
/// local: this just writes rows into the on-device database.
Future<void> seedMockTransactions(AppDatabase db) async {
  const uuid = Uuid();
  final now = DateTime.now();

  await db.batch((b) {
    b.insertAll(
      db.transactions,
      [
        for (final m in _mockTransactions)
          TransactionsCompanion.insert(
            id: uuid.v4(),
            amountMinor: m.amountMinor,
            merchant: m.merchant,
            categoryId: Value(m.categoryId),
            type: m.type,
            date: now.subtract(Duration(days: m.daysAgo)),
            source: 'manual',
            isInternational: Value(m.isInternational),
            isFlaggedUnusual: Value(m.isFlaggedUnusual),
            isRecurring: Value(m.isRecurring),
          ),
      ],
    );
  });
}

/// Soft-deletes every transaction so the app can be tested again from a
/// clean slate without losing categories/rules.
Future<void> clearAllTransactions(AppDatabase db) async {
  await db.update(db.transactions).write(const TransactionsCompanion(isDeleted: Value(true)));
}
