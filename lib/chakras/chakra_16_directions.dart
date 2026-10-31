import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vastu_data.dart';
import 'chakra_painters.dart';

/// 16 Directions Chakra - Smooth gradient ring with HORIZONTAL degree/direction text
class Chakra16DirectionsPainter extends BaseChakraPainter {
  final bool showDegrees; // Show degree numbers

  Chakra16DirectionsPainter({required super.rotation, this.showDegrees = true});

  // Authentic Vastu Shastra colors for 16 directions (Shodasha Disha)
  // Based on traditional Vastu Purusha Mandala and zone-specific elements
  static final List<MapEntry<double, Color>> _stops = [
    const MapEntry(0, Color(0xFF2E86C1)), // N - Water (Deep Blue) - Wealth
    const MapEntry(22.5, Color(0xFF5DADE2)), // NNE - Light Blue - Health
    const MapEntry(
      45,
      Color(0xFF85C1E2),
    ), // NE - Light Blue/Silver - Clarity (sacred)
    const MapEntry(
      67.5,
      Color(0xFF82E0AA),
    ), // ENE - Light Blue/Green - Recreation
    const MapEntry(90, Color(0xFF52BE80)), // E - Green - Air/Social
    const MapEntry(
      112.5,
      Color(0xFFD7DBDD),
    ), // ESE - Light Green/Beige - Anxiety
    const MapEntry(135, Color(0xFFEC7063)), // SE - Pink/Red - Fire
    const MapEntry(157.5, Color(0xFFE74C3C)), // SSE - Red - Power
    const MapEntry(180, Color(0xFFC0392B)), // S - Red/Orange - Fame
    const MapEntry(202.5, Color(0xFFF4D03F)), // SSW - Yellow - Expenditure
    const MapEntry(
      225,
      Color(0xFFF1C40F),
    ), // SW - Yellow/Golden - Earth/Relationships
    const MapEntry(247.5, Color(0xFFF7DC6F)), // WSW - Yellow/White - Education
    const MapEntry(270, Color(0xFFECF0F1)), // W - White/Silver - Space/Gains
    const MapEntry(292.5, Color(0xFFBDC3C7)), // WNW - White/Grey - Detox
    const MapEntry(315, Color(0xFFD5DBDB)), // NW - White/Cream - Air/Support
    const MapEntry(
      337.5,
      Color(0xFFAED6F1),
    ), // NNW - White/Light Blue - Attraction
    const MapEntry(360, Color(0xFF2E86C1)), // Back to N
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - 2;
    final rInner = rOuter - size.width * 0.085;

    canvas.save();
    applyRotation(canvas, center);

    // Draw CENTER RADIATING LINES (16 directions - all pointing to exact center)
    const lineCount = 16;
    for (int i = 0; i < lineCount; i++) {
      final angle = (360 / lineCount) * i;
      final lineColor = gradientAt(_stops, angle);

      // Line from center outward
      canvas.drawLine(
        center,
        polar(center, rOuter + 8, angle),
        Paint()
          ..color = lineColor.withValues(alpha: 0.7)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Gradient ring (optimized 120 segments)
    const segCount = 120;
    for (int i = 0; i < segCount; i++) {
      final a1 = (i / segCount) * 360;
      final a2 = ((i + 1) / segCount) * 360;
      final color = gradientAt(_stops, (a1 + a2) / 2);
      final path = arcSegment(center, rInner, rOuter, a1, a2);
      canvas.drawPath(path, Paint()..color = color);
    }

    // Dividers between 16 zones
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 16; i++) {
      final a = i * 22.5 - 11.25;
      canvas.drawLine(
        polar(center, rInner, a),
        polar(center, rOuter, a),
        dividerPaint,
      );
    }

    // Outer/inner circles
    canvas.drawCircle(
      center,
      rOuter,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    canvas.drawCircle(
      center,
      rInner,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Direction labels
    final labelStyle = GoogleFonts.inter(
      fontSize: size.width * 0.022,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    for (int i = 0; i < 16; i++) {
      final angle = i * 22.5;
      final pos = polar(center, (rOuter + rInner) / 2, angle);
      drawHorizontalText(canvas, VastuData.dirNames[i], pos, labelStyle);
    }

    canvas.restore();

    // Multi-colored center dot - Pancha Mahabhuta (5 elements) representation
    const centerDotRadius = 6.0;

    // SW quadrant - Earth (Yellow/Golden)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: centerDotRadius),
      -3.14159 / 4 * 3,
      3.14159 / 2,
      true,
      Paint()..color = const Color(0xFFF1C40F),
    );

    // SE quadrant - Fire (Red)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: centerDotRadius),
      -3.14159 / 4,
      3.14159 / 2,
      true,
      Paint()..color = const Color(0xFFC0392B),
    );

    // NE quadrant - Water (Blue)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: centerDotRadius),
      3.14159 / 4,
      3.14159 / 2,
      true,
      Paint()..color = const Color(0xFF2E86C1),
    );

    // NW quadrant - Air (Green)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: centerDotRadius),
      3.14159 / 4 * 3,
      3.14159 / 2,
      true,
      Paint()..color = const Color(0xFF52BE80),
    );

    // Small arrow indicator (outside rotated canvas, always points up)
    drawSmallArrow(canvas, center, rOuter);
  }
}

/// Chakra widget that displays heading and direction OUTSIDE the chakra
class ImprovedChakraWithInfo extends StatelessWidget {
  final String chakraId;
  final double rotation;
  final double heading;
  final double size;

  const ImprovedChakraWithInfo({
    super.key,
    required this.chakraId,
    required this.rotation,
    required this.heading,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    final dirName = VastuData.nameFromDegree(heading);

    return Column(
      children: [
        // Heading display - HORIZONTAL column above chakra
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A961).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFC9A961).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HEADING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFFC9A961),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${heading.round()}°',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  color: const Color(0xFFE8DCC4),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                dirName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  color: const Color(0xFFE8C87B),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Chakra
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC9A961).withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: CustomPaint(
            painter: Chakra16DirectionsPainter(rotation: rotation),
          ),
        ),
      ],
    );
  }
}
