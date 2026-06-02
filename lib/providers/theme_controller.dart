import 'package:flutter/material.dart';

import '../services/appearance_service.dart';
import '../theme/app_theme.dart';

/// Provider مرکزی برای مدیریت تم و دسترسی‌پذیری
class ThemeController extends ChangeNotifier {
  final AppearanceService _service = AppearanceService();

  ThemeMode _themeMode = ThemeMode.system;
  AccessibilitySettings _accessibility = const AccessibilitySettings();
  bool _compactLayout = false;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  AccessibilitySettings get accessibility => _accessibility;
  bool get compactLayout => _compactLayout;
  bool get isLoading => _isLoading;

  /// تم روشن
  ThemeData get lightTheme => AppTheme.lightTheme(
    highContrast: highContrast,
    largeControls: largeControls,
    extraSpacing: extraSpacing,
  );

  /// تم تاریک
  ThemeData get darkTheme => AppTheme.darkTheme(
    highContrast: highContrast,
    largeControls: largeControls,
    extraSpacing: extraSpacing,
  );

  /// آیا کنتراست بالا فعال است
  bool get highContrast => _accessibility.highContrast;

  /// آیا انیمیشن‌ها کاهش یافته‌اند
  bool get reduceMotion => _accessibility.reduceMotion;

  /// آیا کنترل‌ها بزرگ هستند
  bool get largeControls => _accessibility.largeControls;

  /// آیا فاصله اضافی بین المان‌ها نیاز است
  bool get extraSpacing => _accessibility.extraSpacing;

  /// ضریب مقیاس فونت
  double get textScale => _accessibility.textScale;

  Future<void> initialize() async {
    _themeMode = await _service.loadThemeMode();
    _accessibility = await _service.loadAccessibility();
    _compactLayout = await _service.loadCompactLayout();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _service.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setAccessibility(AccessibilitySettings settings) async {
    _accessibility = settings;
    await _service.saveAccessibility(settings);
    notifyListeners();
  }

  Future<void> updateAccessibility({
    double? textScale,
    bool? highContrast,
    bool? reduceMotion,
    bool? screenReaderHints,
    bool? largeControls,
    bool? extraSpacing,
    bool? emojiLabels,
  }) async {
    final updated = _accessibility.copyWith(
      textScale: textScale,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
      screenReaderHints: screenReaderHints,
      largeControls: largeControls,
      extraSpacing: extraSpacing,
      emojiLabels: emojiLabels,
    );
    await setAccessibility(updated);
  }

  Future<void> setCompactLayout(bool v) async {
    _compactLayout = v;
    await _service.saveCompactLayout(v);
    notifyListeners();
  }
}
