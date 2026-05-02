import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── ألوان Blutoon الرسمية من قالبك
  static const primary     = Color(0xFF2394FC);
  static const primaryDeep = Color(0xFF0066D6);
  static const black       = Color(0xFF111111);
  static const white       = Color(0xFFFFFFFF);
  static const grey        = Color(0xFFF1F5F9);
  static const greyBorder  = Color(0xFFE2E8F0);
  static const greyText    = Color(0xFF64748B);
  static const greyLight   = Color(0xFF94A3B8);
  static const green       = Color(0xFF2ecc71);
  static const red         = Color(0xFFe74c3c);
  static const yellow      = Color(0xFFF1C40F);
  static const purple      = Color(0xFFa78bfa);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: white,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: black,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: black,
        unselectedLabelColor: greyLight,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey,
        selectedColor: primary,
        labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: greyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red),
        ),
        hintStyle: GoogleFonts.cairo(color: greyLight, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: greyBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
