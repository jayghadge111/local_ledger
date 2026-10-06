import '../../core/money_format.dart';
import 'package:flutter/material.dart';

/// Counts up from zero to the given rupee amount (stored as minor units) the
/// first time it appears — used for headline dashboard figures. Later changes
/// (a new month, or rows arriving during an import) glide briefly from the
/// current figure instead of replaying the whole count-up, so the number never
/// looks stuck while data keeps landing.
class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({super.key, required this.amountMinor, this.style});

  final int amountMinor;
  final TextStyle? style;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount> {
  bool _updated = false;

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amountMinor != widget.amountMinor) _updated = true;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = appCurrency(symbol: '₹', decimalDigits: 0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.amountMinor / 100),
      duration: Duration(milliseconds: _updated ? 220 : 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(formatter.format(value), style: widget.style);
      },
    );
  }
}
