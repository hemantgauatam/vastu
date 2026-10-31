import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chakra_painters.dart';
import 'chakra_map_geometry.dart';
import 'generated_vastu_purush_dwg.dart';

class Provided16ZonePainter extends _ProvidedChakraPainter {
  Provided16ZonePainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    final bandInner = r * 0.91;

    _drawDisc(canvas, center, r);

    canvas.save();
    applyRotation(canvas, center);
    _drawSixteenBand(
      canvas,
      center,
      bandInner,
      r,
      _directions16,
      drawOuterBorder: false,
    );
    // Sixteen labels are centred every 22.5°. Their boundaries begin half a
    // sector before North, at -11.25°.
    _drawSpokes(
      canvas,
      center,
      r * 0.02,
      bandInner,
      16,
      startAngle: -11.25,
    );
    // The band paths already draw both circumferences; do not overdraw them.
    canvas.restore();

    _drawElementDot(canvas, center, r * 0.018);
  }
}

class Provided32GatePainter extends _ProvidedChakraPainter {
  Provided32GatePainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    final bandInner = r * 0.91;

    _drawDisc(canvas, center, r);

    canvas.save();
    applyRotation(canvas, center);
    _drawGateBand(
      canvas,
      center,
      bandInner,
      r,
      drawOuterBorder: false,
    );
    // North is the shared boundary between N4 and N5 in the 32-gate grid.
    _drawSpokes(
      canvas,
      center,
      r * 0.02,
      bandInner,
      32,
      startAngle: -45,
    );
    // The band paths already draw both circumferences; do not overdraw them.
    canvas.restore();

    _drawElementDot(canvas, center, r * 0.018);
  }
}

/// Direction bands designed to sit completely outside a fitted map. They do
/// not draw spokes through the map, which keeps floor-plan content unobscured.
class Provided16ZoneOuterRingPainter extends _ProvidedChakraPainter {
  Provided16ZoneOuterRingPainter({
    required super.rotation,
    super.transparentBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final outer = _radius(size, 0.49);
    final inner = outer * 0.79;
    canvas.save();
    applyRotation(canvas, center);
    _drawSixteenBand(
      canvas,
      center,
      inner,
      outer,
      _directions16,
      fontScale: 0.036,
      drawFill: true,
      drawOuterBorder: false,
    );
    // Sector paths provide the inner and outer circumference once.
    canvas.restore();
  }
}

/// Compact, lighter 16-zone direction ring used only around the supplied
/// 45 Devata artwork. Its inner edge is calibrated to touch the artwork.
class Provided45DevataOuterRingPainter extends _ProvidedChakraPainter {
  Provided45DevataOuterRingPainter({
    required super.rotation,
    super.transparentBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final outer = _radius(size, 0.49);
    final inner = outer * k45DevataOuterRingInnerRadiusRatio;
    canvas.save();
    applyRotation(canvas, center);
    _drawSixteenBand(
      canvas,
      center,
      inner,
      outer,
      _directions16,
      fontScale: 0.032,
      drawFill: true,
    );
    // Sector paths provide the inner and outer circumference once.
    canvas.restore();
  }
}

class Provided32GateOuterRingPainter extends _ProvidedChakraPainter {
  Provided32GateOuterRingPainter({
    required super.rotation,
    super.transparentBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final outer = _radius(size, 0.49);
    final inner = outer * 0.79;
    canvas.save();
    applyRotation(canvas, center);
    _drawGateBand(canvas, center, inner, outer);
    // Sector paths provide the inner and outer circumference once.
    canvas.restore();
  }
}

/// Native 45 Devata construction: 32 outer padas, 12 intermediate sectors,
/// and the central Brahmasthan. It remains resolution-independent in preview
/// and PDF exports and does not depend on a bitmap asset.
class Provided45DevataPainter extends _ProvidedChakraPainter {
  Provided45DevataPainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    final drawFill = !transparentBackground;
    _drawDisc(canvas, center, r);

    canvas.save();
    applyRotation(canvas, center);
    _drawReferenceDirectionBand(
      canvas,
      center,
      r * k45DevataOuterBandInnerRatio,
      r,
    );

    // The supplied 45 Devata reference has 32 outer padas, twelve
    // intermediate divisions and a clear Brahmasthan. Keep those rings tied
    // to the same North axis as the 16-zone chakra.
    _drawSpokes(
      canvas,
      center,
      r * 0.23,
      r * 0.54,
      12,
      color: const Color(0xFF70757A),
      strokeWidth: 0.56,
      startAngle: -15,
    );
    _drawSpokes(
      canvas,
      center,
      r * 0.54,
      r * k45DevataOuterBandInnerRatio,
      32,
      color: const Color(0xFF70757A),
      strokeWidth: 0.52,
      startAngle: -5.625,
    );
    _drawCircleLines(
      canvas,
      center,
      [
        r * 0.23,
        r * 0.54,
        r * 0.72,
        r * k45DevataOuterBandInnerRatio,
        r,
      ],
      0.62,
    );
    _drawCenterBrahmasthan(
      canvas,
      center,
      r * 0.23,
      drawFill: drawFill,
    );
    canvas.restore();
  }
}

class ProvidedVastuPurushPainter extends _ProvidedChakraPainter {
  ProvidedVastuPurushPainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = _center(size);
    final r = side * 0.48;

    if (!transparentBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    }

    canvas.save();
    applyRotation(canvas, center);
    _drawSimpleDirectionBand(
      canvas,
      center,
      r * kVastuPurushOuterBandInnerRatio,
      r,
    );
    _drawSpokes(
      canvas,
      center,
      0,
      r * kVastuPurushOuterBandInnerRatio,
      16,
      color: const Color(0xFF242424),
      strokeWidth: 1.05,
    );
    _drawDwgVastuPurushOutline(canvas, center, r * 0.98);
    _drawCircleLines(
      canvas,
      center,
      [r * kVastuPurushOuterBandInnerRatio, r],
      1.75,
    );
    canvas.restore();
  }
}

/// Purush and radial grid without the labelled direction band. Used when the
/// report compositor draws the common outer direction ring around the crop.
class ProvidedVastuPurushInnerPainter extends _ProvidedChakraPainter {
  ProvidedVastuPurushInnerPainter({
    required super.rotation,
    super.transparentBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = size.shortestSide * 0.49;
    canvas.save();
    applyRotation(canvas, center);
    _drawSpokes(
      canvas,
      center,
      0,
      r,
      16,
      color: const Color(0xFF181818),
      strokeWidth: 1.05,
    );
    _drawDwgVastuPurushOutline(canvas, center, r * 0.98);
    canvas.restore();
  }
}

class ProvidedKubarVastuPainter extends _ProvidedChakraPainter {
  ProvidedKubarVastuPainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    final drawTextBackgrounds = !transparentBackground;
    _drawDisc(canvas, center, r);

    canvas.save();
    applyRotation(canvas, center);
    _drawDegreeScale(canvas, center, r * 0.88, r,
        color: Colors.black, textSize: r * 0.055);
    _drawRing(canvas, center, r * 0.75, r * 0.86, _benefits,
        colors: _benefitColors,
        startAngle: -11.25,
        fontScale: 0.033,
        drawFill: drawTextBackgrounds);
    _drawRing(canvas, center, r * 0.67, r * 0.74, _organs,
        colors: _organColors,
        startAngle: -11.25,
        fontScale: 0.026,
        textColor: const Color(0xFFB22722),
        drawFill: drawTextBackgrounds);
    _drawSixteenBand(
      canvas,
      center,
      r * 0.59,
      r * 0.66,
      _directions16,
      fontScale: 0.030,
      drawFill: drawTextBackgrounds,
    );
    _drawGateTextRing(canvas, center, r * 0.46, r * 0.58,
        drawFill: drawTextBackgrounds);
    _drawRing(canvas, center, r * 0.29, r * 0.45, _devtas,
        colors: _devtaColors,
        startAngle: -45,
        fontScale: 0.025,
        textColor: const Color(0xFF102033),
        drawFill: drawTextBackgrounds);
    _drawInnerDevtaRing(canvas, center, r * 0.19, r * 0.285,
        drawFill: drawTextBackgrounds);
    _drawCenterBrahmasthan(canvas, center, r * 0.185,
        drawFill: drawTextBackgrounds);
    canvas.restore();
  }
}

/// KV content without its embedded 32-gate ring. The gate ring is rendered by
/// [Provided32GateOuterRingPainter] outside the fitted map instead.
class ProvidedKubarVastuInnerPainter extends _ProvidedChakraPainter {
  ProvidedKubarVastuInnerPainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    final drawTextBackgrounds = !transparentBackground;
    _drawDisc(canvas, center, r);
    canvas.save();
    applyRotation(canvas, center);
    _drawRing(
      canvas,
      center,
      r * 0.78,
      r * 0.96,
      _benefits,
      colors: _benefitColors,
      startAngle: -11.25,
      fontScale: 0.031,
      drawFill: drawTextBackgrounds,
    );
    _drawRing(
      canvas,
      center,
      r * 0.68,
      r * 0.77,
      _organs,
      colors: _organColors,
      startAngle: -11.25,
      fontScale: 0.025,
      textColor: const Color(0xFFB22722),
      drawFill: drawTextBackgrounds,
    );
    _drawSixteenBand(
      canvas,
      center,
      r * 0.57,
      r * 0.67,
      _directions16,
      fontScale: 0.028,
      drawFill: drawTextBackgrounds,
    );
    _drawRing(
      canvas,
      center,
      r * 0.30,
      r * 0.55,
      _devtas,
      colors: _devtaColors,
      startAngle: -45,
      fontScale: 0.024,
      textColor: const Color(0xFF102033),
      drawFill: drawTextBackgrounds,
    );
    _drawInnerDevtaRing(
      canvas,
      center,
      r * 0.19,
      r * 0.295,
      drawFill: drawTextBackgrounds,
    );
    _drawCenterBrahmasthan(
      canvas,
      center,
      r * 0.185,
      drawFill: drawTextBackgrounds,
    );
    canvas.restore();
  }
}

class ProvidedCompassChakraPainter extends _ProvidedChakraPainter {
  ProvidedCompassChakraPainter({
    required super.rotation,
    super.transparentBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = _center(size);
    final r = _radius(size, 0.49);
    _drawDisc(canvas, center, r);
    if (!transparentBackground) {
      canvas.drawCircle(
        center.translate(0, r * 0.025),
        r * 0.985,
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.025),
      );
      canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFF8E9));
    }

    canvas.save();
    applyRotation(canvas, center);
    _drawRing(canvas, center, r * 0.835, r, _mainDirections,
        colors: _mainDirectionColors,
        startAngle: -11.25,
        fontScale: 0.064,
        textColor: Colors.black,
        drawFill: !transparentBackground,
        borderColor: const Color(0xFFA77A4C),
        borderWidth: 1.45,
        bilingual: false);
    _drawMainPuzzleRing(canvas, center, r * 0.55, r * 0.825, _mainLifeLabels,
        colors: _mainLifeColors,
        startAngle: -11.25,
        fontScale: 0.037,
        bilingual: true,
        notchRadius: r * 0.030);
    _drawMainPuzzleRing(canvas, center, r * 0.30, r * 0.54, _mainInnerLabels,
        colors: _mainInnerColors,
        startAngle: -22.5,
        fontScale: 0.057,
        bilingual: false,
        notchRadius: r * 0.040);
    _drawMainKuberCenter(canvas, center, r * 0.29);
    final rim = Paint()
      ..color = const Color(0xFFA77A4C)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, rim..strokeWidth = 2.2);
    canvas.drawCircle(center, r * 0.985, rim..strokeWidth = 0.8);
    canvas.drawCircle(center, r * 0.835, rim..strokeWidth = 1.25);
    canvas.drawCircle(center, r * 0.55, rim..strokeWidth = 1.25);
    canvas.drawCircle(center, r * 0.30, rim..strokeWidth = 1.15);
    canvas.restore();
  }
}

abstract class _ProvidedChakraPainter extends BaseChakraPainter {
  final bool transparentBackground;

  _ProvidedChakraPainter({
    required super.rotation,
    this.transparentBackground = false,
  });

  @override
  bool shouldRepaint(covariant _ProvidedChakraPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.transparentBackground != transparentBackground;
  }

  Offset _center(Size size) => Offset(size.width / 2, size.height / 2);

  double _radius(Size size, double scale) => size.shortestSide * scale;

  void _drawDisc(Canvas canvas, Offset center, double r) {
    if (transparentBackground) return;
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
  }

  void _drawSquareFrame(Canvas canvas, Offset center, double side) {
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawSixteenBand(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
    List<String> labels, {
    double fontScale = 0.040,
    bool drawFill = true,
    bool drawOuterBorder = true,
  }) {
    final overlayText = const Color(0xFF161A1D).withValues(alpha: 0.98);
    final overlayLine = const Color(0xFF252A2E).withValues(alpha: 0.94);
    final textStyle = GoogleFonts.inter(
      fontSize: outer * (transparentBackground ? fontScale * 1.28 : fontScale),
      color: transparentBackground ? overlayText : const Color(0xFF686E73),
      fontWeight: transparentBackground ? FontWeight.w700 : FontWeight.w500,
    );
    for (var i = 0; i < 16; i++) {
      final start = -11.25 + i * 22.5;
      final path = arcSegment(center, inner, outer, start, start + 22.5);
      if (drawFill) {
        _drawTransparentAwareFill(canvas, path, _zoneColor(i));
      }
      if (drawOuterBorder) {
        canvas.drawPath(
          path,
          _stroke(transparentBackground ? overlayLine : const Color(0xFF646464),
              0.65),
        );
      } else {
        canvas.drawLine(
          polar(center, inner, start),
          polar(center, outer, start),
          _stroke(transparentBackground ? overlayLine : const Color(0xFF646464),
              0.65),
        );
      }
      _drawTangentText(
        canvas,
        labels[i],
        center,
        (inner + outer) / 2,
        i * 22.5,
        textStyle,
        maxWidth: (outer - inner) * 2.9,
      );
    }
    if (!drawOuterBorder) {
      canvas.drawCircle(
        center,
        inner,
        _stroke(transparentBackground ? overlayLine : const Color(0xFF646464),
            0.65),
      );
    }
  }

  void _drawGateBand(
    Canvas canvas,
    Offset center,
    double inner,
    double outer, {
    bool drawOuterBorder = true,
  }) {
    final overlayText = const Color(0xFF161A1D).withValues(alpha: 0.98);
    final overlayLine = const Color(0xFF252A2E).withValues(alpha: 0.94);
    final textStyle = GoogleFonts.inter(
      fontSize: outer * (transparentBackground ? 0.040 : 0.035),
      color: transparentBackground ? overlayText : const Color(0xFF50565C),
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < 32; i++) {
      final start = -45 + i * 11.25;
      final path = arcSegment(center, inner, outer, start, start + 11.25);
      _drawTransparentAwareFill(canvas, path, _gateColor(i));
      final borderPaint = _stroke(
        transparentBackground ? overlayLine : const Color(0xFF656565),
        transparentBackground ? 0.85 : 0.55,
      );
      if (drawOuterBorder) {
        canvas.drawPath(path, borderPaint);
      } else {
        canvas.drawLine(
          polar(center, inner, start),
          polar(center, outer, start),
          borderPaint,
        );
      }
      _drawTangentText(
        canvas,
        _gateLabels[i],
        center,
        (inner + outer) / 2,
        -39.375 + i * 11.25,
        textStyle,
        maxWidth: (outer - inner) * 2.2,
      );
    }
    if (!drawOuterBorder) {
      canvas.drawCircle(
        center,
        inner,
        _stroke(
          const Color(0xFF656565),
          transparentBackground ? 0.85 : 0.55,
        ),
      );
    }
  }

  Color _referenceDirectionColor(int index) {
    if (index == 15 || index <= 2) return const Color(0xFF1528E8);
    if (index <= 5) return const Color(0xFF16C928);
    if (index <= 9) return const Color(0xFFE81D3F);
    if (index <= 11) return const Color(0xFFE8C20A);
    return const Color(0xFF505050);
  }

  void _drawReferenceDirectionBand(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
  ) {
    for (var i = 0; i < 16; i++) {
      final baseColor = _referenceDirectionColor(i);
      final color = baseColor.withValues(alpha: 0.62);
      final start = -11.25 + i * 22.5;
      final path = arcSegment(center, inner, outer, start, start + 22.5);
      if (!transparentBackground) {
        canvas.drawPath(path, Paint()..color = Colors.white);
      }
      canvas.drawPath(path, _stroke(color, i % 4 == 0 ? 0.88 : 0.52));
      _drawTangentText(
        canvas,
        _directions16[i],
        center,
        (inner + outer) / 2,
        i * 22.5,
        GoogleFonts.inter(
          fontSize: outer * 0.041,
          color: color,
          fontWeight: FontWeight.w400,
        ),
        maxWidth: (outer - inner) * 3.2,
      );
    }
  }

  void _drawSimpleDirectionBand(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
  ) {
    final style = GoogleFonts.cormorantGaramond(
      fontSize: outer * 0.086,
      color: const Color(0xFF111111),
      fontWeight: FontWeight.w500,
    );
    for (var i = 0; i < 16; i++) {
      final label = switch (i) {
        0 => 'N',
        4 => 'E',
        8 => 'S',
        12 => 'W',
        _ => _directions16[i],
      };
      final start = -11.25 + i * 22.5;
      final path = arcSegment(center, inner, outer, start, start + 22.5);
      if (!transparentBackground) {
        canvas.drawPath(path, Paint()..color = Colors.white);
      }
      canvas.drawPath(path, _stroke(const Color(0xFF181818), 1.55));
      _drawTangentText(
        canvas,
        label,
        center,
        (inner + outer) / 2,
        i * 22.5,
        style,
        maxWidth: (outer - inner) * 3,
      );
    }
  }

  void _drawVastuDirectionBand(
      Canvas canvas, Offset center, double inner, double outer) {
    final style = GoogleFonts.inter(
      fontSize: outer * (transparentBackground ? 0.044 : 0.035),
      color: const Color(0xFF25304A),
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < 16; i++) {
      final start = -11.25 + i * 22.5;
      final path = arcSegment(center, inner, outer, start, start + 22.5);
      final color = i < 2 || i == 15
          ? const Color(0xFF2E36C7)
          : i < 6
              ? const Color(0xFF24C841)
              : i < 10
                  ? const Color(0xFFE6292D)
                  : i < 12
                      ? const Color(0xFFFFEB25)
                      : const Color(0xFFD6D6D6);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: transparentBackground ? 0.48 : 0.9),
      );
      canvas.drawPath(path, _stroke(Colors.white.withValues(alpha: 0.8), 0.7));
      _drawTangentText(canvas, _directions16[i], center, (inner + outer) / 2,
          i * 22.5, style,
          maxWidth: (outer - inner) * 3.2);
    }
  }

  void _drawVastuGateBand(
      Canvas canvas, Offset center, double inner, double outer) {
    final style = GoogleFonts.inter(
      fontSize: outer * (transparentBackground ? 0.041 : 0.032),
      color: const Color(0xFF18813B),
      fontWeight: FontWeight.w600,
    );
    const highlights = {
      2: Color(0xFF2935C5),
      3: Color(0xFF2935C5),
      10: Color(0xFF169C32),
      11: Color(0xFF169C32),
      18: Color(0xFFE22B31),
      19: Color(0xFFE22B31),
      26: Color(0xFF8D8D8D),
      27: Color(0xFF8D8D8D),
    };
    for (var i = 0; i < 32; i++) {
      final start = -45 + i * 11.25;
      final path = arcSegment(center, inner, outer, start, start + 11.25);
      final highlight = highlights[i];
      if (highlight != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color =
                highlight.withValues(alpha: transparentBackground ? 0.55 : 1),
        );
      } else if (!transparentBackground) {
        canvas.drawPath(path, Paint()..color = Colors.white);
      }
      canvas.drawPath(path, _stroke(const Color(0xFF7D6B62), 0.55));
      _drawTangentText(
        canvas,
        _gateLabels[i],
        center,
        (inner + outer) / 2,
        -39.375 + i * 11.25,
        highlight == null ? style : style.copyWith(color: Colors.white),
        maxWidth: (outer - inner) * 1.9,
      );
    }
  }

  void _drawGateTextRing(
    Canvas canvas,
    Offset center,
    double inner,
    double outer, {
    bool drawFill = true,
  }) {
    final gateStyle = GoogleFonts.inter(
      fontSize: outer * (transparentBackground ? 0.060 : 0.048),
      color: const Color(0xFF202020),
      fontWeight: transparentBackground ? FontWeight.w700 : FontWeight.w600,
    );
    for (var i = 0; i < 32; i++) {
      final start = -45 + i * 11.25;
      final path = arcSegment(center, inner, outer, start, start + 11.25);
      if (drawFill) {
        _drawTransparentAwareFill(canvas, path, _gateBlockColors[i]);
      }
      canvas.drawPath(path, _stroke(_lineWhite, 1.4));
      _drawTangentText(
        canvas,
        _gateLabels[i],
        center,
        outer * 0.91,
        -39.375 + i * 11.25,
        gateStyle,
        maxWidth: (outer - inner) * 2.1,
      );
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
    List<String> labels, {
    required List<Color> colors,
    required double startAngle,
    required double fontScale,
    Color textColor = const Color(0xFF202020),
    bool drawFill = true,
    Color? borderColor,
    double borderWidth = 0.55,
    bool bilingual = false,
  }) {
    final overlayText = const Color(0xFF161A1D).withValues(alpha: 0.98);
    final overlayLine = const Color(0xFF252A2E).withValues(alpha: 0.94);
    final effectiveTextColor = transparentBackground ? overlayText : textColor;
    final sweep = 360 / labels.length;
    final style = bilingual
        ? GoogleFonts.notoSansDevanagari(
            fontSize:
                outer * (transparentBackground ? fontScale * 1.22 : fontScale),
            color: effectiveTextColor,
            fontWeight: FontWeight.w600,
            height: 0.94,
          )
        : GoogleFonts.inter(
            fontSize:
                outer * (transparentBackground ? fontScale * 1.22 : fontScale),
            color: effectiveTextColor,
            fontWeight:
                transparentBackground ? FontWeight.w700 : FontWeight.w600,
            height: 0.92,
          );
    for (var i = 0; i < labels.length; i++) {
      final start = startAngle + i * sweep;
      final path = arcSegment(center, inner, outer, start, start + sweep);
      if (drawFill) {
        _drawTransparentAwareFill(canvas, path, colors[i % colors.length]);
      }
      canvas.drawPath(
        path,
        borderColor == null
            ? _stroke(
                transparentBackground ? overlayLine : const Color(0xFFB8322C),
                borderWidth,
              )
            : (Paint()
              ..color = transparentBackground ? overlayLine : borderColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth),
      );
      _drawTangentText(
        canvas,
        labels[i],
        center,
        (inner + outer) / 2,
        start + sweep / 2,
        style,
        maxWidth: (outer - inner) * 3.1,
      );
    }
  }

  void _drawSpokes(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
    int count, {
    Color? color,
    double strokeWidth = 1.5,
    double startAngle = 0,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = startAngle + i * 360 / count;
      canvas.drawLine(
        polar(center, inner, angle),
        polar(center, outer, angle),
        Paint()
          ..color = transparentBackground
              ? const Color(0xFF747A80).withValues(alpha: 0.52)
              : const Color(0xFF858A8F).withValues(alpha: 0.62)
          ..strokeWidth = strokeWidth * 0.55,
      );
    }
  }

  void _drawMainPuzzleRing(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
    List<String> labels, {
    required List<Color> colors,
    required double startAngle,
    required double fontScale,
    required bool bilingual,
    required double notchRadius,
  }) {
    final sweep = 360 / labels.length;
    final border = Paint()
      ..color = const Color(0xFFA77A4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    final style = bilingual
        ? GoogleFonts.notoSansDevanagari(
            fontSize: outer * fontScale,
            color: Colors.black,
            fontWeight: FontWeight.w600,
            height: 0.94,
          )
        : GoogleFonts.inter(
            fontSize: outer * fontScale,
            color: Colors.black,
            fontWeight: FontWeight.w600,
            height: 0.92,
          );

    for (var i = 0; i < labels.length; i++) {
      final start = startAngle + i * sweep;
      final mid = start + sweep / 2;
      final path = arcSegment(center, inner, outer, start, start + sweep);
      final color = colors[i % colors.length];
      if (!transparentBackground) {
        final bounds = path.getBounds();
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.32)!,
                color,
              ],
            ).createShader(bounds),
        );
      }
      canvas.drawPath(path, border);

      final notchCenter = polar(center, inner, mid);
      if (i.isEven) {
        if (!transparentBackground) {
          canvas.drawCircle(notchCenter, notchRadius, Paint()..color = color);
        }
        canvas.drawArc(
          Rect.fromCircle(center: notchCenter, radius: notchRadius),
          (mid + 90) * math.pi / 180,
          math.pi,
          false,
          border,
        );
      } else {
        if (!transparentBackground) {
          canvas.drawCircle(
            notchCenter,
            notchRadius,
            Paint()..color = const Color(0xFFFFF8E9),
          );
        }
        canvas.drawArc(
          Rect.fromCircle(center: notchCenter, radius: notchRadius),
          (mid - 90) * math.pi / 180,
          math.pi,
          false,
          border,
        );
      }

      _drawTangentText(
        canvas,
        labels[i],
        center,
        (inner + outer) / 2,
        mid,
        style,
        maxWidth: (outer - inner) * 3.15,
      );
    }
  }

  void _drawCircleLines(
    Canvas canvas,
    Offset center,
    List<double> radii,
    double strokeWidth,
  ) {
    for (final radius in radii) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF858A8F)
              .withValues(alpha: transparentBackground ? 0.52 : 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  void _drawDegreeScale(
    Canvas canvas,
    Offset center,
    double inner,
    double outer, {
    required Color color,
    required double textSize,
  }) {
    final effectiveTextSize =
        transparentBackground ? textSize * 1.18 : textSize;
    for (var degree = 0; degree < 360; degree++) {
      final major = degree % 10 == 0;
      final mid = degree % 5 == 0;
      final length = major
          ? (outer - inner) * 0.52
          : mid
              ? (outer - inner) * 0.36
              : (outer - inner) * 0.22;
      canvas.drawLine(
        polar(center, outer - length, degree.toDouble()),
        polar(center, outer, degree.toDouble()),
        Paint()
          ..color = color
          ..strokeWidth = major ? 0.75 : 0.3,
      );
      if (major) {
        _drawTangentText(
          canvas,
          '$degree',
          center,
          inner,
          degree.toDouble(),
          GoogleFonts.inter(
            fontSize: effectiveTextSize,
            color: color,
            fontWeight:
                transparentBackground ? FontWeight.w700 : FontWeight.w500,
          ),
          maxWidth: (outer - inner) * 2,
        );
      }
    }
  }

  void _drawCardinalWords(
      Canvas canvas, Offset center, double inner, double outer) {
    const labels = ['NORTH', 'EAST', 'SOUTH', 'WEST'];
    const angles = [0.0, 90.0, 180.0, 270.0];
    for (var i = 0; i < labels.length; i++) {
      _drawTangentText(
        canvas,
        labels[i],
        center,
        (inner + outer) / 2,
        angles[i],
        GoogleFonts.inter(
          fontSize: outer * (transparentBackground ? 0.074 : 0.060),
          color: const Color(0xFF142068),
          fontWeight: transparentBackground ? FontWeight.w700 : FontWeight.w500,
        ),
        maxWidth: (outer - inner) * 4,
      );
    }
  }

  void _drawDwgVastuPurushOutline(
    Canvas canvas,
    Offset center,
    double radius,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF141414)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.0055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final points in vastuPurushDwgPaths) {
      if (points.length < 2) continue;
      final path = Path()
        ..moveTo(
          center.dx + points.first.dx * radius,
          center.dy + points.first.dy * radius,
        );
      for (var i = 1; i < points.length; i++) {
        path.lineTo(
          center.dx + points[i].dx * radius,
          center.dy + points[i].dy * radius,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  // ignore: unused_element
  void _drawAccurateVastuPurushOutline(
    Canvas canvas,
    Offset center,
    double r,
  ) {
    Offset p(double x, double y) => center.translate(x * r, y * r);
    final outline = Paint()
      ..color = const Color(0xFF171717)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.008
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final detail = Paint()
      ..color = const Color(0xFF202020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.0062
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void drawReadable(Path path, Paint foreground) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = foreground.strokeWidth + r * 0.007
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, foreground);
    }

    // One continuous silhouette: back, shoulder, neck, chest, hip, legs and
    // the long south-west foot. Coordinates are normalized against the inner
    // circle and traced from vastu_p1.png.
    final silhouette = Path()
      ..moveTo(p(-0.58, -0.58).dx, p(-0.58, -0.58).dy)
      ..cubicTo(p(-0.48, -0.72).dx, p(-0.48, -0.72).dy, p(-0.25, -0.66).dx,
          p(-0.25, -0.66).dy, p(-0.04, -0.64).dx, p(-0.04, -0.64).dy)
      ..cubicTo(p(0.16, -0.64).dx, p(0.16, -0.64).dy, p(0.24, -0.60).dx,
          p(0.24, -0.60).dy, p(0.30, -0.49).dx, p(0.30, -0.49).dy)
      ..cubicTo(p(0.38, -0.37).dx, p(0.38, -0.37).dy, p(0.55, -0.34).dx,
          p(0.55, -0.34).dy, p(0.62, -0.20).dx, p(0.62, -0.20).dy)
      ..cubicTo(p(0.71, -0.02).dx, p(0.71, -0.02).dy, p(0.69, 0.25).dx,
          p(0.69, 0.25).dy, p(0.57, 0.39).dx, p(0.57, 0.39).dy)
      ..cubicTo(p(0.49, 0.48).dx, p(0.49, 0.48).dy, p(0.48, 0.59).dx,
          p(0.48, 0.59).dy, p(0.34, 0.65).dx, p(0.34, 0.65).dy)
      ..cubicTo(p(0.12, 0.73).dx, p(0.12, 0.73).dy, p(-0.16, 0.68).dx,
          p(-0.16, 0.68).dy, p(-0.39, 0.67).dx, p(-0.39, 0.67).dy)
      ..cubicTo(p(-0.52, 0.66).dx, p(-0.52, 0.66).dy, p(-0.63, 0.68).dx,
          p(-0.63, 0.68).dy, p(-0.76, 0.73).dx, p(-0.76, 0.73).dy)
      ..cubicTo(p(-0.82, 0.75).dx, p(-0.82, 0.75).dy, p(-0.84, 0.70).dx,
          p(-0.84, 0.70).dy, p(-0.72, 0.61).dx, p(-0.72, 0.61).dy)
      ..cubicTo(p(-0.65, 0.55).dx, p(-0.65, 0.55).dy, p(-0.68, 0.46).dx,
          p(-0.68, 0.46).dy, p(-0.63, 0.34).dx, p(-0.63, 0.34).dy)
      ..cubicTo(p(-0.58, 0.21).dx, p(-0.58, 0.21).dy, p(-0.61, 0.09).dx,
          p(-0.61, 0.09).dy, p(-0.68, -0.02).dx, p(-0.68, -0.02).dy)
      ..cubicTo(p(-0.72, -0.16).dx, p(-0.72, -0.16).dy, p(-0.70, -0.42).dx,
          p(-0.70, -0.42).dy, p(-0.58, -0.58).dx, p(-0.58, -0.58).dy)
      ..close();
    canvas.drawPath(silhouette, outline);

    // Inclined head and ear.
    final head = Path()
      ..moveTo(p(0.30, -0.49).dx, p(0.30, -0.49).dy)
      ..cubicTo(p(0.31, -0.67).dx, p(0.31, -0.67).dy, p(0.48, -0.78).dx,
          p(0.48, -0.78).dy, p(0.64, -0.68).dx, p(0.64, -0.68).dy)
      ..cubicTo(p(0.76, -0.60).dx, p(0.76, -0.60).dy, p(0.74, -0.42).dx,
          p(0.74, -0.42).dy, p(0.62, -0.35).dx, p(0.62, -0.35).dy)
      ..cubicTo(p(0.49, -0.27).dx, p(0.49, -0.27).dy, p(0.35, -0.36).dx,
          p(0.35, -0.36).dy, p(0.30, -0.49).dx, p(0.30, -0.49).dy)
      ..close();
    canvas.drawPath(head, outline);
    canvas.drawArc(
      Rect.fromCenter(
        center: p(0.31, -0.58),
        width: r * 0.14,
        height: r * 0.20,
      ),
      math.pi * 0.35,
      math.pi * 1.25,
      false,
      detail,
    );

    // Folded left arm running from the shoulder toward the centre.
    final leftArm = Path()
      ..moveTo(p(-0.51, -0.44).dx, p(-0.51, -0.44).dy)
      ..cubicTo(p(-0.40, -0.30).dx, p(-0.40, -0.30).dy, p(-0.31, -0.18).dx,
          p(-0.31, -0.18).dy, p(-0.24, -0.07).dx, p(-0.24, -0.07).dy)
      ..cubicTo(p(-0.18, 0.02).dx, p(-0.18, 0.02).dy, p(-0.11, 0.08).dx,
          p(-0.11, 0.08).dy, p(-0.02, 0.10).dx, p(-0.02, 0.10).dy)
      ..cubicTo(p(-0.13, 0.20).dx, p(-0.13, 0.20).dy, p(-0.28, 0.19).dx,
          p(-0.28, 0.19).dy, p(-0.40, 0.08).dx, p(-0.40, 0.08).dy)
      ..cubicTo(p(-0.52, -0.03).dx, p(-0.52, -0.03).dy, p(-0.57, -0.19).dx,
          p(-0.57, -0.19).dy, p(-0.51, -0.44).dx, p(-0.51, -0.44).dy)
      ..close();
    drawReadable(leftArm, outline);

    final leftHand = Path()
      ..moveTo(p(-0.08, 0.07).dx, p(-0.08, 0.07).dy)
      ..cubicTo(p(0.00, 0.07).dx, p(0.00, 0.07).dy, p(0.08, 0.10).dx,
          p(0.08, 0.10).dy, p(0.15, 0.14).dx, p(0.15, 0.14).dy)
      ..cubicTo(p(0.10, 0.18).dx, p(0.10, 0.18).dy, p(0.04, 0.19).dx,
          p(0.04, 0.19).dy, p(-0.03, 0.16).dx, p(-0.03, 0.16).dy);
    drawReadable(leftHand, detail);

    // Forearm across the abdomen ending in a small hand to the south-east.
    final frontArm = Path()
      ..moveTo(p(-0.31, -0.37).dx, p(-0.31, -0.37).dy)
      ..cubicTo(p(-0.16, -0.17).dx, p(-0.16, -0.17).dy, p(0.06, 0.02).dx,
          p(0.06, 0.02).dy, p(0.39, 0.25).dx, p(0.39, 0.25).dy)
      ..cubicTo(p(0.34, 0.32).dx, p(0.34, 0.32).dy, p(0.29, 0.34).dx,
          p(0.29, 0.34).dy, p(0.23, 0.29).dx, p(0.23, 0.29).dy)
      ..cubicTo(p(0.02, 0.14).dx, p(0.02, 0.14).dy, p(-0.20, -0.02).dx,
          p(-0.20, -0.02).dy, p(-0.36, -0.25).dx, p(-0.36, -0.25).dy);
    drawReadable(frontArm, outline);
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        p(0.29 + i * 0.025, 0.235 + i * 0.012),
        p(0.38 + i * 0.018, 0.275 + i * 0.010),
        detail,
      );
    }

    // Folded legs: one rounded knee at west and one long shin toward south.
    final legs = Path()
      ..moveTo(p(-0.60, 0.23).dx, p(-0.60, 0.23).dy)
      ..cubicTo(p(-0.52, 0.16).dx, p(-0.52, 0.16).dy, p(-0.46, 0.24).dx,
          p(-0.46, 0.24).dy, p(-0.42, 0.39).dx, p(-0.42, 0.39).dy)
      ..cubicTo(p(-0.37, 0.57).dx, p(-0.37, 0.57).dy, p(-0.20, 0.64).dx,
          p(-0.20, 0.64).dy, p(-0.04, 0.54).dx, p(-0.04, 0.54).dy)
      ..cubicTo(p(0.10, 0.45).dx, p(0.10, 0.45).dy, p(0.20, 0.31).dx,
          p(0.20, 0.31).dy, p(0.31, 0.21).dx, p(0.31, 0.21).dy);
    drawReadable(legs, outline);

    final foot = Path()
      ..moveTo(p(-0.77, 0.69).dx, p(-0.77, 0.69).dy)
      ..cubicTo(p(-0.70, 0.59).dx, p(-0.70, 0.59).dy, p(-0.61, 0.57).dx,
          p(-0.61, 0.57).dy, p(-0.53, 0.62).dx, p(-0.53, 0.62).dy)
      ..cubicTo(p(-0.61, 0.64).dx, p(-0.61, 0.64).dy, p(-0.67, 0.68).dx,
          p(-0.67, 0.68).dy, p(-0.72, 0.73).dx, p(-0.72, 0.73).dy);
    canvas.drawPath(foot, detail);

    // Minimal face: closed eye, nose/jaw and mouth.
    canvas.drawArc(
      Rect.fromCenter(
        center: p(0.57, -0.53),
        width: r * 0.10,
        height: r * 0.045,
      ),
      0.1,
      math.pi * 0.75,
      false,
      detail,
    );
    final face = Path()
      ..moveTo(p(0.68, -0.53).dx, p(0.68, -0.53).dy)
      ..cubicTo(p(0.71, -0.47).dx, p(0.71, -0.47).dy, p(0.68, -0.41).dx,
          p(0.68, -0.41).dy, p(0.61, -0.38).dx, p(0.61, -0.38).dy)
      ..cubicTo(p(0.56, -0.35).dx, p(0.56, -0.35).dy, p(0.50, -0.36).dx,
          p(0.50, -0.36).dy, p(0.46, -0.39).dx, p(0.46, -0.39).dy);
    canvas.drawPath(face, detail);
  }

  // Retained only as a historical fallback while the new coherent trace is
  // validated across existing saved projects.
  // ignore: unused_element
  void _drawVastuPurushOutline(Canvas canvas, Offset center, double r) {
    Offset p(double x, double y) => center.translate(x * r, y * r);
    void drawSeparatedPath(Path path, Paint foreground) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = foreground.strokeWidth + r * 0.006
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, foreground);
    }

    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.0085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Continuous outside silhouette traced from the supplied Vastu Purush.
    final body = Path()
      ..moveTo(p(-0.63, 0.58).dx, p(-0.63, 0.58).dy)
      ..cubicTo(p(-0.76, 0.48).dx, p(-0.76, 0.48).dy, p(-0.67, 0.29).dx,
          p(-0.67, 0.29).dy, p(-0.62, 0.18).dx, p(-0.62, 0.18).dy)
      ..cubicTo(p(-0.69, -0.03).dx, p(-0.69, -0.03).dy, p(-0.67, -0.42).dx,
          p(-0.67, -0.42).dy, p(-0.54, -0.54).dx, p(-0.54, -0.54).dy)
      ..cubicTo(p(-0.47, -0.63).dx, p(-0.47, -0.63).dy, p(-0.31, -0.61).dx,
          p(-0.31, -0.61).dy, p(-0.20, -0.58).dx, p(-0.20, -0.58).dy)
      ..cubicTo(p(-0.05, -0.54).dx, p(-0.05, -0.54).dy, p(0.12, -0.58).dx,
          p(0.12, -0.58).dy, p(0.22, -0.54).dx, p(0.22, -0.54).dy)
      ..cubicTo(p(0.28, -0.51).dx, p(0.28, -0.51).dy, p(0.29, -0.44).dx,
          p(0.29, -0.44).dy, p(0.35, -0.40).dx, p(0.35, -0.40).dy)
      ..cubicTo(p(0.45, -0.33).dx, p(0.45, -0.33).dy, p(0.58, -0.31).dx,
          p(0.58, -0.31).dy, p(0.62, -0.20).dx, p(0.62, -0.20).dy)
      ..cubicTo(p(0.70, 0.02).dx, p(0.70, 0.02).dy, p(0.65, 0.30).dx,
          p(0.65, 0.30).dy, p(0.53, 0.39).dx, p(0.53, 0.39).dy)
      ..cubicTo(p(0.45, 0.45).dx, p(0.45, 0.45).dy, p(0.48, 0.55).dx,
          p(0.48, 0.55).dy, p(0.36, 0.61).dx, p(0.36, 0.61).dy)
      ..cubicTo(p(0.18, 0.70).dx, p(0.18, 0.70).dy, p(-0.13, 0.67).dx,
          p(-0.13, 0.67).dy, p(-0.36, 0.66).dx, p(-0.36, 0.66).dy)
      ..cubicTo(p(-0.48, 0.66).dx, p(-0.48, 0.66).dy, p(-0.57, 0.67).dx,
          p(-0.57, 0.67).dy, p(-0.68, 0.70).dx, p(-0.68, 0.70).dy)
      ..cubicTo(p(-0.74, 0.72).dx, p(-0.74, 0.72).dy, p(-0.76, 0.67).dx,
          p(-0.76, 0.67).dy, p(-0.63, 0.58).dx, p(-0.63, 0.58).dy)
      ..close();
    drawSeparatedPath(body, paint);

    // Head and face, inclined toward the north-east as in the reference.
    final head = Path()
      ..moveTo(p(0.28, -0.45).dx, p(0.28, -0.45).dy)
      ..cubicTo(p(0.34, -0.70).dx, p(0.34, -0.70).dy, p(0.68, -0.72).dx,
          p(0.68, -0.72).dy, p(0.69, -0.51).dx, p(0.69, -0.51).dy)
      ..cubicTo(p(0.70, -0.39).dx, p(0.70, -0.39).dy, p(0.62, -0.31).dx,
          p(0.62, -0.31).dy, p(0.49, -0.31).dx, p(0.49, -0.31).dy)
      ..cubicTo(p(0.42, -0.31).dx, p(0.42, -0.31).dy, p(0.34, -0.37).dx,
          p(0.34, -0.37).dy, p(0.28, -0.45).dx, p(0.28, -0.45).dy)
      ..close();
    drawSeparatedPath(head, paint);

    final ear = Path()
      ..moveTo(p(0.34, -0.56).dx, p(0.34, -0.56).dy)
      ..cubicTo(p(0.26, -0.70).dx, p(0.26, -0.70).dy, p(0.20, -0.58).dx,
          p(0.20, -0.58).dy, p(0.28, -0.49).dx, p(0.28, -0.49).dy)
      ..cubicTo(p(0.23, -0.56).dx, p(0.23, -0.56).dy, p(0.27, -0.62).dx,
          p(0.27, -0.62).dy, p(0.34, -0.56).dx, p(0.34, -0.56).dy);
    canvas.drawPath(ear, paint);

    // Folded arms and legs form the characteristic central crossed pose.
    final frontArm = Path()
      ..moveTo(p(-0.35, -0.43).dx, p(-0.35, -0.43).dy)
      ..cubicTo(p(-0.18, -0.23).dx, p(-0.18, -0.23).dy, p(0.03, -0.03).dx,
          p(0.03, -0.03).dy, p(0.42, 0.22).dx, p(0.42, 0.22).dy)
      ..cubicTo(p(0.34, 0.30).dx, p(0.34, 0.30).dy, p(0.28, 0.32).dx,
          p(0.28, 0.32).dy, p(0.20, 0.25).dx, p(0.20, 0.25).dy)
      ..cubicTo(p(0.02, 0.12).dx, p(0.02, 0.12).dy, p(-0.23, -0.04).dx,
          p(-0.23, -0.04).dy, p(-0.38, -0.30).dx, p(-0.38, -0.30).dy);
    canvas.drawPath(frontArm, paint);

    final rearArm = Path()
      ..moveTo(p(-0.50, -0.18).dx, p(-0.50, -0.18).dy)
      ..cubicTo(p(-0.38, -0.15).dx, p(-0.38, -0.15).dy, p(-0.28, -0.05).dx,
          p(-0.28, -0.05).dy, p(-0.18, 0.09).dx, p(-0.18, 0.09).dy)
      ..cubicTo(p(-0.05, 0.27).dx, p(-0.05, 0.27).dy, p(0.14, 0.27).dx,
          p(0.14, 0.27).dy, p(0.34, 0.13).dx, p(0.34, 0.13).dy);
    canvas.drawPath(rearArm, paint);

    final foldedLeg = Path()
      ..moveTo(p(0.38, 0.22).dx, p(0.38, 0.22).dy)
      ..cubicTo(p(0.18, 0.36).dx, p(0.18, 0.36).dy, p(0.06, 0.47).dx,
          p(0.06, 0.47).dy, p(-0.08, 0.55).dx, p(-0.08, 0.55).dy)
      ..cubicTo(p(-0.26, 0.65).dx, p(-0.26, 0.65).dy, p(-0.43, 0.48).dx,
          p(-0.43, 0.48).dy, p(-0.48, 0.31).dx, p(-0.48, 0.31).dy)
      ..cubicTo(p(-0.53, 0.16).dx, p(-0.53, 0.16).dy, p(-0.61, 0.24).dx,
          p(-0.61, 0.24).dy, p(-0.62, 0.40).dx, p(-0.62, 0.40).dy);
    canvas.drawPath(foldedLeg, paint);

    final torso = Path()
      ..moveTo(p(-0.22, -0.57).dx, p(-0.22, -0.57).dy)
      ..cubicTo(p(-0.08, -0.36).dx, p(-0.08, -0.36).dy, p(-0.07, -0.10).dx,
          p(-0.07, -0.10).dy, p(-0.28, 0.03).dx, p(-0.28, 0.03).dy)
      ..cubicTo(p(-0.41, 0.11).dx, p(-0.41, 0.11).dy, p(-0.49, 0.02).dx,
          p(-0.49, 0.02).dy, p(-0.50, -0.18).dx, p(-0.50, -0.18).dy);
    canvas.drawPath(torso, paint);

    final detailPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.0052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Neck and shoulder folds.
    final neck = Path()
      ..moveTo(p(0.29, -0.45).dx, p(0.29, -0.45).dy)
      ..cubicTo(p(0.20, -0.39).dx, p(0.20, -0.39).dy, p(0.16, -0.31).dx,
          p(0.16, -0.31).dy, p(0.10, -0.24).dx, p(0.10, -0.24).dy)
      ..cubicTo(p(0.02, -0.17).dx, p(0.02, -0.17).dy, p(-0.08, -0.19).dx,
          p(-0.08, -0.19).dy, p(-0.18, -0.29).dx, p(-0.18, -0.29).dy);
    canvas.drawPath(neck, detailPaint);

    // Upper arm and elbow on the north-west side.
    final leftArmFold = Path()
      ..moveTo(p(-0.46, -0.43).dx, p(-0.46, -0.43).dy)
      ..cubicTo(p(-0.37, -0.32).dx, p(-0.37, -0.32).dy, p(-0.32, -0.20).dx,
          p(-0.32, -0.20).dy, p(-0.29, -0.08).dx, p(-0.29, -0.08).dy)
      ..cubicTo(p(-0.27, 0.01).dx, p(-0.27, 0.01).dy, p(-0.33, 0.08).dx,
          p(-0.33, 0.08).dy, p(-0.43, 0.05).dx, p(-0.43, 0.05).dy)
      ..cubicTo(p(-0.51, 0.02).dx, p(-0.51, 0.02).dy, p(-0.54, -0.07).dx,
          p(-0.54, -0.07).dy, p(-0.54, -0.17).dx, p(-0.54, -0.17).dy);
    canvas.drawPath(leftArmFold, detailPaint);

    // Bent thigh, knee and calf contours.
    final kneeFold = Path()
      ..moveTo(p(-0.57, 0.25).dx, p(-0.57, 0.25).dy)
      ..cubicTo(p(-0.50, 0.20).dx, p(-0.50, 0.20).dy, p(-0.46, 0.25).dx,
          p(-0.46, 0.25).dy, p(-0.43, 0.36).dx, p(-0.43, 0.36).dy)
      ..cubicTo(p(-0.38, 0.53).dx, p(-0.38, 0.53).dy, p(-0.25, 0.61).dx,
          p(-0.25, 0.61).dy, p(-0.10, 0.52).dx, p(-0.10, 0.52).dy);
    canvas.drawPath(kneeFold, detailPaint);

    final rightLegFold = Path()
      ..moveTo(p(0.34, 0.13).dx, p(0.34, 0.13).dy)
      ..cubicTo(p(0.25, 0.22).dx, p(0.25, 0.22).dy, p(0.19, 0.35).dx,
          p(0.19, 0.35).dy, p(0.08, 0.44).dx, p(0.08, 0.44).dy)
      ..cubicTo(p(-0.02, 0.53).dx, p(-0.02, 0.53).dy, p(-0.09, 0.57).dx,
          p(-0.09, 0.57).dy, p(-0.18, 0.55).dx, p(-0.18, 0.55).dy);
    canvas.drawPath(rightLegFold, detailPaint);

    // South-west foot and toes.
    final foot = Path()
      ..moveTo(p(-0.69, 0.65).dx, p(-0.69, 0.65).dy)
      ..cubicTo(p(-0.65, 0.59).dx, p(-0.65, 0.59).dy, p(-0.58, 0.57).dx,
          p(-0.58, 0.57).dy, p(-0.51, 0.60).dx, p(-0.51, 0.60).dy)
      ..cubicTo(p(-0.58, 0.62).dx, p(-0.58, 0.62).dy, p(-0.63, 0.65).dx,
          p(-0.63, 0.65).dy, p(-0.67, 0.70).dx, p(-0.67, 0.70).dy);
    canvas.drawPath(foot, detailPaint);
    for (var i = 0; i < 4; i++) {
      final y = 0.615 + i * 0.018;
      canvas.drawArc(
        Rect.fromCenter(
          center: p(-0.66 + i * 0.018, y),
          width: r * 0.075,
          height: r * 0.035,
        ),
        math.pi * 1.05,
        math.pi * 0.72,
        false,
        detailPaint,
      );
    }

    // Shoulder blade and spine contours from the north-west shoulder toward
    // the central waist.
    final spine = Path()
      ..moveTo(p(-0.30, -0.52).dx, p(-0.30, -0.52).dy)
      ..cubicTo(p(-0.20, -0.38).dx, p(-0.20, -0.38).dy, p(-0.12, -0.22).dx,
          p(-0.12, -0.22).dy, p(-0.08, -0.07).dx, p(-0.08, -0.07).dy)
      ..cubicTo(p(-0.05, 0.05).dx, p(-0.05, 0.05).dy, p(-0.12, 0.13).dx,
          p(-0.12, 0.13).dy, p(-0.24, 0.17).dx, p(-0.24, 0.17).dy);
    canvas.drawPath(spine, detailPaint);

    final shoulderBlade = Path()
      ..moveTo(p(-0.41, -0.36).dx, p(-0.41, -0.36).dy)
      ..cubicTo(p(-0.30, -0.28).dx, p(-0.30, -0.28).dy, p(-0.22, -0.18).dx,
          p(-0.22, -0.18).dy, p(-0.19, -0.08).dx, p(-0.19, -0.08).dy)
      ..cubicTo(p(-0.27, -0.12).dx, p(-0.27, -0.12).dy, p(-0.36, -0.21).dx,
          p(-0.36, -0.21).dy, p(-0.41, -0.36).dx, p(-0.41, -0.36).dy);
    canvas.drawPath(shoulderBlade, detailPaint);

    // Forearm and hand resting across the eastern thigh.
    final rightHand = Path()
      ..moveTo(p(0.18, 0.10).dx, p(0.18, 0.10).dy)
      ..cubicTo(p(0.26, 0.12).dx, p(0.26, 0.12).dy, p(0.34, 0.17).dx,
          p(0.34, 0.17).dy, p(0.43, 0.23).dx, p(0.43, 0.23).dy)
      ..cubicTo(p(0.39, 0.29).dx, p(0.39, 0.29).dy, p(0.35, 0.33).dx,
          p(0.35, 0.33).dy, p(0.29, 0.34).dx, p(0.29, 0.34).dy)
      ..cubicTo(p(0.23, 0.29).dx, p(0.23, 0.29).dy, p(0.18, 0.22).dx,
          p(0.18, 0.22).dy, p(0.13, 0.16).dx, p(0.13, 0.16).dy);
    canvas.drawPath(rightHand, detailPaint);
    for (var i = 0; i < 3; i++) {
      final finger = Path()
        ..moveTo(p(0.28 + i * 0.025, 0.19 + i * 0.012).dx,
            p(0.28 + i * 0.025, 0.19 + i * 0.012).dy)
        ..lineTo(p(0.38 + i * 0.018, 0.245 + i * 0.012).dx,
            p(0.38 + i * 0.018, 0.245 + i * 0.012).dy);
      canvas.drawPath(finger, detailPaint);
    }

    // Abdomen and hip folds make the central pose legible without filling it.
    final abdomen = Path()
      ..moveTo(p(-0.14, 0.12).dx, p(-0.14, 0.12).dy)
      ..cubicTo(p(-0.05, 0.18).dx, p(-0.05, 0.18).dy, p(0.06, 0.19).dx,
          p(0.06, 0.19).dy, p(0.16, 0.14).dx, p(0.16, 0.14).dy)
      ..cubicTo(p(0.10, 0.23).dx, p(0.10, 0.23).dy, p(0.02, 0.29).dx,
          p(0.02, 0.29).dy, p(-0.09, 0.30).dx, p(-0.09, 0.30).dy);
    canvas.drawPath(abdomen, detailPaint);

    // Jaw, nose and closed eye on the inclined head.
    final profile = Path()
      ..moveTo(p(0.62, -0.55).dx, p(0.62, -0.55).dy)
      ..cubicTo(p(0.66, -0.50).dx, p(0.66, -0.50).dy, p(0.67, -0.45).dx,
          p(0.67, -0.45).dy, p(0.63, -0.41).dx, p(0.63, -0.41).dy)
      ..cubicTo(p(0.59, -0.37).dx, p(0.59, -0.37).dy, p(0.53, -0.35).dx,
          p(0.53, -0.35).dy, p(0.47, -0.36).dx, p(0.47, -0.36).dy);
    canvas.drawPath(profile, detailPaint);

    // Small facial and hand/foot contours keep the code drawing readable at
    // report resolution without using the bitmap reference itself.
    canvas.drawArc(
      Rect.fromCenter(
          center: p(0.57, -0.39), width: r * 0.20, height: r * 0.10),
      0.15,
      math.pi * 0.78,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: p(0.55, -0.48),
        width: r * 0.075,
        height: r * 0.035,
      ),
      math.pi * 0.10,
      math.pi * 0.78,
      false,
      detailPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: p(-0.67, 0.63), width: r * 0.20, height: r * 0.10),
      math.pi,
      math.pi * 0.82,
      false,
      paint,
    );
  }

  void _drawInnerDevtaRing(
    Canvas canvas,
    Offset center,
    double inner,
    double outer, {
    bool drawFill = true,
  }) {
    const labels = ['BHUDHAR', 'ARYAMA', 'VIVASWAN', 'MITRA'];
    const colors = [
      Color(0xFFFFF3C4),
      Color(0xFFDDF2FF),
      Color(0xFFFFE2DC),
      Color(0xFFE5F5DF),
    ];
    _drawRing(
      canvas,
      center,
      inner,
      outer,
      labels,
      colors: colors,
      startAngle: -45,
      fontScale: 0.070,
      textColor: const Color(0xFF4E5964),
      drawFill: drawFill,
      borderColor: const Color(0xFF8B8F92),
      borderWidth: 0.45,
    );
  }

  void _drawCenterBrahmasthan(
    Canvas canvas,
    Offset center,
    double r, {
    bool drawFill = true,
  }) {
    const colors = [
      Color(0xFFE97059),
      Color(0xFFFCEB27),
      Color(0xFF109BDA),
      Color(0xFFE97059),
    ];
    if (drawFill) {
      for (var i = 0; i < 4; i++) {
        canvas.drawPath(
          arcSegment(center, r * 0.42, r, i * 90.0, (i + 1) * 90.0),
          Paint()..color = colors[i],
        );
      }
    }
    if (!transparentBackground) {
      canvas.drawCircle(center, r * 0.42, Paint()..color = Colors.white);
    }
    canvas.drawCircle(center, r, _stroke(_lineWhite, r * 0.04));
    _drawPlainText(
      canvas,
      'BRAHMASTHAN',
      center.translate(0, -r * 0.14),
      GoogleFonts.inter(
        fontSize: r * (transparentBackground ? 0.24 : 0.20),
        color: const Color(0xFF1F2833),
        fontWeight: transparentBackground ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 2,
      ),
    );
    _drawPlainText(
      canvas,
      'SUDARSHAN CHAKRA',
      center.translate(0, r * 0.19),
      GoogleFonts.inter(
        fontSize: r * (transparentBackground ? 0.135 : 0.11),
        color: const Color(0xFF1F2833),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
    final cross = Paint()
      ..color = const Color(0xFF777777)
      ..strokeWidth = r * 0.018;
    canvas.drawLine(
        center.translate(-r * 0.22, 0), center.translate(r * 0.22, 0), cross);
    canvas.drawLine(
        center.translate(0, -r * 0.22), center.translate(0, r * 0.22), cross);
  }

  void _drawMainKuberCenter(Canvas canvas, Offset center, double r) {
    if (!transparentBackground) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: const [
              Color(0xFFFFFDF6),
              Color(0xFFFFF1C7),
              Color(0xFFF3D891),
            ],
            stops: const [0, 0.68, 1],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFA77A4C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final mark = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E651D), Color(0xFFFFE58A), Color(0xFF9C6C18)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.75))
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final symbol = Path()
      ..moveTo(center.dx - r * 0.30, center.dy - r * 0.34)
      ..lineTo(center.dx - r * 0.12, center.dy - r * 0.18)
      ..lineTo(center.dx - r * 0.12, center.dy + r * 0.34)
      ..moveTo(center.dx + r * 0.34, center.dy - r * 0.35)
      ..lineTo(center.dx - r * 0.10, center.dy + r * 0.10)
      ..moveTo(center.dx + r * 0.02, center.dy - r * 0.02)
      ..lineTo(center.dx + r * 0.34, center.dy + r * 0.32);
    canvas.drawPath(symbol, mark);
    final diamondPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E651D), Color(0xFFFFE58A), Color(0xFF9C6C18)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    for (final offset in [
      Offset(0, -r * 0.48),
      Offset(r * 0.48, 0),
      Offset(0, r * 0.48),
      Offset(-r * 0.48, 0),
    ]) {
      final c = center + offset;
      final d = r * 0.07;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - d)
          ..lineTo(c.dx + d, c.dy)
          ..lineTo(c.dx, c.dy + d)
          ..lineTo(c.dx - d, c.dy)
          ..close(),
        diamondPaint,
      );
    }
  }

  void _drawElementDot(Canvas canvas, Offset center, double r) {
    const colors = [
      Color(0xFF1147B9),
      Color(0xFF19B94A),
      Color(0xFFD52430),
      Color(0xFFE7DE16),
    ];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2 + i * math.pi / 2,
        math.pi / 2,
        true,
        Paint()..color = colors[i],
      );
    }
  }

  void _drawTangentText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angle,
    TextStyle style, {
    double? maxWidth,
  }) {
    final pos = polar(center, radius, angle);
    final normalized = ((angle % 360) + 360) % 360;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: maxWidth ?? radius * 0.35);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle * math.pi / 180);
    if (normalized > 90 && normalized < 270) {
      canvas.rotate(math.pi);
    }
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _drawPlainText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    TextAlign textAlign = TextAlign.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = transparentBackground
        ? const Color(0xFF252A2E).withValues(alpha: 0.96)
        : color.withValues(alpha: 0.78)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * (transparentBackground ? 0.92 : 0.62);

  Color get _lineWhite =>
      transparentBackground ? const Color(0xFF3F3F3F) : Colors.white;

  void _drawTransparentAwareFill(Canvas canvas, Path path, Color color) {
    // Map overlays must be uniformly transparent. Previously white sectors
    // were skipped while coloured sectors retained a translucent fill, which
    // produced alternating shaded patches over the floor plan.
    if (transparentBackground) return;
    canvas.drawPath(
      path,
      Paint()..color = Color.lerp(color, Colors.white, 0.44)!,
    );
  }

  Color _zoneColor(int index) {
    if (index <= 1 || index == 15) return const Color(0xFF62ADD8);
    if (index >= 2 && index <= 5) return const Color(0xFFB8DDBE);
    if (index >= 6 && index <= 8) return const Color(0xFFFF6570);
    if (index >= 9 && index <= 10) return const Color(0xFFFFF15B);
    return Colors.white;
  }

  Color _gateColor(int index) {
    if (index <= 7) return const Color(0xFF62ADD8);
    if (index <= 14) return const Color(0xFFB8DDBE);
    if (index <= 22) return const Color(0xFFFF6570);
    if (index <= 24) return const Color(0xFFFFF15B);
    return Colors.white;
  }

  Color _spokeColor(double angle) {
    final d = ((angle % 360) + 360) % 360;
    if (d >= 315 || d < 45) return const Color(0xFF111DB8);
    if (d >= 45 && d < 135) return const Color(0xFF08CC39);
    if (d >= 135 && d < 180) return const Color(0xFFD61D35);
    if (d >= 180 && d < 225) return const Color(0xFFE4E000);
    return Colors.black;
  }
}

const _directions16 = [
  'NORTH',
  'NNE',
  'NE',
  'ENE',
  'EAST',
  'ESE',
  'SE',
  'SSE',
  'SOUTH',
  'SSW',
  'SW',
  'WSW',
  'WEST',
  'WNW',
  'NW',
  'NNW',
];

const _mainDirections = [
  'SSW',
  'SW',
  'WSW',
  'W',
  'WNW',
  'NW',
  'NNW',
  'N',
  'NNE',
  'NE',
  'ENE',
  'E',
  'ESE',
  'SE',
  'SSE',
  'S',
];

final _gateLabels = [
  for (final prefix in ['N', 'E', 'S', 'W'])
    for (var i = 1; i <= 8; i++) '$prefix$i',
];

const _benefits = [
  'MONEY\nOPPORTUNITIES',
  'HEALTH\nIMMUNITY',
  'IDEAS\nVISION',
  'FUN &\nRECREATION',
  'SOCIAL\nASSOCIATIONS',
  'ANALYSIS\nCHURNING',
  'CASH\nLIQUIDITY',
  'POWER\nCONFIDENCE',
  'FAME\nRELAXATION',
  'LETTING\nDISPOSAL',
  'RELATIONSHIP\nSKILLS',
  'EDUCATION\nSAVINGS',
  'GAINS\nFULFILLMENT',
  'DEPRESSION\nDETOX',
  'BANK\nSUPPORT',
  'SEX\nATTRACTION',
];

const _organs = [
  'KIDNEY',
  'PERICARDIUM',
  'CIRCULATION',
  'LIVER',
  'GALL BLADDER',
  'SPLEEN',
  'STOMACH',
  'HEART',
  'LUNGS',
  'VATA',
  'COLON',
  'INTESTINE',
  'BLADDER',
  'KAPHA',
  'TAMAS',
  'PITTA',
];

const _devtas = [
  'ROGA',
  'AHI',
  'MUKHYA',
  'BHALLAT',
  'SOMA',
  'BHUJANG',
  'ADITI',
  'DITI',
  'SHIKHI',
  'PARJANYA',
  'JAYANT',
  'MAHENDRI',
  'SURYA',
  'SATYA',
  'ANTRIKSH',
  'ANIL',
  'PUSHA',
  'VITATHA',
  'GRIHASPATYA',
  'YAMA',
  'GANDHARVA',
  'BHRINGRAJ',
  'MRIGAH',
  'PITRA',
  'DAUVARIK',
  'SUGREEV',
  'PUSHPDANT',
  'VARUN',
  'ASUR',
  'SHOSHA',
  'PAPYAKSHMA',
  'RUDRA',
];

const _mainLifeLabels = [
  'विसर्जन\nDisposal',
  'संबंध\nRelationship',
  'शिक्षा\nStudies',
  'प्राप्तियाँ\nGains',
  'डिप्रेशन\nDepression',
  'सहयोग\nSupport',
  'संवेदनशीलता\nSensuality',
  'ग्राहक\nCustomer',
  'समुदाय\nCommunity',
  'प्रेरणा\nMotivation',
  'खुशी\nHappiness',
  'मेल जोल\nNetworking',
  'मंथन\nOverthinking',
  'धन\nMoney',
  'आत्मविश्वास\nConfidence',
  'यश\nFame',
];

const _mainInnerLabels = [
  'Earth',
  'Space',
  'Vata',
  'Kapha',
  'Water',
  'Air',
  'Pitta',
  'Fire',
];

const _benefitColors = [
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFF3BD631),
  Color(0xFF3BD631),
  Color(0xFF3BD631),
  Color(0xFFF47B62),
  Color(0xFFF47B62),
  Color(0xFFF47B62),
  Color(0xFFFFE72D),
  Color(0xFFFFE72D),
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Color(0xFF139FDB),
];

const _organColors = [
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Colors.white,
  Color(0xFFF04B34),
  Color(0xFFF04B34),
  Color(0xFFDCD0E2),
  Color(0xFFDCD0E2),
  Colors.white,
  Colors.white,
  Colors.white,
  Color(0xFFDCD0E2),
  Colors.white,
  Color(0xFFFFEC1D),
];

const _gateBlockColors = [
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFFFFEA20),
  Color(0xFF139FDB),
  Colors.white,
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFF28D832),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFFF58268),
  Color(0xFF28D832),
  Color(0xFFFFEA20),
  Color(0xFFF58268),
  Color(0xFFF58268),
  Colors.white,
  Color(0xFF28D832),
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Colors.white,
  Color(0xFFF58268),
  Color(0xFFF58268),
  Colors.white,
  Colors.white,
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
];

const _devtaColors = [
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFFFFEA20),
  Color(0xFFF58268),
  Color(0xFFFFEA20),
  Color(0xFF28D832),
  Color(0xFF28D832),
  Color(0xFF139FDB),
  Color(0xFF28D832),
  Color(0xFF28D832),
  Color(0xFF28D832),
  Color(0xFF139FDB),
  Color(0xFFF58268),
  Color(0xFFFFEA20),
  Color(0xFFFFEA20),
  Color(0xFF139FDB),
  Color(0xFFF58268),
  Color(0xFF28D832),
  Color(0xFFFFEA20),
  Color(0xFF139FDB),
  Color(0xFFFFEA20),
  Color(0xFF28D832),
  Color(0xFF139FDB),
  Color(0xFF139FDB),
  Color(0xFFF58268),
  Color(0xFF139FDB),
  Color(0xFFF58268),
  Color(0xFFF58268),
  Color(0xFFFFEA20),
  Color(0xFF28D832),
  Color(0xFF139FDB),
];

const _mainDirectionColors = [
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
  Color(0xFFF7EBD4),
];

const _mainLifeColors = [
  Color(0xFFFFDF69),
  Color(0xFFFFE89A),
  Color(0xFFF7F2E8),
  Color(0xFFF7F2E8),
  Color(0xFFF7F2E8),
  Color(0xFFF7F2E8),
  Color(0xFFCFEAF8),
  Color(0xFFCFEAF8),
  Color(0xFFCFEAF8),
  Color(0xFFDDEB9A),
  Color(0xFFDDEB9A),
  Color(0xFFDDEB9A),
  Color(0xFFDDEB9A),
  Color(0xFFF5C4BC),
  Color(0xFFF5C4BC),
  Color(0xFFF5C4BC),
];

const _mainInnerColors = [
  Color(0xFFFFDF69),
  Color(0xFFF7F7F7),
  Color(0xFFE7E6EC),
  Color(0xFFCFEAF8),
  Color(0xFFBFDFF2),
  Color(0xFFDDEB9A),
  Color(0xFFF5C4BC),
  Color(0xFFF5C4BC),
];
