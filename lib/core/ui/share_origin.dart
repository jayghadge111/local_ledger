import 'dart:ui';

/// Where the iPad share popover should point from. iPad needs an anchor
/// rectangle for the share sheet (without one it can throw instead of
/// showing), and a phone ignores it. A point in the middle of the screen is
/// always valid and needs no widget context, so background callers can use it.
Rect shareOrigin() {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
  final view = views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
