import 'package:flutter/material.dart';

import '../models/color_config.dart';
import '../services/appearance_service.dart';
import '../theme/app_theme.dart';

/// Provider مرکزی برای مدیریت تم و دسترسی‌پذیری
class ThemeController extends ChangeNotifier {
  final AppearanceService _service = AppearanceService();

  ThemeMode _themeMode = ThemeMode.system;
  AccessibilitySettings _accessibility = const AccessibilitySettings();
  ColorConfig _colorConfig = const ColorConfig();
  bool _compactLayout = false;
  bool _isLoading = true;
  bool _disposed = false;

  /// ColorScheme از dynamic_color (در صورت پشتیبانی دستگاه)
  ColorScheme? _dynamicLightScheme;
  ColorScheme? _dynamicDarkScheme;
  bool _firstRunAutoEnabled = false;

  /// کش تم‌ها برای جلوگیری از rebuild غیرضروری
  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;
  bool _themeDirty = true;

  ThemeMode get themeMode => _themeMode;
  AccessibilitySettings get accessibility => _accessibility;
  ColorConfig get colorConfig => _colorConfig;
  bool get compactLayout => _compactLayout;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// آیا دستگاه از dynamic color پشتیبانی می‌کند
  bool get supportsDynamicColor => _dynamicLightScheme != null;

  /// اطمینان از ساخت هر دو تم با هم (جلوگیری از باگ کش)
  void _ensureThemesBuilt() {
    if (!_themeDirty && _cachedLightTheme != null && _cachedDarkTheme != null) {
      return;
    }

    _cachedLightTheme = AppTheme.lightTheme(
      highContrast: highContrast,
      largeControls: largeControls,
      extraSpacing: extraSpacing,
      colorScheme: _buildLightColorScheme(),
    );
    _cachedDarkTheme = AppTheme.darkTheme(
      highContrast: highContrast,
      largeControls: largeControls,
      extraSpacing: extraSpacing,
      colorScheme: _buildDarkColorScheme(),
    );
    _themeDirty = false;
  }

  /// تم روشن (با کش)
  ThemeData get lightTheme {
    _ensureThemesBuilt();
    return _cachedLightTheme!;
  }

  /// تم تاریک (با کش)
  ThemeData get darkTheme {
    _ensureThemesBuilt();
    return _cachedDarkTheme!;
  }

  /// ساخت ColorScheme برای تم روشن
  ColorScheme? _buildLightColorScheme() {
    if (_colorConfig.useDynamicColors && _dynamicLightScheme != null) {
      return _dynamicLightScheme;
    }
    if (!_colorConfig.useDynamicColors) {
      return ColorScheme.fromSeed(
        seedColor: _colorConfig.seedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: _colorConfig.variant,
      );
    }
    return null;
  }

  /// ساخت ColorScheme برای تم تاریک
  ColorScheme? _buildDarkColorScheme() {
    if (_colorConfig.useDynamicColors && _dynamicDarkScheme != null) {
      return _dynamicDarkScheme;
    }
    if (!_colorConfig.useDynamicColors) {
      return ColorScheme.fromSeed(
        seedColor: _colorConfig.seedColor,
        brightness: Brightness.dark,
        dynamicSchemeVariant: _colorConfig.variant,
      );
    }
    return null;
  }

  bool get highContrast => _accessibility.highContrast;
  bool get reduceMotion => _accessibility.reduceMotion;
  bool get largeControls => _accessibility.largeControls;
  bool get extraSpacing => _accessibility.extraSpacing;
  double get textScale => _accessibility.textScale;
  double get uiScale => _accessibility.uiScale;

  Future<void> initialize() async {
    _themeMode = await _service.loadThemeMode();
    _accessibility = await _service.loadAccessibility();
    _colorConfig = await _service.loadColorConfig();
    _compactLayout = await _service.loadCompactLayout();
    _isLoading = false;
    _themeDirty = true;
    notifyListeners();
  }

  /// تنظیم dynamic color schemes از DynamicColorBuilder
  /// فقط در صورت تغییر واقعی schemes بازسازی ایجاد می‌کند
  void setDynamicSchemes(ColorScheme? light, ColorScheme? dark) {
    if (_disposed) return;

    final lightChanged = light != _dynamicLightScheme;
    final darkChanged = dark != _dynamicDarkScheme;

    // ذخیره schemes
    _dynamicLightScheme = light;
    _dynamicDarkScheme = dark;

    // فقط در اولین اجرا، اگر دستگاه پشتیبانی می‌کند و کاربر تنظیمات را تغییر نداده
    if (!_firstRunAutoEnabled && light != null) {
      _firstRunAutoEnabled = true;
      // فقط اگر seed color پیش‌فرض باشد (یعنی کاربر هنوز چیزی تغییر نداده)
      if (_colorConfig.seedColorValue == 0xFF004394 &&
          !_colorConfig.useDynamicColors) {
        _colorConfig = _colorConfig.copyWith(useDynamicColors: true);
        _service.saveColorConfig(_colorConfig);
        _themeDirty = true;
        notifyListeners();
        return;
      }
    }

    // فقط اگر dynamic colors فعال باشد و schemes واقعاً تغییر کرده باشد، بازسازی کن
    if (_colorConfig.useDynamicColors && (lightChanged || darkChanged)) {
      _themeDirty = true;
      notifyListeners();
    }
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
    _themeDirty = true;
    notifyListeners();
  }

  Future<void> updateAccessibility({
    double? textScale,
    double? uiScale,
    bool? highContrast,
    bool? reduceMotion,
    bool? screenReaderHints,
    bool? largeControls,
    bool? extraSpacing,
    bool? emojiLabels,
  }) async {
    final updated = _accessibility.copyWith(
      textScale: textScale,
      uiScale: uiScale,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
      screenReaderHints: screenReaderHints,
      largeControls: largeControls,
      extraSpacing: extraSpacing,
      emojiLabels: emojiLabels,
    );
    await setAccessibility(updated);
  }

  Future<void> setColorConfig(ColorConfig config) async {
    _colorConfig = config;
    await _service.saveColorConfig(config);
    _themeDirty = true;
    notifyListeners();
  }

  Future<void> updateColorConfig({
    bool? useDynamicColors,
    int? seedColorValue,
    DynamicSchemeVariant? variant,
  }) async {
    final updated = _colorConfig.copyWith(
      useDynamicColors: useDynamicColors,
      seedColorValue: seedColorValue,
      variant: variant,
    );
    await setColorConfig(updated);
  }

  Future<void> setCompactLayout(bool v) async {
    _compactLayout = v;
    await _service.saveCompactLayout(v);
    notifyListeners();
  }
}
