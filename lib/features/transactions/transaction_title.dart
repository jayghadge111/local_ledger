import '../../core/db/app_database.dart';

/// What to call a transaction in lists and details. Money moved between the
/// user's own accounts is a "Self Transfer" whatever name the bank printed
/// (usually the user's own).
String transactionTitle(Transaction t) =>
    t.kind == 'transfer' ? 'Self Transfer' : t.merchant;

/// Why a credit-card bill payment is listed but left out of the totals.
const cardPaymentNote =
    'Credit card bill payment. Not counted as spending, because the '
    'purchases it pays for were already counted when you used the card.';
