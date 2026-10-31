import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry measured from the user-supplied 600 x 546 fifth-chakra image.
/// The visible outer circle is a 510 px square. A dedicated inner ring holds
/// Sattava, Tamas, and Rajas, leaving the new innermost circle for the map.
/// These values are intentionally independent
/// of the geometry used by the other four map chakras.
class FifthChakraGeometry {
  static const double innerDiameterFraction = 0.56;
  static const double gunaRingOuterFraction = 324 / 510;

  static Size mapSize(double chakraSide, double aspectRatio, double mapScale) {
    final aspect = aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1.0;
    final diagonal = chakraSide * innerDiameterFraction * mapScale;
    final height = diagonal / math.sqrt(aspect * aspect + 1);
    return Size(height * aspect, height);
  }

  static double chakraSideForMap(Size mapSize, double mapScale) {
    final diagonal = math.sqrt(
      mapSize.width * mapSize.width + mapSize.height * mapSize.height,
    );
    return diagonal / (innerDiameterFraction * mapScale);
  }

  static double rotationForBearing(double bearing) => -bearing;
}

/// Draws only the fifth chakra, with each label in its own designated ring.
/// The supplied screenshot is the reference for its blue line work and zones.
class FifthChakraPainter extends CustomPainter {
  static const _directionLabels = [
    'NORTH\nCUSTOMER',
    'NNE\nIMMUNITY',
    'NE\nCLARITY',
    'ENE\nRECREATION',
    'EAST\nNETWORKING',
    'ESE\nANALYZING',
    'SE\nMONEY FLOW',
    'SSE\nENERGY',
    'SOUTH\nFAME',
    'SSW\nWASTAGE',
    'SW\nRELATIONSHIP',
    'WSW\nEDUCATION',
    'WEST\nGAINS',
    'WNW\nDEPRESSION',
    'NW\nSUPPORT',
    'NNW\nATTRACTION',
  ];
  static const _organLabels = [
    'KIDNEY',
    'PERICARDIUM',
    'CIRCULATION',
    'LIVER',
    'GALL BLADDER',
    'SPLEEN',
    'STOMACH',
    'HEART',
    'LUNGS',
    'COLON',
    'INTESTINE',
    'BLADDER',
  ];

  final double rotationDegrees;
  final double opacity;

  const FifthChakraPainter({
    required this.rotationDegrees,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final blue = const Color(0xFF0788FF).withValues(alpha: opacity);
    final paint = Paint()
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDegrees * math.pi / 180);
    for (final fraction in [
      1.0,
      0.89,
      0.77,
      0.69,
      FifthChakraGeometry.gunaRingOuterFraction,
      FifthChakraGeometry.innerDiameterFraction,
    ]) {
      canvas.drawCircle(Offset.zero, radius * fraction, paint);
    }
    for (var degree = 0; degree < 360; degree++) {
      final angle = (degree - 90) * math.pi / 180;
      final tickLength = radius *
          (degree % 10 == 0
              ? 0.055
              : degree % 5 == 0
                  ? 0.035
                  : 0.017);
      canvas.drawLine(
        Offset(math.cos(angle) * (radius - tickLength),
            math.sin(angle) * (radius - tickLength)),
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }
    for (var sector = 0; sector < 16; sector++) {
      final angle = (sector * 22.5 - 90 + 11.25) * math.pi / 180;
      canvas.drawLine(
        Offset.zero,
        Offset(
          math.cos(angle) * radius * FifthChakraGeometry.innerDiameterFraction,
          math.sin(angle) * radius * FifthChakraGeometry.innerDiameterFraction,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(
            math.cos(angle) * radius * 0.77, math.sin(angle) * radius * 0.77),
        Offset(
            math.cos(angle) * radius * 0.89, math.sin(angle) * radius * 0.89),
        paint,
      );
      _paintLabel(
        canvas,
        _directionLabels[sector],
        sector * 22.5,
        radius * 0.83,
        size.shortestSide * 0.016,
        blue,
      );
    }
    for (var organ = 0; organ < _organLabels.length; organ++) {
      final angle = (organ * 30 - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(
            math.cos(angle) * radius * 0.69, math.sin(angle) * radius * 0.69),
        Offset(
            math.cos(angle) * radius * 0.77, math.sin(angle) * radius * 0.77),
        paint,
      );
      _paintLabel(
        canvas,
        _organLabels[organ],
        organ * 30 + 15,
        radius * 0.73,
        size.shortestSide * 0.013,
        blue,
      );
    }
    for (final boundary in [0.0, 120.0, 240.0]) {
      final angle = (boundary - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(
            math.cos(angle) *
                radius *
                FifthChakraGeometry.gunaRingOuterFraction,
            math.sin(angle) *
                radius *
                FifthChakraGeometry.gunaRingOuterFraction),
        Offset(
            math.cos(angle) * radius * 0.69, math.sin(angle) * radius * 0.69),
        paint,
      );
    }
    for (final (label, angle) in [
      ('KAPHA', 45.0),
      ('PITTA', 150.0),
      ('VATTA', 270.0),
    ]) {
      _paintLabel(canvas, label, angle, radius * 0.663,
          size.shortestSide * 0.014, blue);
    }
    for (final (label, angle) in [
      ('SATTAVA', 330.0),
      ('TAMAS', 90.0),
      ('RAJAS', 210.0),
    ]) {
      _paintLabel(
          canvas, label, angle, radius * 0.59, size.shortestSide * 0.015, blue);
    }
    for (var degree = 0; degree < 360; degree += 10) {
      _paintLabel(
        canvas,
        '$degree',
        degree.toDouble(),
        radius * 0.92,
        size.shortestSide * 0.02,
        blue,
      );
    }
    canvas.restore();
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    double degree,
    double distance,
    double fontSize,
    Color color,
  ) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.rotate(degree * math.pi / 180);
    canvas.translate(0, -distance);
    if (degree > 90 && degree < 270) canvas.rotate(math.pi);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(FifthChakraPainter oldDelegate) =>
      oldDelegate.rotationDegrees != rotationDegrees ||
      oldDelegate.opacity != opacity;
}
