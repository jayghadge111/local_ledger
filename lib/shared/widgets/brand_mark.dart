import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The NativeSpend icon (the vault on a soft grey tile), drawn from the
/// brand SVG so it stays sharp at any size and reads on light and dark pages.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/nativespend_icon.svg',
      width: size,
      height: size,
      semanticsLabel: 'NativeSpend',
    );
  }
}
