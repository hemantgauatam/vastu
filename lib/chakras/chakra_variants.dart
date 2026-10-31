import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chakra_painters.dart';
import 'provided_chakra_painters.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHAKRA 32 PANDAS - Devta names arranged in outer ring
// ═══════════════════════════════════════════════════════════════════════════
class Chakra32PadasPainter extends BaseChakraPainter {
  static const List<String> pandas = [
    'Naga',
    'Mukhya',
    'Bhallat',
    'Soma',
    'Bhujaga',
    'Aditi',
    'Diti',
    'Shikhi',
    'Brahma',
    'Rudra',
    'Indra',
    'Surya',
    'Vayau',
    'Varuna',
    'Mitra',
    'Aryama',
    'Kartik',
    'Ashvini',
    'Marut',
    'Ketu',
    'Ravi',
    'Shukra',
    'Budha',
    'Chandra',
    'Jaya',
    'Surya',
    'Vijaya',
    'Ananda',
    'Puruhta',
    'Asura',
    'Diti',
    'Hiranya',
  ];

  static const List<Color> pandas4Colors = [
    Color(0xFF2E86C1), // Blue - North/Water
    Color(0xFF52BE80), // Green - East/Air
    Color(0xFFC0392B), // Red - South/Fire
    Color(0xFFF1C40F), // Yellow/Gold - West/Earth
  ];

  Chakra32PadasPainter({required super.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - 2;
    final rInner = rOuter * 0.75;
    final rMid = (rOuter + rInner) / 2;

    canvas.save();
    applyRotation(canvas, center);

    canvas.drawCircle(center, rOuter, Paint()..color = const Color(0xFFFFFEF5));
    canvas.drawCircle(
      center,
      rInner,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // 32 radiating lines from center
    for (int i = 0; i < 32; i++) {
      final angle = (360 / 32) * i;
      final color = pandas4Colors[i % 4];
      canvas.drawLine(
        center,
        polar(center, rOuter, angle),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Segments
    for (int i = 0; i < 32; i++) {
      final angle = (360 / 32) * i;
      final color = pandas4Colors[i % 4];
      final path = arcSegment(center, rInner, rOuter, angle, angle + 11.25);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.3));
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Pandas names
    final textStyle = GoogleFonts.inter(
      fontSize: size.width * 0.013,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w600,
    );
    for (int i = 0; i < 32; i++) {
      final angle = (360 / 32) * i + 5.625;
      final pos = polar(center, rMid, angle);
      drawHorizontalText(canvas, pandas[i], pos, textStyle);
    }

    canvas.drawCircle(
      center,
      rOuter,
      Paint()
        ..color = const Color(0xFFC9A961)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
    drawSmallArrow(canvas, center, rOuter);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAKRA 5 ELEMENTS - Wu Xing style (Water/Wood/Fire/Earth/Metal)
// Based on user reference image with generative cycle arrows
// ═══════════════════════════════════════════════════════════════════════════
class Chakra5ElementsPainter extends BaseChakraPainter {
  // Wu Xing 5 Elements - exact colors from reference image
  static const List<Map<String, dynamic>> wuXing = [
    {
      'name': 'WATER',
      'color': Color(0xFF4A90D9),
      'icon': '💧',
      'angle': 0.0,
    }, // Top
    {
      'name': 'WOOD',
      'color': Color(0xFF5BB85B),
      'icon': '🎋',
      'angle': 72.0,
    }, // Right
    {
      'name': 'FIRE',
      'color': Color(0xFFE74C3C),
      'icon': '🔥',
      'angle': 144.0,
    }, // Bottom-right
    {
      'name': 'EARTH',
      'color': Color(0xFFD4A847),
      'icon': '⛰️',
      'angle': 216.0,
    }, // Bottom-left
    {
      'name': 'METAL',
      'color': Color(0xFF8C8C8C),
      'icon': '💎',
      'angle': 288.0,
    }, // Top-left
  ];

  Chakra5ElementsPainter({required super.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - 4;
    final rRing = rOuter * 0.32; // Element circle radius
    final rOrbit = rOuter * 0.72; // Distance from center to element circle

    canvas.save();
    applyRotation(canvas, center);

    // Background white circle
    canvas.drawCircle(
      center,
      rOuter,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    // Draw 5 grey arrows in inner ring (the cycle indicators)
    for (int i = 0; i < 5; i++) {
      final startAngle = (i * 72.0) + 36;

      final arrowPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.25)
        ..strokeWidth = size.width * 0.025
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw arc segment
      final rect = Rect.fromCircle(center: center, radius: rOuter * 0.42);
      canvas.drawArc(
        rect,
        (startAngle - 90) * math.pi / 180,
        70 * math.pi / 180,
        false,
        arrowPaint,
      );
    }

    // Draw colored arrows (generative cycle: Water→Wood→Fire→Earth→Metal→Water)
    for (int i = 0; i < 5; i++) {
      final element = wuXing[i];
      final nextElement = wuXing[(i + 1) % 5];
      final color = element['color'] as Color;

      // Draw curved arrow between elements
      _drawCurvedArrow(
        canvas,
        center,
        rOrbit,
        element['angle'] as double,
        nextElement['angle'] as double,
        color,
      );
    }

    // Draw 5 element circles
    for (int i = 0; i < 5; i++) {
      final element = wuXing[i];
      final pos = polar(center, rOrbit, element['angle'] as double);
      final color = element['color'] as Color;

      // White background circle
      canvas.drawCircle(pos, rRing, Paint()..color = Colors.white);

      // Colored ring border
      canvas.drawCircle(
        pos,
        rRing,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.012,
      );

      // Inner colored fill (light)
      canvas.drawCircle(
        pos,
        rRing * 0.85,
        Paint()..color = color.withValues(alpha: 0.08),
      );

      // Element icon (drawn as simplified shape)
      _drawElementIcon(
        canvas,
        pos,
        rRing * 0.45,
        element['name'] as String,
        color,
      );

      // Element name label
      final textStyle = GoogleFonts.inter(
        fontSize: size.width * 0.020,
        color: color,
        fontWeight: FontWeight.w700,
      );
      drawHorizontalText(
        canvas,
        element['name'] as String,
        Offset(pos.dx, pos.dy + rRing * 0.55),
        textStyle,
      );
    }

    // Center text "5 Elements"
    final centerStyle = GoogleFonts.inter(
      fontSize: size.width * 0.042,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w700,
    );
    drawHorizontalText(
      canvas,
      '5',
      Offset(center.dx, center.dy - size.width * 0.025),
      centerStyle,
    );

    final subStyle = GoogleFonts.inter(
      fontSize: size.width * 0.026,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w600,
    );
    drawHorizontalText(
      canvas,
      'Elements',
      Offset(center.dx, center.dy + size.width * 0.025),
      subStyle,
    );

    canvas.restore();
    drawSmallArrow(canvas, center, rOuter);
  }

  /// Draw a curved arrow between two angles
  void _drawCurvedArrow(
    Canvas canvas,
    Offset center,
    double radius,
    double fromAngle,
    double toAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate sweep
    double sweep = toAngle - fromAngle;
    if (sweep < 0) sweep += 360;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startRad = (fromAngle - 90 + 18) * math.pi / 180;
    final sweepRad = (sweep - 36) * math.pi / 180;

    canvas.drawArc(rect, startRad, sweepRad, false, paint);

    // Draw arrowhead at end
    final endAngle = fromAngle + sweep - 18;
    final endPos = polar(center, radius, endAngle);
    final headAngle = endAngle - 90;
    final headRad = headAngle * math.pi / 180;

    final arrowSize = 8.0;
    final p1 = Offset(
      endPos.dx + arrowSize * math.cos(headRad + 2.4),
      endPos.dy + arrowSize * math.sin(headRad + 2.4),
    );
    final p2 = Offset(
      endPos.dx + arrowSize * math.cos(headRad - 2.4),
      endPos.dy + arrowSize * math.sin(headRad - 2.4),
    );

    final arrowPath = Path()
      ..moveTo(endPos.dx, endPos.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  /// Draw simple element icon based on name
  void _drawElementIcon(
    Canvas canvas,
    Offset center,
    double size,
    String name,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (name) {
      case 'WATER':
        // Water drop
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..quadraticBezierTo(
            center.dx + size * 0.8,
            center.dy - size * 0.2,
            center.dx + size * 0.5,
            center.dy + size * 0.4,
          )
          ..quadraticBezierTo(
            center.dx,
            center.dy + size * 0.9,
            center.dx - size * 0.5,
            center.dy + size * 0.4,
          )
          ..quadraticBezierTo(
            center.dx - size * 0.8,
            center.dy - size * 0.2,
            center.dx,
            center.dy - size,
          )
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'WOOD':
        // Bamboo/tree - vertical lines
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: size * 0.6,
              height: size * 1.6,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
        // Leaves
        canvas.drawCircle(
          Offset(center.dx - size * 0.5, center.dy - size * 0.5),
          size * 0.3,
          paint,
        );
        canvas.drawCircle(
          Offset(center.dx + size * 0.5, center.dy - size * 0.5),
          size * 0.3,
          paint,
        );
        break;
      case 'FIRE':
        // Flame
        final path = Path()
          ..moveTo(center.dx, center.dy + size * 0.8)
          ..quadraticBezierTo(
            center.dx - size * 0.8,
            center.dy + size * 0.3,
            center.dx - size * 0.4,
            center.dy - size * 0.3,
          )
          ..quadraticBezierTo(
            center.dx - size * 0.2,
            center.dy - size * 0.6,
            center.dx,
            center.dy - size,
          )
          ..quadraticBezierTo(
            center.dx + size * 0.4,
            center.dy - size * 0.3,
            center.dx + size * 0.6,
            center.dy + size * 0.2,
          )
          ..quadraticBezierTo(
            center.dx + size * 0.5,
            center.dy + size * 0.7,
            center.dx,
            center.dy + size * 0.8,
          )
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'EARTH':
        // Mountains
        final path = Path()
          ..moveTo(center.dx - size, center.dy + size * 0.6)
          ..lineTo(center.dx - size * 0.4, center.dy - size * 0.6)
          ..lineTo(center.dx, center.dy + size * 0.2)
          ..lineTo(center.dx + size * 0.4, center.dy - size * 0.8)
          ..lineTo(center.dx + size, center.dy + size * 0.6)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'METAL':
        // Diamond/crystal
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx + size * 0.7, center.dy)
          ..lineTo(center.dx, center.dy + size)
          ..lineTo(center.dx - size * 0.7, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        // Inner lines
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(center.dx, center.dy - size),
          Offset(center.dx, center.dy + size),
          linePaint,
        );
        canvas.drawLine(
          Offset(center.dx - size * 0.7, center.dy),
          Offset(center.dx + size * 0.7, center.dy),
          linePaint,
        );
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAKRA MAHAVASTU - Comprehensive Vastu chakra (based on reference image 2)
// 4 concentric rings: Life Aspects → 32 Devtas → Body Organs → Brahma center
// ═══════════════════════════════════════════════════════════════════════════
class ChakraMahaVastuPainter extends BaseChakraPainter {
  // 16 Outer life aspects (from reference image)
  static const List<String> outerZones = [
    'CUSTOMER',
    'IMMUNITY',
    'MOTIVATION',
    'HAPPINESS',
    'NETWORKING',
    'OVERTHINKING',
    'MONEY',
    'CONFIDENCE',
    'FAME',
    'DISPOSAL',
    'RELATIONSHIP',
    'STUDIES',
    'GAINS',
    'DEPRESSION',
    'SUPPORT',
    'SEXUALITY',
  ];

  // 16 zone colors (matching the reference image)
  static const List<Color> zoneColors = [
    Color(0xFFB8DCE8),
    Color(0xFFB8DCE8),
    Color(0xFFB5DAA8),
    Color(0xFFB5DAA8), // N to ENE
    Color(0xFFB5DAA8),
    Color(0xFFF5C4BC),
    Color(0xFFF5C4BC),
    Color(0xFFF5C4BC), // E to SSE
    Color(0xFFF5C4BC),
    Color(0xFFF5E8A8),
    Color(0xFFF5E8A8),
    Color(0xFFF5E8A8), // S to WSW
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFB8DCE8), // W to NNW
  ];

  // 32 inner devta names
  static const List<String> devtaNames = [
    'Solution',
    'Doctor',
    'CareTaker',
    'Restrainer',
    'Visionary',
    'Fertilizer',
    'Go Getter',
    'Manager',
    'Regulator',
    'Judge',
    'Grinder',
    'Expander',
    'Uplifter',
    'Navigator',
    'Cruncher',
    'Binder',
    'Discipliner',
    'Artist',
    'Cleaner',
    'Hunter',
    'Ancestors',
    'Guardian',
    'Strategist',
    'Grasper',
    'Guru',
    'Chief Operator',
    'Controller',
    'Choker',
    'Addiction',
    'Weakner',
    'Attacker',
    'Designer',
  ];

  ChakraMahaVastuPainter({required super.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - 2;
    final r1 = rOuter * 0.95; // Outer ring (life aspects)
    final r2 = rOuter * 0.78; // 32 devtas ring
    final r3 = rOuter * 0.55; // Body organs ring
    final r4 = rOuter * 0.35; // Doshas ring
    final r5 = rOuter * 0.18; // Center Brahma

    canvas.save();
    applyRotation(canvas, center);

    // White background
    canvas.drawCircle(center, r1, Paint()..color = Colors.white);

    // ===== RING 1: 16 Outer Life Aspects =====
    for (int i = 0; i < 16; i++) {
      final angle1 = (360 / 16) * i - 11.25;
      final angle2 = angle1 + 22.5;
      final path = arcSegment(center, r2, r1, angle1, angle2);
      canvas.drawPath(path, Paint()..color = zoneColors[i]);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Life aspect labels
    final outerStyle = GoogleFonts.inter(
      fontSize: size.width * 0.013,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w700,
    );
    for (int i = 0; i < 16; i++) {
      final angle = (360 / 16) * i;
      final pos = polar(center, (r1 + r2) / 2, angle);
      drawHorizontalText(canvas, outerZones[i], pos, outerStyle);
    }

    // ===== RING 2: 32 Devta Names =====
    for (int i = 0; i < 32; i++) {
      final angle1 = (360 / 32) * i - 5.625;
      final angle2 = angle1 + 11.25;
      // Get color from corresponding zone
      final zoneIdx = (i ~/ 2) % 16;
      final path = arcSegment(center, r3, r2, angle1, angle2);
      canvas.drawPath(
        path,
        Paint()..color = zoneColors[zoneIdx].withValues(alpha: 0.6),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final devtaStyle = GoogleFonts.inter(
      fontSize: size.width * 0.013,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w600,
    );
    for (int i = 0; i < 32; i++) {
      final angle = (360 / 32) * i;
      final pos = polar(center, (r2 + r3) / 2, angle);
      drawHorizontalText(canvas, devtaNames[i], pos, devtaStyle);
    }

    // ===== RING 3: Body Organs =====
    const organs = [
      'Bladder',
      'Pericardium',
      'Circulation',
      'Liver',
      'Gall Bladder',
      'Small Intestine',
      'Heart',
      'Stomach',
      'Spleen',
      'Lungs',
      'Large Intestine',
      'Kidney',
    ];
    const organColors = [
      Color(0xFFF5C4BC),
      Color(0xFFF5C4BC),
      Color(0xFFB5DAA8),
      Color(0xFFB5DAA8),
      Color(0xFFB5DAA8),
      Color(0xFFF5C4BC),
      Color(0xFFF5C4BC),
      Color(0xFFF5E8A8),
      Color(0xFFF5E8A8),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFB8DCE8),
    ];

    for (int i = 0; i < 12; i++) {
      final angle1 = (360 / 12) * i - 15;
      final angle2 = angle1 + 30;
      final path = arcSegment(center, r4, r3, angle1, angle2);
      canvas.drawPath(path, Paint()..color = organColors[i]);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    final organStyle = GoogleFonts.inter(
      fontSize: size.width * 0.012,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w600,
    );
    for (int i = 0; i < 12; i++) {
      final angle = (360 / 12) * i;
      final pos = polar(center, (r3 + r4) / 2, angle);
      drawHorizontalText(canvas, organs[i], pos, organStyle);
    }

    // ===== RING 4: T/R/S Dosha markers =====
    const doshas = ['T', 'R', 'S', 'T', 'R', 'S', 'T', 'R', 'S', 'T', 'R', 'S'];
    for (int i = 0; i < 12; i++) {
      final angle = (360 / 12) * i;
      final pos = polar(center, (r4 + r5) / 2 + r5 * 0.5, angle);
      final color = i % 3 == 0
          ? const Color(0xFFB8DCE8)
          : i % 3 == 1
              ? const Color(0xFFF5C4BC)
              : const Color(0xFFF5E8A8);

      // Small circle background
      canvas.drawCircle(pos, r5 * 0.35, Paint()..color = color);

      // Letter
      final doshaStyle = GoogleFonts.inter(
        fontSize: size.width * 0.013,
        color: const Color(0xFF333333),
        fontWeight: FontWeight.w700,
      );
      drawHorizontalText(canvas, doshas[i], pos, doshaStyle);
    }

    // ===== CENTER: Brahma =====
    canvas.drawCircle(center, r5, Paint()..color = const Color(0xFFF5E8A8));
    canvas.drawCircle(
      center,
      r5,
      Paint()
        ..color = const Color(0xFFC9A961)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final goalStyle = GoogleFonts.cormorantGaramond(
      fontSize: size.width * 0.022,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w700,
    );
    drawHorizontalText(
      canvas,
      '1 Goal',
      Offset(center.dx, center.dy - r5 * 0.3),
      goalStyle,
    );

    final brahmaStyle = GoogleFonts.cormorantGaramond(
      fontSize: size.width * 0.026,
      color: const Color(0xFF8B4513),
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    );
    drawHorizontalText(
      canvas,
      'Brahma',
      Offset(center.dx, center.dy + r5 * 0.2),
      brahmaStyle,
    );

    // Degree markers around outermost edge
    final degreeStyle = GoogleFonts.inter(
      fontSize: size.width * 0.012,
      color: const Color(0xFF666666),
      fontWeight: FontWeight.w500,
    );
    for (int i = 0; i < 36; i++) {
      final angle = i * 10.0;
      final tickStart = polar(center, r1 + 2, angle);
      final tickEnd = polar(center, r1 + (i % 9 == 0 ? 10 : 5), angle);
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = i % 9 == 0 ? Colors.red : Colors.grey
          ..strokeWidth = i % 9 == 0 ? 1.5 : 0.7,
      );

      // Degree numbers every 10°
      if (i % 1 == 0 && i > 0) {
        final degPos = polar(center, r1 + 18, angle);
        drawHorizontalText(canvas, '${(angle).toInt()}', degPos, degreeStyle);
      }
    }

    // 8 cardinal direction labels (outer)
    const directions = [
      'NORTH',
      'NE',
      'EAST',
      'SE',
      'SOUTH',
      'SW',
      'WEST',
      'NW',
    ];
    final dirStyle = GoogleFonts.inter(
      fontSize: size.width * 0.014,
      color: const Color(0xFF333333),
      fontWeight: FontWeight.w700,
    );
    for (int i = 0; i < 8; i++) {
      final angle = i * 45.0;
      final pos = polar(center, r1 + 35, angle);
      drawHorizontalText(canvas, directions[i], pos, dirStyle);
    }

    canvas.restore();
    drawSmallArrow(canvas, center, rOuter);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAKRA PAINTER FACTORY
// ═══════════════════════════════════════════════════════════════════════════
CustomPainter chakraPainterFor(
  String chakraId,
  double rotation, {
  bool transparentBackground = false,
}) {
  switch (chakraId) {
    case '16-outer-ring':
      return Provided16ZoneOuterRingPainter(
        rotation: rotation,
        transparentBackground: true,
      );
    case '45-outer-ring':
      return Provided45DevataOuterRingPainter(
        rotation: rotation,
        transparentBackground: true,
      );
    case '16-directions':
      return Provided16ZonePainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case '32-gates':
    case '32-pandas':
      return Provided32GatePainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case '45-devata':
      return Provided45DevataPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case 'vastu-purush':
      return ProvidedVastuPurushPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case 'vastu-purush-inner':
      return ProvidedVastuPurushInnerPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case 'kubar-vastu':
    case 'kv-chakra':
    case 'mahavastu':
      return ProvidedKubarVastuPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case 'kv-inner':
      return ProvidedKubarVastuInnerPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    case 'compass-chakra':
    case '5-elements':
      return ProvidedCompassChakraPainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
    default:
      return Provided16ZonePainter(
        rotation: rotation,
        transparentBackground: transparentBackground,
      );
  }
}
