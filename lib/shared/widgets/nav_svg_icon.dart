import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A bottom-navigation icon drawn from an SVG in `assets/icons/nav/`.
///
/// Takes its colour and size from the surrounding [IconTheme], which the
/// navigation bar/rail sets per state (selected / unselected), so the icons
/// follow the app theme in light and dark. [scale] evens out the padding
/// baked into each artwork so they all look the same size.
class NavSvgIcon extends StatelessWidget {
  const NavSvgIcon(this.name, {super.key, this.scale = 1});

  /// File name without extension, e.g. `home`.
  final String name;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = (iconTheme.size ?? 24) * scale;
    final color = iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox.square(
      dimension: (iconTheme.size ?? 24),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/nav/$name.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
