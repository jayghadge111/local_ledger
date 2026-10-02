import 'package:drift/drift.dart';

/// Money is always stored as an integer in the currency's minor unit
/// (paise for INR) to avoid floating-point rounding errors.
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bankName => text().nullable()();
  TextColumn get last4 => text().nullable()();
  TextColumn get accountType => text()(); // bank, card, wallet, cash
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get merchant => text()();

  /// AES-256-GCM encrypted original SMS/email text, base64-encoded.
  TextColumn get rawTextEncrypted => text().nullable()();

  TextColumn get source => text()(); // sms, email, manual
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()(); // debit, credit
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringGroupId =>
      text().nullable().references(RecurringGroups, #id)();
  BoolColumn get isInternational =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isFlaggedUnusual =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Rules extends Table {
  TextColumn get id => text()();
  TextColumn get pattern => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get source => text()(); // system, user

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringGroups extends Table {
  TextColumn get id => text()();
  TextColumn get merchantPattern => text()();
  IntColumn get expectedAmountMinor => integer()();
  IntColumn get intervalDays => integer()();
  DateTimeColumn get nextExpectedDate => dateTime()();
  DateTimeColumn get lastConfirmedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Alerts extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().nullable().references(Transactions, #id)();
  TextColumn get alertType => text()(); // recurring_due, international, unusual, duplicate
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A simple recurring monthly spending limit per category.
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get monthlyLimitMinor => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic local key-value store for app preferences and the app-lock PIN
/// (hash + salt only — see HashingService; the PIN itself is never stored).
class AppSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}
