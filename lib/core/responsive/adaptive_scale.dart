import 'dart:ui' show DisplayFeature;

import 'package:flutter/material.dart';

/// How much a window is scaled up so the app reads right on a tablet.
///
/// Phones (anything under 600 points on the short side) are left alone. From
/// there the scale grows with the window — an iPad mini is about 1.16×, an
/// 11-inch about 1.3×, a 13-inch 1.5× — so text, controls and spacing all
/// grow in proportion and the layout fills the screen instead of sitting
/// small in the middle of it. It follows the *short* side, so turning the
/// device does not change it.
double uiScaleFor(Size window) {
  final shortest = window.shortestSide;
  if (shortest < 600) return 1.0;
  return (shortest / 640).clamp(1.0, 1.5);
}

/// While true the app is drawn at its normal size even on a tablet.
///
/// The first-run tour places its highlights and tooltips in real screen
/// coordinates, which do not line up inside a scaled-up tree, so the shell
/// switches the scale off for the few seconds the tour is on screen and back
/// on when it ends.
final adaptiveScaleSuspended = ValueNotifier<bool>(false);

/// Draws [child] as if the window were smaller by [uiScaleFor], then scales
/// it up to fill the real one. Every screen, dialog, sheet and snackbar below
/// it grows together; nothing is shrunk, and on a phone it does nothing.
///
/// Inside, `MediaQuery` reports the smaller (logical) size, insets and
/// display features, so layout decisions — the navigation rail, the content
/// column, the keyboard — are made for the size things are actually laid out
/// at.
class AdaptiveScale extends StatelessWidget {
  const AdaptiveScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adaptiveScaleSuspended,
      builder: (context, suspended, _) => _build(context, suspended),
    );
  }

  Widget _build(BuildContext context, bool suspended) {
    final media = MediaQuery.of(context);
    final scale = suspended ? 1.0 : uiScaleFor(media.size);

    final logical = Size(media.size.width / scale, media.size.height / scale);
    Rect shrink(Rect r) => Rect.fromLTRB(
      r.left / scale,
      r.top / scale,
      r.right / scale,
      r.bottom / scale,
    );
    final scaled = media.copyWith(
      size: logical,
      padding: media.padding / scale,
      viewPadding: media.viewPadding / scale,
      viewInsets: media.viewInsets / scale,
      systemGestureInsets: media.systemGestureInsets / scale,
      displayFeatures: [
        for (final f in media.displayFeatures)
          DisplayFeature(bounds: shrink(f.bounds), type: f.type, state: f.state),
      ],
    );

    // Same widgets at any scale (at 1.0 the FittedBox is a no-op), so turning
    // the scale on or off changes numbers, not the tree, and nothing below
    // is rebuilt from scratch.
    return _ScaleScope(
      scale: scale,
      child: SizedBox.fromSize(
        size: media.size,
        child: FittedBox(
          // The logical size has exactly the window's aspect ratio, so this
          // is a uniform scale by [scale] and nothing is cropped or stretched.
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: logical,
            child: MediaQuery(data: scaled, child: child),
          ),
        ),
      ),
    );
  }
}

/// Carries the scale down the tree, so "is this a tablet?" does not depend on
/// `MediaQuery` (which a content column narrows).
class _ScaleScope extends InheritedWidget {
  const _ScaleScope({required this.scale, required super.child});

  final double scale;

  @override
  bool updateShouldNotify(_ScaleScope old) => scale != old.scale;
}

/// The scale the app is drawn at (1.0 on a phone).
double uiScaleOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_ScaleScope>()?.scale ?? 1.0;

/// True when the window is a tablet (so [AdaptiveScale] is scaling up).
bool isTabletLayout(BuildContext context) => uiScaleOf(context) > 1.0;

/// Extra size for focused screens (onboarding, PIN) on a tablet, on top of
/// [AdaptiveScale]: they have little on them, so they can afford to be big.
double focusedBoost(BuildContext context) =>
    isTabletLayout(context) ? 1.35 : 1.0;

/// Makes text on a focused screen as large as [focusedBoost] says. Sizes
/// that are not text are scaled by the screens themselves.
class FocusedBoost extends StatelessWidget {
  const FocusedBoost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final boost = focusedBoost(context);
    if (boost == 1.0) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(media.textScaler.scale(1) * boost),
      ),
      child: child,
    );
  }
}
