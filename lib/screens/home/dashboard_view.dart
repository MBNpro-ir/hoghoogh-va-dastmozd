import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../models/employee.dart';
import '../../models/salary_record.dart';
import '../../services/dashboard_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/persian_date_helper.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_sidebar.dart' show AppCurves;
import '../../widgets/count_up_text.dart';
import '../../widgets/dashboard_charts.dart';
import '../../widgets/floating_nav_safe_area.dart';

/// داشبورد اصلی برنامه - نسخه جدید
class DashboardView extends StatefulWidget {
  final VoidCallback onNavigateToEmployees;
  final VoidCallback onNavigateToSalaryCalc;
  final VoidCallback onNavigateToSalaryRecords;
  final VoidCallback onNavigateToLoans;
  final VoidCallback onNavigateToSettings;
  final DashboardService? service;

  const DashboardView({
    super.key,
    required this.onNavigateToEmployees,
    required this.onNavigateToSalaryCalc,
    required this.onNavigateToSalaryRecords,
    required this.onNavigateToLoans,
    required this.onNavigateToSettings,
    this.service,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardService _service;
  DashboardSnapshot? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DashboardService();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.loadSnapshot(
      currentYear: PersianDateHelper.currentYear,
    );
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await SyncService().syncNow();
            await _load();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              r.pagePadding,
              r.pagePadding,
              FloatingNavSafeArea.scrollBottomInset(context, minimum: 96),
            ),
            child: _loading
                ? _LoadingSkeleton(r: r)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeInUp(
                        duration: AppDurations.medium,
                        child: _WelcomeHeader(data: _data!, isDark: isDark),
                      ),
                      SizedBox(height: r.sectionGap),
                      FadeInUp(
                        delay: const Duration(milliseconds: 60),
                        duration: AppDurations.medium,
                        child: _KpiGrid(data: _data!, r: r, isDark: isDark),
                      ),
                      SizedBox(height: r.sectionGap),
                      FadeInUp(
                        delay: const Duration(milliseconds: 120),
                        duration: AppDurations.medium,
                        child: _ChartsSection(
                          data: _data!,
                          r: r,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: r.sectionGap),
                      FadeInUp(
                        delay: const Duration(milliseconds: 180),
                        duration: AppDurations.medium,
                        child: _BottomSection(
                          data: _data!,
                          r: r,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: r.sectionGap),
                      FadeInUp(
                        delay: const Duration(milliseconds: 240),
                        duration: AppDurations.medium,
                        child: _QuickActionsGrid(
                          r: r,
                          isDark: isDark,
                          onEmployees: widget.onNavigateToEmployees,
                          onSalaryCalc: widget.onNavigateToSalaryCalc,
                          onRecords: widget.onNavigateToSalaryRecords,
                          onLoans: widget.onNavigateToLoans,
                          onSettings: widget.onNavigateToSettings,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _dashboardCardDecoration(
  BuildContext context, {
  Color? borderColor,
  Color? shadowColor,
  bool elevated = false,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final effectiveShadow = shadowColor ?? scheme.shadow;
  return BoxDecoration(
    color: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
    border: Border.all(
      color:
          borderColor ??
          scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.50),
    ),
    boxShadow: isDark
        ? const []
        : elevated
        ? [
            BoxShadow(
              color: effectiveShadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
        : AppTheme.elevation1(effectiveShadow),
  );
}

/// اسکلت لودینگ
class _LoadingSkeleton extends StatelessWidget {
  final Responsive r;
  const _LoadingSkeleton({required this.r});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        SizedBox(height: r.sectionGap),
        GridView.count(
          crossAxisCount: r.bentoColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: r.cardGap,
          mainAxisSpacing: r.cardGap,
          childAspectRatio: 2.2,
          children: List.generate(6, (_) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
            );
          }),
        ),
        SizedBox(height: r.sectionGap),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ],
    );
  }
}

/// هدر خوش‌آمدگویی با بنر اطلاعات
class _WelcomeHeader extends StatelessWidget {
  final DashboardSnapshot data;
  final bool isDark;
  const _WelcomeHeader({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final now = Jalali.fromDateTime(data.now);
    final weekDay = PersianDateHelper.weekDays[now.weekDay - 1];
    final dateText =
        '$weekDay '
        '${PersianNumberFormatter.toPersian(now.day.toString())} '
        '${PersianDateHelper.monthName(now.month)} '
        '${PersianNumberFormatter.toPersian(now.year.toString())}';

    final headerForeground = isDark ? scheme.onSurface : scheme.onPrimary;
    final headerPillBackground = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  scheme.surfaceContainerHigh,
                  scheme.surfaceContainer,
                  scheme.primary.withValues(alpha: 0.28),
                ]
              : [
                  scheme.primary,
                  scheme.primaryContainer.withValues(alpha: 0.85),
                ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
        boxShadow: AppTheme.elevation1(scheme.shadow),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: _decorCircle(
              size: 180,
              color: (isDark ? scheme.primary : Colors.white).withValues(
                alpha: isDark ? 0.10 : 0.12,
              ),
              blur: 60,
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: _decorCircle(
              size: 160,
              color: (isDark ? scheme.tertiary : Colors.white).withValues(
                alpha: 0.08,
              ),
              blur: 50,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.isMobileSize ? 18 : 28),
            child: r.isMobileSize
                ? _buildMobileContent(
                    context,
                    scheme,
                    dateText,
                    headerForeground,
                    headerPillBackground,
                  )
                : _buildDesktopContent(
                    context,
                    scheme,
                    dateText,
                    headerForeground,
                    headerPillBackground,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    ColorScheme scheme,
    String dateText,
    Color foreground,
    Color pillBackground,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pillBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: foreground,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سلام، مدیر مالی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.settings.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: foreground.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          textDirection: TextDirection.rtl,
          spacing: 8,
          runSpacing: 8,
          children: [
            _metaPill(
              icon: Icons.event_rounded,
              label: dateText,
              bgColor: pillBackground,
              fgColor: foreground,
            ),
            _metaPill(
              icon: Icons.workspace_premium_rounded,
              label:
                  'سال مالی ${PersianNumberFormatter.toPersian(data.settings.year.toString())}',
              bgColor: pillBackground,
              fgColor: foreground,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    ColorScheme scheme,
    String dateText,
    Color foreground,
    Color pillBackground,
  ) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: pillBackground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: foreground,
            size: 38,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سلام، مدیر مالی',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.settings.companyName,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: foreground.withValues(alpha: 0.84),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metaPill(
                    icon: Icons.event_rounded,
                    label: dateText,
                    bgColor: pillBackground,
                    fgColor: foreground,
                  ),
                  _metaPill(
                    icon: Icons.workspace_premium_rounded,
                    label:
                        'سال مالی ${PersianNumberFormatter.toPersian(data.settings.year.toString())}',
                    bgColor: pillBackground,
                    fgColor: foreground,
                  ),
                  _metaPill(
                    icon: Icons.bolt_rounded,
                    label: '${data.activeEmployees.length} پرسنل فعال',
                    bgColor: pillBackground,
                    fgColor: foreground,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (data.hasAnyRecord)
          _SummaryStat(
            label: 'خالص پرداختی ${data.targetLabel}',
            value: PersianNumberFormatter.formatNumber(
              (data.monthNet / 1000000).round(),
            ),
            suffix: 'میلیون',
          ),
      ],
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: fgColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle({
    required double size,
    required Color color,
    required double blur,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: 20),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? scheme.onSurface : scheme.onPrimary;
    final background = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              color: foreground.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: foreground.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// گرید کارت‌های KPI
class _KpiGrid extends StatelessWidget {
  final DashboardSnapshot data;
  final Responsive r;
  final bool isDark;
  const _KpiGrid({required this.data, required this.r, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final kpis = <_KpiData>[
      _KpiData(
        title: 'کارمندان فعال',
        value: data.activeEmployees.length.toDouble(),
        formatter: (v) =>
            PersianNumberFormatter.toPersian(v.round().toString()),
        icon: Icons.groups_2_rounded,
        primary: const Color(0xFF004394),
        secondary: const Color(0xFF005AC1),
        trend: '${data.employees.length} کل',
        isInt: true,
      ),
      _KpiData(
        title: 'فیش‌های صادر شده',
        value: data.monthRecordCount.toDouble(),
        formatter: (v) =>
            PersianNumberFormatter.toPersian(v.round().toString()),
        icon: Icons.receipt_long_rounded,
        primary: const Color(0xFFB61718),
        secondary: const Color(0xFFDA342D),
        trend: data.targetLabel,
        isInt: true,
      ),
      _KpiData(
        title: 'خالص پرداختی',
        value: data.monthNet,
        formatter: (v) => PersianNumberFormatter.formatNumber(v.round()),
        icon: Icons.payments_rounded,
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF66BB6A),
        trend: 'ریال',
      ),
      _KpiData(
        title: 'میانگین حقوق',
        value: data.avgNet,
        formatter: (v) => PersianNumberFormatter.formatNumber(v.round()),
        icon: Icons.trending_up_rounded,
        primary: const Color(0xFFEF6C00),
        secondary: const Color(0xFFFF9800),
        trend: 'ریال',
      ),
      _KpiData(
        title: 'وام‌های فعال',
        value: data.activeLoans.length.toDouble(),
        formatter: (v) =>
            PersianNumberFormatter.toPersian(v.round().toString()),
        icon: Icons.account_balance_wallet_rounded,
        primary: const Color(0xFF7B1FA2),
        secondary: const Color(0xFF9C27B0),
        trend: data.activeLoans.isEmpty
            ? 'بدون وام'
            : '${_toMillion(data.totalRemainingLoan)} م.ر باقی',
        isInt: true,
      ),
      _KpiData(
        title: 'مالیات ماه',
        value: data.monthTax,
        formatter: (v) => PersianNumberFormatter.formatNumber(v.round()),
        icon: Icons.receipt_rounded,
        primary: const Color(0xFF004E58),
        secondary: const Color(0xFF006874),
        trend: 'ریال',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = r.isMobileSize
            ? 2
            : c.maxWidth >= 1200
            ? 6
            : c.maxWidth >= 900
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: r.isMobileSize ? 120 : 142,
            crossAxisSpacing: r.cardGap,
            mainAxisSpacing: r.cardGap,
          ),
          itemBuilder: (context, i) {
            return _KpiCard(data: kpis[i], delay: i * 60);
          },
        );
      },
    );
  }

  String _toMillion(double v) {
    if (v == 0) return '۰';
    return PersianNumberFormatter.toPersian((v / 1000000).toStringAsFixed(0));
  }
}

class _KpiData {
  final String title;
  final double value;
  final String Function(double) formatter;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final String? trend;
  final bool isInt;
  const _KpiData({
    required this.title,
    required this.value,
    required this.formatter,
    required this.icon,
    required this.primary,
    required this.secondary,
    this.trend,
    this.isInt = false,
  });
}

class _KpiCard extends StatefulWidget {
  final _KpiData data;
  final int delay;
  const _KpiCard({required this.data, required this.delay});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovered = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isMobile = r.isMobileSize;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.short,
        curve: AppCurves.emphasizedDecelerate,
        transform: Matrix4.diagonal3Values(
          _hovered ? 1.025 : 1.0,
          _hovered ? 1.025 : 1.0,
          1.0,
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: _dashboardCardDecoration(
          context,
          borderColor: _hovered
              ? widget.data.primary.withValues(alpha: 0.45)
              : null,
          shadowColor: widget.data.primary,
          elevated: _hovered,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: isMobile ? 30 : 36,
                  height: isMobile ? 30 : 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.data.primary, widget.data.secondary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.data.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: Colors.white,
                    size: isMobile ? 16 : 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: isMobile ? 11 : 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (_visible)
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    value: widget.data.value,
                    formatter: widget.data.formatter,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: isMobile ? 22 : 28,
                  width: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            if (widget.data.trend != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.data.primary.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.data.trend!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.data.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// بخش نمودارها
class _ChartsSection extends StatelessWidget {
  final DashboardSnapshot data;
  final Responsive r;
  final bool isDark;
  const _ChartsSection({
    required this.data,
    required this.r,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = r.isMobileSize;
    final barCard = _ChartCard(
      title: 'روند پرداخت ۶ ماه اخیر',
      subtitle: 'مبلغ خالص پرداختی به تفکیک ماه (میلیون ریال)',
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFF004394),
      height: isNarrow ? 280 : 320,
      child: MonthlyBarChart(
        points: data.monthlyHistory,
        primary: const Color(0xFF004394),
        secondary: const Color(0xFFADC6FF),
        isDark: isDark,
      ),
    );
    final donutCard = _ChartCard(
      title: 'ترکیب پرداختی‌ها',
      subtitle: 'ماه ${data.targetLabel}',
      icon: Icons.donut_large_rounded,
      iconColor: const Color(0xFFB61718),
      height: isNarrow ? 320 : 320,
      child: DeductionsDonut(
        net: data.monthNet,
        tax: data.monthTax,
        insuranceEmployee: data.monthInsuranceEmployee,
        insuranceEmployer: data.monthInsuranceEmployer,
        loanInstallment: data.monthLoanInstallment,
        isDark: isDark,
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          barCard,
          SizedBox(height: r.cardGap),
          donutCard,
        ],
      );
    }
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: barCard),
        SizedBox(width: r.cardGap),
        Expanded(flex: 5, child: donutCard),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final double height;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: _dashboardCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// گرید اقدام سریع
class _QuickActionsGrid extends StatefulWidget {
  final Responsive r;
  final bool isDark;
  final VoidCallback onEmployees;
  final VoidCallback onSalaryCalc;
  final VoidCallback onRecords;
  final VoidCallback onLoans;
  final VoidCallback onSettings;
  const _QuickActionsGrid({
    required this.r,
    required this.isDark,
    required this.onEmployees,
    required this.onSalaryCalc,
    required this.onRecords,
    required this.onLoans,
    required this.onSettings,
  });

  @override
  State<_QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<_QuickActionsGrid> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItem>[
      _ActionItem(
        title: 'مدیریت کارکنان',
        subtitle: 'افزودن، ویرایش و حذف',
        icon: Icons.groups_2_rounded,
        gradient: const [Color(0xFF005AC1), Color(0xFF003974)],
        onTap: widget.onEmployees,
      ),
      _ActionItem(
        title: 'محاسبه حقوق',
        subtitle: 'محاسبه و ثبت فیش',
        icon: Icons.calculate_rounded,
        gradient: const [Color(0xFF004E58), Color(0xFF003138)],
        onTap: widget.onSalaryCalc,
      ),
      _ActionItem(
        title: 'فیش‌های حقوقی',
        subtitle: 'مشاهده، چاپ و حذف',
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFFDA342D), Color(0xFF8B0F0F)],
        onTap: widget.onRecords,
      ),
      _ActionItem(
        title: 'وام و اقساط',
        subtitle: 'کنترل اقساط ماهیانه',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFFEF6C00), Color(0xFFB04000)],
        onTap: widget.onLoans,
      ),
      _ActionItem(
        title: 'تنظیمات',
        subtitle: 'حقوق پایه و ضرایب',
        icon: Icons.tune_rounded,
        gradient: const [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        onTap: widget.onSettings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        int columns;
        if (c.maxWidth >= 1200) {
          columns = 3;
        } else if (c.maxWidth >= 720) {
          columns = 2;
        } else {
          columns = 1;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 110,
            crossAxisSpacing: widget.r.cardGap,
            mainAxisSpacing: widget.r.cardGap,
          ),
          itemBuilder: (context, i) {
            return _ActionCard(
              item: items[i],
              hovered: _hoveredIndex == i,
              onHover: (v) => setState(() => _hoveredIndex = v ? i : null),
              delay: i * 50,
            );
          },
        );
      },
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final int delay;
  const _ActionCard({
    required this.item,
    required this.hovered,
    required this.onHover,
    required this.delay,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.item.gradient.first;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.item.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: AppDurations.short,
            curve: AppCurves.emphasizedDecelerate,
            height: 110,
            transform: Matrix4.diagonal3Values(
              widget.hovered ? 1.035 : 1.0,
              widget.hovered ? 1.035 : 1.0,
              1.0,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: widget.hovered ? 0.16 : 0.08),
                isDark
                    ? scheme.surfaceContainer
                    : scheme.surfaceContainerLowest,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: widget.hovered
                    ? accent.withValues(alpha: 0.7)
                    : accent.withValues(alpha: 0.18),
                width: widget.hovered ? 1.5 : 1,
              ),
              boxShadow: widget.hovered
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: scheme.shadow.withValues(
                          alpha: isDark ? 0 : 0.06,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: AppDurations.short,
                      width: widget.hovered ? 5 : 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.item.gradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(
                          alpha: widget.hovered ? 0.12 : 0.06,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: -12,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppDurations.short,
                          width: widget.hovered ? 50 : 44,
                          height: widget.hovered ? 50 : 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.item.gradient,
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(
                                  alpha: widget.hovered ? 0.4 : 0.2,
                                ),
                                blurRadius: widget.hovered ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.item.icon,
                            color: Colors.white,
                            size: widget.hovered ? 24 : 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: AppDurations.short,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: widget.hovered ? 0.15 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AnimatedContainer(
                            duration: AppDurations.short,
                            transform: Matrix4.translationValues(
                              widget.hovered ? 3 : 0,
                              0,
                              0,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14,
                              color: accent.withValues(
                                alpha: widget.hovered ? 1.0 : 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// بخش پایینی: لیست‌ها و وام
class _BottomSection extends StatelessWidget {
  final DashboardSnapshot data;
  final Responsive r;
  final bool isDark;
  const _BottomSection({
    required this.data,
    required this.r,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final employeesMap = <int, Employee>{
      for (final e in data.employees)
        if (e.id != null) e.id!: e,
    };

    Widget topCard({required bool fillHeight}) => _TopEarnersCard(
      data: data,
      employeesMap: employeesMap,
      fillHeight: fillHeight,
    );
    Widget loanCard({required bool fillHeight}) =>
        _LoanSummaryCard(data: data, fillHeight: fillHeight);
    Widget recentCard({required bool fillHeight}) => _RecentRecordsCard(
      data: data,
      employeesMap: employeesMap,
      fillHeight: fillHeight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The app sidebar can make this section much narrower than MediaQuery.
        final stackCards = constraints.maxWidth < 840;
        if (stackCards) {
          return Column(
            children: [
              topCard(fillHeight: false),
              SizedBox(height: r.cardGap),
              loanCard(fillHeight: false),
              SizedBox(height: r.cardGap),
              recentCard(fillHeight: false),
            ],
          );
        }
        final topHeight =
            90.0 +
            (data.topEarners.length * 28) +
            ((data.topEarners.length - 1).clamp(0, 4) * 13);
        final recentHeight =
            96.0 +
            (data.recentRecords.length * 44) +
            ((data.recentRecords.length - 1).clamp(0, 4) * 9);
        final loanHeight = data.activeLoans.isEmpty ? 170.0 : 246.0;
        final contentHeight = [
          topHeight,
          loanHeight,
          recentHeight,
        ].reduce((current, next) => current > next ? current : next);
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1).clamp(1.0, 1.5);
        final desktopHeight = (contentHeight * textScale).clamp(246.0, 520.0);

        return SizedBox(
          height: desktopHeight,
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: topCard(fillHeight: true)),
              SizedBox(width: r.cardGap),
              Expanded(flex: 4, child: loanCard(fillHeight: true)),
              SizedBox(width: r.cardGap),
              Expanded(flex: 6, child: recentCard(fillHeight: true)),
            ],
          ),
        );
      },
    );
  }
}

class _TopEarnersCard extends StatelessWidget {
  final DashboardSnapshot data;
  final Map<int, Employee> employeesMap;
  final bool fillHeight;
  const _TopEarnersCard({
    required this.data,
    required this.employeesMap,
    required this.fillHeight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxVal = data.maxNet;
    return _PanelCard(
      title: 'پرداخت‌های برتر',
      subtitle: data.targetLabel,
      icon: Icons.workspace_premium_rounded,
      iconColor: const Color(0xFFEF6C00),
      fillHeight: fillHeight,
      child: data.topEarners.isEmpty
          ? _emptyState('داده‌ای برای نمایش نیست', scheme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: fillHeight
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                for (var i = 0; i < data.topEarners.length; i++) ...[
                  _TopEarnerRow(
                    rank: i + 1,
                    record: data.topEarners[i],
                    employee: employeesMap[data.topEarners[i].employeeId],
                    maxValue: maxVal,
                  ),
                  if (i < data.topEarners.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        height: 1,
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _TopEarnerRow extends StatelessWidget {
  final int rank;
  final SalaryRecord record;
  final Employee? employee;
  final double maxValue;
  const _TopEarnerRow({
    required this.rank,
    required this.record,
    required this.employee,
    required this.maxValue,
  });

  String get _employeeName {
    final snapshot = record.employeeFullNameSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return employee?.fullName ?? 'کارمند #${record.employeeId}';
  }

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFF90A4AE);
      case 3:
        return const Color(0xFFBF8970);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = maxValue == 0 ? 0.0 : (record.finalPayment / maxValue);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _rankColor().withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            PersianNumberFormatter.toPersian(rank.toString()),
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _rankColor(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      _employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    PersianNumberFormatter.formatNumber(
                      record.finalPayment.round(),
                    ),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEF6C00),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: const Cubic(0.16, 1, 0.3, 1),
                        width: constraints.maxWidth * pct.clamp(0, 1),
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF6C00), Color(0xFFFFB74D)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final DashboardSnapshot data;
  final bool fillHeight;
  const _LoanSummaryCard({required this.data, required this.fillHeight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PanelCard(
      title: 'وضعیت وام‌ها',
      subtitle:
          '${PersianNumberFormatter.toPersian(data.activeLoans.length.toString())} وام فعال',
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFF7B1FA2),
      fillHeight: fillHeight,
      child: data.activeLoans.isEmpty
          ? _emptyState('وام فعالی ثبت نشده', scheme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: fillHeight
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                _loanStat(
                  context: context,
                  label: 'مبلغ کل وام‌ها',
                  value: data.totalActiveLoanAmount,
                  color: const Color(0xFF7B1FA2),
                ),
                const SizedBox(height: 10),
                _loanStat(
                  context: context,
                  label: 'پرداخت شده',
                  value: data.totalPaidLoan,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 10),
                _loanStat(
                  context: context,
                  label: 'باقیمانده',
                  value: data.totalRemainingLoan,
                  color: const Color(0xFFEF6C00),
                ),
                const SizedBox(height: 14),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'پیشرفت بازپرداخت',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${PersianNumberFormatter.toPersian((data.loanProgress * 100).toStringAsFixed(0))}٪',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7B1FA2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: data.loanProgress),
                  duration: const Duration(milliseconds: 1200),
                  curve: const Cubic(0.16, 1, 0.3, 1),
                  builder: (context, val, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: val.clamp(0, 1),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Wrap(
                  textDirection: TextDirection.rtl,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'کسر ماهانه',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${PersianNumberFormatter.formatNumber(data.monthlyInstallmentSum.round())} ریال',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _loanStat({
    required BuildContext context,
    required String label,
    required double value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 124),
          child: Text(
            PersianNumberFormatter.formatNumber(value.round()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentRecordsCard extends StatelessWidget {
  final DashboardSnapshot data;
  final Map<int, Employee> employeesMap;
  final bool fillHeight;
  const _RecentRecordsCard({
    required this.data,
    required this.employeesMap,
    required this.fillHeight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _PanelCard(
      title: 'آخرین فیش‌های صادر شده',
      subtitle: data.targetLabel,
      icon: Icons.history_rounded,
      iconColor: const Color(0xFF004394),
      fillHeight: fillHeight,
      child: data.recentRecords.isEmpty
          ? _emptyState('فیشی صادر نشده', scheme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: fillHeight
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                for (var i = 0; i < data.recentRecords.length; i++) ...[
                  _RecentRow(
                    record: data.recentRecords[i],
                    employee: employeesMap[data.recentRecords[i].employeeId],
                    index: i,
                  ),
                  if (i < data.recentRecords.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        height: 1,
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _RecentRow extends StatefulWidget {
  final SalaryRecord record;
  final Employee? employee;
  final int index;
  const _RecentRow({
    required this.record,
    required this.employee,
    required this.index,
  });

  @override
  State<_RecentRow> createState() => _RecentRowState();
}

class _RecentRowState extends State<_RecentRow> {
  bool _hovered = false;

  String get _employeeName {
    final snapshot = widget.record.employeeFullNameSnapshot?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return widget.employee?.fullName ?? 'کارمند #${widget.record.employeeId}';
  }

  int? get _employeeCode =>
      widget.record.employeePersonnelCodeSnapshot ??
      widget.employee?.personnelCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.micro,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF004394).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _employeeName.characters.firstOrNull ?? '?',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF004394),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    'کد ${PersianNumberFormatter.toPersian(_employeeCode?.toString() ?? '-')}',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Text(
                PersianNumberFormatter.formatNumber(
                  widget.record.finalPayment.round(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final bool fillHeight;
  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _dashboardCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (fillHeight) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

Widget _emptyState(String text, ColorScheme scheme) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
