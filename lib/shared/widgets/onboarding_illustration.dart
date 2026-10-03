import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An onboarding picture on a soft grey tile. The drawings use dark outlines,
/// so the tile stays light in dark mode too.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.asset,
    this.height = 210,
  });

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E6EA),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(8),
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
  }
}
