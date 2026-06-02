import 'package:flutter/material.dart';

/// ابزارهای ریسپانسیو (Material 3 Breakpoints)
class Responsive {
  final double _width;
  final double _height;
  final BuildContext _context;

  const Responsive._raw(this._width, this._height, this._context);

  factory Responsive.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Responsive._raw(mq.size.width, mq.size.height, context);
  }

  double get width => _width;
  double get height => _height;
  BuildContext get context => _context;

  // -------- Breakpoints (Material 3 + DESIGN.md) --------
  static const double compact = 600; // موبایل / پنجره کوچک
  static const double medium = 840; // تبلت کوچک
  static const double expanded = 1200; // دسکتاپ / تبلت بزرگ
  static const double large = 1600; // مانیتور بزرگ
  static const double sidebarBreakpoint = 720; // نمایش سایدبار

  // -------- Device Type --------
  bool get isCompact => _width < compact;
  bool get isMedium => _width >= compact && _width < expanded;
  bool get isExpanded => _width >= expanded;
  bool get isLarge => _width >= large;
  bool get isMobileSize => _width < compact;
  bool get isTabletSize => _width >= compact && _width < expanded;
  bool get isDesktopSize => _width >= expanded;
  bool get showsSidebar => _width >= sidebarBreakpoint;

  // -------- Padding مقیاس‌پذیر --------
  double get pagePadding {
    if (isCompact) return 16;
    if (isMedium) return 24;
    if (isExpanded) return 32;
    return 40;
  }

  double get sectionGap {
    if (isCompact) return 16;
    if (isMedium) return 20;
    return 24;
  }

  double get cardGap {
    if (isCompact) return 12;
    if (isMedium) return 16;
    return 20;
  }

  // -------- تعداد ستون‌های Bento Grid --------
  int get bentoColumns {
    if (isCompact) return 1;
    if (isMedium) return 2;
    if (_width < 1500) return 3;
    return 4;
  }

  /// عرض سایدبار
  double get sidebarWidth {
    if (isCompact) return 0;
    if (isMedium) return 240;
    return 280;
  }

  /// محاسبه scale فونت برای موبایل (کمی ریزتر برای خوانایی بیشتر)
  double fontScale(double baseScale, {bool isAndroid = false}) {
    if (isMobileSize) {
      if (isAndroid) {
        // برای اندروید: 0.92 برای متن‌ها
        return baseScale * 0.92;
      }
      // iOS/موبایل دیگر: 0.95
      return baseScale * 0.95;
    }
    return baseScale;
  }

  /// آیا صفحه خیلی کوچک است (گوشی‌های قدیمی با عرض کم)
  bool get isVerySmall => _width < 360;
}

/// ویجت کمکی برای استفاده از Responsive در متد build
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive._raw(
          constraints.maxWidth,
          constraints.maxHeight,
          context,
        );
        return builder(context, r);
      },
    );
  }
}
