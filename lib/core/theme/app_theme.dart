import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  // Backgrounds
  static const bg = Color(0xFF080808);
  static const sheet = Color(0xFF111111);
  static const elevated = Color(0xFF191919);
  static const pill = Color(0xFF161616);

  // Dividers
  static const line = Color(0xFF1C1C1C);
  static const border = Color(0xFF242424);

  // Text
  static const ink = Color(0xFFFFFFFF);
  static const dim = Color(0xFF888888);
  static const muted = Color(0xFF444444);

  // Semantic
  static const ok = Color(0xFF32D74B);
  static const warn = Color(0xFFFF9500);
  static const err = Color(0xFFFF3B30);
  static const blue = Color(0xFF0A84FF);

  static Color priority(int p) => [muted, warn, err][p.clamp(0, 2)];
}

// Typographie — Space Grotesk pour les titres, Inter pour le corps
class T {
  static TextStyle hero(BuildContext ctx) => GoogleFonts.spaceGrotesk(
      fontSize: 64, fontWeight: FontWeight.w700, color: C.ink, height: 1.0, letterSpacing: -2);
  static TextStyle h1(BuildContext ctx) => GoogleFonts.spaceGrotesk(
      fontSize: 34, fontWeight: FontWeight.w700, color: C.ink, height: 1.1, letterSpacing: -0.5);
  static TextStyle h2(BuildContext ctx) => GoogleFonts.spaceGrotesk(
      fontSize: 22, fontWeight: FontWeight.w600, color: C.ink, letterSpacing: -0.3);
  static TextStyle h3(BuildContext ctx) => GoogleFonts.spaceGrotesk(
      fontSize: 17, fontWeight: FontWeight.w600, color: C.ink);
  static TextStyle body(BuildContext ctx) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: C.ink);
  static TextStyle small(BuildContext ctx) =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: C.dim);
  static TextStyle label(BuildContext ctx) => GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, color: C.muted, letterSpacing: 1.4);
  static TextStyle mono(BuildContext ctx) => GoogleFonts.jetBrainsMono(
      fontSize: 13, fontWeight: FontWeight.w400, color: C.dim);
  static TextStyle monoLg(BuildContext ctx) => GoogleFonts.jetBrainsMono(
      fontSize: 22, fontWeight: FontWeight.w500, color: C.ink);
  static TextStyle monoXl(BuildContext ctx) => GoogleFonts.jetBrainsMono(
      fontSize: 48, fontWeight: FontWeight.w300, color: C.ink, letterSpacing: -1);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(
        primary: C.ink,
        onPrimary: C.bg,
        surface: C.sheet,
        onSurface: C.ink,
        error: C.err,
        outline: C.border,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: C.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: C.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      dividerTheme: const DividerThemeData(color: C.line, thickness: 0.5, space: 0),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.bg : C.dim),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? C.ink : C.elevated),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.elevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.ink, width: 1)),
        hintStyle: GoogleFonts.inter(color: C.muted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: C.elevated,
        contentTextStyle: GoogleFonts.inter(color: C.ink, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
