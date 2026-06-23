import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_profile.dart';
import '../providers/theme_controller.dart';
import '../services/company_service.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/sync_status_banner.dart';
import 'advances/advances_list_screen.dart';
import 'batch/batch_operations_screen.dart';
import 'employees/employees_list_screen.dart';
import 'home/dashboard_view.dart';
import 'leaves/employee_leaves_screen.dart';
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
  static const _sidebarCollapsedKey = 'hvm_sidebar_collapsed_v1';

  int _index = 0;
  final PageController _pageController = PageController();
  final _companyService = CompanyService();
  final _sync = SyncService();
  CompanyProfile? _currentCompany;
  bool _sidebarCollapsed = false;

  List<Widget> get _pages => [
    DashboardView(
      onNavigateToEmployees: () => _goToIndex(1),
      onNavigateToSalaryCalc: () => _goToIndex(2),
      onNavigateToSalaryRecords: () => _goToIndex(3),
      onNavigateToLoans: () => _goToIndex(5),
      onNavigateToSettings: () => _goToIndex(8),
    ),
    const EmployeesListScreen(),
    const SalaryCalculationScreen(),
    const SalaryRecordsScreen(),
    const EmployeeLeavesScreen(),
    const LoansListScreen(),
    const AdvancesListScreen(),
    const BatchOperationsScreen(),
  ];

  late final List<SidebarItem> _items = [
    const SidebarItem(label: 'داشبورد', icon: Icons.dashboard_rounded),
    const SidebarItem(label: 'مدیریت کارکنان', icon: Icons.groups_rounded),
    const SidebarItem(label: 'محاسبه حقوق', icon: Icons.calculate_rounded),
    const SidebarItem(label: 'فیش‌های حقوقی', icon: Icons.receipt_long_rounded),
    const SidebarItem(label: 'مرخصی کارکنان', icon: Icons.beach_access_rounded),
    const SidebarItem(
      label: 'وام و اقساط',
      icon: Icons.account_balance_wallet_rounded,
    ),
    const SidebarItem(label: 'مساعده کارکنان', icon: Icons.payments_rounded),
    const SidebarItem(label: 'عملیات دسته‌ای', icon: Icons.fact_check_rounded),
    const SidebarItem(label: 'تنظیمات سیستم', icon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _sync.dataVersion.addListener(_onSyncedDataChanged);
    _loadCompanies();
    unawaited(_loadSidebarState());
    unawaited(_startSync());
  }

  @override
  void dispose() {
    _sync.dataVersion.removeListener(_onSyncedDataChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (responsive.showsSidebar) {
      final canCollapse = Platform.isWindows;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      final sidebarWidth = canCollapse && _sidebarCollapsed
          ? 84.0
          : responsive.sidebarWidth;
      // -------- دسکتاپ / تبلت: سایدبار دائمی --------
      return Scaffold(
        body: Row(
          textDirection: TextDirection.rtl,
          children: [
            AnimatedContainer(
              width: sidebarWidth,
              duration: reduceMotion ? Duration.zero : AppDurations.medium,
              curve: AppCurves.smoothInOut,
              child: AppSidebar(
                currentIndex: _index,
                onSelect: (i) => _goToIndex(i),
                items: _items,
                collapsed: canCollapse && _sidebarCollapsed,
                onToggleCollapsed: canCollapse ? _toggleSidebar : null,
                header: _SidebarHeader(
                  companyName: _currentCompany?.name,
                  canManageCompanies: false,
                ),
                footer: _SidebarFooter(),
              ),
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  const SyncStatusBanner(),
                  Expanded(
                    child: _AnimatedPageSwitcher(
                      pageKey: ValueKey('$_index-${_sync.dataVersion.value}'),
                      child: _buildCurrentPage(),
                    ),
                  ),
                ],
              ),
            ),
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
            header: _SidebarHeader(
              companyName: _currentCompany?.name,
              canManageCompanies: false,
            ),
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
        body: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                reverse: false, // RTL: swipe چپ به راست = صفحه بعد
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    KeyedSubtree(
                      key: ValueKey(
                        'mobile-page-$i-${_sync.dataVersion.value}',
                      ),
                      child: _pages[i],
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index < 4 ? _index : 0,
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
          ],
        ),
      ),
    );
  }

  /// صفحه فعلی
  Widget _buildCurrentPage() => KeyedSubtree(
    key: ValueKey('desktop-page-$_index-${_sync.dataVersion.value}'),
    child: _pages[_index],
  );

  void _onSyncedDataChanged() {
    unawaited(_loadCompanies());
    if (mounted) setState(() {});
  }

  Future<void> _loadSidebarState() async {
    if (!Platform.isWindows) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sidebarCollapsed = prefs.getBool(_sidebarCollapsedKey) ?? false;
    });
  }

  Future<void> _toggleSidebar() async {
    final collapsed = !_sidebarCollapsed;
    setState(() => _sidebarCollapsed = collapsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sidebarCollapsedKey, collapsed);
  }

  Future<void> _startSync() async {
    try {
      await _sync.ensureServerHydrated();
    } catch (_) {}
    await _sync.startAutoSync();
    await _sync.syncNow(silent: true);
  }

  /// تغییر index با همگام‌سازی PageController (در موبایل)
  void _goToIndex(int index) {
    if (!mounted) return;

    // تنظیمات در صفحه جداگانه باز می‌شود.
    if (index == 8) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }

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

  // -------- سوئیچ صفحه با انیمیشن --------
  Future<void> _loadCompanies() async {
    final current = await _companyService.syncCurrentCompanyFromSession();
    if (!mounted) return;
    setState(() {
      _currentCompany = current;
    });
  }
}

class _AnimatedPageSwitcher extends StatelessWidget {
  final Widget child;
  final Key pageKey;
  const _AnimatedPageSwitcher({required this.child, required this.pageKey});

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
      child: KeyedSubtree(key: pageKey, child: child),
    );
  }
}

// -------- هدر سایدبار --------
class _SidebarHeader extends StatelessWidget {
  final String? companyName;
  final bool canManageCompanies;

  const _SidebarHeader({this.companyName, required this.canManageCompanies});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final compact = constraints.maxWidth < 200;
        return AnimatedSize(
          duration: AppDurations.medium,
          curve: AppCurves.smoothInOut,
          alignment: Alignment.topCenter,
          child: compact
              ? Padding(
                  key: const ValueKey('compact-header'),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Tooltip(
                    message: companyName ?? 'سیستم حقوق و دستمزد',
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 27,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : Padding(
                  key: const ValueKey('expanded-header'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                        companyName ?? 'سیستم حقوق و دستمزد',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      if (canManageCompanies) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('تعویض شرکت'),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// -------- فوتر سایدبار --------
class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final compact = constraints.maxWidth < 200;
        return AnimatedSize(
          duration: AppDurations.medium,
          curve: AppCurves.smoothInOut,
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              children: [
                Divider(color: scheme.outlineVariant, height: 1),
                SizedBox(height: compact ? 8 : 12),
                if (compact) const _CompactThemeButton() else _ThemeSwitcher(),
                SizedBox(height: compact ? 6 : 8),
                Tooltip(
                  message: 'نسخه ${AppConstants.appVersion}',
                  child: Text(
                    compact
                        ? AppConstants.appVersion.split(' ').first
                        : 'نسخه ${AppConstants.appVersion}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: compact ? 9 : 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactThemeButton extends StatelessWidget {
  const _CompactThemeButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<ThemeController>();
    final icon = switch (controller.themeMode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
    final label = switch (controller.themeMode) {
      ThemeMode.system => 'تم سیستم',
      ThemeMode.light => 'تم روشن',
      ThemeMode.dark => 'تم تاریک',
    };
    return Tooltip(
      message: '$label؛ برای تغییر کلیک کنید',
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final next = switch (controller.themeMode) {
              ThemeMode.system => ThemeMode.light,
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
            };
            controller.setThemeMode(next);
          },
          child: SizedBox(
            width: 48,
            height: 42,
            child: AnimatedSwitcher(
              duration: AppDurations.micro,
              child: Icon(
                icon,
                key: ValueKey(controller.themeMode),
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
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
