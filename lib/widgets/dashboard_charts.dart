import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';
import '../utils/persian_date_helper.dart';
import '../utils/persian_number_formatter.dart';

/// نمودار میله‌ای روند ماهانه پرداخت‌ها
class MonthlyBarChart extends StatefulWidget {
  final List<MonthlyPoint> points;
  final Color primary;
  final Color secondary;
  final bool isDark;

  const MonthlyBarChart({
    super.key,
    required this.points,
    required this.primary,
    required this.secondary,
    required this.isDark,
  });

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant MonthlyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.points.isEmpty) {
      return _emptyState(scheme, 'داده‌ای برای نمایش وجود ندارد');
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _BarChartPainter(
            progress: _animation.value,
            points: widget.points,
            primary: widget.primary,
            secondary: widget.secondary,
            isDark: widget.isDark,
            labelColor: scheme.onSurfaceVariant,
            gridColor: scheme.outlineVariant.withValues(alpha: 0.4),
            tooltipColor: scheme.inverseSurface,
            tooltipTextColor: scheme.onInverseSurface,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _emptyState(ColorScheme scheme, String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          color: scheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final double progress;
  final List<MonthlyPoint> points;
  final Color primary;
  final Color secondary;
  final bool isDark;
  final Color labelColor;
  final Color gridColor;
  final Color tooltipColor;
  final Color tooltipTextColor;

  _BarChartPainter({
    required this.progress,
    required this.points,
    required this.primary,
    required this.secondary,
    required this.isDark,
    required this.labelColor,
    required this.gridColor,
    required this.tooltipColor,
    required this.tooltipTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const topPad = 28.0;
    const bottomPad = 36.0;
    const leftPad = 56.0;
    const rightPad = 12.0;

    final chartH = size.height - topPad - bottomPad;
    final chartW = size.width - leftPad - rightPad;

    final maxValue = points
        .map((p) => p.total)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxScaled = maxValue == 0 ? 1.0 : maxValue * 1.15;

    // خطوط افقی راهنما
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      color: labelColor,
      fontSize: 10,
    );
    for (var i = 0; i <= 4; i++) {
      final t = i / 4;
      final y = topPad + chartH * (1 - t);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );
      final value = maxScaled * t;
      final text = PersianNumberFormatter.formatNumber(value.round());
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // محور X (خط پایه)
    canvas.drawLine(
      Offset(leftPad, topPad + chartH),
      Offset(leftPad + chartW, topPad + chartH),
      gridPaint..strokeWidth = 1.2,
    );

    // میله‌ها
    final n = points.length;
    final barGroupW = chartW / n;
    final barW = math.min(barGroupW * 0.55, 36.0);

    for (var i = 0; i < n; i++) {
      final p = points[i];
      final ratio = (p.total / maxScaled).clamp(0.0, 1.0);
      final animatedRatio = ratio * progress;
      final h = chartH * animatedRatio;
      final cx = leftPad + barGroupW * i + barGroupW / 2;
      final left = cx - barW / 2;
      final top = topPad + chartH - h;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, left + barW, topPad + chartH),
        const Radius.circular(8),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      // Highlight درخشان روی میله
      if (animatedRatio > 0.05) {
        final highlight = Paint()
          ..color = Colors.white.withValues(alpha: isDark ? 0.18 : 0.35);
        final hlRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(left + 2, top + 2, left + 6, topPad + chartH - 4),
          const Radius.circular(3),
        );
        canvas.drawRRect(hlRect, highlight);
      }

      // لیبل ماه
      final monthLabel = PersianDateHelper.monthName(p.month);
      final mlTp = TextPainter(
        text: TextSpan(
          text: PersianNumberFormatter.toPersian(monthLabel),
          style: textStyle.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      mlTp.paint(canvas, Offset(cx - mlTp.width / 2, topPad + chartH + 8));

      // مقدار بالای میله (فقط وقتی ratio کامل است)
      if (progress > 0.85) {
        final valueText = PersianNumberFormatter.formatNumber(
          (p.total / 1000000).round(),
        );
        final valueTp = TextPainter(
          text: TextSpan(
            text: valueText,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout(maxWidth: barGroupW - 4);
        valueTp.paint(
          canvas,
          Offset(cx - valueTp.width / 2, top - valueTp.height - 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.primary != primary ||
      old.secondary != secondary;
}

/// نمودار دایره‌ای (Donut) برای ترکیب کسورات
class DeductionsDonut extends StatefulWidget {
  final double net;
  final double tax;
  final double insuranceEmployee;
  final double insuranceEmployer;
  final double loanInstallment;
  final bool isDark;

  const DeductionsDonut({
    super.key,
    required this.net,
    required this.tax,
    required this.insuranceEmployee,
    required this.insuranceEmployer,
    required this.loanInstallment,
    required this.isDark,
  });

  @override
  State<DeductionsDonut> createState() => _DeductionsDonutState();
}

class _DeductionsDonutState extends State<DeductionsDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1, 0.3, 1),
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = <_DonutSegment>[
      _DonutSegment(
        label: 'خالص پرداختی',
        value: widget.net,
        color: const Color(0xFF004394),
        darkColor: const Color(0xFFADC6FF),
      ),
      _DonutSegment(
        label: 'مالیات',
        value: widget.tax,
        color: const Color(0xFFB61718),
        darkColor: const Color(0xFFFFB4AB),
      ),
      _DonutSegment(
        label: 'بیمه کارمند',
        value: widget.insuranceEmployee,
        color: const Color(0xFFEF6C00),
        darkColor: const Color(0xFFFFB778),
      ),
      _DonutSegment(
        label: 'بیمه کارفرما',
        value: widget.insuranceEmployer,
        color: const Color(0xFF2E7D32),
        darkColor: const Color(0xFF7BD389),
      ),
      _DonutSegment(
        label: 'اقساط وام',
        value: widget.loanInstallment,
        color: const Color(0xFF7B1FA2),
        darkColor: const Color(0xFFD0A5F0),
      ),
    ]..removeWhere((s) => s.value <= 0);

    final total = segments.fold<double>(0, (a, b) => a + b.value);

    if (total <= 0) {
      return Center(
        child: Text(
          'داده‌ای برای نمایش وجود ندارد',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: scheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          flex: 5,
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _DonutPainter(
                    progress: _animation.value,
                    segments: segments,
                    isDark: widget.isDark,
                    trackColor: scheme.surfaceContainerHigh,
                    centerColor: scheme.onSurface,
                    centerSubColor: scheme.onSurfaceVariant,
                    total: total,
                    totalLabel: 'مجموع',
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((s) {
              final pct = (s.value / total * 100);
              final color = widget.isDark ? s.darkColor : s.color;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${PersianNumberFormatter.toPersian(pct.toStringAsFixed(1))}٪',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  final Color darkColor;

  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
    required this.darkColor,
  });
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final List<_DonutSegment> segments;
  final bool isDark;
  final Color trackColor;
  final Color centerColor;
  final Color centerSubColor;
  final double total;
  final String totalLabel;

  _DonutPainter({
    required this.progress,
    required this.segments,
    required this.isDark,
    required this.trackColor,
    required this.centerColor,
    required this.centerSubColor,
    required this.total,
    required this.totalLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final innerR = radius * 0.62;

    // Track پس‌زمینه
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius - innerR;
    canvas.drawCircle(center, (radius + innerR) / 2, trackPaint);

    // سگمنت‌ها
    var startAngle = -math.pi / 2; // از بالا شروع
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * progress;
      final color = isDark ? seg.darkColor : seg.color;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerR
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerR) / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += (seg.value / total) * 2 * math.pi;
    }

    // دایره مرکزی
    final centerBg = Paint()..color = trackColor.withValues(alpha: 0);
    canvas.drawCircle(center, innerR, centerBg);

    // متن مرکز
    if (progress > 0.6) {
      final totalText = PersianNumberFormatter.formatNumber(
        (total / 1000000).round(),
      );
      final centerTextPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: totalLabel,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: centerSubColor,
              ),
            ),
            TextSpan(
              text: '\n$totalText',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: centerColor,
              ),
            ),
            TextSpan(
              text: '\nمیلیون ریال',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 9,
                color: centerSubColor,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout(maxWidth: innerR * 1.6);
      centerTextPainter.paint(
        canvas,
        Offset(
          center.dx - centerTextPainter.width / 2,
          center.dy - centerTextPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.segments != segments;
}
