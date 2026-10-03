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

  /// The merchant text exactly as the bank sent it, kept next to the
  /// cleaned-up [merchant] so aliases can be learned and re-applied.
  TextColumn get rawMerchant => text().nullable()();

  /// normal | transfer (between the user's own accounts — not spending or
  /// income) | refund (a credit that reverses an earlier debit).
  TextColumn get kind => text().withDefault(const Constant('normal'))();

  /// True once the user set [kind] by hand, so auto-detection never
  /// overrides their decision.
  BoolColumn get kindLocked => boolean().withDefault(const Constant(false))();

  /// Shared by the two halves of a detected transfer.
  TextColumn get transferGroupId => text().nullable()();

  /// For [kind] == refund: the debit this credit reverses.
  TextColumn get refundOfId => text().nullable()();

  /// The original message talked about a refund/reversal. That wording
  /// isn't in [merchant], so it's kept here for the refund matcher.
  BoolColumn get refundHint => boolean().withDefault(const Constant(false))();

  /// Other channels that reported this same transaction and were merged into
  /// it (comma-separated, e.g. "email") — each channel can be merged into a
  /// transaction only once, so two real payments are never collapsed.
  TextColumn get alsoInSource => text().nullable()();

  /// SHA-512 of source + original message text + timestamp; identical
  /// re-scans of the same message produce the same hash.
  TextColumn get sourceHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Strings that identify the user themself (own name, own VPA, own account
/// last-4) — a transaction mentioning one is a transfer between their own
/// accounts, not spending.
class OwnIdentifiers extends Table {
  TextColumn get id => text()();
  TextColumn get value => text()(); // stored lowercase

  @override
  Set<Column> get primaryKey => {id};
}

/// User-taught merchant clean-ups: raw bank text [pattern] → [displayName].
class MerchantAliases extends Table {
  TextColumn get id => text()();
  TextColumn get pattern => text()(); // stored lowercase
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One person's share of an expense the user paid for.
class SplitShares extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get personName => text()();
  IntColumn get shareMinor => integer()();
  BoolColumn get settled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bank messages that looked like a transaction but couldn't be parsed,
/// held (encrypted) for the user to review by hand.
class UnparsedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()(); // sms, email
  TextColumn get senderCode => text().nullable()();
  TextColumn get rawTextEncrypted => text()();
  TextColumn get hash => text()();
  DateTimeColumn get receivedAt => dateTime()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

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
