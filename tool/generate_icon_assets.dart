// Regenerates assets/icon/*.png from the logo mark design (kept in sync by
// hand with lib/shared/widgets/app_logo_mark.dart). Needs `dart:ui`'s image
// encoding, which is only available through the Flutter test harness — run
// with `flutter test tool/generate_icon_assets.dart`, then re-run
// `dart run flutter_launcher_icons` to regenerate the platform icon sets.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _navy = Color(0xFF152447);
const _gold = Color(0xFFF2B33D);

class Color {
  const Color(this.value);
  final int value;
  ui.Color get asUiColor => ui.Color(value);
}

Future<void> _paintMark(
  ui.Canvas canvas,
  double w, {
  required bool fullBleed,
  required double scale,
}) async {
  final cx = w / 2;
  final cy = w / 2;
  final markW = w * scale;
  final left = cx - markW / 2;
  final top = cy - markW / 2;

  if (fullBleed) {
    final bg = ui.Paint()..color = _navy.asUiColor;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, w), bg);
  }

  final shacklePaint = ui.Paint()
    ..color = _gold.asUiColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = markW * 0.05
    ..strokeCap = ui.StrokeCap.round;
  final shackleRadius = markW * 0.1375;
  final shackleCenter = ui.Offset(left + markW * 0.5, top + markW * 0.4375);
  canvas.drawArc(
    ui.Rect.fromCircle(center: shackleCenter, radius: shackleRadius),
    3.14159265,
    3.14159265,
    false,
    shacklePaint,
  );

  final bodyRect = ui.Rect.fromLTWH(
    left + markW * 0.2875,
    top + markW * 0.425,
    markW * 0.425,
    markW * 0.3625,
  );
  final bodyPaint = ui.Paint()..color = _gold.asUiColor;
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(bodyRect, ui.Radius.circular(markW * 0.0625)),
    bodyPaint,
  );

  // A classic keyhole (circle + tapering bar) instead of a rendered glyph:
  // text relies on a font being loaded, which this offscreen script can't
  // guarantee, and a character this small wouldn't stay legible at the
  // smallest launcher-icon sizes anyway.
  final keyholePaint = ui.Paint()..color = _navy.asUiColor;
  final keyholeCenter = ui.Offset(
    bodyRect.center.dx,
    bodyRect.top + bodyRect.height * 0.34,
  );
  canvas.drawCircle(keyholeCenter, bodyRect.width * 0.13, keyholePaint);
  final barRect = ui.Rect.fromLTWH(
    keyholeCenter.dx - bodyRect.width * 0.065,
    keyholeCenter.dy,
    bodyRect.width * 0.13,
    bodyRect.bottom - keyholeCenter.dy - bodyRect.height * 0.12,
  );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(barRect, ui.Radius.circular(barRect.width * 0.3)),
    keyholePaint,
  );
}

Future<void> _renderAndSave(String path, {required bool fullBleed, required double scale}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  await _paintMark(canvas, size, fullBleed: fullBleed, scale: scale);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  // ignore: avoid_print
  print('Wrote $path (${bytes.length} bytes)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate icon assets', () async {
    await _renderAndSave(
      'assets/icon/icon_master.png',
      fullBleed: true,
      scale: 1.0,
    );
    await _renderAndSave(
      'assets/icon/icon_foreground.png',
      fullBleed: false,
      scale: 0.62,
    );
  });
}
