import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../providers/theme_controller.dart';
import '../services/salary_service.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import '../utils/constants.dart';
import '../utils/gradient_helpers.dart';
import '../utils/responsive.dart';
import '../widgets/app_sidebar.dart';
import 'employees/employees_list_screen.dart';
import 'help/help_support_screen.dart';
import 'loans/loans_list_screen.dart';
import 'salary/salary_calculation_screen.dart';
import 'salary/salary_records_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final PageController _pageController = PageController();

  late final List<Widget> _pages = [
    const _DashboardView(),
    const EmployeesListScreen(),
    const SalaryCalculationScreen(),
    const SalaryRecordsScreen(),
    const LoansListScreen(),
    const SettingsScreen(),
    const HelpSupportScreen(),
  ];

  late final List<SidebarItem> _items = [
    const SidebarItem(label: 'داشبورد', icon: Icons.dashboard_rounded),
    const SidebarItem(label: 'مدیریت کارکنان', icon: Icons.groups_rounded),
    const SidebarItem(label: 'محاسبه حقوق', icon: Icons.calculate_rounded),
    const SidebarItem(label: 'فیش‌های حقوقی', icon: Icons.receipt_long_rounded),
    const SidebarItem(
      label: 'وام و اقساط',
      icon: Icons.account_balance_wallet_rounded,
    ),
    const SidebarItem(label: 'تنظیمات سیستم', icon: Icons.settings_rounded),
    const SidebarItem(
      label: 'راهنما و پشتیبانی',
      icon: Icons.support_agent_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (responsive.showsSidebar) {
      // -------- دسکتاپ / تبلت: سایدبار دائمی --------
      return Scaffold(
        body: Row(
          textDirection: TextDirection.rtl,
          children: [
            SizedBox(
              width: responsive.sidebarWidth,
              child: AppSidebar(
                currentIndex: _index,
                onSelect: (i) => _goToIndex(i),
                items: _items,
                header: _SidebarHeader(),
                footer: _SidebarFooter(),
              ),
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(child: _AnimatedPageSwitcher(child: _buildCurrentPage())),
          ],
        ),
      );
    }

    // -------- موبایل: Drawer + BottomNav + Swipe --------
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goToIndex(0);
      },
      child: Scaffold(
        drawer: Drawer(
          child: AppSidebar(
            currentIndex: _index,
            onSelect: (i) {
              Navigator.pop(context);
              _goToIndex(i);
            },
            items: _items,
            header: _SidebarHeader(),
            footer: _SidebarFooter(),
          ),
        ),
        appBar: AppBar(
          title: Text(_items[_index].label),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6_rounded),
              tooltip: 'تغییر تم',
              onPressed: () => _cycleTheme(context),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          reverse: true, // RTL: swipe راست به چپ = صفحه بعد
          onPageChanged: (i) => setState(() => _index = i),
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index < 5 ? _index : 0,
          onDestinationSelected: (i) => _goToIndex(i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_rounded),
              label: 'کارکنان',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_rounded),
              label: 'محاسبه',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'فیش‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'وام',
            ),
          ],
        ),
      ),
    );
  }

  /// صفحه فعلی
  Widget _buildCurrentPage() => _pages[_index];

  /// تغییر index با همگام‌سازی PageController (در موبایل)
  void _goToIndex(int index) {
    if (!mounted) return;
    setState(() => _index = index);
    if (index < _pages.length && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void changeIndex(int index) {
    _goToIndex(index);
  }

  void _cycleTheme(BuildContext context) {
    final controller = context.read<ThemeController>();
    final next = switch (controller.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    controller.setThemeMode(next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_themeModeLabel(next)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  String _themeModeLabel(ThemeMode m) => switch (m) {
    ThemeMode.system => 'تم سیستم',
    ThemeMode.light => 'تم روشن',
    ThemeMode.dark => 'تم تاریک',
  };
}

// -------- سوئیچ صفحه با انیمیشن --------
class _AnimatedPageSwitcher extends StatelessWidget {
  final Widget child;
  const _AnimatedPageSwitcher({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: AppCurves.emphasizedDecelerate,
      switchOutCurve: AppCurves.emphasizedAccelerate,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}

// -------- هدر سایدبار --------
class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: 32,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'سیستم حقوق و دستمزد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سال مالی ۱۴۰۵',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// -------- فوتر سایدبار --------
class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 12),
          _ThemeSwitcher(),
          const SizedBox(height: 8),
          Text(
            'نسخه ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<ThemeController>();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeButton(
            icon: Icons.brightness_auto_rounded,
            label: 'سیستم',
            isActive: controller.themeMode == ThemeMode.system,
            onTap: () => controller.setThemeMode(ThemeMode.system),
          ),
          _ThemeButton(
            icon: Icons.light_mode_rounded,
            label: 'روشن',
            isActive: controller.themeMode == ThemeMode.light,
            onTap: () => controller.setThemeMode(ThemeMode.light),
          ),
          _ThemeButton(
            icon: Icons.dark_mode_rounded,
            label: 'تیره',
            isActive: controller.themeMode == ThemeMode.dark,
            onTap: () => controller.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isActive ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
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

// -------- داشبورد اصلی با Bento Grid --------
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding,
            r.pagePadding,
            r.pagePadding,
            80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopBar(),
              SizedBox(height: r.sectionGap),
              _HeroBanner(),
              SizedBox(height: r.sectionGap),
              _BentoGrid(),
              SizedBox(height: r.sectionGap),
              _AnalyticsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FadeInUp(
      duration: AppDurations.medium,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سلام، مدیر مالی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: r.isMobileSize ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'به سیستم حقوق و دستمزد خوش آمدید',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: r.isMobileSize ? 12 : 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (r.isDesktopSize) ...[
            SizedBox(width: 280, child: _SearchField()),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'جستجو در سیستم...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintStyle: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// -------- بنر هیرو --------
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FadeInUp(
      delay: const Duration(milliseconds: 80),
      duration: AppDurations.medium,
      child: Container(
        height: r.isMobileSize ? 180 : 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primaryContainer],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.elevation2(scheme.shadow),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: _BlurredCircle(
                size: 200,
                color: context.gradientDecoLarge,
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: _BlurredCircle(
                size: 180,
                color: context.gradientDecoSmall,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(r.isMobileSize ? 20 : 32),
                child: r.isMobileSize
                    ? _buildMobileContent(scheme)
                    : _buildDesktopContent(scheme, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_rounded, size: 48, color: scheme.onPrimary),
        const SizedBox(height: 12),
        Text(
          'سیستم محاسبه حقوق و دستمزد',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'شرکت فرایند کود و سم بافق • سال ۱۴۰۵',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: scheme.onPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(ColorScheme scheme, BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: context.onGradientOverlayMedium,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            size: 48,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'سیستم محاسبه حقوق و دستمزد',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'شرکت فرایند کود و سم بافق • سال مالی ۱۴۰۵',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: scheme.onPrimary.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurredCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 30)],
      ),
    );
  }
}

// -------- Bento Grid (کارت‌های اصلی) --------
class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final items = [
      _BentoItem(
        title: 'مدیریت کارکنان',
        subtitle: 'افزودن، ویرایش و حذف کارمندان',
        icon: Icons.groups_rounded,
        gradient: const [Color(0xFF005AC1), Color(0xFF004394)],
        onTap: () => _navTo(context, 1),
      ),
      _BentoItem(
        title: 'محاسبه حقوق',
        subtitle: 'محاسبه و ثبت فیش حقوق پرسنل',
        icon: Icons.calculate_rounded,
        gradient: const [Color(0xFF006874), Color(0xFF004E58)],
        onTap: () => _navTo(context, 2),
      ),
      _BentoItem(
        title: 'فیش‌های حقوقی',
        subtitle: 'مشاهده، چاپ و حذف فیش‌ها',
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFFDA342D), Color(0xFFB61718)],
        onTap: () => _navTo(context, 3),
      ),
      _BentoItem(
        title: 'مدیریت وام و اقساط',
        subtitle: 'کنترل کسر اقساط ماهیانه کارکنان',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFFEF6C00), Color(0xFFE65100)],
        onTap: () => _navTo(context, 4),
      ),
      _BentoItem(
        title: 'تنظیمات حقوق پایه',
        subtitle: 'تعیین ضرایب، سقف بیمه و مالیات سالانه',
        icon: Icons.tune_rounded,
        gradient: const [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        onTap: () => _navTo(context, 5),
        isLarge: true,
      ),
      _BentoItem(
        title: 'راهنما و پشتیبانی',
        subtitle: 'مستندات و راهنمای استفاده',
        icon: Icons.support_agent_rounded,
        gradient: const [Color(0xFF455A64), Color(0xFF263238)],
        onTap: () => _navTo(context, 6),
        isLarge: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = r.bentoColumns;
        final gap = r.cardGap;
        final aspectRatio = r.isMobileSize ? 2.3 : 2.6;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return FadeInUp(
              delay: Duration(milliseconds: 100 + (i * 60)),
              child: _BentoCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  void _navTo(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_HomeScreenState>();
    if (state == null) return;
    state.changeIndex(index);
  }
}

class _BentoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isLarge;

  const _BentoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isLarge = false,
  });
}

class _BentoCard extends StatefulWidget {
  final _BentoItem item;
  const _BentoCard({required this.item});

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: AppDurations.short,
          curve: AppCurves.emphasizedDecelerate,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : (_hovered ? 1.02 : 1.0),
            _pressed ? 0.97 : (_hovered ? 1.02 : 1.0),
            1.0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.item.gradient,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: widget.item.gradient.first.withValues(
                  alpha: _hovered ? 0.35 : 0.15,
                ),
                blurRadius: _hovered ? 24 : 12,
                offset: Offset(0, _hovered ? 12 : 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.gradientDecoSmall,
                  ),
                ),
              ),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.onGradientOverlayStrong,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------- بخش تحلیلی پایین داشبورد --------
class _AnalyticsSection extends StatefulWidget {
  const _AnalyticsSection();

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  bool _loading = true;
  double _totalEarnings = 0;
  double _employerInsurance = 0;
  double _tax = 0;
  String _monthLabel = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = Jalali.now();
    final year = now.year;
    final month = now.month;

    const monthNames = [
      '', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
    ];
    _monthLabel = '${monthNames[month]} $year';

    final db = DatabaseHelper.instance;
    final settingsRows = await (await db.database).query(
      'app_settings',
      where: 'year = ?',
      whereArgs: [year],
    );
    final settings = settingsRows.isNotEmpty
        ? AppSettings.fromMap(settingsRows.first)
        : AppSettings();

    final service = SalaryService();
    final records = await service.getByYearMonth(year, month);
    _totalEarnings = records.fold(0.0, (s, r) => s + r.totalEarnings);
    _employerInsurance = records.fold(
      0.0,
      (s, r) => s + r.insuranceBase * settings.employerInsuranceRate,
    );
    _tax = records.fold(0.0, (s, r) => s + r.tax);

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final statGap = r.cardGap;

    String fmt(double v) {
      if (v == 0) return '۰';
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      final str = buf.toString();
      const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      return str.split('').map((c) => persian[int.tryParse(c) ?? 0]).join();
    }

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.all(r.isMobileSize ? 14 : 24),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (r.isMobileSize) ...[
              Text(
                'وضعیت کلی پرداخت‌های ماه جاری',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _monthLabel,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ] else
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    'وضعیت کلی پرداخت‌های ماه جاری',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _monthLabel,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: r.isMobileSize ? 14 : 24),
            LayoutBuilder(
              builder: (context, c) {
                final isNarrow = c.maxWidth < 720;
                final cards = [
                  _StatCard(
                    title: 'مجموع ناخالص حقوق',
                    value: _loading ? '—' : '${fmt(_totalEarnings)} ریال',
                    color: scheme.primary,
                    icon: Icons.payments_rounded,
                  ),
                  _StatCard(
                    title: 'حق بیمه سهم کارفرما',
                    value: _loading ? '—' : '${fmt(_employerInsurance)} ریال',
                    color: scheme.tertiary,
                    icon: Icons.health_and_safety_rounded,
                  ),
                  _StatCard(
                    title: 'مالیات متعلقه',
                    value: _loading ? '—' : '${fmt(_tax)} ریال',
                    color: scheme.secondary,
                    icon: Icons.receipt_rounded,
                  ),
                ];
                if (isNarrow) {
                  return Column(
                    children: [
                      cards[0],
                      SizedBox(height: statGap),
                      cards[1],
                      SizedBox(height: statGap),
                      cards[2],
                    ],
                  );
                }
                return Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(child: cards[0]),
                    SizedBox(width: statGap),
                    Expanded(child: cards[1]),
                    SizedBox(width: statGap),
                    Expanded(child: cards[2]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isMobile = r.isMobileSize;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.short,
        curve: AppCurves.emphasizedDecelerate,
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
          boxShadow: _hovered
              ? AppTheme.elevation2(scheme.shadow)
              : AppTheme.elevation1(scheme.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: isMobile ? 34 : 40,
                  height: isMobile ? 34 : 40,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: isMobile ? 11 : 12,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.value,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ریال',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: isMobile ? 10 : 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
