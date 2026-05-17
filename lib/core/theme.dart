import 'package:flutter/material.dart';

class AppTheme {
  // Warna Utama: Blue Palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color backgroundGrey = Color(0xFFF8FAFC); // Slate 50
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textGrey = Color(0xFF64748B); // Slate 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundGrey,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: cardWhite,
        background: backgroundGrey,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}