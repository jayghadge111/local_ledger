import 'package:flutter/material.dart';

/// The app's page backdrop: a flat, solid fill matching the current theme's
/// scaffold background (near-white in light mode, true black in dark mode —
/// the "Uber Slate" look). Kept as its own widget (rather than inlining
/// `scaffoldBackgroundColor` everywhere) so every screen gets it for free
/// just by wrapping in one place, same as before.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
