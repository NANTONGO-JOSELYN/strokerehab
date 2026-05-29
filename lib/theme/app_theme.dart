import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  RehabCoach Design System
///  Dark clinical theme + quality colour tokens
/// ─────────────────────────────────────────────────────────────────────────────

/// The three exercise quality levels recognised by the classifier.
/// Used throughout the app to replace the old "posture" terminology.
enum QualityLevel {
  /// Movement meets expected biomechanical criteria.
  good,

  /// Minor deviations — patient should make small adjustments.
  needsImprovement,

  /// Significant deviation — corrective instruction required.
  poor,
}

class AppTheme {
  AppTheme._();

  // ── Brand colours ────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF00C6AE);
  static const Color primaryDark  = Color(0xFF008F7E);
  static const Color primaryLight = Color(0xFF4DFFD9);
  static const Color accent       = Color(0xFF3D8BFF);

  // ── Quality colours ───────────────────────────────────────────────────────────
  static const Color good         = Color(0xFF00E676);
  static const Color goodBg       = Color(0xFF003320);
  static const Color warning      = Color(0xFFFFD600);
  static const Color warningBg    = Color(0xFF332A00);
  static const Color poor         = Color(0xFFFF5252);
  static const Color poorBg       = Color(0xFF330D0D);

  // ── Named aliases (used across all screens/widgets) ───────────────────────────
  static const Color qualityGood     = good;
  static const Color qualityWarning  = warning;
  static const Color qualityPoor     = poor;
  static const Color accentBlue      = accent;

  // ── Background layers ─────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFF0A0E1A);
  static const Color background = bg;   // alias
  static const Color surface    = Color(0xFF111827);
  static const Color card       = Color(0xFF1A2236);
  static const Color surfaceCard = card; // alias
  static const Color border     = Color(0xFF243050);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8A9BBF);
  static const Color textMuted     = Color(0xFF4A5580);

  // ── Gradient ──────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C6AE), Color(0xFF3D8BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Quality helpers ───────────────────────────────────────────────────────────
  static Color qualityColor(QualityLevel q) {
    switch (q) {
      case QualityLevel.good:            return good;
      case QualityLevel.needsImprovement: return warning;
      case QualityLevel.poor:            return poor;
    }
  }

  static Color qualityBgColor(QualityLevel q) {
    switch (q) {
      case QualityLevel.good:            return goodBg;
      case QualityLevel.needsImprovement: return warningBg;
      case QualityLevel.poor:            return poorBg;
    }
  }

  static String qualityLabel(QualityLevel q) {
    switch (q) {
      case QualityLevel.good:            return 'Good Exercise Quality';
      case QualityLevel.needsImprovement: return 'Needs Improvement';
      case QualityLevel.poor:            return 'Poor Exercise Quality';
    }
  }

  static String qualityEmoji(QualityLevel q) {
    switch (q) {
      case QualityLevel.good:            return '🟢';
      case QualityLevel.needsImprovement: return '🟡';
      case QualityLevel.poor:            return '🔴';
    }
  }

  // ── Material Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: card,
      selectedColor: primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontFamily: 'Outfit', color: textSecondary),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
  );
}
