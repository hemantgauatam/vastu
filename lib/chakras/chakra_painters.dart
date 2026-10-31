import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Base painter for all chakras with common drawing utilities
abstract class BaseChakraPainter extends CustomPainter {
  final double rotation;

  BaseChakraPainter({required this.rotation});

  /// Convert polar coords (r, angleDegrees where 0=up, 90=right) to Offset
  Offset polar(Offset center, double r, double angleDeg) {
    final a = (angleDeg - 90) * math.pi / 180.0;
    return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
  }

  /// Interpolate between two colors
  Color lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }

  /// Get color at angle from gradient stops
  Color gradientAt(List<MapEntry<double, Color>> stops, double deg) {
    double d = deg % 360;
    if (d < 0) d += 360;
    for (int i = 0; i < stops.length - 1; i++) {
      if (d >= stops[i].key && d <= stops[i + 1].key) {
        final t = (d - stops[i].key) / (stops[i + 1].key - stops[i].key);
        return lerpColor(stops[i].value, stops[i + 1].value, t);
      }
    }
    return stops.first.value;
  }

  /// Draw HORIZONTAL text at position (NOT rotated - key improvement!)
  void drawHorizontalText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(position.dx - tp.width / 2, position.dy - tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  /// Arc segment path between two radii and angles
  Path arcSegment(
    Offset c,
    double rInner,
    double rOuter,
    double startDeg,
    double endDeg,
  ) {
    final path = Path();
    final p1 = polar(c, rOuter, startDeg);
    final p2 = polar(c, rOuter, endDeg);
    final p3 = polar(c, rInner, endDeg);
    final p4 = polar(c, rInner, startDeg);
    path.moveTo(p1.dx, p1.dy);
    path.arcToPoint(p2, radius: Radius.circular(rOuter), clockwise: true);
    path.lineTo(p3.dx, p3.dy);
    path.arcToPoint(p4, radius: Radius.circular(rInner), clockwise: false);
    path.close();
    return path;
  }

  /// Apply rotation around center
  void applyRotation(Canvas canvas, Offset center) {
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);
  }

  /// Draw small arrow indicator (at top, pointing to current direction)
  void drawSmallArrow(Canvas canvas, Offset center, double radius) {
    final tipY = center.dy - radius - 10;
    final arrowWidth = 8.0;
    final arrowHeight = 10.0;

    final arrowPath = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - arrowWidth, tipY + arrowHeight)
      ..lineTo(center.dx + arrowWidth, tipY + arrowHeight)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFFFF4444)
        ..style = PaintingStyle.fill,
    );

    // Arrow outline
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant BaseChakraPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
