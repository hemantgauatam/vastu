import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Home palette shared across every screen.
  static const Color bgDark = Color(0xFFF5EEDD);
  static const Color bgDarker = Color(0xFFEAD9B8);
  static const Color bgPanel = Color(0xFFFFFBF1);
  static const Color gold = Color(0xFF9B7428);
  static const Color goldBright = Color(0xFFB8913E);
  static const Color cream = Color(0xFF2A2117);
  static const Color creamSoft = Color(0xFFF5EEDD);
  static const Color body = Color(0xFF3C3022);
  static const Color muted = Color(0xFF76664D);
  static const Color goldSoft = Color(0xFFF0DFC0);
  static const Color line = Color(0x3D9B7428);
  static const Color surfaceWarm = Color(0xFFF9EBD0);
  static const Color accentRed = Color(0xFFC8102E);

  // Soft cream panels used throughout the app.
  static BoxDecoration glassDecoration({
    double radius = 16,
    double opacity = 0.04,
    double borderOpacity = 0.15,
  }) {
    final fillOpacity = (0.88 + opacity).clamp(0.88, 0.98).toDouble();
    return BoxDecoration(
      color: bgPanel.withValues(alpha: fillOpacity),
      borderRadius: BorderRadius.circular(radius),
      border:
          Border.all(color: gold.withValues(alpha: borderOpacity), width: 1),
      boxShadow: [
        BoxShadow(
          color: body.withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration glassStrongDecoration({double radius = 16}) {
    return BoxDecoration(
      color: bgPanel.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: gold.withValues(alpha: 0.25), width: 1),
      boxShadow: [
        BoxShadow(
          color: body.withValues(alpha: 0.1),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({double radius = 10}) {
    return BoxDecoration(
      color: bgPanel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: line),
      boxShadow: [
        BoxShadow(
          color: body.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration insetPanelDecoration({double radius = 10}) {
    return BoxDecoration(
      color: surfaceWarm.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: gold.withValues(alpha: 0.16)),
    );
  }

  static BoxDecoration goldButtonDecoration({double radius = 14}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [gold, goldBright],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: gold.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle({double radius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: cream,
      elevation: 0,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }

  static ButtonStyle secondaryButtonStyle({double radius = 10}) {
    return OutlinedButton.styleFrom(
      foregroundColor: cream,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      side: BorderSide(color: gold.withValues(alpha: 0.34)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  static InputDecoration inputDecoration({
    required String label,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      labelStyle: uiText(size: 12, color: muted),
      suffixStyle: uiText(size: 11, color: gold, weight: FontWeight.w700),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: gold),
      filled: true,
      fillColor: bgPanel,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: gold.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentRed.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentRed, width: 1.3),
      ),
    );
  }

  // Typography
  static TextStyle divineTitle({
    double size = 24,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: size,
      color: color ?? cream,
      fontWeight: weight,
      letterSpacing: 0,
    );
  }

  static TextStyle divineItalic({double size = 16, Color? color}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: size,
      color: color ?? cream,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle devanagari({double size = 14, Color? color}) {
    return GoogleFonts.notoSerifDevanagari(
      fontSize: size,
      color: color ?? cream,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle uiLabel({double size = 10, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color ?? muted,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
  }

  static TextStyle uiText({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color ?? cream,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  // App background gradient
  static BoxDecoration appBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFBF1), bgDark, Color(0xFFEAD9B8)],
        stops: [0.0, 0.46, 1.0],
      ),
    );
  }
}
