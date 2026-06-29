import '../models/app_settings.dart';
import '../utils/constants.dart';
import 'salary_calculator.dart';

typedef CalculatorFormula =
    Map<String, double> Function(
      Map<String, double> inputs,
      AppSettings settings,
    );

class CalculatorCategory {
  static const payroll = 'حقوق و فیش';
  static const settlement = 'سنوات و تسویه';
  static const leave = 'مرخصی';
  static const tax = 'مالیات';
  static const insurance = 'بیمه';
  static const worktime = 'قرارداد و کارکرد';
  static const conversion = 'خالص و ناخالص';

  static const all = [
    payroll,
    settlement,
    leave,
    tax,
    insurance,
    worktime,
    conversion,
  ];
}

class CalculatorField {
  final String key;
  final String label;
  final bool isCurrency;
  final String? suffix;
  final double Function(AppSettings settings) defaultValue;

  CalculatorField({
    required this.key,
    required this.label,
    this.isCurrency = false,
    this.suffix,
    double Function(AppSettings settings)? defaultValue,
  }) : defaultValue = defaultValue ?? ((_) => 0);
}

class CalculatorOutput {
  final String key;
  final String label;
  final bool isCurrency;
  final String? suffix;

  const CalculatorOutput({
    required this.key,
    required this.label,
    this.isCurrency = true,
    this.suffix,
  });
}

class PayrollCalculatorDefinition {
  final String id;
  final String title;
  final String category;
  final List<CalculatorField> fields;
  final List<CalculatorOutput> outputs;
  final String formulaVersion;
  final int lawYear;
  final List<String> sourceUrls;
  final bool appliesToPayslip;
  final CalculatorFormula formula;

  const PayrollCalculatorDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.fields,
    required this.outputs,
    required this.formulaVersion,
    required this.lawYear,
    required this.sourceUrls,
    required this.appliesToPayslip,
    required this.formula,
  });

  Map<String, double> defaultInputs(AppSettings settings) => {
    for (final field in fields) field.key: field.defaultValue(settings),
  };

  Map<String, double> calculate(
    Map<String, double> inputs,
    AppSettings settings,
  ) {
    final normalized = defaultInputs(settings)..addAll(inputs);
    return formula(normalized, settings);
  }
}

class PayrollCalculatorRegistry {
  static const formulaVersion = 'bidbarg-local-1405-v1';

  static const onlinePayslipUrl = 'https://bidbarg.net/blog/online-payslip/';
  static const baseAnnuitiesUrl = 'https://bidbarg.net/blog/base-annuities/';
  static const salaryHubUrl = 'https://bidbarg.net/salary/';
  static const sitemapUrl = 'https://bidbarg.net/blog_sitemap.xml';
  static const socialSecurityPenaltyUrl =
      'https://bidbarg.net/blog/social-security-penalty/';
  static const unemploymentInsuranceUrl =
      'https://bidbarg.net/blog/unemployment-insurance/';
  static const maternityLeaveUrl = 'https://bidbarg.net/blog/maternity-leave/';
  static const sickLeaveUrl = 'https://bidbarg.net/blog/sick-leave/';
  static const workContractUrl = 'https://bidbarg.net/blog/work-contract/';
  static const advancedPaymentUrl =
      'https://bidbarg.net/blog/advanced-payment/';
  static const mandatoryWorkingHoursUrl =
      'https://bidbarg.net/blog/mandatory-working-hours/';
  static const aboveMinimumWageUrl =
      'https://bidbarg.net/blog/above-minimum-wage/';
  static const maximumSsoPremiumUrl =
      'https://bidbarg.net/blog/maximum-sso-premium/';
  static const oneInAThousandSalaryUrl =
      'https://bidbarg.net/blog/one-in-a-thousand-salary/';
  static const unpaidLeaveUrl = 'https://bidbarg.net/blog/unpaid-leave/';

  static List<PayrollCalculatorDefinition> get all => _definitions;

  static PayrollCalculatorDefinition? byId(String id) {
    for (final definition in _definitions) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  static final _definitions = <PayrollCalculatorDefinition>[
    _definition(
      id: 'online_payslip',
      title: 'فیش حقوقی آنلاین',
      category: CalculatorCategory.payroll,
      appliesToPayslip: true,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field(
          'payable_days',
          'روز قابل پرداخت',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
        _field('children_count', 'تعداد فرزند', suffix: 'نفر'),
        _field('overtime_hours', 'اضافه کاری', suffix: 'ساعت'),
        _field('night_work_hours', 'شب کاری', suffix: 'ساعت'),
        _field('friday_work_hours', 'جمعه کاری', suffix: 'ساعت'),
        _field('holiday_work_hours', 'تعطیل کاری', suffix: 'ساعت'),
        _field('mission_days', 'ماموریت', suffix: 'روز'),
        _field('absence_hours', 'کسری غیبت', suffix: 'ساعت'),
        _moneyField('loan_installment', 'قسط وام'),
        _moneyField('advance', 'مساعده'),
        _moneyField('other_deductions', 'سایر کسورات'),
      ],
      outputs: const [
        CalculatorOutput(key: 'gross_salary', label: 'جمع ناخالص'),
        CalculatorOutput(key: 'insurance', label: 'بیمه سهم کارگر'),
        CalculatorOutput(key: 'tax', label: 'مالیات'),
        CalculatorOutput(key: 'absence_deduction', label: 'کسر غیبت'),
        CalculatorOutput(key: 'net_salary', label: 'خالص پرداختی'),
      ],
      formula: (inputs, settings) {
        final dailyWage = _value(inputs, 'daily_wage', settings.dailyWage);
        final days = _value(inputs, 'payable_days', 30);
        final hourly = _hourly(dailyWage);
        final baseSalary = dailyWage * days;
        final fixedBenefits =
            ((settings.monthlyHousing +
                    settings.monthlyFood +
                    settings.monthlyMarriage +
                    settings.dailySeniority * 30) /
                30) *
            days;
        final childAllowance =
            (settings.monthlyChild / 30) *
            days *
            _value(inputs, 'children_count');
        final overtime =
            hourly *
            AppConstants.overtimeMultiplier *
            _value(inputs, 'overtime_hours');
        final nightWork =
            hourly *
            settings.nightWorkRate *
            _value(inputs, 'night_work_hours');
        final fridayWork =
            hourly *
            settings.fridayWorkRate *
            _value(inputs, 'friday_work_hours');
        final holidayWork =
            hourly *
            settings.holidayWorkMultiplier *
            _value(inputs, 'holiday_work_hours');
        final mission =
            dailyWage *
            settings.missionDailyMultiplier *
            _value(inputs, 'mission_days');
        final absenceDeduction =
            hourly *
            settings.absenceHourlyMultiplier *
            _value(inputs, 'absence_hours');
        final gross =
            baseSalary +
            fixedBenefits +
            childAllowance +
            overtime +
            nightWork +
            fridayWork +
            holidayWork +
            mission;
        final insuranceBase = (gross - childAllowance)
            .clamp(0, double.infinity)
            .toDouble();
        final insurance = insuranceBase * settings.employeeInsuranceRate;
        final tax = SalaryCalculator.calculateTax(gross - insurance);
        final net =
            gross -
            insurance -
            tax -
            absenceDeduction -
            _value(inputs, 'loan_installment') -
            _value(inputs, 'advance') -
            _value(inputs, 'other_deductions');
        return {
          'gross_salary': gross,
          'insurance': insurance,
          'tax': tax,
          'absence_deduction': absenceDeduction,
          'net_salary': net,
        };
      },
    ),
    _simpleAmount(
      id: 'base_annuities',
      title: 'پایه سنوات',
      category: CalculatorCategory.payroll,
      sourceUrls: const [baseAnnuitiesUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _field(
          'daily_seniority',
          'پایه سنوات روزانه',
          isCurrency: true,
          defaultValue: (settings) => settings.dailySeniority,
        ),
        _field(
          'payable_days',
          'روز قابل پرداخت',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'daily_seniority', label: 'پایه روزانه'),
        CalculatorOutput(key: 'monthly_seniority', label: 'پایه ماهانه'),
      ],
      formula: (inputs, _) => {
        'daily_seniority': _value(inputs, 'daily_seniority'),
        'monthly_seniority':
            _value(inputs, 'daily_seniority') * _value(inputs, 'payable_days'),
      },
      appliesToPayslip: true,
    ),
    _hourlyCalculator(
      id: 'overtime_work',
      title: 'اضافه کاری',
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      inputKey: 'overtime_hours',
      inputLabel: 'ساعت اضافه کاری',
      multiplier: (settings) => AppConstants.overtimeMultiplier,
      outputKey: 'overtime_amount',
      outputLabel: 'مبلغ اضافه کاری',
      category: CalculatorCategory.payroll,
      appliesToPayslip: true,
    ),
    _hourlyCalculator(
      id: 'night_work',
      title: 'شب کاری',
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      inputKey: 'night_work_hours',
      inputLabel: 'ساعت شب کاری',
      multiplier: (settings) => settings.nightWorkRate,
      outputKey: 'night_work_amount',
      outputLabel: 'مبلغ شب کاری',
      category: CalculatorCategory.payroll,
      appliesToPayslip: true,
    ),
    _simpleAmount(
      id: 'shift_work',
      title: 'نوبت کاری',
      category: CalculatorCategory.payroll,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField(
          'base_salary',
          'حقوق ثابت ماهانه',
          defaultValue: (settings) => settings.dailyWage * 30,
        ),
        _field(
          'shift_rate',
          'ضریب نوبت کاری',
          defaultValue: (_) => AppConstants.shiftWorkRate,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'shift_work_amount', label: 'مبلغ نوبت کاری'),
      ],
      formula: (inputs, _) => {
        'shift_work_amount':
            _value(inputs, 'base_salary') * _value(inputs, 'shift_rate'),
      },
      appliesToPayslip: true,
    ),
    _hourlyCalculator(
      id: 'friday_work',
      title: 'جمعه کاری',
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      inputKey: 'friday_work_hours',
      inputLabel: 'ساعت جمعه کاری',
      multiplier: (settings) => settings.fridayWorkRate,
      outputKey: 'friday_work_amount',
      outputLabel: 'مبلغ جمعه کاری',
      category: CalculatorCategory.payroll,
      appliesToPayslip: true,
    ),
    _hourlyCalculator(
      id: 'holiday_work',
      title: 'تعطیل کاری',
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      inputKey: 'holiday_work_hours',
      inputLabel: 'ساعت تعطیل کاری',
      multiplier: (settings) => settings.holidayWorkMultiplier,
      outputKey: 'holiday_work_amount',
      outputLabel: 'مبلغ تعطیل کاری',
      category: CalculatorCategory.payroll,
      appliesToPayslip: true,
    ),
    _simpleAmount(
      id: 'mission',
      title: 'حق ماموریت',
      category: CalculatorCategory.payroll,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field('mission_days', 'روز ماموریت', suffix: 'روز'),
        _field(
          'mission_multiplier',
          'ضریب ماموریت',
          defaultValue: (settings) => settings.missionDailyMultiplier,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'mission_amount', label: 'مبلغ ماموریت'),
      ],
      formula: (inputs, _) => {
        'mission_amount':
            _value(inputs, 'daily_wage') *
            _value(inputs, 'mission_days') *
            _value(inputs, 'mission_multiplier'),
      },
      appliesToPayslip: true,
    ),
    _simpleAmount(
      id: 'absence_deduction',
      title: 'کسری غیبت',
      category: CalculatorCategory.payroll,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field('absence_days', 'روز غیبت', suffix: 'روز'),
        _field('absence_hours', 'ساعت غیبت', suffix: 'ساعت'),
      ],
      outputs: const [
        CalculatorOutput(key: 'absence_deduction', label: 'کسر غیبت'),
      ],
      formula: (inputs, settings) => {
        'absence_deduction':
            _value(inputs, 'daily_wage') * _value(inputs, 'absence_days') +
            _hourly(_value(inputs, 'daily_wage')) *
                settings.absenceHourlyMultiplier *
                _value(inputs, 'absence_hours'),
      },
      appliesToPayslip: true,
    ),
    _simpleAmount(
      id: 'salary_tax',
      title: 'مالیات حقوق',
      category: CalculatorCategory.tax,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [_moneyField('taxable_income', 'حقوق مشمول مالیات')],
      outputs: const [CalculatorOutput(key: 'tax', label: 'مالیات')],
      formula: (inputs, _) => {
        'tax': SalaryCalculator.calculateTax(_value(inputs, 'taxable_income')),
      },
    ),
    _simpleAmount(
      id: 'employee_employer_insurance_premiums',
      title: 'حق بیمه کارگر و کارفرما',
      category: CalculatorCategory.insurance,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [_moneyField('insurance_base', 'حقوق مشمول بیمه')],
      outputs: const [
        CalculatorOutput(key: 'employee_insurance', label: 'سهم کارگر'),
        CalculatorOutput(key: 'employer_insurance', label: 'سهم کارفرما'),
        CalculatorOutput(key: 'unemployment_insurance', label: 'بیمه بیکاری'),
        CalculatorOutput(key: 'total_insurance', label: 'جمع حق بیمه'),
      ],
      formula: (inputs, settings) {
        final base = _value(inputs, 'insurance_base');
        final employee = base * settings.employeeInsuranceRate;
        final employer = base * settings.employerInsuranceRate;
        final unemployment = base * settings.unemploymentInsuranceRate;
        return {
          'employee_insurance': employee,
          'employer_insurance': employer,
          'unemployment_insurance': unemployment,
          'total_insurance': employee + employer + unemployment,
        };
      },
    ),
    _simpleAmount(
      id: 'gross_salary_to_net_salary',
      title: 'تبدیل ناخالص به خالص',
      category: CalculatorCategory.conversion,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('gross_salary', 'حقوق ناخالص'),
        _moneyField('deductions', 'کسورات غیر بیمه و مالیات'),
      ],
      outputs: const [
        CalculatorOutput(key: 'insurance', label: 'بیمه'),
        CalculatorOutput(key: 'tax', label: 'مالیات'),
        CalculatorOutput(key: 'net_salary', label: 'حقوق خالص'),
      ],
      formula: (inputs, settings) {
        final gross = _value(inputs, 'gross_salary');
        final insurance = gross * settings.employeeInsuranceRate;
        final tax = SalaryCalculator.calculateTax(gross - insurance);
        return {
          'insurance': insurance,
          'tax': tax,
          'net_salary': gross - insurance - tax - _value(inputs, 'deductions'),
        };
      },
    ),
    _simpleAmount(
      id: 'net_salary_to_gross_salary',
      title: 'تبدیل خالص به ناخالص',
      category: CalculatorCategory.conversion,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [_moneyField('net_salary', 'حقوق خالص مورد نظر')],
      outputs: const [
        CalculatorOutput(key: 'gross_salary', label: 'حقوق ناخالص تقریبی'),
        CalculatorOutput(key: 'insurance', label: 'بیمه'),
        CalculatorOutput(key: 'tax', label: 'مالیات'),
      ],
      formula: (inputs, settings) {
        final targetNet = _value(inputs, 'net_salary');
        var low = targetNet;
        var high = targetNet * 2 + settings.dailyWage * 30;
        for (var i = 0; i < 40; i++) {
          final mid = (low + high) / 2;
          final insurance = mid * settings.employeeInsuranceRate;
          final tax = SalaryCalculator.calculateTax(mid - insurance);
          final net = mid - insurance - tax;
          if (net < targetNet) {
            low = mid;
          } else {
            high = mid;
          }
        }
        final gross = high;
        final insurance = gross * settings.employeeInsuranceRate;
        final tax = SalaryCalculator.calculateTax(gross - insurance);
        return {'gross_salary': gross, 'insurance': insurance, 'tax': tax};
      },
    ),
    _simpleAmount(
      id: 'leave_balance_days',
      title: 'مانده مرخصی',
      category: CalculatorCategory.leave,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _field(
          'monthly_leave_allowance',
          'مرخصی مجاز ماهانه',
          suffix: 'روز',
          defaultValue: (settings) => settings.monthlyLeaveAllowance,
        ),
        _field(
          'months_worked',
          'ماه کارکرد',
          suffix: 'ماه',
          defaultValue: (_) => 1,
        ),
        _field('used_leave_days', 'مرخصی استفاده شده', suffix: 'روز'),
      ],
      outputs: const [
        CalculatorOutput(
          key: 'remaining_leave_days',
          label: 'مانده مرخصی',
          isCurrency: false,
          suffix: 'روز',
        ),
      ],
      formula: (inputs, _) => {
        'remaining_leave_days':
            _value(inputs, 'monthly_leave_allowance') *
                _value(inputs, 'months_worked') -
            _value(inputs, 'used_leave_days'),
      },
    ),
    _simpleAmount(
      id: 'reward',
      title: 'عیدی',
      category: CalculatorCategory.settlement,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field(
          'worked_days',
          'روز کارکرد سال',
          suffix: 'روز',
          defaultValue: (_) => 365,
        ),
      ],
      outputs: const [CalculatorOutput(key: 'reward_amount', label: 'عیدی')],
      formula: (inputs, settings) {
        final ratio = _value(inputs, 'worked_days') / 365;
        final amount = _value(inputs, 'daily_wage') * 60 * ratio;
        final cap = settings.dailyWage * 90 * ratio;
        return {'reward_amount': amount > cap ? cap : amount};
      },
    ),
    _simpleAmount(
      id: 'calculation_of_annuities',
      title: 'سنوات پایان کار',
      category: CalculatorCategory.settlement,
      sourceUrls: const [baseAnnuitiesUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field(
          'worked_days',
          'روز کارکرد',
          suffix: 'روز',
          defaultValue: (_) => 365,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'severance_amount', label: 'سنوات'),
      ],
      formula: (inputs, _) => {
        'severance_amount':
            _value(inputs, 'daily_wage') *
            30 *
            _value(inputs, 'worked_days') /
            365,
      },
    ),
    _simpleAmount(
      id: 'worker_settlement',
      title: 'تسویه حساب کارگر',
      category: CalculatorCategory.settlement,
      sourceUrls: const [
        baseAnnuitiesUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
      fields: [
        _dailyWageField(),
        _field(
          'worked_days',
          'روز کارکرد',
          suffix: 'روز',
          defaultValue: (_) => 365,
        ),
        _field('unused_leave_days', 'مرخصی ذخیره', suffix: 'روز'),
      ],
      outputs: const [
        CalculatorOutput(key: 'severance_amount', label: 'سنوات'),
        CalculatorOutput(key: 'reward_amount', label: 'عیدی'),
        CalculatorOutput(key: 'leave_cash_amount', label: 'بازخرید مرخصی'),
        CalculatorOutput(key: 'settlement_total', label: 'جمع تسویه'),
      ],
      formula: (inputs, settings) {
        final dailyWage = _value(inputs, 'daily_wage');
        final workedDays = _value(inputs, 'worked_days');
        final severance = dailyWage * 30 * workedDays / 365;
        final reward = (dailyWage * 60 * workedDays / 365)
            .clamp(0, settings.dailyWage * 90 * workedDays / 365)
            .toDouble();
        final leaveCash = dailyWage * _value(inputs, 'unused_leave_days');
        return {
          'severance_amount': severance,
          'reward_amount': reward,
          'leave_cash_amount': leaveCash,
          'settlement_total': severance + reward + leaveCash,
        };
      },
    ),
    _simpleAmount(
      id: 'part_time_wage',
      title: 'حقوق پاره وقت',
      category: CalculatorCategory.worktime,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field('work_hours', 'ساعت کارکرد', suffix: 'ساعت'),
      ],
      outputs: const [
        CalculatorOutput(key: 'part_time_amount', label: 'مزد کارکرد'),
      ],
      formula: (inputs, _) => {
        'part_time_amount':
            _hourly(_value(inputs, 'daily_wage')) *
            _value(inputs, 'work_hours'),
      },
    ),
    _simpleAmount(
      id: 'minimum_wage',
      title: 'حداقل مزد و مزایا',
      category: CalculatorCategory.worktime,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _field(
          'payable_days',
          'روز قابل پرداخت',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
        _field('children_count', 'تعداد فرزند', suffix: 'نفر'),
      ],
      outputs: const [
        CalculatorOutput(key: 'base_salary', label: 'حداقل مزد'),
        CalculatorOutput(key: 'fixed_benefits', label: 'مزایای ثابت'),
        CalculatorOutput(key: 'gross_salary', label: 'جمع دریافتی ناخالص'),
      ],
      formula: (inputs, settings) {
        final days = _value(inputs, 'payable_days');
        final base = settings.dailyWage * days;
        final benefits =
            ((settings.monthlyHousing +
                    settings.monthlyFood +
                    settings.monthlyMarriage +
                    settings.dailySeniority * 30 +
                    settings.monthlyChild * _value(inputs, 'children_count')) /
                30) *
            days;
        return {
          'base_salary': base,
          'fixed_benefits': benefits,
          'gross_salary': base + benefits,
        };
      },
    ),
    _simpleAmount(
      id: 'above_minimum_wage',
      title: 'مزد بالاتر از حداقل',
      category: CalculatorCategory.worktime,
      sourceUrls: const [aboveMinimumWageUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField(
          'daily_wage_1404',
          'مزد روزانه سال قبل',
          defaultValue: (_) => AppConstants.defaultDailyWage1404,
        ),
        _field(
          'increase_rate',
          'ضریب افزایش',
          defaultValue: (settings) => settings.salaryRateA,
        ),
        _moneyField(
          'fixed_rial',
          'مبلغ ثابت روزانه',
          defaultValue: (settings) => settings.fixedRial,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'daily_wage_1405', label: 'مزد روزانه جدید'),
        CalculatorOutput(key: 'monthly_wage_1405', label: 'مزد ۳۰ روزه جدید'),
      ],
      formula: (inputs, _) {
        final dailyWage = SalaryCalculator.calculateDailyWage1405(
          dailyWage1404: _value(inputs, 'daily_wage_1404'),
          rate: _value(inputs, 'increase_rate'),
          fixedRial: _value(inputs, 'fixed_rial'),
        );
        return {
          'daily_wage_1405': dailyWage,
          'monthly_wage_1405': dailyWage * AppConstants.standardMonthDays,
        };
      },
    ),
    _simpleAmount(
      id: 'mandatory_working_hours',
      title: 'ساعات کار موظفی',
      category: CalculatorCategory.worktime,
      sourceUrls: const [mandatoryWorkingHoursUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _field(
          'work_days',
          'روز کاری ماه',
          suffix: 'روز',
          defaultValue: (_) => 22,
        ),
        _field(
          'daily_hours',
          'ساعت کار روزانه',
          suffix: 'ساعت',
          defaultValue: (_) => AppConstants.dailyWorkHours,
        ),
      ],
      outputs: const [
        CalculatorOutput(
          key: 'mandatory_hours',
          label: 'ساعات موظفی',
          isCurrency: false,
          suffix: 'ساعت',
        ),
      ],
      formula: (inputs, _) => {
        'mandatory_hours':
            _value(inputs, 'work_days') * _value(inputs, 'daily_hours'),
      },
    ),
    _simpleAmount(
      id: 'work_contract',
      title: 'قرارداد کار',
      category: CalculatorCategory.worktime,
      sourceUrls: const [workContractUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field(
          'contract_months',
          'مدت قرارداد',
          suffix: 'ماه',
          defaultValue: (_) => 1,
        ),
        _field(
          'monthly_hours',
          'ساعت کار ماهانه',
          suffix: 'ساعت',
          defaultValue: (_) => AppConstants.standardMonthlyHours,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'monthly_wage', label: 'مزد ماهانه'),
        CalculatorOutput(key: 'contract_total', label: 'جمع قرارداد'),
        CalculatorOutput(key: 'hourly_wage', label: 'مزد ساعتی'),
      ],
      formula: (inputs, _) {
        final monthly = _value(inputs, 'daily_wage') * 30;
        final months = _value(inputs, 'contract_months');
        final hours = _value(
          inputs,
          'monthly_hours',
          1,
        ).clamp(1, double.infinity);
        return {
          'monthly_wage': monthly,
          'contract_total': monthly * months,
          'hourly_wage': monthly / hours,
        };
      },
    ),
    _simpleAmount(
      id: 'advanced_payment',
      title: 'مساعده',
      category: CalculatorCategory.payroll,
      sourceUrls: const [advancedPaymentUrl, salaryHubUrl, sitemapUrl],
      appliesToPayslip: true,
      fields: [
        _moneyField('requested_amount', 'مبلغ درخواستی'),
        _moneyField('approved_amount', 'مبلغ مصوب'),
        _field(
          'installment_months',
          'تعداد اقساط',
          suffix: 'ماه',
          defaultValue: (_) => 1,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'approved_amount', label: 'مبلغ مساعده'),
        CalculatorOutput(key: 'installment_amount', label: 'قسط ماهانه'),
      ],
      formula: (inputs, _) {
        final approved = _value(
          inputs,
          'approved_amount',
          _value(inputs, 'requested_amount'),
        );
        final months = _value(
          inputs,
          'installment_months',
          1,
        ).clamp(1, double.infinity);
        return {
          'approved_amount': approved,
          'installment_amount': approved / months,
        };
      },
    ),
    _simpleAmount(
      id: 'social_security_penalty',
      title: 'جریمه بیمه تامین اجتماعی',
      category: CalculatorCategory.insurance,
      sourceUrls: const [socialSecurityPenaltyUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('insurance_debt', 'حق بیمه پرداخت نشده'),
        _field(
          'delay_months',
          'مدت تاخیر',
          suffix: 'ماه',
          defaultValue: (_) => 1,
        ),
        _field('penalty_rate', 'نرخ جریمه ماهانه', defaultValue: (_) => 0.02),
      ],
      outputs: const [
        CalculatorOutput(key: 'penalty_amount', label: 'جریمه تاخیر'),
        CalculatorOutput(key: 'payable_total', label: 'جمع بدهی و جریمه'),
      ],
      formula: (inputs, _) {
        final debt = _value(inputs, 'insurance_debt');
        final penalty =
            debt *
            _value(inputs, 'delay_months') *
            _value(inputs, 'penalty_rate');
        return {'penalty_amount': penalty, 'payable_total': debt + penalty};
      },
    ),
    _simpleAmount(
      id: 'unemployment_insurance',
      title: 'بیمه بیکاری',
      category: CalculatorCategory.insurance,
      sourceUrls: const [unemploymentInsuranceUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('average_monthly_wage', 'میانگین مزد ماهانه'),
        _field('dependents_count', 'تعداد افراد تحت تکفل', suffix: 'نفر'),
      ],
      outputs: const [
        CalculatorOutput(key: 'support_amount', label: 'مقرری ماهانه'),
      ],
      formula: (inputs, settings) {
        final average = _value(inputs, 'average_monthly_wage');
        final dependents = _value(inputs, 'dependents_count');
        final calculated = average * (0.55 + 0.10 * dependents);
        final capped = calculated.clamp(0, average * 0.80).toDouble();
        final minimum = settings.dailyWage * AppConstants.standardMonthDays;
        return {'support_amount': capped < minimum ? minimum : capped};
      },
    ),
    _simpleAmount(
      id: 'maternity_leave',
      title: 'مرخصی زایمان',
      category: CalculatorCategory.leave,
      sourceUrls: const [maternityLeaveUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('average_daily_wage', 'میانگین مزد روزانه'),
        _field(
          'leave_days',
          'روز مرخصی',
          suffix: 'روز',
          defaultValue: (_) => 270,
        ),
      ],
      outputs: const [
        CalculatorOutput(key: 'allowance_amount', label: 'غرامت مرخصی'),
      ],
      formula: (inputs, _) => {
        'allowance_amount':
            _value(inputs, 'average_daily_wage') *
            _value(inputs, 'leave_days') *
            2 /
            3,
      },
    ),
    _simpleAmount(
      id: 'sick_leave',
      title: 'مرخصی استعلاجی',
      category: CalculatorCategory.leave,
      sourceUrls: const [sickLeaveUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('average_daily_wage', 'میانگین مزد روزانه'),
        _field('sick_days', 'روز استعلاجی', suffix: 'روز'),
        _field('hospitalized', 'بستری بوده است', defaultValue: (_) => 0),
      ],
      outputs: const [
        CalculatorOutput(key: 'allowance_amount', label: 'غرامت استعلاجی'),
      ],
      formula: (inputs, _) {
        final rate = _value(inputs, 'hospitalized') >= 1 ? 0.75 : 2 / 3;
        return {
          'allowance_amount':
              _value(inputs, 'average_daily_wage') *
              _value(inputs, 'sick_days') *
              rate,
        };
      },
    ),
    _simpleAmount(
      id: 'unpaid_leave',
      title: 'مرخصی بدون حقوق',
      category: CalculatorCategory.leave,
      sourceUrls: const [unpaidLeaveUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field('unpaid_leave_days', 'روز مرخصی بدون حقوق', suffix: 'روز'),
      ],
      outputs: const [
        CalculatorOutput(key: 'unpaid_leave_deduction', label: 'کسر مرخصی'),
      ],
      formula: (inputs, _) => {
        'unpaid_leave_deduction':
            _value(inputs, 'daily_wage') * _value(inputs, 'unpaid_leave_days'),
      },
      appliesToPayslip: true,
    ),
    _simpleAmount(
      id: 'maximum_sso_premium',
      title: 'سقف حق بیمه تامین اجتماعی',
      category: CalculatorCategory.insurance,
      sourceUrls: const [maximumSsoPremiumUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _dailyWageField(),
        _field(
          'payable_days',
          'روز مشمول بیمه',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
        _field('premium_cap_multiplier', 'ضریب سقف', defaultValue: (_) => 7),
      ],
      outputs: const [
        CalculatorOutput(key: 'insurance_base_cap', label: 'سقف مبنای بیمه'),
      ],
      formula: (inputs, _) => {
        'insurance_base_cap':
            _value(inputs, 'daily_wage') *
            _value(inputs, 'premium_cap_multiplier') *
            _value(inputs, 'payable_days'),
      },
    ),
    _simpleAmount(
      id: 'one_in_a_thousand_salary',
      title: 'یک در هزار حقوق',
      category: CalculatorCategory.tax,
      sourceUrls: const [oneInAThousandSalaryUrl, salaryHubUrl, sitemapUrl],
      fields: [
        _moneyField('salary_base', 'مبنای محاسبه'),
        _field('rate', 'نرخ', defaultValue: (_) => 0.001),
      ],
      outputs: const [
        CalculatorOutput(key: 'payable_amount', label: 'مبلغ قابل پرداخت'),
      ],
      formula: (inputs, _) => {
        'payable_amount':
            _value(inputs, 'salary_base') * _value(inputs, 'rate'),
      },
    ),
    _benefit(
      'child_allowance',
      'حق اولاد',
      'children_count',
      'تعداد فرزند',
      (s) => s.monthlyChild,
    ),
    _benefit(
      'marriage_allowance',
      'حق تاهل',
      'is_married',
      'مشمول حق تاهل',
      (s) => s.monthlyMarriage,
    ),
    _benefit(
      'housing_allowance',
      'حق مسکن',
      'payable_months',
      'ماه مشمول',
      (s) => s.monthlyHousing,
    ),
    _benefit(
      'worker_coupon',
      'بن کارگری',
      'payable_months',
      'ماه مشمول',
      (s) => s.monthlyFood,
    ),
  ];

  static PayrollCalculatorDefinition _definition({
    required String id,
    required String title,
    required String category,
    required List<CalculatorField> fields,
    required List<CalculatorOutput> outputs,
    required List<String> sourceUrls,
    required CalculatorFormula formula,
    bool appliesToPayslip = false,
  }) {
    return PayrollCalculatorDefinition(
      id: id,
      title: title,
      category: category,
      fields: fields,
      outputs: outputs,
      formulaVersion: formulaVersion,
      lawYear: AppConstants.currentYear,
      sourceUrls: sourceUrls,
      appliesToPayslip: appliesToPayslip,
      formula: formula,
    );
  }

  static PayrollCalculatorDefinition _simpleAmount({
    required String id,
    required String title,
    required String category,
    required List<CalculatorField> fields,
    required List<CalculatorOutput> outputs,
    required List<String> sourceUrls,
    required CalculatorFormula formula,
    bool appliesToPayslip = false,
  }) {
    return _definition(
      id: id,
      title: title,
      category: category,
      fields: fields,
      outputs: outputs,
      sourceUrls: sourceUrls,
      appliesToPayslip: appliesToPayslip,
      formula: formula,
    );
  }

  static PayrollCalculatorDefinition _hourlyCalculator({
    required String id,
    required String title,
    required List<String> sourceUrls,
    required String inputKey,
    required String inputLabel,
    required double Function(AppSettings settings) multiplier,
    required String outputKey,
    required String outputLabel,
    required String category,
    bool appliesToPayslip = false,
  }) {
    return _definition(
      id: id,
      title: title,
      category: category,
      sourceUrls: sourceUrls,
      appliesToPayslip: appliesToPayslip,
      fields: [
        _dailyWageField(),
        _field(inputKey, inputLabel, suffix: 'ساعت'),
      ],
      outputs: [CalculatorOutput(key: outputKey, label: outputLabel)],
      formula: (inputs, settings) => {
        outputKey:
            _hourly(_value(inputs, 'daily_wage')) *
            multiplier(settings) *
            _value(inputs, inputKey),
      },
    );
  }

  static PayrollCalculatorDefinition _benefit(
    String id,
    String title,
    String quantityKey,
    String quantityLabel,
    double Function(AppSettings settings) monthlyAmount,
  ) {
    return _definition(
      id: id,
      title: title,
      category: CalculatorCategory.payroll,
      sourceUrls: const [onlinePayslipUrl, salaryHubUrl, sitemapUrl],
      appliesToPayslip: true,
      fields: [
        _field(quantityKey, quantityLabel, defaultValue: (_) => 1),
        _field(
          'payable_days',
          'روز قابل پرداخت',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
      ],
      outputs: [CalculatorOutput(key: '${id}_amount', label: title)],
      formula: (inputs, settings) => {
        '${id}_amount':
            monthlyAmount(settings) *
            _value(inputs, quantityKey) *
            _value(inputs, 'payable_days') /
            30,
      },
    );
  }

  static CalculatorField _field(
    String key,
    String label, {
    bool isCurrency = false,
    String? suffix,
    double Function(AppSettings settings)? defaultValue,
  }) {
    return CalculatorField(
      key: key,
      label: label,
      isCurrency: isCurrency,
      suffix: suffix,
      defaultValue: defaultValue,
    );
  }

  static CalculatorField _moneyField(
    String key,
    String label, {
    double Function(AppSettings settings)? defaultValue,
  }) {
    return _field(key, label, isCurrency: true, defaultValue: defaultValue);
  }

  static CalculatorField _dailyWageField() {
    return _moneyField(
      'daily_wage',
      'مزد روزانه',
      defaultValue: (settings) => settings.dailyWage,
    );
  }

  static double _value(
    Map<String, double> inputs,
    String key, [
    double fallback = 0,
  ]) {
    final value = inputs[key] ?? fallback;
    return value.isFinite ? value : fallback;
  }

  static double _hourly(double dailyWage) =>
      dailyWage / AppConstants.dailyWorkHours;
}
