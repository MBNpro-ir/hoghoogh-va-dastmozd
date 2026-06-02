import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// سیستم طراحی Material Persian 3
/// بر اساس DESIGN.md - پالت آبی کبالت و قرمز یاقوتی
class AppTheme {
  // -------- پالت رنگ اصلی (Material 3 Tonal Palette) --------
  static const Color primarySeed = Color(0xFF004394);
  static const Color secondarySeed = Color(0xFFB61718);
  static const Color tertiarySeed = Color(0xFF004E58);

  // -------- نام‌های مستعار برای سازگاری با کد قدیمی --------
  // (deprecated: استفاده از Theme.of(context).colorScheme.* توصیه می‌شود)
  static const Color primaryColor = lightPrimary;
  static const Color primaryDarkColor = lightPrimaryContainer;
  static const Color accentColor = lightTertiary;
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = lightError;
  static const Color warningColor = Color(0xFFEF6C00);
  static const Color backgroundColor = lightBackground;
  static const Color cardColor = lightSurfaceContainerLowest;
  static const Color textPrimary = lightOnSurface;
  static const Color textSecondary = lightOnSurfaceVariant;
  static const Color borderColor = lightOutlineVariant;
  static const Color tableHeaderBlue = lightPrimary;
  static const Color tableHeaderPurple = Color(0xFF7B1FA2);
  static const Color tableHeaderTeal = lightTertiary;
  static const Color tableRowAlternate = Color(0xFFE3F2FD);

  // -------- پالت لایت (مقادیر DESIGN.md) --------
  static const Color lightPrimary = Color(0xFF004394);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFF005AC1);
  static const Color lightOnPrimaryContainer = Color(0xFFC8D8FF);

  static const Color lightSecondary = Color(0xFFB61718);
  static const Color lightOnSecondary = Colors.white;
  static const Color lightSecondaryContainer = Color(0xFFDA342D);
  static const Color lightOnSecondaryContainer = Color(0xFFFFFBFF);

  static const Color lightTertiary = Color(0xFF004E58);
  static const Color lightOnTertiary = Colors.white;
  static const Color lightTertiaryContainer = Color(0xFF006874);
  static const Color lightOnTertiaryContainer = Color(0xFF97E4F2);

  static const Color lightBackground = Color(0xFFFBF8FE);
  static const Color lightOnBackground = Color(0xFF1B1B1F);

  static const Color lightSurface = Color(0xFFFBF8FE);
  static const Color lightOnSurface = Color(0xFF1B1B1F);
  static const Color lightSurfaceDim = Color(0xFFDCD9DE);
  static const Color lightSurfaceBright = Color(0xFFFBF8FE);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF6F2F8);
  static const Color lightSurfaceContainer = Color(0xFFF0EDF2);
  static const Color lightSurfaceContainerHigh = Color(0xFFEAE7ED);
  static const Color lightSurfaceContainerHighest = Color(0xFFE4E1E7);
  static const Color lightOnSurfaceVariant = Color(0xFF424753);
  static const Color lightSurfaceVariant = Color(0xFFE4E1E7);

  static const Color lightOutline = Color(0xFF727784);
  static const Color lightOutlineVariant = Color(0xFFC2C6D5);

  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Colors.white;
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF93000A);

  static const Color lightInverseSurface = Color(0xFF303034);
  static const Color lightInverseOnSurface = Color(0xFFF3F0F5);
  static const Color lightInversePrimary = Color(0xFFADC6FF);

  // -------- پالت تاریک (Dark Mode با کنتراست بالا) --------
  static const Color darkPrimary = Color(0xFFADC6FF);
  static const Color darkOnPrimary = Color(0xFF002F69);
  static const Color darkPrimaryContainer = Color(0xFF004494);
  static const Color darkOnPrimaryContainer = Color(0xFFD8E2FF);

  static const Color darkSecondary = Color(0xFFFFB4AB);
  static const Color darkOnSecondary = Color(0xFF690007);
  static const Color darkSecondaryContainer = Color(0xFF930009);
  static const Color darkOnSecondaryContainer = Color(0xFFFFDAD5);

  static const Color darkTertiary = Color(0xFF85D2E0);
  static const Color darkOnTertiary = Color(0xFF00363D);
  static const Color darkTertiaryContainer = Color(0xFF004F58);
  static const Color darkOnTertiaryContainer = Color(0xFFA2EFFD);

  static const Color darkBackground = Color(0xFF131318);
  static const Color darkOnBackground = Color(0xFFE4E1E7);

  static const Color darkSurface = Color(0xFF131318);
  static const Color darkOnSurface = Color(0xFFE4E1E7);
  static const Color darkSurfaceDim = Color(0xFF131318);
  static const Color darkSurfaceBright = Color(0xFF393941);
  static const Color darkSurfaceContainerLowest = Color(0xFF0D0E13);
  static const Color darkSurfaceContainerLow = Color(0xFF1B1B22);
  static const Color darkSurfaceContainer = Color(0xFF1F1F27);
  static const Color darkSurfaceContainerHigh = Color(0xFF292A32);
  static const Color darkSurfaceContainerHighest = Color(0xFF34343D);
  static const Color darkOnSurfaceVariant = Color(0xFFC2C6D5);
  static const Color darkSurfaceVariant = Color(0xFF424753);

  static const Color darkOutline = Color(0xFF8C909F);
  static const Color darkOutlineVariant = Color(0xFF424753);

  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color darkInverseSurface = Color(0xFFE4E1E7);
  static const Color darkInverseOnSurface = Color(0xFF303034);
  static const Color darkInversePrimary = Color(0xFF004494);

  // -------- شعاع‌های گوشه (Design.md) --------
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusDefault = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusFull = 9999;

  // -------- سایه‌های اتمسفری --------
  static List<BoxShadow> elevation1(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevation2(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevation3(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.15),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // -------- تم روشن --------
  static ThemeData lightTheme({
    bool highContrast = false,
    bool largeControls = false,
    bool extraSpacing = false,
  }) {
    const family = AppConstants.fontFamily;
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      secondary: lightSecondary,
      onSecondary: lightOnSecondary,
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: lightOnSecondaryContainer,
      tertiary: lightTertiary,
      onTertiary: lightOnTertiary,
      tertiaryContainer: lightTertiaryContainer,
      onTertiaryContainer: lightOnTertiaryContainer,
      error: lightError,
      onError: lightOnError,
      errorContainer: lightErrorContainer,
      onErrorContainer: lightOnErrorContainer,
      surface: lightSurface,
      onSurface: lightOnSurface,
      surfaceContainerLowest: lightSurfaceContainerLowest,
      surfaceContainerLow: lightSurfaceContainerLow,
      surfaceContainer: lightSurfaceContainer,
      surfaceContainerHigh: lightSurfaceContainerHigh,
      surfaceContainerHighest: lightSurfaceContainerHighest,
      onSurfaceVariant: lightOnSurfaceVariant,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      inverseSurface: lightInverseSurface,
      onInverseSurface: lightInverseOnSurface,
      inversePrimary: lightInversePrimary,
      surfaceTint: lightPrimary,
      // ignore: deprecated_member_use
      surfaceVariant: lightSurfaceContainerHighest,
      scrim: Color(0x99000000),
      shadow: Color(0xFF000000),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: family,
    );

    final controlPadding = largeControls
        ? const EdgeInsets.symmetric(horizontal: 30, vertical: 18)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 11);
    final inputPadding = largeControls
        ? const EdgeInsets.symmetric(horizontal: 18, vertical: 18)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    final density = extraSpacing
        ? const VisualDensity(horizontal: 1, vertical: 1)
        : VisualDensity.standard;

    final theme = base.copyWith(
      visualDensity: density,
      textTheme: _persianTextTheme(base.textTheme, lightOnSurface),
      primaryTextTheme: _persianTextTheme(base.primaryTextTheme, Colors.white),
      iconTheme: const IconThemeData(color: lightOnSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        surfaceTintColor: lightPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightOnSurface,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          padding: controlPadding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: lightOnPrimary,
          padding: controlPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: controlPadding,
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightOutline, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceContainerLowest,
        contentPadding: inputPadding,
        labelStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: lightOnSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: lightOnSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIconColor: lightOnSurfaceVariant,
        suffixIconColor: lightOnSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightError, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: lightOutlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: lightOutlineVariant,
        thickness: 0.6,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightOnSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: lightOnSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightInverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: lightInverseOnSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: lightPrimary,
        unselectedLabelColor: lightOnSurfaceVariant,
        indicatorColor: lightPrimary,
        labelStyle: const TextStyle(
          fontFamily: family,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceContainer,
        selectedColor: lightPrimaryContainer,
        labelStyle: TextStyle(
          fontFamily: family,
          fontSize: 13,
          color: lightOnSurface,
        ),
        padding: extraSpacing
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightSecondary,
        foregroundColor: lightOnSecondary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightOnPrimary;
          return lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightPrimary;
          return lightSurfaceContainerHighest;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: lightPrimary,
        inactiveTrackColor: lightSurfaceContainerHighest,
        thumbColor: lightPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPrimary,
        linearTrackColor: lightSurfaceContainer,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: lightOnSurfaceVariant,
        textColor: lightOnSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: lightSurfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: lightOnSurface,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightInverseSurface,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: TextStyle(
          fontFamily: family,
          fontSize: 12,
          color: lightInverseOnSurface,
        ),
      ),
    );
    return highContrast ? _highContrast(theme) : theme;
  }

  // -------- تم تاریک --------
  static ThemeData darkTheme({
    bool highContrast = false,
    bool largeControls = false,
    bool extraSpacing = false,
  }) {
    const family = AppConstants.fontFamily;
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: darkOnSecondaryContainer,
      tertiary: darkTertiary,
      onTertiary: darkOnTertiary,
      tertiaryContainer: darkTertiaryContainer,
      onTertiaryContainer: darkOnTertiaryContainer,
      error: darkError,
      onError: darkOnError,
      errorContainer: darkErrorContainer,
      onErrorContainer: darkOnErrorContainer,
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerLowest: darkSurfaceContainerLowest,
      surfaceContainerLow: darkSurfaceContainerLow,
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceContainerHigh,
      surfaceContainerHighest: darkSurfaceContainerHighest,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      inverseSurface: darkInverseSurface,
      onInverseSurface: darkInverseOnSurface,
      inversePrimary: darkInversePrimary,
      surfaceTint: darkPrimary,
      // ignore: deprecated_member_use
      surfaceVariant: darkSurfaceContainerHighest,
      scrim: Color(0xCC000000),
      shadow: Color(0xFF000000),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: family,
    );

    final controlPadding = largeControls
        ? const EdgeInsets.symmetric(horizontal: 30, vertical: 18)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 11);
    final inputPadding = largeControls
        ? const EdgeInsets.symmetric(horizontal: 18, vertical: 18)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    final density = extraSpacing
        ? const VisualDensity(horizontal: 1, vertical: 1)
        : VisualDensity.standard;

    final theme = base.copyWith(
      visualDensity: density,
      textTheme: _persianTextTheme(base.textTheme, darkOnSurface),
      primaryTextTheme: _persianTextTheme(base.primaryTextTheme, darkOnPrimary),
      iconTheme: const IconThemeData(color: darkOnSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        surfaceTintColor: darkPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          padding: controlPadding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          padding: controlPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: controlPadding,
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkOutline, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontFamily: family,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLowest,
        contentPadding: inputPadding,
        labelStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: darkOnSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: darkOnSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIconColor: darkOnSurfaceVariant,
        suffixIconColor: darkOnSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkError, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkOutlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: darkOutlineVariant,
        thickness: 0.6,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: darkOnSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkInverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: darkInverseOnSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: darkPrimary,
        unselectedLabelColor: darkOnSurfaceVariant,
        indicatorColor: darkPrimary,
        labelStyle: const TextStyle(
          fontFamily: family,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceContainer,
        selectedColor: darkPrimaryContainer,
        labelStyle: TextStyle(
          fontFamily: family,
          fontSize: 13,
          color: darkOnSurface,
        ),
        padding: extraSpacing
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkSecondaryContainer,
        foregroundColor: darkOnSecondaryContainer,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkOnPrimary;
          return darkOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkSurfaceContainerHighest;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: darkPrimary,
        inactiveTrackColor: darkSurfaceContainerHighest,
        thumbColor: darkPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
        linearTrackColor: darkSurfaceContainer,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: darkOnSurfaceVariant,
        textColor: darkOnSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: TextStyle(
          fontFamily: family,
          fontSize: 14,
          color: darkOnSurface,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkInverseSurface,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: TextStyle(
          fontFamily: family,
          fontSize: 12,
          color: darkInverseOnSurface,
        ),
      ),
    );
    return highContrast ? _highContrast(theme) : theme;
  }

  // -------- مقیاس تایپوگرافی (DESIGN.md) --------
  static ThemeData _highContrast(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme.copyWith(
      primary: dark ? const Color(0xFFD7E3FF) : const Color(0xFF002F69),
      onPrimary: dark ? const Color(0xFF001B3F) : Colors.white,
      secondary: dark ? const Color(0xFFFFDAD6) : const Color(0xFF8C0009),
      tertiary: dark ? const Color(0xFFA2EFFD) : const Color(0xFF00363D),
      surface: dark ? Colors.black : Colors.white,
      onSurface: dark ? Colors.white : Colors.black,
      onSurfaceVariant: dark
          ? const Color(0xFFE6E6E6)
          : const Color(0xFF101010),
      outline: dark ? Colors.white : Colors.black,
      outlineVariant: dark ? const Color(0xFFBDBDBD) : const Color(0xFF303030),
    );
    final borderColor = scheme.outlineVariant;
    return theme.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      cardTheme: theme.cardTheme.copyWith(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2.4),
        ),
      ),
    );
  }

  static TextTheme _persianTextTheme(TextTheme base, Color color) {
    const family = AppConstants.fontFamily;
    return base.copyWith(
      displayLarge: TextStyle(
        fontFamily: family,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: family,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.35,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
}
