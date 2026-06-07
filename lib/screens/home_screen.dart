import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/company_profile.dart';
import '../providers/theme_controller.dart';
import '../services/company_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_sidebar.dart';
import 'employees/employees_list_screen.dart';
import 'help/help_support_screen.dart';
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
  int _index = 0;
  int _workspaceVersion = 0;
  final PageController _pageController = PageController();
  final _companyService = CompanyService();
  final _settingsService = SettingsService();
  List<CompanyProfile> _companies = const [];
  CompanyProfile? _currentCompany;

  List<Widget> get _pages => [
    DashboardView(
      onNavigateToEmployees: () => _goToIndex(1),
      onNavigateToSalaryCalc: () => _goToIndex(2),
      onNavigateToSalaryRecords: () => _goToIndex(3),
      onNavigateToLoans: () => _goToIndex(5),
      onNavigateToSettings: () => _goToIndex(6),
      onNavigateToHelp: () => _goToIndex(7),
    ),
    const EmployeesListScreen(),
    const SalaryCalculationScreen(),
    const SalaryRecordsScreen(),
    const EmployeeLeavesScreen(),
    const LoansListScreen(),
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
    const SidebarItem(label: 'تنظیمات سیستم', icon: Icons.settings_rounded),
    const SidebarItem(
      label: 'راهنما و پشتیبانی',
      icon: Icons.support_agent_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

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
                header: _SidebarHeader(
                  companyName: _currentCompany?.name,
                  onManageCompanies: _showCompanyDialog,
                ),
                footer: _SidebarFooter(),
              ),
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(
              child: _AnimatedPageSwitcher(
                pageKey: ValueKey('$_workspaceVersion-$_index'),
                child: _buildCurrentPage(),
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
              onManageCompanies: _showCompanyDialog,
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
        body: PageView(
          key: ValueKey(_workspaceVersion),
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          reverse: false, // RTL: swipe چپ به راست = صفحه بعد
          onPageChanged: (i) => setState(() => _index = i),
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index < 6 ? _index : 0,
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
              icon: Icon(Icons.beach_access_rounded),
              label: 'مرخصی',
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

    // تنظیمات و راهنما: صفحه جداگانه
    if (index == 6) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }
    if (index == 7) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
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
    var companies = await _companyService.getCompanies();
    var current = await _companyService.getCurrentCompany();
    final settings = await _settingsService.getCurrentSettings();
    if (settings.companyName.trim().isNotEmpty &&
        current.name != settings.companyName) {
      await _companyService.syncCurrentCompanyName(settings.companyName);
      companies = await _companyService.getCompanies();
      current = await _companyService.getCurrentCompany();
    }
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _currentCompany = current;
    });
  }

  Future<void> _showCompanyDialog() async {
    await _loadCompanies();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مدیریت شرکت‌ها', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final company in _companies)
                ListTile(
                  leading: Icon(
                    company.dbName == _currentCompany?.dbName
                        ? Icons.check_circle_rounded
                        : Icons.business_rounded,
                  ),
                  title: Text(company.name),
                  subtitle: Text(company.dbName),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _activateCompany(company);
                  },
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showAddCompanyDialog();
                },
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('افزودن شرکت جدید'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCompanyDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شرکت جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'نام شرکت',
            prefixIcon: Icon(Icons.business_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    final company = await _companyService.addCompany(name);
    await DatabaseHelper.instance.close();
    final settings = await _settingsService.getCurrentSettings();
    await _settingsService.update(settings.copyWith(companyName: name));
    await _refreshWorkspace(company);
  }

  Future<void> _activateCompany(CompanyProfile company) async {
    if (company.dbName == _currentCompany?.dbName) return;
    await _companyService.switchCompany(company);
    await DatabaseHelper.instance.close();
    await _refreshWorkspace(company);
  }

  Future<void> _refreshWorkspace(CompanyProfile company) async {
    final companies = await _companyService.getCompanies();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _currentCompany = company;
      _index = 0;
      _workspaceVersion++;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
  final VoidCallback onManageCompanies;

  const _SidebarHeader({this.companyName, required this.onManageCompanies});

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
            companyName ?? 'سیستم حقوق و دستمزد',
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onManageCompanies,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('تعویض شرکت'),
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
