import 'package:intl/intl.dart';

/// The one way rupee amounts are written: Indian grouping (12,34,567), with
/// the symbol and decimals the caller wants.
NumberFormat appCurrency({String symbol = '₹', int decimalDigits = 2}) =>
    NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
