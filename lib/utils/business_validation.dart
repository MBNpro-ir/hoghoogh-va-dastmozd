import '../models/advance_payment.dart';
import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/employee_leave.dart';
import '../models/loan.dart';
import '../models/salary_draft.dart';
import '../models/salary_record.dart';
import 'persian_date_helper.dart';

class BusinessValidationException implements Exception {
  final String message;

  const BusinessValidationException(this.message);

  @override
  String toString() => message;
}

class BusinessValidation {
  const BusinessValidation._();

  static void employee(Employee employee) {
    if (employee.personnelCode <= 0) {
      throw const BusinessValidationException(
        'کد پرسنلی باید عددی بزرگ‌تر از صفر باشد.',
      );
    }
    if (employee.firstName.trim().isEmpty || employee.lastName.trim().isEmpty) {
      throw const BusinessValidationException(
        'نام و نام خانوادگی کارمند الزامی است.',
      );
    }
    if (!RegExp(r'^\d{10}$').hasMatch(employee.nationalId.trim())) {
      throw const BusinessValidationException(
        'کد ملی باید دقیقاً ۱۰ رقم باشد.',
      );
    }
    if (employee.childrenCount < 0) {
      throw const BusinessValidationException(
        'تعداد فرزند نمی‌تواند منفی باشد.',
      );
    }
    _nonNegative('مقادیر حقوق و مزایای کارمند', [
      employee.lastYearSeniority,
      employee.baseSalary30Days,
      employee.dailyWage1404,
      employee.dailyWage1405,
      employee.dailyHousing,
      employee.dailyFood,
      employee.dailyMarriage,
      employee.dailyChildAllowance,
      employee.dailySeniority,
      employee.otherBenefitsDaily,
      employee.hourlyBenefits,
    ]);
    if (employee.useCustomOvertimeBase && employee.overtimeBaseDaily <= 0) {
      throw const BusinessValidationException(
        'در حالت مبنای دستی اضافه‌کاری، مبلغ مبنای روزانه باید بیشتر از صفر باشد.',
      );
    }
    final start = PersianDateHelper.parseJalali(employee.startDate);
    if (start == null) {
      throw const BusinessValidationException('تاریخ شروع به کار معتبر نیست.');
    }
    if (employee.birthDate.trim().isNotEmpty &&
        PersianDateHelper.parseJalali(employee.birthDate) == null) {
      throw const BusinessValidationException('تاریخ تولد معتبر نیست.');
    }
    if (!employee.isActive && employee.endDate.trim().isEmpty) {
      throw const BusinessValidationException(
        'برای کارمند غیرفعال، تاریخ ترک کار الزامی است.',
      );
    }
    if (employee.endDate.trim().isNotEmpty) {
      final end = PersianDateHelper.parseJalali(employee.endDate);
      if (end == null || end.toDateTime().isBefore(start.toDateTime())) {
        throw const BusinessValidationException(
          'تاریخ ترک کار نمی‌تواند قبل از تاریخ شروع به کار باشد.',
        );
      }
    }
  }

  static void loan(Loan loan) {
    if (loan.employeeId <= 0) {
      throw const BusinessValidationException('کارمند معتبر انتخاب نشده است.');
    }
    if (loan.loanNumber <= 0 ||
        loan.amount <= 0 ||
        loan.installmentAmount <= 0 ||
        loan.totalInstallments <= 0) {
      throw const BusinessValidationException(
        'مبلغ وام، مبلغ قسط و تعداد اقساط باید بیشتر از صفر باشند.',
      );
    }
    if (loan.paidInstallments < 0 ||
        loan.paidInstallments > loan.totalInstallments) {
      throw const BusinessValidationException(
        'تعداد اقساط پرداخت‌شده باید بین صفر و کل اقساط باشد.',
      );
    }
    _finite('اطلاعات عددی وام', [
      loan.amount,
      loan.installmentAmount,
      loan.totalInstallments,
      loan.paidInstallments,
    ]);
    if (PersianDateHelper.parseJalali(loan.startDate) == null) {
      throw const BusinessValidationException('تاریخ شروع اقساط معتبر نیست.');
    }
  }

  static void advance(AdvancePayment advance) {
    if (advance.employeeId <= 0) {
      throw const BusinessValidationException('کارمند معتبر انتخاب نشده است.');
    }
    if (!advance.amount.isFinite || advance.amount <= 0) {
      throw const BusinessValidationException(
        'مبلغ مساعده باید عددی بزرگ‌تر از صفر باشد.',
      );
    }
    if (PersianDateHelper.parseJalali(advance.paymentDate) == null) {
      throw const BusinessValidationException(
        'تاریخ پرداخت مساعده معتبر نیست.',
      );
    }
  }

  static void leave(EmployeeLeave leave) {
    if (leave.employeeId <= 0) {
      throw const BusinessValidationException('کارمند معتبر انتخاب نشده است.');
    }
    if (!leave.days.isFinite || leave.days <= 0) {
      throw const BusinessValidationException(
        'مدت مرخصی باید عددی بزرگ‌تر از صفر باشد.',
      );
    }
    final from = PersianDateHelper.parseJalali(leave.fromDate);
    final to = PersianDateHelper.parseJalali(leave.toDate);
    if (from == null ||
        to == null ||
        to.toDateTime().isBefore(from.toDateTime())) {
      throw const BusinessValidationException('بازه تاریخ مرخصی معتبر نیست.');
    }
    final calendarDays =
        to.toDateTime().difference(from.toDateTime()).inDays + 1;
    if (leave.days > calendarDays) {
      throw const BusinessValidationException(
        'مدت مرخصی نمی‌تواند از تعداد روزهای بازه انتخاب‌شده بیشتر باشد.',
      );
    }
    if (leave.normalizedType != EmployeeLeave.typeAnnual &&
        leave.normalizedType != EmployeeLeave.typeSick) {
      throw const BusinessValidationException('نوع مرخصی معتبر نیست.');
    }
    if (leave.normalizedStatus != EmployeeLeave.statusApproved &&
        leave.normalizedStatus != EmployeeLeave.statusPending) {
      throw const BusinessValidationException('وضعیت مرخصی معتبر نیست.');
    }
  }

  static void salaryRecord(SalaryRecord record) {
    _payrollPeriod(
      record.employeeId,
      record.year,
      record.month,
      record.totalDays,
    );
    _attendance(record.totalDays, record.leaveDays, record.sickLeaveDays);
    if (record.workDays < 0 || record.workDays > record.totalDays) {
      throw const BusinessValidationException('کارکرد خالص معتبر نیست.');
    }
    if (record.overtimeHours < 0 || record.hourlyBenefitHours < 0) {
      throw const BusinessValidationException(
        'ساعت اضافه‌کاری و مزایای ساعتی نمی‌تواند منفی باشد.',
      );
    }
    if (record.useCustomOvertimeBase && record.overtimeBaseDaily <= 0) {
      throw const BusinessValidationException(
        'مبنای دستی اضافه‌کاری باید بیشتر از صفر باشد.',
      );
    }
    _nonNegative('مبالغ فیش حقوقی', [
      record.baseSalary,
      record.housing,
      record.food,
      record.marriage,
      record.childAllowance,
      record.seniority,
      record.otherBenefits,
      record.totalEarnings,
      record.insurance,
      record.tax,
      record.loanInstallment,
      record.advance,
      record.otherDeductions,
      record.totalDeductions,
      record.insuranceBase,
      record.taxBase,
      record.finalPayment,
    ]);
  }

  static void salaryDraft(SalaryDraft draft) {
    _payrollPeriod(draft.employeeId, draft.year, draft.month, draft.totalDays);
    _attendance(draft.totalDays, draft.leaveDays, draft.sickLeaveDays);
    if (draft.overtimeHours < 0 ||
        draft.hourlyBenefitHours < 0 ||
        draft.overtimeBaseDaily < 0) {
      throw const BusinessValidationException(
        'مقادیر ساعت و مبنای اضافه‌کاری نمی‌تواند منفی باشد.',
      );
    }
    if (draft.useCustomOvertimeBase && draft.overtimeBaseDaily <= 0) {
      throw const BusinessValidationException(
        'مبنای دستی اضافه‌کاری باید بیشتر از صفر باشد.',
      );
    }
    if (draft.otherBenefitsOverride < -1) {
      throw const BusinessValidationException('مبلغ سایر مزایا معتبر نیست.');
    }
    if (draft.dailySeniorityOverride < -1) {
      throw const BusinessValidationException('مبلغ پایه سنوات معتبر نیست.');
    }
    _nonNegative('مبالغ پیش‌نویس حقوق', [
      draft.shiftWork,
      draft.hourlyBenefitsAmount,
      draft.loanInstallment,
      draft.advance,
      draft.otherDeductions,
    ]);
  }

  static void settings(AppSettings settings) {
    if (settings.year < 1200 || settings.year > 1700) {
      throw const BusinessValidationException('سال مالی معتبر نیست.');
    }
    _nonNegative('مبالغ تنظیمات حقوق', [
      settings.dailyWage,
      settings.monthlyFood,
      settings.monthlyHousing,
      settings.monthlyMarriage,
      settings.monthlyChild,
      settings.dailySeniority,
      settings.salaryRateA,
      settings.salaryRateB,
      settings.fixedRial,
      settings.twoSevenBaseRate,
      settings.monthlyLeaveAllowance,
      settings.annualLeaveAllowance,
    ]);
    for (final rate in [
      settings.employeeInsuranceRate,
      settings.employerInsuranceRate,
      settings.unemploymentInsuranceRate,
    ]) {
      if (!rate.isFinite || rate < 0 || rate > 1) {
        throw const BusinessValidationException(
          'نرخ‌های بیمه باید بین صفر و صد درصد باشند.',
        );
      }
    }
    if (settings.monthlyLeaveAllowance > settings.annualLeaveAllowance) {
      throw const BusinessValidationException(
        'سقف مرخصی ماهانه نمی‌تواند از سقف سالانه بیشتر باشد.',
      );
    }
  }

  static void _payrollPeriod(int employeeId, int year, int month, int days) {
    if (employeeId <= 0) {
      throw const BusinessValidationException('کارمند معتبر انتخاب نشده است.');
    }
    if (year < 1200 || year > 1700 || month < 1 || month > 12) {
      throw const BusinessValidationException('دوره حقوق معتبر نیست.');
    }
    if (days <= 0 || days > 31) {
      throw const BusinessValidationException(
        'تعداد روزهای دوره باید بین ۱ تا ۳۱ باشد.',
      );
    }
  }

  static void _attendance(int total, double leave, double sick) {
    if (!leave.isFinite ||
        !sick.isFinite ||
        leave < 0 ||
        sick < 0 ||
        leave + sick > total) {
      throw const BusinessValidationException(
        'جمع مرخصی و استعلاجی باید بین صفر و کل روزهای دوره باشد.',
      );
    }
  }

  static void _finite(String label, Iterable<double> values) {
    if (values.any((value) => !value.isFinite)) {
      throw BusinessValidationException('$label معتبر نیست.');
    }
  }

  static void _nonNegative(String label, Iterable<double> values) {
    _finite(label, values);
    if (values.any((value) => value < 0)) {
      throw BusinessValidationException('$label نمی‌تواند منفی باشد.');
    }
  }
}
