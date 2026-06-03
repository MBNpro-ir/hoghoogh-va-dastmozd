import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/color_config.dart';

/// مدل تنظیمات دسترسی‌پذیری (Accessibility)
@immutable
class AccessibilitySettings {
  /// ضریب مقیاس فونت (0.85 تا 1.5)
  final double textScale;

  /// حالت کنتراست بالا
  final bool highContrast;

  /// کاهش انیمیشن‌ها (بر اساس تنظیمات سیستم به صورت پیش‌فرض)
  final bool reduceMotion;

  /// نمایش راهنمای صوتی
  final bool screenReaderHints;

  /// بزرگنمایی دکمه‌ها
  final bool largeControls;

  /// فاصله بیشتر بین المان‌ها
  final bool extraSpacing;

  /// نمایش متن جایگزین برای ایموجی‌ها
  final bool emojiLabels;

  const AccessibilitySettings({
    this.textScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.screenReaderHints = true,
    this.largeControls = false,
    this.extraSpacing = false,
    this.emojiLabels = true,
  });

  AccessibilitySettings copyWith({
    double? textScale,
    bool? highContrast,
    bool? reduceMotion,
    bool? screenReaderHints,
    bool? largeControls,
    bool? extraSpacing,
    bool? emojiLabels,
  }) => AccessibilitySettings(
    textScale: textScale ?? this.textScale,
    highContrast: highContrast ?? this.highContrast,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    screenReaderHints: screenReaderHints ?? this.screenReaderHints,
    largeControls: largeControls ?? this.largeControls,
    extraSpacing: extraSpacing ?? this.extraSpacing,
    emojiLabels: emojiLabels ?? this.emojiLabels,
  );

  Map<String, dynamic> toJson() => {
    'textScale': textScale,
    'highContrast': highContrast,
    'reduceMotion': reduceMotion,
    'screenReaderHints': screenReaderHints,
    'largeControls': largeControls,
    'extraSpacing': extraSpacing,
    'emojiLabels': emojiLabels,
  };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) =>
      AccessibilitySettings(
        textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
        highContrast: json['highContrast'] as bool? ?? false,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        screenReaderHints: json['screenReaderHints'] as bool? ?? true,
        largeControls: json['largeControls'] as bool? ?? false,
        extraSpacing: json['extraSpacing'] as bool? ?? false,
        emojiLabels: json['emojiLabels'] as bool? ?? true,
      );
}

/// سرویس مدیریت تنظیمات ظاهری، تم و دسترسی‌پذیری
class AppearanceService {
  static const _kThemeMode = 'app.themeMode';
  static const _kAccessibility = 'app.accessibility';
  static const _kCompactLayout = 'app.compactLayout';
  static const _kFirstRun = 'app.firstRun';
  static const _kColorConfig = 'app.colorConfig';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kThemeMode);
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<AccessibilitySettings> loadAccessibility() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccessibility);
    if (raw == null) return const AccessibilitySettings();
    try {
      final map = Map<String, dynamic>.from(
        (raw.split(';').fold<Map<String, String>>({}, (m, p) {
          final idx = p.indexOf('=');
          if (idx > 0) m[p.substring(0, idx)] = p.substring(idx + 1);
          return m;
        })),
      );
      return AccessibilitySettings(
        textScale: double.tryParse(map['ts'] ?? '1.0') ?? 1.0,
        highContrast: (map['hc'] ?? '0') == '1',
        reduceMotion: (map['rm'] ?? '0') == '1',
        screenReaderHints: (map['sr'] ?? '1') == '1',
        largeControls: (map['lc'] ?? '0') == '1',
        extraSpacing: (map['es'] ?? '0') == '1',
        emojiLabels: (map['el'] ?? '1') == '1',
      );
    } catch (_) {
      return const AccessibilitySettings();
    }
  }

  Future<void> saveAccessibility(AccessibilitySettings s) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        'ts=${s.textScale};hc=${s.highContrast ? 1 : 0};'
        'rm=${s.reduceMotion ? 1 : 0};sr=${s.screenReaderHints ? 1 : 0};'
        'lc=${s.largeControls ? 1 : 0};es=${s.extraSpacing ? 1 : 0};'
        'el=${s.emojiLabels ? 1 : 0}';
    await prefs.setString(_kAccessibility, raw);
  }

  Future<bool> loadCompactLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCompactLayout) ?? false;
  }

  Future<void> saveCompactLayout(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompactLayout, v);
  }

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_kFirstRun) ?? true;
    if (v) await prefs.setBool(_kFirstRun, false);
    return v;
  }

  Future<ColorConfig> loadColorConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kColorConfig);
    if (raw == null) return const ColorConfig();
    try {
      final map = <String, dynamic>{};
      for (final part in raw.split(';')) {
        final idx = part.indexOf('=');
        if (idx > 0) map[part.substring(0, idx)] = part.substring(idx + 1);
      }
      return ColorConfig(
        useDynamicColors: (map['ud'] ?? '0') == '1',
        seedColorValue: int.tryParse(map['sc'] ?? '0') ?? 0xFF004394,
        variant: DynamicSchemeVariant.values.firstWhere(
          (e) => e.name == (map['vr'] ?? 'tonalSpot'),
          orElse: () => DynamicSchemeVariant.tonalSpot,
        ),
      );
    } catch (_) {
      return const ColorConfig();
    }
  }

  Future<void> saveColorConfig(ColorConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        'ud=${config.useDynamicColors ? 1 : 0};'
        'sc=${config.seedColorValue};'
        'vr=${config.variant.name}';
    await prefs.setString(_kColorConfig, raw);
  }
}
