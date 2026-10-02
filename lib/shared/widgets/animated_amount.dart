import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Counts up from zero to the given rupee amount (stored as minor units)
/// whenever the value changes — used for headline dashboard figures.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.amountMinor,
    this.style,
  });

  final int amountMinor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amountMinor / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(formatter.format(value), style: style);
      },
    );
  }
}
