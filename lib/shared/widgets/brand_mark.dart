import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The TrueLedger icon (the keyhole T on a dark tile), drawn from the
/// brand SVG so it stays sharp at any size and reads on light and dark pages.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/trueledger_icon.svg',
      width: size,
      height: size,
      semanticsLabel: 'TrueLedger',
    );
  }
}
