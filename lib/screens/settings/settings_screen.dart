import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_settings.dart';
import '../../models/color_config.dart';
import '../../providers/theme_controller.dart';
import '../../services/appearance_service.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../services/api_client.dart';
import '../../services/local_security_service.dart';
import '../../services/sync_service.dart';
import '../../services/update_service.dart';
import '../../services/window_close_service.dart';
import '../auth/local_unlock_setup_screen.dart';
import '../auth/server_login_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_error_message.dart';
import '../../utils/animations.dart';
import '../../utils/constants.dart';
import '../../utils/persian_digit_input_formatter.dart';
import '../../utils/persian_number_formatter.dart';
import '../../utils/gradient_helpers.dart';
import '../../utils/responsive.dart';
import '../../widgets/persian_number_field.dart';
import '../../widgets/app_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _backupService = BackupService();
  final _security = LocalSecurityService();
  final _apiClient = ApiClient();
  final _updateService = UpdateService();
  final _formKey = GlobalKey<FormState>();

  LocalCredentialMethod? _localMethod;
  bool _hasLocalCredential = false;
  bool _biometricEnabled = false;
  WindowCloseBehavior _closeBehavior = WindowCloseBehavior.ask;
  UpdatePreferences _updatePreferences = const UpdatePreferences();
  bool _checkingUpdate = false;

  AppSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  // مقادیر اولیه برای مقایسه
  double _initDailyWage = 0;
  double _initMonthlyFood = 0;
  double _initMonthlyHousing = 0;
  double _initMonthlyMarriage = 0;
  double _initMonthlyChild = 0;
  double _initDailySeniority = 0;
  double _initSalaryRateA = 0;
  double _initSalaryRateB = 0;
  double _initFixedRial = 0;
  double _initEmployeeInsuranceRate = 0;
  double _initEmployerInsuranceRate = 0;
  double _initUnemploymentInsuranceRate = 0;
  double _initTwoSevenBaseRate = 0;
  double _initMonthlyLeaveAllowance = 0;
  double _initAnnualLeaveAllowance = 0;
  double _initNightWorkRate = 0;
  double _initFridayWorkRate = 0;
  double _initHolidayWorkMultiplier = 0;
  double _initMissionDailyMultiplier = 0;
  double _initAbsenceHourlyMultiplier = 0;

  late TextEditingController _companyNameCtrl;

  double _dailyWage = 0;
  double _monthlyFood = 0;
  double _monthlyHousing = 0;
  double _monthlyMarriage = 0;
  double _monthlyChild = 0;
  double _dailySeniority = 0;
  double _salaryRateA = 0;
  double _salaryRateB = 0;
  double _fixedRial = 0;
  double _employeeInsuranceRate = 0;
  double _employerInsuranceRate = 0;
  double _unemploymentInsuranceRate = 0;
  double _twoSevenBaseRate = 0;
  double _monthlyLeaveAllowance = 0;
  double _annualLeaveAllowance = 0;
  double _nightWorkRate = 0;
  double _fridayWorkRate = 0;
  double _holidayWorkMultiplier = 0;
  double _missionDailyMultiplier = 0;
  double _absenceHourlyMultiplier = 0;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController();
    SyncService().dataVersion.addListener(_onSyncedDataChanged);
    _load();
  }

  Future<void> _load() async {
    _settings = await _service.getCurrentSettings();
    _companyNameCtrl.removeListener(_checkChanges);
    _companyNameCtrl.text = PersianNumberFormatter.toPersian(
      _settings!.companyName,
    );
    _companyNameCtrl.addListener(_checkChanges);
    _dailyWage = _settings!.dailyWage;
    _monthlyFood = _settings!.monthlyFood;
    _monthlyHousing = _settings!.monthlyHousing;
    _monthlyMarriage = _settings!.monthlyMarriage;
    _monthlyChild = _settings!.monthlyChild;
    _dailySeniority = _settings!.dailySeniority;
    _salaryRateA = _settings!.salaryRateA;
    _salaryRateB = _settings!.salaryRateB;
    _fixedRial = _settings!.fixedRial;
    _employeeInsuranceRate = _settings!.employeeInsuranceRate;
    _employerInsuranceRate = _settings!.employerInsuranceRate;
    _unemploymentInsuranceRate = _settings!.unemploymentInsuranceRate;
    _twoSevenBaseRate = _settings!.twoSevenBaseRate;
    _monthlyLeaveAllowance = _settings!.monthlyLeaveAllowance;
    _annualLeaveAllowance = _settings!.annualLeaveAllowance;
    _nightWorkRate = _settings!.nightWorkRate;
    _fridayWorkRate = _settings!.fridayWorkRate;
    _holidayWorkMultiplier = _settings!.holidayWorkMultiplier;
    _missionDailyMultiplier = _settings!.missionDailyMultiplier;
    _absenceHourlyMultiplier = _settings!.absenceHourlyMultiplier;

    _initDailyWage = _settings!.dailyWage;
    _initMonthlyFood = _settings!.monthlyFood;
    _initMonthlyHousing = _settings!.monthlyHousing;
    _initMonthlyMarriage = _settings!.monthlyMarriage;
    _initMonthlyChild = _settings!.monthlyChild;
    _initDailySeniority = _settings!.dailySeniority;
    _initSalaryRateA = _settings!.salaryRateA;
    _initSalaryRateB = _settings!.salaryRateB;
    _initFixedRial = _settings!.fixedRial;
    _initEmployeeInsuranceRate = _settings!.employeeInsuranceRate;
    _initEmployerInsuranceRate = _settings!.employerInsuranceRate;
    _initUnemploymentInsuranceRate = _settings!.unemploymentInsuranceRate;
    _initTwoSevenBaseRate = _settings!.twoSevenBaseRate;
    _initMonthlyLeaveAllowance = _settings!.monthlyLeaveAllowance;
    _initAnnualLeaveAllowance = _settings!.annualLeaveAllowance;
    _initNightWorkRate = _settings!.nightWorkRate;
    _initFridayWorkRate = _settings!.fridayWorkRate;
    _initHolidayWorkMultiplier = _settings!.holidayWorkMultiplier;
    _initMissionDailyMultiplier = _settings!.missionDailyMultiplier;
    _initAbsenceHourlyMultiplier = _settings!.absenceHourlyMultiplier;

    _hasLocalCredential = await _security.hasCredential();
    _localMethod = await _security.getMethod();
    _biometricEnabled = await _security.biometricsEnabled();
    if (Platform.isWindows) {
      _closeBehavior = await WindowClosePreferences.getBehavior();
    }
    _updatePreferences = await _updateService.loadPreferences();
    if (mounted) setState(() => _loading = false);
  }

  void _checkChanges() {
    if (!mounted) return;
    final changed =
        _dailyWage != _initDailyWage ||
        _monthlyFood != _initMonthlyFood ||
        _monthlyHousing != _initMonthlyHousing ||
        _monthlyMarriage != _initMonthlyMarriage ||
        _monthlyChild != _initMonthlyChild ||
        _dailySeniority != _initDailySeniority ||
        _salaryRateA != _initSalaryRateA ||
        _salaryRateB != _initSalaryRateB ||
        _fixedRial != _initFixedRial ||
        _employeeInsuranceRate != _initEmployeeInsuranceRate ||
        _employerInsuranceRate != _initEmployerInsuranceRate ||
        _unemploymentInsuranceRate != _initUnemploymentInsuranceRate ||
        _twoSevenBaseRate != _initTwoSevenBaseRate ||
        _monthlyLeaveAllowance != _initMonthlyLeaveAllowance ||
        _annualLeaveAllowance != _initAnnualLeaveAllowance ||
        _nightWorkRate != _initNightWorkRate ||
        _fridayWorkRate != _initFridayWorkRate ||
        _holidayWorkMultiplier != _initHolidayWorkMultiplier ||
        _missionDailyMultiplier != _initMissionDailyMultiplier ||
        _absenceHourlyMultiplier != _initAbsenceHourlyMultiplier;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  void _setMonthlyLeaveAllowance(num? value) {
    _monthlyLeaveAllowance = value?.toDouble() ?? 0;
    _annualLeaveAllowance = _monthlyLeaveAllowance * 12;
    _checkChanges();
    if (mounted) setState(() {});
  }

  void _setAnnualLeaveAllowance(num? value) {
    _annualLeaveAllowance = value?.toDouble() ?? 0;
    _monthlyLeaveAllowance = _annualLeaveAllowance / 12;
    _checkChanges();
    if (mounted) setState(() {});
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغییرات ذخیره نشده'),
        content: const Text(
          'تغییراتی اعمال کرده‌اید که ذخیره نشده است. آیا می‌خواهید بدون ذخیره خارج شوید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ماندن'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('خروج بدون ذخیره'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    SyncService().dataVersion.removeListener(_onSyncedDataChanged);
    _companyNameCtrl.dispose();
    super.dispose();
  }

  void _onSyncedDataChanged() {
    if (_saving || _hasChanges) return;
    unawaited(_load());
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _settings!.copyWith(
        companyName: _settings!.companyName,
        dailyWage: _dailyWage,
        monthlyFood: _monthlyFood,
        monthlyHousing: _monthlyHousing,
        monthlyMarriage: _monthlyMarriage,
        monthlyChild: _monthlyChild,
        dailySeniority: _dailySeniority,
        salaryRateA: _salaryRateA,
        salaryRateB: _salaryRateB,
        fixedRial: _fixedRial,
        employeeInsuranceRate: _employeeInsuranceRate,
        employerInsuranceRate: _employerInsuranceRate,
        unemploymentInsuranceRate: _unemploymentInsuranceRate,
        twoSevenBaseRate: _twoSevenBaseRate,
        monthlyLeaveAllowance: _monthlyLeaveAllowance,
        annualLeaveAllowance: _annualLeaveAllowance,
        nightWorkRate: _nightWorkRate,
        fridayWorkRate: _fridayWorkRate,
        holidayWorkMultiplier: _holidayWorkMultiplier,
        missionDailyMultiplier: _missionDailyMultiplier,
        absenceHourlyMultiplier: _absenceHourlyMultiplier,
      );
      await _service.update(updated);
      _initDailyWage = updated.dailyWage;
      _initMonthlyFood = updated.monthlyFood;
      _initMonthlyHousing = updated.monthlyHousing;
      _initMonthlyMarriage = updated.monthlyMarriage;
      _initMonthlyChild = updated.monthlyChild;
      _initDailySeniority = updated.dailySeniority;
      _initSalaryRateA = updated.salaryRateA;
      _initSalaryRateB = updated.salaryRateB;
      _initFixedRial = updated.fixedRial;
      _initEmployeeInsuranceRate = updated.employeeInsuranceRate;
      _initEmployerInsuranceRate = updated.employerInsuranceRate;
      _initUnemploymentInsuranceRate = updated.unemploymentInsuranceRate;
      _initTwoSevenBaseRate = updated.twoSevenBaseRate;
      _initMonthlyLeaveAllowance = updated.monthlyLeaveAllowance;
      _initAnnualLeaveAllowance = updated.annualLeaveAllowance;
      _initNightWorkRate = updated.nightWorkRate;
      _initFridayWorkRate = updated.fridayWorkRate;
      _initHolidayWorkMultiplier = updated.holidayWorkMultiplier;
      _initMissionDailyMultiplier = updated.missionDailyMultiplier;
      _initAbsenceHourlyMultiplier = updated.absenceHourlyMultiplier;
      _hasChanges = false;
      if (!mounted) return;
      AppNotification.success(context, 'تنظیمات با موفقیت ذخیره شد');
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(
        context,
        AppErrorMessage.from(
          e,
          fallback: 'ذخیره تنظیمات انجام نشد. مقادیر را بررسی کنید.',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازنشانی تنظیمات'),
        content: const Text(
          'آیا از بازنشانی تنظیمات به مقادیر پیش‌فرض ۱۴۰۵ مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بازنشانی'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.resetToDefaults();
        await _load();
        if (!mounted) return;
        AppNotification.success(context, 'تنظیمات بازنشانی شد');
      } catch (error) {
        if (!mounted) return;
        AppNotification.error(
          context,
          AppErrorMessage.from(error, fallback: 'بازنشانی تنظیمات انجام نشد.'),
        );
      }
    }
  }

  Future<void> _backup() async {
    try {
      final path = await _backupService.backupDatabase();
      if (!mounted || path == null) return;
      AppNotification.success(context, 'بکاپ ذخیره شد: $path');
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(
        context,
        AppErrorMessage.from(e, fallback: 'ساخت فایل بکاپ انجام نشد.'),
      );
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی بکاپ'),
        content: const Text(
          'با ریستور بکاپ، دیتابیس فعلی جایگزین می‌شود. بهتر است قبل از ادامه از دیتای فعلی بکاپ بگیرید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('انتخاب بکاپ'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final path = await _backupService.restoreDatabase();
      if (!mounted || path == null) return;
      await _load();
      if (!mounted) return;
      AppNotification.success(context, 'بکاپ بازیابی شد: $path');
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(
        context,
        AppErrorMessage.from(e, fallback: 'بازیابی فایل بکاپ انجام نشد.'),
      );
    }
  }

  Future<void> _serverBackup() async {
    try {
      final response = await _apiClient.get('/api/sync/backup');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_apiErrorFrom(response), response.statusCode);
      }
      final path = await _backupService.saveServerBackup(response.body);
      if (!mounted || path == null) return;
      AppNotification.success(context, 'بکاپ سرور ذخیره شد: $path');
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(
        context,
        AppErrorMessage.from(e, fallback: 'دریافت بکاپ سرور انجام نشد.'),
      );
    }
  }

  Future<void> _serverRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ریستور بکاپ سرور'),
        content: const Text(
          'با ریستور سروری، داده‌های شرکت روی سرور با فایل بکاپ جایگزین می‌شود و سپس برنامه همگام‌سازی می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('انتخاب بکاپ'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final password = await _askServerBackupPassword();
      if (password == null || password.isEmpty) return;
      final raw = await _backupService.pickServerBackupFile();
      if (raw == null || raw.trim().isEmpty) return;
      final response = await _apiClient.post('/api/sync/restore', {
        'backup_file': raw,
        'password': password,
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_apiErrorFrom(response), response.statusCode);
      }
      await SyncService().syncNow();
      await _load();
      if (!mounted) return;
      AppNotification.success(context, 'بکاپ سرور با موفقیت ریستور شد');
    } catch (e) {
      if (!mounted) return;
      AppNotification.error(
        context,
        AppErrorMessage.from(e, fallback: 'بازیابی بکاپ سرور انجام نشد.'),
      );
    }
  }

  Future<String?> _askServerBackupPassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز فایل بکاپ سرور'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          decoration: const InputDecoration(
            labelText: 'رمز بکاپ شرکت',
            prefixIcon: Icon(Icons.key_rounded),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ادامه'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _changeLocalCredential() async {
    if (!mounted) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocalUnlockSetupScreen(returnToPrevious: true),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _toggleBiometrics() async {
    if (!_hasLocalCredential) {
      AppNotification.warning(context, 'ابتدا رمز محلی برنامه را بسازید');
      return;
    }
    final next = !await _security.biometricsEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hvm_biometric_enabled_v1', next);
    setState(() => _biometricEnabled = next);
  }

  Future<void> _clearLocalCredential() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف رمز محلی'),
        content: const Text(
          'با حذف رمز محلی، ورود بعدی دوباره ساخت رمز PIN یا Password را درخواست می‌کند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _security.clearCredential();
    setState(() {
      _hasLocalCredential = false;
      _localMethod = null;
      _biometricEnabled = false;
    });
  }

  Future<void> _setCloseBehavior(WindowCloseBehavior behavior) async {
    await WindowClosePreferences.setBehavior(behavior);
    if (!mounted) return;
    setState(() => _closeBehavior = behavior);
  }

  Future<void> _setUpdatePreferences(UpdatePreferences preferences) async {
    final saved = await _updateService.savePreferences(preferences);
    if (!mounted) return;
    setState(() => _updatePreferences = saved);
  }

  Future<void> _checkUpdateNow() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    try {
      await _updateService.checkAndPrompt(context);
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _changeServerAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از حساب سرور'),
        content: const Text(
          'برای تغییر حساب باید از حساب فعلی خارج شوید و دوباره وارد شوید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _apiClient.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ServerLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (!context.mounted) return;
        if (shouldPop) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظیمات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.restore_rounded),
              tooltip: 'بازنشانی به مقادیر پیش‌فرض',
              onPressed: _resetDefaults,
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FilledButton.icon(
                  onPressed: _hasChanges ? _save : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('ذخیره'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 1100;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  desktop ? 28 : 16,
                  desktop ? 24 : 16,
                  desktop ? 28 : 16,
                  80,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desktop ? 1280 : 1100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeInUp(child: _buildInfoBanner()),
                        const SizedBox(height: 22),
                        FadeInUp(
                          delay: const Duration(milliseconds: 80),
                          child: _SettingsGroupSection(
                            title: 'تنظیمات حقوق و دستمزد',
                            subtitle:
                                'مقادیر پایه، بیمه، مالیات، کارکرد و مرخصی که در صدور فیش استفاده می‌شوند',
                            icon: Icons.payments_rounded,
                            accent: Theme.of(context).colorScheme.primary,
                            children: _buildPayrollSettingsCards(),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeInUp(
                          delay: const Duration(milliseconds: 160),
                          child: _SettingsGroupSection(
                            title: 'تنظیمات برنامه',
                            subtitle:
                                'امنیت، ظاهر، دسترسی‌پذیری، آپدیت و پشتیبان‌گیری برنامه',
                            icon: Icons.settings_rounded,
                            accent: Theme.of(context).colorScheme.secondary,
                            children: _buildApplicationSettingsCards(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPayrollSettingsCards() {
    final scheme = Theme.of(context).colorScheme;
    return [
      _section(
        title: 'اطلاعات کلی',
        subtitle: 'شناسه شرکت و اطلاعات پایه پرونده حقوق',
        icon: Icons.business_rounded,
        color: scheme.tertiary,
        initiallyExpanded: true,
        children: [
          TextFormField(
            controller: _companyNameCtrl,
            enabled: false,
            inputFormatters: const [PersianDigitsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'نام شرکت',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
          ),
        ],
      ),
      _section(
        title: 'حقوق و دستمزد پایه',
        subtitle: 'مبالغ ثابت مصوب که در محاسبه ماهانه استفاده می‌شوند',
        icon: Icons.payments_rounded,
        color: scheme.primary,
        initiallyExpanded: true,
        children: [
          _row([
            PersianNumberField(
              label: 'دستمزد روزانه پایه',
              isCurrency: true,
              prefixIcon: Icons.attach_money_rounded,
              initialValue: _dailyWage,
              onChanged: (v) {
                _dailyWage = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'پایه سنوات (روزانه)',
              isCurrency: true,
              prefixIcon: Icons.workspace_premium_rounded,
              initialValue: _dailySeniority,
              onChanged: (v) {
                _dailySeniority = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          _row([
            PersianNumberField(
              label: 'حق مسکن (ماهانه)',
              isCurrency: true,
              prefixIcon: Icons.home_rounded,
              initialValue: _monthlyHousing,
              onChanged: (v) {
                _monthlyHousing = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'حق خواروبار / بن (ماهانه)',
              isCurrency: true,
              prefixIcon: Icons.shopping_basket_rounded,
              initialValue: _monthlyFood,
              onChanged: (v) {
                _monthlyFood = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          _row([
            PersianNumberField(
              label: 'حق تاهل (ماهانه)',
              isCurrency: true,
              prefixIcon: Icons.favorite_rounded,
              initialValue: _monthlyMarriage,
              onChanged: (v) {
                _monthlyMarriage = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'حق فرزند (ماهانه - هر فرزند)',
              isCurrency: true,
              prefixIcon: Icons.child_care_rounded,
              initialValue: _monthlyChild,
              onChanged: (v) {
                _monthlyChild = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
        ],
      ),
      _section(
        title: 'ضرایب افزایش دستمزد ۱۴۰۵',
        subtitle: 'فرمول تبدیل دستمزد سال قبل به سال جاری',
        icon: Icons.trending_up_rounded,
        color: scheme.tertiary,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: scheme.tertiary.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.info_rounded, color: scheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'فرمول: دستمزد ۱۴۰۵ = دستمزد ۱۴۰۴ × ضریب + ثابت ریالی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _row([
            PersianNumberField(
              label: 'ضریب الف (کارگری)',
              prefixIcon: Icons.engineering_rounded,
              initialValue: _salaryRateA,
              onChanged: (v) {
                _salaryRateA = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'ضریب ب (سایر سطوح)',
              prefixIcon: Icons.work_rounded,
              initialValue: _salaryRateB,
              onChanged: (v) {
                _salaryRateB = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          PersianNumberField(
            label: 'ثابت ریالی',
            isCurrency: true,
            prefixIcon: Icons.add_rounded,
            initialValue: _fixedRial,
            onChanged: (v) {
              _fixedRial = v?.toDouble() ?? 0;
              _checkChanges();
            },
          ),
        ],
      ),
      _section(
        title: 'بیمه تامین اجتماعی',
        subtitle: 'نرخ سهم کارمند، کارفرما و بیمه بیکاری',
        icon: Icons.health_and_safety_rounded,
        color: scheme.secondary,
        children: [
          _row([
            PersianNumberField(
              label: 'سهم کارمند (۰.۰۷ = ۷٪)',
              prefixIcon: Icons.person_rounded,
              initialValue: _employeeInsuranceRate,
              onChanged: (v) {
                _employeeInsuranceRate = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'سهم کارفرما (۰.۲۰ = ۲۰٪)',
              prefixIcon: Icons.business_rounded,
              initialValue: _employerInsuranceRate,
              onChanged: (v) {
                _employerInsuranceRate = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          PersianNumberField(
            label: 'بیمه بیکاری (۰.۰۳ = ۳٪)',
            prefixIcon: Icons.work_off_rounded,
            initialValue: _unemploymentInsuranceRate,
            onChanged: (v) {
              _unemploymentInsuranceRate = v?.toDouble() ?? 0;
              _checkChanges();
            },
          ),
        ],
      ),
      _section(
        title: 'ضرایب کارکرد و ماموریت',
        subtitle:
            'نرخ‌های قابل ویرایش برای شب کاری، جمعه کاری، تعطیل کاری، ماموریت و غیبت',
        icon: Icons.event_repeat_rounded,
        color: scheme.primary,
        children: [
          _row([
            PersianNumberField(
              label: 'شب کاری (۰.۳۵ = ۳۵٪)',
              prefixIcon: Icons.dark_mode_rounded,
              initialValue: _nightWorkRate,
              onChanged: (v) {
                _nightWorkRate = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'جمعه کاری (۰.۴۰ = ۴۰٪)',
              prefixIcon: Icons.weekend_rounded,
              initialValue: _fridayWorkRate,
              onChanged: (v) {
                _fridayWorkRate = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          _row([
            PersianNumberField(
              label: 'ضریب تعطیل کاری',
              prefixIcon: Icons.event_busy_rounded,
              initialValue: _holidayWorkMultiplier,
              onChanged: (v) {
                _holidayWorkMultiplier = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
            PersianNumberField(
              label: 'ضریب روز ماموریت',
              prefixIcon: Icons.business_center_rounded,
              initialValue: _missionDailyMultiplier,
              onChanged: (v) {
                _missionDailyMultiplier = v?.toDouble() ?? 0;
                _checkChanges();
              },
            ),
          ]),
          const SizedBox(height: 14),
          PersianNumberField(
            label: 'ضریب کسر ساعت غیبت',
            prefixIcon: Icons.timer_off_rounded,
            initialValue: _absenceHourlyMultiplier,
            onChanged: (v) {
              _absenceHourlyMultiplier = v?.toDouble() ?? 0;
              _checkChanges();
            },
          ),
        ],
      ),
      _section(
        title: 'معافیت مالیاتی دو هفتم',
        subtitle: 'ضریب معافیت قابل اعمال برای صنایع سخت',
        icon: Icons.discount_rounded,
        color: scheme.tertiary,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.info_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'این معافیت برای شاغلین در صنایع سخت اعمال می‌شود. طبق فایل اکسل، مبلغ معافیت برابر دو هفتم حق بیمه کارگر است.',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PersianNumberField(
            label: 'ضریب معافیت دو هفتم بیمه (مثلاً ۰.۲۸۵۷)',
            prefixIcon: Icons.percent_rounded,
            initialValue: _twoSevenBaseRate,
            onChanged: (v) {
              _twoSevenBaseRate = v?.toDouble() ?? 0;
              _checkChanges();
            },
          ),
        ],
      ),
      _section(
        title: 'جدول مالیات بر حقوق ۱۴۰۵',
        subtitle: 'پله‌های مالیاتی ماهانه و نرخ هر بازه',
        icon: Icons.account_balance_rounded,
        color: scheme.error,
        children: [_buildTaxBracketTable()],
      ),
      _section(
        title: 'مرخصی کارکنان',
        subtitle: 'سقف مرخصی استحقاقی ماهانه و سالانه',
        icon: Icons.beach_access_rounded,
        color: AppTheme.successColor,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'سقف پیش‌فرض مرخصی استحقاقی ۲.۵ روز در ماه است که در سال برابر ۳۰ روز می‌شود. هر دو مقدار قابل ویرایش هستند و مقدار مقابل به صورت خودکار محاسبه می‌شود.',
            ),
          ),
          const SizedBox(height: 14),
          _row([
            PersianNumberField(
              label: 'مرخصی مجاز ماهانه',
              prefixIcon: Icons.calendar_view_month_rounded,
              suffix: 'روز',
              initialValue: _monthlyLeaveAllowance,
              onChanged: _setMonthlyLeaveAllowance,
            ),
            PersianNumberField(
              label: 'مرخصی مجاز سالانه',
              prefixIcon: Icons.event_available_rounded,
              suffix: 'روز',
              initialValue: _annualLeaveAllowance,
              onChanged: _setAnnualLeaveAllowance,
            ),
          ]),
        ],
      ),
    ];
  }

  List<Widget> _buildApplicationSettingsCards() {
    return [
      _SecuritySection(
        hasCredential: _hasLocalCredential,
        method: _localMethod,
        biometricEnabled: _biometricEnabled,
        onChangeCredential: _changeLocalCredential,
        onToggleBiometrics: _toggleBiometrics,
        onClearCredential: _clearLocalCredential,
        onChangeServerAccount: _changeServerAccount,
      ),
      _UpdateSection(
        preferences: _updatePreferences,
        checking: _checkingUpdate,
        onAutoCheckChanged: (value) => _setUpdatePreferences(
          _updatePreferences.copyWith(autoCheck: value),
        ),
        onAutoDownloadChanged: (value) => _setUpdatePreferences(
          _updatePreferences.copyWith(autoDownload: value),
        ),
        onCheckNow: _checkUpdateNow,
      ),
      if (Platform.isWindows)
        _WindowCloseSection(
          selected: _closeBehavior,
          onChanged: _setCloseBehavior,
        ),
      const _ColorSection(),
      const _AccessibilitySection(),
      _BackupSection(
        onBackup: _backup,
        onRestore: _restore,
        onServerBackup: _serverBackup,
        onServerRestore: _serverRestore,
      ),
      const _AboutSection(),
    ];
  }

  Widget _buildInfoBanner() {
    final scheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final isMobile = r.isMobileSize;
    final icon = Container(
      width: isMobile ? 48 : 56,
      height: isMobile ? 48 : 56,
      decoration: BoxDecoration(
        color: context.onGradientOverlayStrong,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
      ),
      child: Icon(
        Icons.tune_rounded,
        color: context.onGradientText,
        size: isMobile ? 26 : 32,
      ),
    );
    final titleStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      color: context.onGradientText,
      fontSize: isMobile ? 16 : 20,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = TextStyle(
      fontFamily: 'Vazirmatn',
      color: context.onGradientTextMuted,
      fontSize: isMobile ? 12 : 13,
      height: 1.6,
    );
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('تنظیمات سال ۱۴۰۵', style: titleStyle),
        const SizedBox(height: 6),
        Text(
          'این مقادیر بر اساس مصوبه شورای عالی کار سال ۱۴۰۵ به صورت پیش‌فرض تنظیم شده‌اند.\nدر صورت تغییر، می‌توانید مقادیر را ویرایش کنید.',
          style: bodyStyle,
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevation2(scheme.shadow),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('تنظیمات سال ۱۴۰۵', style: titleStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'این مقادیر بر اساس مصوبه شورای عالی کار سال ۱۴۰۵ به صورت پیش‌فرض تنظیم شده‌اند.\nدر صورت تغییر، می‌توانید مقادیر را ویرایش کنید.',
                  style: bodyStyle,
                ),
              ],
            )
          : Row(
              textDirection: TextDirection.rtl,
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(child: textColumn),
              ],
            ),
    );
  }

  Widget _buildTaxBracketTable() {
    final scheme = Theme.of(context).colorScheme;
    final brackets = [
      ('۰', '۴۰۰,۰۰۰,۰۰۰', '۰٪', 'معاف'),
      ('۴۰۰,۰۰۰,۰۰۱', '۸۰۰,۰۰۰,۰۰۰', '۱۰٪', ''),
      ('۸۰۰,۰۰۰,۰۰۱', '۱,۰۰۰,۰۰۰,۰۰۰', '۱۵٪', ''),
      ('۱,۰۰۰,۰۰۰,۰۰۱', '۱۲,۰۰۰,۰۰۰,۰۰۰', '۲۰٪', ''),
      ('۱۲,۰۰۰,۰۰۰,۰۰۱', '۱۴,۰۰۰,۰۰۰,۰۰۰', '۲۵٪', ''),
      ('۱۴,۰۰۰,۰۰۰,۰۰۱', 'بیشتر', '۳۰٪', ''),
    ];
    return Table(
      border: TableBorder.all(color: scheme.outlineVariant),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.4),
          ),
          children: const [
            _TaxCell('از (ریال)', isHeader: true),
            _TaxCell('تا (ریال)', isHeader: true),
            _TaxCell('نرخ', isHeader: true),
            _TaxCell('وضعیت', isHeader: true),
          ],
        ),
        ...brackets.map(
          (b) => TableRow(
            children: [
              _TaxCell(b.$1),
              _TaxCell(b.$2),
              _TaxCell(b.$3),
              _TaxCell(b.$4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return _SettingsAccordionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: color,
      initiallyExpanded: initiallyExpanded,
      children: children,
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 500) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        final widgets = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          widgets.add(Expanded(child: children[i]));
          if (i < children.length - 1) widgets.add(const SizedBox(width: 14));
        }
        return Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );
      },
    );
  }
}

class _TaxCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _TaxCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        PersianNumberFormatter.toPersian(text),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? scheme.onErrorContainer : scheme.onSurface,
        ),
      ),
    );
  }
}

class _SettingsGroupSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  const _SettingsGroupSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.children,
  });

  int _settingsColumnCount(double width) {
    if (width >= 1120) return 3;
    if (width >= 740) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 12),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        height: 1.55,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = _settingsColumnCount(constraints.maxWidth);
            final gap = columns == 1 ? 12.0 : 16.0;
            final itemWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;
            return Wrap(
              textDirection: TextDirection.rtl,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final child in children)
                  SizedBox(width: itemWidth, child: child),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SettingsAccordionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _SettingsAccordionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('settings-section-$title'),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsetsDirectional.fromSTEB(18, 12, 16, 12),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          iconColor: accent,
          collapsedIconColor: scheme.onSurfaceVariant,
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        height: 1.45,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// -------- بخش دسترسی‌پذیری --------
class _AccessibilitySection extends StatelessWidget {
  const _AccessibilitySection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<ThemeController>();
    final a = controller.accessibility;
    return _SettingsAccordionCard(
      title: 'دسترسی‌پذیری',
      subtitle: 'اندازه متن، کنتراست، فاصله‌ها و کاهش انیمیشن‌ها',
      icon: Icons.accessibility_new_rounded,
      accent: scheme.primary,
      children: [
        _TextScaleTile(
          value: a.textScale,
          onChanged: (v) => controller.updateAccessibility(textScale: v),
        ),
        _InterfaceScaleTile(
          value: a.uiScale,
          onChanged: (v) => controller.updateAccessibility(uiScale: v),
        ),
        _SwitchTile(
          icon: Icons.contrast_rounded,
          title: 'کنتراست بالا',
          subtitle: 'افزایش کنتراست رنگ‌ها برای دید بهتر',
          value: a.highContrast,
          onChanged: (v) => controller.updateAccessibility(highContrast: v),
        ),
        _SwitchTile(
          icon: Icons.motion_photos_pause_rounded,
          title: 'کاهش انیمیشن‌ها',
          subtitle: 'غیرفعال‌سازی انتقال‌ها و انیمیشن‌ها',
          value: a.reduceMotion,
          onChanged: (v) => controller.updateAccessibility(reduceMotion: v),
        ),
        _SwitchTile(
          icon: Icons.touch_app_rounded,
          title: 'دکمه‌های بزرگ',
          subtitle: 'افزایش اندازه دکمه‌ها و کنترل‌ها برای لمس راحت‌تر',
          value: a.largeControls,
          onChanged: (v) => controller.updateAccessibility(largeControls: v),
        ),
        _SwitchTile(
          icon: Icons.space_bar_rounded,
          title: 'فاصله بیشتر بین المان‌ها',
          subtitle: 'افزایش فضای خالی بین آیتم‌ها برای خوانایی بهتر',
          value: a.extraSpacing,
          onChanged: (v) => controller.updateAccessibility(extraSpacing: v),
        ),
        _SwitchTile(
          icon: Icons.volume_up_rounded,
          title: 'راهنمای صفحه‌خوان',
          subtitle: 'نمایش راهنما برای کاربران صفحه‌خوان',
          value: a.screenReaderHints,
          onChanged: (v) =>
              controller.updateAccessibility(screenReaderHints: v),
        ),
        _SwitchTile(
          icon: Icons.emoji_emotions_rounded,
          title: 'برچسب ایموجی‌ها',
          subtitle: 'نمایش متن توصیفی برای ایموجی‌ها',
          value: a.emojiLabels,
          onChanged: (v) => controller.updateAccessibility(emojiLabels: v),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () =>
              controller.setAccessibility(const AccessibilitySettings()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('بازنشانی تنظیمات دسترسی‌پذیری'),
        ),
      ],
    );
  }
}

class _TextScaleTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TextScaleTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ExpressiveScaleTile(
      icon: Icons.text_fields_rounded,
      title: 'اندازه متن',
      subtitle: 'مقیاس متن در کل برنامه',
      accent: scheme.primary,
      value: value,
      min: 0.85,
      max: 1.5,
      divisions: 13,
      leadingIndicator: Text(
        'A',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailingIndicator: Text(
        'A',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _InterfaceScaleTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _InterfaceScaleTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ExpressiveScaleTile(
      icon: Icons.aspect_ratio_rounded,
      title: 'اندازه رابط برنامه',
      subtitle: 'مقیاس همه اجزای برنامه',
      accent: scheme.secondary,
      value: value.clamp(0.8, 1.3).toDouble(),
      min: 0.8,
      max: 1.3,
      divisions: 10,
      commitOnChangeEnd: true,
      leadingIndicator: Icon(
        Icons.crop_free_rounded,
        size: 16,
        color: scheme.onSurfaceVariant,
      ),
      trailingIndicator: Icon(
        Icons.crop_free_rounded,
        size: 26,
        color: scheme.onSurface,
      ),
      onChanged: onChanged,
    );
  }
}

class _ExpressiveScaleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Widget leadingIndicator;
  final Widget trailingIndicator;
  final bool commitOnChangeEnd;
  final ValueChanged<double> onChanged;

  const _ExpressiveScaleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.leadingIndicator,
    required this.trailingIndicator,
    required this.onChanged,
    this.commitOnChangeEnd = false,
  });

  @override
  State<_ExpressiveScaleTile> createState() => _ExpressiveScaleTileState();
}

class _ExpressiveScaleTileState extends State<_ExpressiveScaleTile> {
  late double _value = widget.value;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _ExpressiveScaleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.short;
    final percent = _formatPercent(_value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedContainer(
        duration: duration,
        curve: AppAnimations.emphasizedDecelerate,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            widget.accent.withValues(alpha: 0.045),
            scheme.surfaceContainerLow,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: duration,
                    curve: AppAnimations.emphasizedDecelerate,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$percent٪',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: widget.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                label: widget.title,
                value: '$percent درصد',
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Center(child: widget.leadingIndicator),
                    ),
                    Expanded(
                      child: Slider(
                        value: _value,
                        min: widget.min,
                        max: widget.max,
                        divisions: widget.divisions,
                        label: '$percent٪',
                        onChangeStart: (_) => setState(() {
                          _dragging = true;
                        }),
                        onChanged: (value) {
                          setState(() => _value = value);
                          if (!widget.commitOnChangeEnd) {
                            widget.onChanged(value);
                          }
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _dragging = false;
                            _value = value;
                          });
                          if (widget.commitOnChangeEnd) {
                            widget.onChanged(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Center(child: widget.trailingIndicator),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPercent(double value) =>
      PersianNumberFormatter.toPersian((value * 100).round().toString());
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final Color? accent;
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileAccent = accent ?? scheme.primary;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.short;
    return MergeSemantics(
      child: Semantics(
        button: true,
        toggled: value,
        label: title,
        hint: subtitle,
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: enabled ? () => onChanged(!value) : null,
              child: AnimatedContainer(
                duration: duration,
                curve: AppAnimations.emphasizedDecelerate,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: value
                      ? Color.alphaBlend(
                          tileAccent.withValues(alpha: 0.14),
                          scheme.surfaceContainerHigh,
                        )
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: value
                        ? tileAccent.withValues(alpha: 0.45)
                        : scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: value
                            ? tileAccent.withValues(alpha: 0.16)
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: enabled
                            ? (value ? tileAccent : scheme.onSurfaceVariant)
                            : scheme.onSurface.withValues(alpha: 0.38),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              color: enabled
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.48),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              color: enabled
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface.withValues(alpha: 0.38),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: Switch(
                          value: value,
                          onChanged: enabled ? onChanged : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------- بخش امنیت ورود به برنامه --------
class _UpdateSection extends StatelessWidget {
  final UpdatePreferences preferences;
  final bool checking;
  final ValueChanged<bool> onAutoCheckChanged;
  final ValueChanged<bool> onAutoDownloadChanged;
  final VoidCallback onCheckNow;

  const _UpdateSection({
    required this.preferences,
    required this.checking,
    required this.onAutoCheckChanged,
    required this.onAutoDownloadChanged,
    required this.onCheckNow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsAccordionCard(
      title: 'آپدیت برنامه',
      subtitle: 'بررسی و دانلود نسخه‌های جدید ویندوز و اندروید',
      icon: Icons.system_update_alt_rounded,
      accent: scheme.primary,
      children: [
        _SwitchTile(
          icon: Icons.manage_search_rounded,
          title: 'بررسی خودکار هنگام باز شدن برنامه',
          subtitle: 'در هر اجرا، آخرین pre-release گیت‌هاب بررسی می‌شود',
          value: preferences.autoCheck,
          onChanged: onAutoCheckChanged,
        ),
        _SwitchTile(
          icon: Icons.downloading_rounded,
          title: 'دانلود خودکار آپدیت',
          subtitle:
              'پس از پیدا شدن نسخه جدید، فایل نصب به صورت خودکار دانلود می‌شود',
          value: preferences.autoDownload,
          enabled: preferences.autoCheck,
          onChanged: onAutoDownloadChanged,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: checking ? null : onCheckNow,
          icon: checking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.update_rounded),
          label: Text(checking ? 'در حال بررسی...' : 'بررسی آپدیت'),
        ),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final bool hasCredential;
  final LocalCredentialMethod? method;
  final bool biometricEnabled;
  final VoidCallback onChangeCredential;
  final VoidCallback onToggleBiometrics;
  final VoidCallback onClearCredential;
  final VoidCallback onChangeServerAccount;

  const _SecuritySection({
    required this.hasCredential,
    required this.method,
    required this.biometricEnabled,
    required this.onChangeCredential,
    required this.onToggleBiometrics,
    required this.onClearCredential,
    required this.onChangeServerAccount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsAccordionCard(
      title: 'امنیت ورود به برنامه',
      subtitle: 'رمز محلی، ورود بیومتریک و حساب سرور',
      icon: Icons.security_rounded,
      accent: scheme.error,
      children: [
        _SecurityTile(
          icon: hasCredential ? Icons.lock_rounded : Icons.lock_open_rounded,
          title: hasCredential ? 'رمز محلی فعال است' : 'رمز محلی ساخته نشده',
          subtitle: method == null
              ? 'برای ورود به برنامه PIN یا Password تعریف کنید'
              : 'نوع رمز: ${method == LocalCredentialMethod.pin ? 'PIN' : 'Password'}',
          actionLabel: 'تغییر رمز',
          onTap: onChangeCredential,
        ),
        _SecurityTile(
          icon: Icons.fingerprint_rounded,
          title: 'اثر انگشت یا تشخیص چهره',
          subtitle: biometricEnabled
              ? 'برای باز کردن سریع برنامه فعال است'
              : 'بعد از ساخت رمز محلی می‌توانید فعال کنید',
          actionLabel: biometricEnabled ? 'غیرفعال کردن' : 'فعال کردن',
          onTap: onToggleBiometrics,
        ),
        if (hasCredential)
          _SecurityTile(
            icon: Icons.delete_rounded,
            title: 'حذف رمز محلی',
            subtitle: 'ورود بعدی دوباره ساخت رمز را درخواست می‌کند',
            actionLabel: 'حذف',
            destructive: true,
            onTap: onClearCredential,
          ),
        _SecurityTile(
          icon: Icons.account_circle_rounded,
          title: 'حساب سرور',
          subtitle: 'تغییر حساب سروری HvM',
          actionLabel: 'خروج و ورود مجدد',
          destructive: true,
          onTap: onChangeServerAccount,
        ),
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool destructive;
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppDurations.short,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: destructive
                ? scheme.errorContainer.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: destructive
                      ? scheme.errorContainer
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: destructive ? scheme.error : scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: destructive ? scheme.error : scheme.primary,
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// -------- بخش رنگ --------
class _WindowCloseSection extends StatelessWidget {
  final WindowCloseBehavior selected;
  final ValueChanged<WindowCloseBehavior> onChanged;

  const _WindowCloseSection({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsAccordionCard(
      title: 'رفتار بستن پنجره ویندوز',
      subtitle: 'انتخاب حالت خروج، کوچک‌شدن یا پرسش هنگام بستن',
      icon: Icons.system_security_update_good_rounded,
      accent: scheme.primary,
      children: [
        RadioGroup<WindowCloseBehavior>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          child: Column(
            children: [
              for (final behavior in WindowCloseBehavior.values)
                RadioListTile<WindowCloseBehavior>(
                  value: behavior,
                  title: Text(behavior.label),
                  subtitle: Text(behavior.description),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.watch<ThemeController>();
    final colorConfig = controller.colorConfig;
    final supportsDynamic = controller.supportsDynamicColor;

    return _SettingsAccordionCard(
      title: 'ظاهر و رنگ برنامه',
      subtitle: 'تم روشن و تاریک، رنگ پایه و مدل رنگ‌بندی',
      icon: Icons.palette_rounded,
      accent: scheme.tertiary,
      children: [
        const Text(
          'ظاهر برنامه را با رنگ‌های دلخواه خود سفارشی کنید.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        Text(
          'انتخاب تم',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _ThemeSelector(
          selected: controller.themeMode,
          onChanged: (mode) => controller.setThemeMode(mode),
        ),
        const SizedBox(height: 16),
        _SwitchTile(
          icon: Icons.phone_android_rounded,
          title: 'دریافت رنگ اتوماتیک دستگاه',
          subtitle: supportsDynamic
              ? 'استفاده از رنگ پس‌زمینه دستگاه (اندروید ۱۲ و بالاتر)'
              : 'فقط در اندروید ۱۲ و بالاتر در دسترس است',
          value: colorConfig.useDynamicColors && supportsDynamic,
          enabled: supportsDynamic,
          accent: scheme.tertiary,
          onChanged: (v) => controller.updateColorConfig(useDynamicColors: v),
        ),
        if (!colorConfig.useDynamicColors) ...[
          const SizedBox(height: 16),
          Text(
            'نوع رنگ',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _VariantGrid(
            selected: colorConfig.variant,
            onChanged: (v) => controller.updateColorConfig(variant: v),
          ),
          const SizedBox(height: 16),
          Text(
            'رنگ پایه',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _ColorPickerRow(
            selectedColor: colorConfig.seedColor,
            onChanged: (c) =>
                controller.updateColorConfig(seedColorValue: c.toARGB32()),
          ),
        ],
      ],
    );
  }
}

// -------- انتخابگر تم --------
class _ThemeSelector extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('سیستم'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_rounded),
          label: Text('روشن'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_rounded),
          label: Text('تاریک'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

// -------- گرید انتخاب variant --------
class _VariantGrid extends StatelessWidget {
  final DynamicSchemeVariant selected;
  final ValueChanged<DynamicSchemeVariant> onChanged;

  const _VariantGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 400 ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: VariantInfo.all.length,
          itemBuilder: (context, index) {
            final info = VariantInfo.all[index];
            final isSelected = info.variant == selected;
            return InkWell(
              onTap: () => onChanged(info.variant),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            info.persianName,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.description,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        color: isSelected
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.7)
                            : scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------- انتخاب رنگ --------
class _ColorPickerRow extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  const _ColorPickerRow({required this.selectedColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // رنگ‌های پیش‌فرض
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Material3Colors.predefined.map((item) {
            final color = Color(item['color'] as int);
            final isSelected = color.toARGB32() == selectedColor.toARGB32();
            return InkWell(
              onTap: () => onChanged(color),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? scheme.onSurface : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // دکمه انتخاب آزاد
        OutlinedButton.icon(
          onPressed: () => _showColorPicker(context),
          icon: const Icon(Icons.colorize_rounded, size: 18),
          label: Text(
            'انتخاب آزاد رنگ',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    final controller = context.read<ThemeController>();
    Color pickerColor = selectedColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'انتخاب رنگ',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              controller.updateColorConfig(
                seedColorValue: pickerColor.toARGB32(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
}

// -------- بخش بکاپ و بازیابی --------
class _BackupSection extends StatelessWidget {
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onServerBackup;
  final VoidCallback onServerRestore;

  const _BackupSection({
    required this.onBackup,
    required this.onRestore,
    required this.onServerBackup,
    required this.onServerRestore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsAccordionCard(
      title: 'بکاپ و بازیابی اطلاعات',
      subtitle: 'خروجی گرفتن و بازیابی دیتای محلی و سرور',
      icon: Icons.backup_rounded,
      accent: scheme.secondary,
      children: [
        Text(
          'از کل دیتابیس برنامه شامل کارکنان، وام‌ها، تنظیمات و فیش‌های ثبت‌شده فایل بکاپ بگیرید یا فایل بکاپ قبلی را بازیابی کنید.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            final backupButton = FilledButton.icon(
              onPressed: onBackup,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('گرفتن بکاپ'),
            );
            final restoreButton = FilledButton.tonalIcon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_page_rounded),
              label: const Text('ریستور بکاپ'),
            );
            final serverBackupButton = FilledButton.icon(
              onPressed: onServerBackup,
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('بکاپ سرور'),
            );
            final serverRestoreButton = FilledButton.tonalIcon(
              onPressed: onServerRestore,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('ریستور سرور'),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  backupButton,
                  const SizedBox(height: 12),
                  restoreButton,
                  const SizedBox(height: 12),
                  serverBackupButton,
                  const SizedBox(height: 12),
                  serverRestoreButton,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: backupButton),
                    const SizedBox(width: 12),
                    Expanded(child: restoreButton),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: serverBackupButton),
                    const SizedBox(width: 12),
                    Expanded(child: serverRestoreButton),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// -------- بخش درباره --------
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SettingsAccordionCard(
      title: 'درباره برنامه',
      subtitle: 'نسخه، سال مالی و مشخصات برنامه',
      icon: Icons.info_rounded,
      accent: scheme.tertiary,
      children: [
        const _AboutRow(label: 'نام', value: 'HvM'),
        _AboutRow(label: 'نسخه', value: AppConstants.appVersion),
        const _AboutRow(label: 'سال مالی', value: '۱۴۰۵'),
        const _AboutRow(
          label: 'پلتفرم',
          value: 'Flutter (Windows, Android, Linux)',
        ),
        const _AboutRow(label: 'فونت', value: 'Vazirmatn'),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              PersianNumberFormatter.toPersian(value),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _apiErrorFrom(dynamic response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['error']?.toString() ?? 'خطا در ارتباط با سرور';
  } catch (_) {
    return response.body.toString().isEmpty
        ? 'خطا در ارتباط با سرور'
        : response.body.toString();
  }
}
