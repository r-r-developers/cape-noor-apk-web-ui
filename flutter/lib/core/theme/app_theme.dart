import 'package:flutter/material.dart';

/// Cape Noor design system — deep Islamic dark theme inspired by Muslim Pro.
/// Accent colours mirror a nighttime mosque aesthetic: navy, gold, green.
class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color navyDeep   = Color(0xFF0A0F1A);
  static const Color navyMid    = Color(0xFF111827);
  static const Color navyLight  = Color(0xFF1E293B);
  static const Color cardBg     = Color(0xFF162032);
  static const Color gold       = Color(0xFFD4AF37);
  static const Color goldLight  = Color(0xFFE8CC6A);
  static const Color green      = Color(0xFF22C55E);
  static const Color greenDark  = Color(0xFF15803D);
  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF64748B);
  static const Color divider       = Color(0xFF1E293B);
  static const Color error         = Color(0xFFEF4444);

  // ── Light theme placeholders (for user setting) ───────────────────────────
  static const Color lightBg      = Color(0xFFF8F5F0);
  static const Color lightCard    = Color(0xFFFFFFFF);
  static const Color lightNavy    = Color(0xFF1E3A5F);

  // ── Prayer colour coding ──────────────────────────────────────────────────
  static const Map<String, Color> prayerColors = {
    'fajr'   : Color(0xFF6366F1), // Indigo — dawn
    'thuhr'  : Color(0xFFEAB308), // Golden — midday
    'asr'    : Color(0xFFF97316), // Orange — afternoon
    'maghrib': Color(0xFFEC4899), // Pink — sunset
    'isha'   : Color(0xFF8B5CF6), // Purple — night
  };

  static ThemeData dark({Color? primaryOverride}) {
    final primary = primaryOverride ?? green;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary:    primary,
        secondary:  gold,
        surface:    navyMid,
        onPrimary:  Colors.black,
        onSecondary: Colors.black,
        onSurface:  textPrimary,
        error:      error,
      ),
      scaffoldBackgroundColor: navyDeep,
      cardTheme: const CardTheme(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDeep,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navyMid,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navyMid,
        indicatorColor: primary.withAlpha(51),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: textMuted),
        ),
        overlayColor: WidgetStatePropertyAll(primary.withAlpha(20)),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Amiri', color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Amiri', color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge:  TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge:   TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium:  TextStyle(color: textSecondary, fontSize: 14),
        bodySmall:   TextStyle(color: textMuted, fontSize: 12),
        labelLarge:  TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: navyLight,
        selectedColor: primary.withAlpha(51),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData light({Color? primaryOverride}) {
    final primary = primaryOverride ?? greenDark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary:   primary,
        secondary: gold,
        surface:   lightCard,
        onPrimary: Colors.white,
        error:     error,
      ),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: lightNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
