// Renders the brand SVGs in assets/brand/ to the PNGs the launcher-icon and
// splash generators need. Run with:
//   flutter test tool/render_brand_assets_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jobs = <(String, String, int)>[
    ('assets/brand/launcher_full_bleed.svg', 'assets/icon/icon_master.png', 1024),
    ('assets/brand/launcher_foreground.svg', 'assets/icon/icon_foreground.png', 1024),
    ('assets/brand/splash_mark.svg', 'assets/icon/splash_mark.png', 512),
    ('assets/brand/nativespend_icon.svg', 'assets/icon/web_icon.png', 1024),
  ];

  for (final (svg, png, size) in jobs) {
    testWidgets('render $svg', (tester) async {
      tester.view.physicalSize = Size(size.toDouble(), size.toDouble());
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: SizedBox.expand(child: SvgPicture.string(File(svg).readAsStringSync(), fit: BoxFit.contain)),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();

      final bytes = await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File(png).writeAsBytesSync(bytes!);
    });
  }
}
