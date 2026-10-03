import '../../core/db/app_database.dart';

/// What to call a transaction in lists and details. Money moved between the
/// user's own accounts is a "Self Transfer" whatever name the bank printed
/// (usually the user's own).
String transactionTitle(Transaction t) =>
    t.kind == 'transfer' ? 'Self Transfer' : t.merchant;
