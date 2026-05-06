import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors (vibrant green palette)
  static const Color primary = Color(0xFF22C55E);      // Green-500
  static const Color primaryLight = Color(0xFF86EFAC); // Green-300
  static const Color primaryDeep = Color(0xFF15803D);  // Green-700
  static const Color accent = Color(0xFF10B981);       // Emerald-500
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Dynamic color getters with greenish tints
  static Color getBackground(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF050F0A) // Very deep green-black
      : const Color(0xFFF0FDF4); // Very light green-tinted white

  static Color getSurface(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF0C1A14) // Dark green card surface
      : Colors.white;

  static Color getBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF14532D) // Dark green border
      : const Color(0xFFDCFCE7); // Light green border

  static Color getTextPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFFF0FDF4) 
      : const Color(0xFF064E3B); // Deepest green text

  static Color getTextSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF86EFAC).withValues(alpha: 0.7) 
      : const Color(0xFF065F46);

  static Color getTextMuted(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? const Color(0xFF14532D) 
      : const Color(0xFF65A30D).withValues(alpha: 0.6);

  // Theme Definitions
  static ThemeData get lightTheme => _createTheme(Brightness.light);
  static ThemeData get darkTheme => _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF050F0A) : const Color(0xFFF0FDF4);
    final surface = isDark ? const Color(0xFF0C1A14) : Colors.white;
    final border = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
    final text = isDark ? const Color(0xFFF0FDF4) : const Color(0xFF064E3B);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: isDark 
          ? ColorScheme.dark(
              primary: primary, 
              onPrimary: Colors.white,
              secondary: accent, 
              surface: surface, 
              error: error,
              onSurface: text,
            ) 
          : ColorScheme.light(
              primary: primary, 
              onPrimary: Colors.white,
              secondary: accent, 
              surface: surface, 
              error: error,
              onSurface: text,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0F241B) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
        hintStyle: TextStyle(color: isDark ? const Color(0xFF14532D) : const Color(0xFF94A3B8)),
        labelStyle: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
        prefixIconColor: primary,
        suffixIconColor: primary,
      ),
    );
  }
}
