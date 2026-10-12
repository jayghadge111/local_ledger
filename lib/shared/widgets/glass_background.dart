import 'package:flutter/material.dart';

/// The widest a normal page (lists, cards, settings) is allowed to be, in
/// layout points (the app is already scaled up on a tablet, see
/// `AdaptiveScale`). On a phone nothing changes; on a wide window the page
/// becomes a centred column instead of cards stretched across the screen.
const kContentMaxWidth = 720.0;

/// The widest a focused, single-purpose screen (onboarding, PIN, name) gets.
const kFocusedMaxWidth = 560.0;

/// Centres [child] and keeps it at most [maxWidth] wide, on a wider screen.
///
/// Narrower than [maxWidth] it does nothing at all, and it keeps the child's
/// constraints tight, so screens behave exactly as they did. Inside, the
/// reported screen size is the column's, so anything that sizes itself from
/// `MediaQuery` (and not just from its constraints) adapts to the column.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth <= maxWidth) return child;
        final media = MediaQuery.of(context);
        final height = box.hasBoundedHeight ? box.maxHeight : null;
        return Center(
          child: SizedBox(
            width: maxWidth,
            height: height,
            child: MediaQuery(
              data: media.copyWith(
                size: Size(maxWidth, height ?? media.size.height),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// The app's page backdrop: a flat, solid fill matching the current theme's
/// scaffold background (near-white in light mode, true black in dark mode —
/// the "Uber Slate" look). Kept as its own widget (rather than inlining
/// `scaffoldBackgroundColor` everywhere) so every screen gets it for free
/// just by wrapping in one place, same as before.
///
/// The fill covers the whole window; the page itself is held to
/// [maxContentWidth] and centred on a wide one (pass null to let it run full
/// width, as the app shell does so its navigation rail can stay at the edge).
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
    this.maxContentWidth = kContentMaxWidth,
  });

  final Widget child;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final width = maxContentWidth;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: width == null
          ? child
          : ContentWidth(maxWidth: width, child: child),
    );
  }
}
