import 'package:flutter/material.dart';

/// Helper های رنگ برای کارت‌های گرادینتی روی پس‌زمینه‌های روشن/تیره.
///
/// دو حالت اصلی:
/// 1. گرادینت ثابت تیره (مثل `successColor = Color(0xFF2E7D32)`) → متن سفید
///    در هر دو mode کار می‌کند.
/// 2. گرادینت وابسته به scheme (primary/tertiary/secondary) → در light mode
///    گرادینت تیره و متن سفید، در dark mode گرادینت روشن و متن **تیره**.
///
/// overlay سفید روی المان‌ها (مثل آیکن‌های مربعی پشت‌بند) نیز در dark mode
/// روشن‌تر می‌شود تا با گرادینت روشن تضاد بهتری داشته باشند.
extension GradientOverlayColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // -------- Overlay سفید روی المان‌های روی گرادینت --------

  /// Overlay قوی: برای آیکن‌های بزرگ در کنار عنوان (مثل بنر اصلی).
  Color get onGradientOverlayStrong => _isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.32)
      : Colors.white.withValues(alpha: 0.20);

  /// Overlay متوسط: برای آیکن‌های کوچک (مثل بنر راهنما).
  Color get onGradientOverlayMedium => _isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.28)
      : Colors.white.withValues(alpha: 0.18);

  /// Overlay ضعیف: برای دایره‌های تزئینی.
  Color get onGradientOverlaySoft => _isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.18)
      : Colors.white.withValues(alpha: 0.10);

  // -------- رنگ متن اصلی روی گرادینت --------

  /// رنگ متن اصلی. در dark mode به دلیل روشن بودن گرادینت، تیره می‌شود.
  Color get onGradientText => _isDark
      ? const Color(0xFF0D1117) // متن تیره روی گرادینت روشن
      : Colors.white;

  /// رنگ متن ثانویه (توضیحات).
  Color get onGradientTextMuted => _isDark
      ? const Color(0xFF1A1F2E).withValues(alpha: 0.85)
      : Colors.white.withValues(alpha: 0.88);

  /// رنگ آیکن کم‌رنگ (chevron، آیکن ثانویه).
  Color get onGradientTextFaint => _isDark
      ? const Color(0xFF1A1F2E).withValues(alpha: 0.7)
      : Colors.white.withValues(alpha: 0.6);
}

/// رنگ‌های المان‌های دایره‌ای/مربعی کوچک روی گرادینت.
extension GradientDecoColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// دایره‌ی تزئینی بزرگ پشت بنر.
  Color get gradientDecoLarge => _isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.22)
      : Colors.white.withValues(alpha: 0.12);

  /// دایره‌ی تزئینی کوچک.
  Color get gradientDecoSmall => _isDark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.16)
      : Colors.white.withValues(alpha: 0.08);
}
