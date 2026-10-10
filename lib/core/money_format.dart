import 'package:intl/intl.dart';

final _formats = <String, NumberFormat>{};

/// The one way rupee amounts are written: Indian grouping (12,34,567), with
/// the symbol and decimals the caller wants.
///
/// Building a [NumberFormat] looks up locale data, which is slow enough to
/// matter when every list row asks for one, so each distinct format is made
/// once and shared (formatting itself has no state).
NumberFormat appCurrency({String symbol = '₹', int decimalDigits = 2}) =>
    _formats.putIfAbsent(
      '$symbol|$decimalDigits',
      () => NumberFormat.currency(
        locale: 'en_IN',
        symbol: symbol,
        decimalDigits: decimalDigits,
      ),
    );
