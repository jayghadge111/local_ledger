import 'package:flutter/material.dart';

/// The app's icon mark: a gold padlock inscribed with a rupee symbol on a
/// navy rounded square — the same design shown and approved for the
/// launcher icon. Kept as a painter (not an image asset) so it renders
/// crisply at any size, including the splash screen.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 120});

  final double size;

  static const _navy = Color(0xFF152447);
  static const _gold = Color(0xFFF2B33D);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LockCoinPainter()),
    );
  }
}

class _LockCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    final bg = Paint()..color = AppLogoMark._navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, w),
        Radius.circular(w * 0.225),
      ),
      bg,
    );

    final shacklePaint = Paint()
      ..color = AppLogoMark._gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    final shackleRadius = w * 0.1375;
    final shackleCenter = Offset(w * 0.5, w * 0.4375);
    canvas.drawArc(
      Rect.fromCircle(center: shackleCenter, radius: shackleRadius),
      3.14159265, // start at left (180deg)
      3.14159265, // sweep through the top to the right (180deg)
      false,
      shacklePaint,
    );

    final bodyRect = Rect.fromLTWH(
      w * 0.2875,
      w * 0.425,
      w * 0.425,
      w * 0.3625,
    );
    final bodyPaint = Paint()..color = AppLogoMark._gold;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.0625)),
      bodyPaint,
    );

    // Classic keyhole — matches the launcher icon (see
    // test/_generate_icon_assets.dart, which renders this same shape).
    final keyholePaint = Paint()..color = AppLogoMark._navy;
    final keyholeCenter = Offset(
      bodyRect.center.dx,
      bodyRect.top + bodyRect.height * 0.34,
    );
    canvas.drawCircle(keyholeCenter, bodyRect.width * 0.13, keyholePaint);
    final barRect = Rect.fromLTWH(
      keyholeCenter.dx - bodyRect.width * 0.065,
      keyholeCenter.dy,
      bodyRect.width * 0.13,
      bodyRect.bottom - keyholeCenter.dy - bodyRect.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(barRect.width * 0.3)),
      keyholePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
