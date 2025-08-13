import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D0D); // خلفية داكنة جدًا
  static const Color primaryRed = Color(0xFFE50914); // أحمر Netflix
  static const Color accentBlue = Color(0xFF0096FF); // أزرق حديث
  static const Color cardDark = Color(0xFF1A1A1A); // رمادي داكن للبطاقات
  static const Color lightText = Color(0xFFF2F2F2); // نص فاتح
  static const Color mutedText = Color(0xFFAAAAAA); // نص خافت
}

class AppTheme {
  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryRed,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryRed,
      secondary: AppColors.accentBlue,
      surface: AppColors.cardDark,
    ),

    textTheme: GoogleFonts.tajawalTextTheme(
      // ← اختر أي خط عربي
      const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryRed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      hintStyle: TextStyle(color: AppColors.mutedText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightText),
    cardColor: AppColors.cardDark,
    dialogTheme: DialogThemeData(backgroundColor: AppColors.cardDark),
  );
}
