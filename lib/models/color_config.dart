import 'package:flutter/material.dart';

/// مدل تنظیمات رنگ برنامه
@immutable
class ColorConfig {
  /// آیا از رنگ اتوماتیک دستگاه استفاده شود
  final bool useDynamicColors;

  /// رنگ پایه (seed color) برای تولید پالت
  final int seedColorValue;

  /// نوع variant رنگی
  final DynamicSchemeVariant variant;

  const ColorConfig({
    this.useDynamicColors = false,
    this.seedColorValue = 0xFF004394, // آبی کبالت پیش‌فرض
    this.variant = DynamicSchemeVariant.tonalSpot,
  });

  /// رنگ پایه به صورت Color
  Color get seedColor => Color(seedColorValue);

  ColorConfig copyWith({
    bool? useDynamicColors,
    int? seedColorValue,
    DynamicSchemeVariant? variant,
  }) => ColorConfig(
    useDynamicColors: useDynamicColors ?? this.useDynamicColors,
    seedColorValue: seedColorValue ?? this.seedColorValue,
    variant: variant ?? this.variant,
  );

  Map<String, dynamic> toJson() => {
    'useDynamicColors': useDynamicColors,
    'seedColorValue': seedColorValue,
    'variant': variant.name,
  };

  factory ColorConfig.fromJson(Map<String, dynamic> json) => ColorConfig(
    useDynamicColors: json['useDynamicColors'] as bool? ?? false,
    seedColorValue: json['seedColorValue'] as int? ?? 0xFF004394,
    variant: DynamicSchemeVariant.values.firstWhere(
      (e) => e.name == json['variant'],
      orElse: () => DynamicSchemeVariant.tonalSpot,
    ),
  );
}

/// لیست رنگ‌های پیش‌فرض Material 3
class Material3Colors {
  static const List<Map<String, dynamic>> predefined = [
    {'name': 'آبی', 'color': 0xFF004394},
    {'name': 'قرمز', 'color': 0xFFB61718},
    {'name': 'سبز', 'color': 0xFF1B5E20},
    {'name': 'بنفش', 'color': 0xFF6A1B9A},
    {'name': 'نارنجی', 'color': 0xFFE65100},
    {'name': 'صورتی', 'color': 0xFFAD1457},
    {'name': 'زرد', 'color': 0xFFF9A825},
    {'name': 'فیروزه‌ای', 'color': 0xFF00695C},
    {'name': 'آبی تیره', 'color': 0xFF0D47A1},
    {'name': 'یاقوتی', 'color': 0xFF880E4F},
    {'name': 'آبی آسمانی', 'color': 0xFF0277BD},
    {'name': 'سبز تیره', 'color': 0xFF2E7D32},
    {'name': 'بنفش تیره', 'color': 0xFF4A148C},
    {'name': 'خاکستری', 'color': 0xFF616161},
  ];
}

/// لیست variant های رنگی با نام فارسی
class VariantInfo {
  final DynamicSchemeVariant variant;
  final String persianName;
  final String description;

  const VariantInfo({
    required this.variant,
    required this.persianName,
    required this.description,
  });

  static const List<VariantInfo> all = [
    VariantInfo(
      variant: DynamicSchemeVariant.tonalSpot,
      persianName: 'نقطه لحنی',
      description: 'پیش‌فرض - تعادل بین رنگ و خنثی',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.fidelity,
      persianName: 'دقت',
      description: 'تطابق دقیق با رنگ پایه',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.vibrant,
      persianName: 'زنده',
      description: 'رنگ‌های زنده‌تر و پررنگ‌تر',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.expressive,
      persianName: 'بیانگر',
      description: 'رنگ‌های ملایم‌تر و متنوع',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.monochrome,
      persianName: 'تک‌رنگ',
      description: 'سایه‌های خاکستری',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.neutral,
      persianName: 'خنثی',
      description: 'نزدیک به خاکستری با کمی رنگ',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.content,
      persianName: 'محتوا',
      description: 'تطابق با رنگ پایه و کنتراست',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.rainbow,
      persianName: 'رنگین‌کمان',
      description: 'بازیگوش و متنوع',
    ),
    VariantInfo(
      variant: DynamicSchemeVariant.fruitSalad,
      persianName: 'سالاد میوه',
      description: 'بازیگوش و رنگارنگ',
    ),
  ];
}
