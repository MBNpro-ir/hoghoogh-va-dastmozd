import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/loan.dart';
import '../models/salary_record.dart';
import '../utils/persian_date_helper.dart';
import 'employee_service.dart';
import 'loan_service.dart';
import 'salary_service.dart';
import 'settings_service.dart';

/// سرویس تجمیع داده برای داشبورد
class DashboardService {
  final EmployeeService _employees = EmployeeService();
  final LoanService _loans = LoanService();
  final SalaryService _salaries = SalaryService();
  final SettingsService _settings = SettingsService();

  /// Snapshot کامل داشبورد
  Future<DashboardSnapshot> loadSnapshot({required int currentYear}) async {
    final now = DateTime.now();
    final settings = await _settings.getCurrentSettings();

    final allEmployees = await _employees.getAll();
    final activeEmployees = await _employees.getAll(onlyActive: true);

    final recordedMonths = await _salaries.getRecordedMonths();
    final hasAnyRecord = recordedMonths.isNotEmpty;

    final currentMonth = PersianDateHelper.currentMonth;
    int targetYear = currentYear;
    int targetMonth = currentMonth;
    if (hasAnyRecord) {
      targetYear = recordedMonths.first.$1;
      targetMonth = recordedMonths.first.$2;
    }

    final currentRecords = await _salaries.getByYearMonth(
      targetYear,
      targetMonth,
    );
    final activeLoans = await _loans.getAll(onlyActive: true);

    // روند ۶ ماه اخیر (از آخرین ماه ثبت‌شده به عقب)
    final monthlyHistory = <MonthlyPoint>[];
    final sortedMonths = [...recordedMonths]
      ..sort((a, b) {
        if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
        return a.$2.compareTo(b.$2);
      });
    final historyMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;
    for (final ym in historyMonths) {
      final recs = await _salaries.getByYearMonth(ym.$1, ym.$2);
      final total = recs.fold<double>(0, (s, r) => s + r.finalPayment);
      final tax = recs.fold<double>(0, (s, r) => s + r.tax);
      final insurance = recs.fold<double>(
        0,
        (s, r) => s + r.insuranceBase * settings.employerInsuranceRate,
      );
      monthlyHistory.add(
        MonthlyPoint(
          year: ym.$1,
          month: ym.$2,
          total: total,
          tax: tax,
          insurance: insurance,
          recordCount: recs.length,
        ),
      );
    }

    // YTD
    final ytdRecords = <SalaryRecord>[];
    for (final ym in sortedMonths) {
      if (ym.$1 == targetYear) {
        final recs = await _salaries.getByYearMonth(ym.$1, ym.$2);
        ytdRecords.addAll(recs);
      }
    }
    final ytdNet = ytdRecords.fold<double>(0, (s, r) => s + r.finalPayment);
    final ytdGross = ytdRecords.fold<double>(0, (s, r) => s + r.totalEarnings);
    final ytdTax = ytdRecords.fold<double>(0, (s, r) => s + r.tax);
    final ytdInsuranceEmployee = ytdRecords.fold<double>(
      0,
      (s, r) => s + r.insurance,
    );
    final ytdInsuranceEmployer = ytdRecords.fold<double>(
      0,
      (s, r) => s + r.insuranceBase * settings.employerInsuranceRate,
    );
    final ytdLoanInstallment = ytdRecords.fold<double>(
      0,
      (s, r) => s + r.loanInstallment,
    );

    // آمار ماه جاری
    final monthNet = currentRecords.fold<double>(
      0,
      (s, r) => s + r.finalPayment,
    );
    final monthGross = currentRecords.fold<double>(
      0,
      (s, r) => s + r.totalEarnings,
    );
    final monthTax = currentRecords.fold<double>(0, (s, r) => s + r.tax);
    final monthInsuranceEmployee = currentRecords.fold<double>(
      0,
      (s, r) => s + r.insurance,
    );
    final monthInsuranceEmployer = currentRecords.fold<double>(
      0,
      (s, r) => s + r.insuranceBase * settings.employerInsuranceRate,
    );
    final monthLoanInstallment = currentRecords.fold<double>(
      0,
      (s, r) => s + r.loanInstallment,
    );
    final monthOvertime = currentRecords.fold<double>(
      0,
      (s, r) => s + r.overtimeAmount,
    );

    final avgNet = currentRecords.isEmpty
        ? 0.0
        : monthNet / currentRecords.length;
    final maxNet = currentRecords.isEmpty
        ? 0.0
        : currentRecords
              .map((r) => r.finalPayment)
              .reduce((a, b) => a > b ? a : b);

    // آخرین فیش‌ها
    final recentRecords = [...currentRecords]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final topEarners = [...currentRecords]
      ..sort((a, b) => b.finalPayment.compareTo(a.finalPayment));

    // آمار کارمندان
    final marriedCount = activeEmployees.where((e) => e.isMarried).length;
    final withChildren = activeEmployees
        .where((e) => e.childrenCount > 0)
        .length;
    final priorExp = activeEmployees.where((e) => e.hasPriorExperience).length;

    // آمار وام
    final totalActiveLoanAmount = activeLoans.fold<double>(
      0,
      (s, l) => s + l.amount,
    );
    final totalRemainingLoan = activeLoans.fold<double>(
      0,
      (s, l) => s + l.remainingAmount,
    );
    final totalPaidLoan = activeLoans.fold<double>(
      0,
      (s, l) => s + l.deductedAmount,
    );
    final monthlyInstallmentSum = activeLoans.fold<double>(
      0,
      (s, l) => s + l.nextInstallmentAmount,
    );
    final loanProgress = totalActiveLoanAmount == 0
        ? 0.0
        : (totalPaidLoan / totalActiveLoanAmount).clamp(0.0, 1.0);

    // نام ماه
    const monthNames = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return DashboardSnapshot(
      settings: settings,
      targetYear: targetYear,
      targetMonth: targetMonth,
      targetLabel: '${monthNames[targetMonth]} $targetYear',
      now: now,
      employees: allEmployees,
      activeEmployees: activeEmployees,
      marriedCount: marriedCount,
      withChildrenCount: withChildren,
      priorExperienceCount: priorExp,
      currentRecords: currentRecords,
      hasAnyRecord: hasAnyRecord,
      monthNet: monthNet,
      monthGross: monthGross,
      monthTax: monthTax,
      monthInsuranceEmployee: monthInsuranceEmployee,
      monthInsuranceEmployer: monthInsuranceEmployer,
      monthLoanInstallment: monthLoanInstallment,
      monthOvertime: monthOvertime,
      monthRecordCount: currentRecords.length,
      avgNet: avgNet,
      maxNet: maxNet,
      activeLoans: activeLoans,
      totalActiveLoanAmount: totalActiveLoanAmount,
      totalRemainingLoan: totalRemainingLoan,
      totalPaidLoan: totalPaidLoan,
      monthlyInstallmentSum: monthlyInstallmentSum,
      loanProgress: loanProgress,
      monthlyHistory: monthlyHistory,
      recentRecords: recentRecords.take(5).toList(),
      topEarners: topEarners.take(5).toList(),
      ytdNet: ytdNet,
      ytdGross: ytdGross,
      ytdTax: ytdTax,
      ytdInsuranceEmployee: ytdInsuranceEmployee,
      ytdInsuranceEmployer: ytdInsuranceEmployer,
      ytdLoanInstallment: ytdLoanInstallment,
    );
  }
}

/// نقطه داده برای نمودار ماهانه
class MonthlyPoint {
  final int year;
  final int month;
  final double total;
  final double tax;
  final double insurance;
  final int recordCount;

  const MonthlyPoint({
    required this.year,
    required this.month,
    required this.total,
    required this.tax,
    required this.insurance,
    required this.recordCount,
  });
}

/// Snapshot یکجا از همه داده‌های داشبورد
class DashboardSnapshot {
  final AppSettings settings;
  final int targetYear;
  final int targetMonth;
  final String targetLabel;
  final DateTime now;

  final List<Employee> employees;
  final List<Employee> activeEmployees;
  final int marriedCount;
  final int withChildrenCount;
  final int priorExperienceCount;

  final List<SalaryRecord> currentRecords;
  final bool hasAnyRecord;
  final int monthRecordCount;

  // مبالغ ماه جاری
  final double monthNet;
  final double monthGross;
  final double monthTax;
  final double monthInsuranceEmployee;
  final double monthInsuranceEmployer;
  final double monthLoanInstallment;
  final double monthOvertime;
  final double avgNet;
  final double maxNet;

  // وام
  final List<Loan> activeLoans;
  final double totalActiveLoanAmount;
  final double totalRemainingLoan;
  final double totalPaidLoan;
  final double monthlyInstallmentSum;
  final double loanProgress;

  // تاریخچه و لیست‌ها
  final List<MonthlyPoint> monthlyHistory;
  final List<SalaryRecord> recentRecords;
  final List<SalaryRecord> topEarners;

  // YTD
  final double ytdNet;
  final double ytdGross;
  final double ytdTax;
  final double ytdInsuranceEmployee;
  final double ytdInsuranceEmployer;
  final double ytdLoanInstallment;

  const DashboardSnapshot({
    required this.settings,
    required this.targetYear,
    required this.targetMonth,
    required this.targetLabel,
    required this.now,
    required this.employees,
    required this.activeEmployees,
    required this.marriedCount,
    required this.withChildrenCount,
    required this.priorExperienceCount,
    required this.currentRecords,
    required this.hasAnyRecord,
    required this.monthRecordCount,
    required this.monthNet,
    required this.monthGross,
    required this.monthTax,
    required this.monthInsuranceEmployee,
    required this.monthInsuranceEmployer,
    required this.monthLoanInstallment,
    required this.monthOvertime,
    required this.avgNet,
    required this.maxNet,
    required this.activeLoans,
    required this.totalActiveLoanAmount,
    required this.totalRemainingLoan,
    required this.totalPaidLoan,
    required this.monthlyInstallmentSum,
    required this.loanProgress,
    required this.monthlyHistory,
    required this.recentRecords,
    required this.topEarners,
    required this.ytdNet,
    required this.ytdGross,
    required this.ytdTax,
    required this.ytdInsuranceEmployee,
    required this.ytdInsuranceEmployer,
    required this.ytdLoanInstallment,
  });
}
