import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// تم اصلی برنامه - پشتیبانی از فارسی و RTL
class AppTheme {
  // پالت رنگ
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF26A69A);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFC62828);
  static const Color warningColor = Color(0xFFEF6C00);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF455A64);
  static const Color borderColor = Color(0xFFCFD8DC);

  // رنگ سرستون‌های جدول (مطابق اکسل)
  static const Color tableHeaderBlue = Color(0xFF1976D2);
  static const Color tableHeaderPurple = Color(0xFF7B1FA2);
  static const Color tableHeaderTeal = Color(0xFF00838F);
  static const Color tableRowAlternate = Color(0xFFE3F2FD);

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
      ),
      textTheme: _persianTextTheme(base.textTheme, Colors.black87),
      primaryTextTheme: _persianTextTheme(base.primaryTextTheme, Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: AppConstants.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 13,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 13,
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryDarkColor,
        contentTextStyle: TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFB0BEC5),
        labelStyle: TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextTheme _persianTextTheme(TextTheme base, Color color) {
    const family = AppConstants.fontFamily;
    return base.copyWith(
      displayLarge: TextStyle(fontFamily: family, fontSize: 36, fontWeight: FontWeight.w700, color: color),
      displayMedium: TextStyle(fontFamily: family, fontSize: 30, fontWeight: FontWeight.w700, color: color),
      displaySmall: TextStyle(fontFamily: family, fontSize: 26, fontWeight: FontWeight.w700, color: color),
      headlineLarge: TextStyle(fontFamily: family, fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineMedium: TextStyle(fontFamily: family, fontSize: 20, fontWeight: FontWeight.w700, color: color),
      headlineSmall: TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleLarge: TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleMedium: TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w400, color: color),
      bodyMedium: TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, color: color),
      labelLarge: TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w600, color: color),
      labelMedium: TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w500, color: color),
      labelSmall: TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, color: color),
    );
  }
}
