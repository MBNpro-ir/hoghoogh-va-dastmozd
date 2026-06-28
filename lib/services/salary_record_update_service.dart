import '../models/app_settings.dart';
import '../models/employee.dart';
import '../models/salary_record.dart';
import 'advance_service.dart';
import 'employee_leave_service.dart';
import 'loan_service.dart';
import 'salary_calculator.dart';

class SalaryRecordSourceSnapshot {
  static const double _dayTolerance = 0.001;
  static const double _moneyTolerance = 0.5;

  final double leaveDays;
  final double sickLeaveDays;
  final double loanInstallment;
  final double advance;

  const SalaryRecordSourceSnapshot({
    required this.leaveDays,
    required this.sickLeaveDays,
    required this.loanInstallment,
    required this.advance,
  });

  bool hasChangesComparedTo(SalaryRecord record) =>
      changedLabelsComparedTo(record).isNotEmpty;

  List<String> changedLabelsComparedTo(SalaryRecord record) {
    final labels = <String>[];
    if (_daysChanged(record.leaveDays, leaveDays) ||
        _daysChanged(record.sickLeaveDays, sickLeaveDays)) {
      labels.add('مرخصی');
    }
    if (_shouldCompareLoan(record.loanInstallment) &&
        _moneyChanged(record.loanInstallment, loanInstallment)) {
      labels.add('وام');
    }
    if (_moneyChanged(record.advance, advance)) {
      labels.add('مساعده');
    }
    return labels;
  }

  static bool _daysChanged(double saved, double current) =>
      (saved - current).abs() > _dayTolerance;

  static bool _moneyChanged(double saved, double current) =>
      (saved - current).abs() > _moneyTolerance;

  bool _shouldCompareLoan(double savedLoanInstallment) {
    if (loanInstallment > _moneyTolerance) return true;
    return savedLoanInstallment.abs() <= _moneyTolerance;
  }
}

class SalaryRecordUpdateService {
  final EmployeeLeaveService _leaveService;
  final LoanService _loanService;
  final AdvanceService _advanceService;

  SalaryRecordUpdateService({
    EmployeeLeaveService? leaveService,
    LoanService? loanService,
    AdvanceService? advanceService,
  }) : _leaveService = leaveService ?? EmployeeLeaveService(),
       _loanService = loanService ?? LoanService(),
       _advanceService = advanceService ?? AdvanceService();

  Future<SalaryRecordSourceSnapshot> currentSnapshotFor(
    SalaryRecord record,
  ) async {
    final leaves = await _leaveService.totalsForEmployeeYearMonth(
      record.employeeId,
      record.year,
      record.month,
    );
    final loans = await _loanService.getActiveLoansForEmployee(
      record.employeeId,
    );
    final advances = await _advanceService.totalForEmployeeYearMonth(
      record.employeeId,
      record.year,
      record.month,
    );

    return SalaryRecordSourceSnapshot(
      leaveDays: leaves.annual,
      sickLeaveDays: leaves.sick,
      loanInstallment: loans.fold<double>(
        0,
        (sum, loan) => sum + loan.nextInstallmentAmount,
      ),
      advance: advances,
    );
  }

  Future<Map<int, SalaryRecordSourceSnapshot>> outdatedSnapshotsFor(
    List<SalaryRecord> records,
  ) async {
    final entries = await Future.wait(
      records.map((record) async {
        final id = record.id;
        if (id == null) return null;
        final snapshot = await currentSnapshotFor(record);
        if (!snapshot.hasChangesComparedTo(record)) return null;
        return MapEntry(id, snapshot);
      }),
    );

    return {
      for (final entry
          in entries.whereType<MapEntry<int, SalaryRecordSourceSnapshot>>())
        entry.key: entry.value,
    };
  }

  SalaryRecord rebuildRecord({
    required SalaryRecord record,
    required Employee employee,
    required AppSettings settings,
    required SalaryRecordSourceSnapshot snapshot,
  }) {
    final id = record.id;
    if (id == null) {
      throw StateError('Salary record id is required for update.');
    }

    final input = SalaryCalculationInput(
      totalDays: record.totalDays,
      leaveDays: snapshot.leaveDays,
      sickLeaveDays: snapshot.sickLeaveDays,
      overtimeHours: record.overtimeHours,
      useCustomOvertimeBase: record.useCustomOvertimeBase,
      overtimeBaseDaily: record.overtimeBaseDaily,
      shiftWork: record.shiftWork,
      hourlyBenefitsAmount: record.hourlyBenefitsAmount,
      hourlyBenefitHours: record.hourlyBenefitHours,
      autoShiftWork: employee.hasShiftWork && record.shiftWork > 0,
      autoHourlyBenefits: record.hourlyBenefitHours > 0,
      includeLeaveInPayslip: record.includeLeaveInPayslip,
      insuranceExempt: record.insuranceBase == 0 && record.totalEarnings > 0,
      taxExempt: record.tax == 0 && record.totalEarnings > 400000000,
      housingExempt: record.housingExempt,
      foodExempt: record.foodExempt,
      seniorityExempt: record.seniorityExempt,
      otherBenefitsOverride: record.workDays > 0
          ? record.otherBenefits / record.workDays
          : record.otherBenefits,
      loanInstallment: snapshot.loanInstallment,
      advance: snapshot.advance,
      otherDeductions: record.otherDeductions,
    );
    final result = SalaryCalculator.calculate(
      employee: employee,
      settings: settings,
      input: input,
    );
    return result
        .toRecord(
          employeeId: employee.id ?? record.employeeId,
          employeeFullNameSnapshot: employee.fullName,
          employeePersonnelCodeSnapshot: employee.personnelCode,
          employeeNationalIdSnapshot: employee.nationalId,
          employeePayslipFooterNoteSnapshot: employee.payslipFooterNote,
          year: record.year,
          month: record.month,
          totalDays: record.totalDays,
          leaveDays: snapshot.leaveDays,
          sickLeaveDays: snapshot.sickLeaveDays,
          workDays: input.workDays,
          overtimeHours: record.overtimeHours,
          hourlyBenefitHours: record.hourlyBenefitHours,
          includeLeaveInPayslip: record.includeLeaveInPayslip,
          housingExempt: record.housingExempt,
          foodExempt: record.foodExempt,
          seniorityExempt: record.seniorityExempt,
          notes: record.notes,
        )
        .copyWithId(id);
  }
}
