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
  static const formulaVersion = 'bidbarg-local-1405-v2';

  static const onlinePayslipUrl = 'https://bidbarg.net/blog/online-payslip/';
  static const baseAnnuitiesUrl = 'https://bidbarg.net/blog/base-annuities/';
  static const salaryHubUrl = 'https://bidbarg.net/salary/';
  static const sitemapUrl = 'https://bidbarg.net/blog_sitemap.xml';
  static const overtimeWorkUrl = 'https://bidbarg.net/blog/overtime-work/';
  static const nightWorkUrl = 'https://bidbarg.net/blog/night-work/';
  static const shiftWorkUrl = 'https://bidbarg.net/blog/shift-work/';
  static const fridayWorkUrl = 'https://bidbarg.net/blog/friday-work/';
  static const holidayWorkUrl = 'https://bidbarg.net/blog/holiday-work/';
  static const missionUrl = 'https://bidbarg.net/blog/mission/';
  static const grossSalaryToNetSalaryUrl =
      'https://bidbarg.net/blog/gross-salary-to-net-salary/';
  static const employeeEmployerInsurancePremiumsUrl =
      'https://bidbarg.net/blog/employee-employer-insurance-premiums/';
  static const leaveBalanceDaysUrl =
      'https://bidbarg.net/blog/leave-balance-days/';
  static const rewardUrl = 'https://bidbarg.net/blog/reward/';
  static const calculationOfAnnuitiesUrl =
      'https://bidbarg.net/blog/calculation-of-annuities/';
  static const workerSettlementUrl =
      'https://bidbarg.net/blog/worker-settlement/';
  static const partTimeWageUrl = 'https://bidbarg.net/blog/part-time-wage/';
  static const minimumWageUrl = 'https://bidbarg.net/blog/minimum-wage/';
  static const workerCouponUrl = 'https://bidbarg.net/blog/worker-coupon/';
  static const salaryComponentsUrl =
      'https://bidbarg.net/blog/salary-components/';
  static const fixedAndVariableWageBenefitsUrl =
      'https://bidbarg.net/blog/fixed-and-variable-wage-benefits/';
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
  static const salaryTaxUrl = 'https://bidbarg.net/blog/salary-tax/';
  static const jobWageBenefitsUrl =
      'https://bidbarg.net/blog/job-wage-benefits/';
  static const welfareWageBenefitsUrl =
      'https://bidbarg.net/blog/welfare-wage-benefits/';
  static const otherWagesUrl = 'https://bidbarg.net/blog/other-wages/';
  static const taxSsoDeductibleUrl =
      'https://bidbarg.net/blog/tax-sso-deductible/';

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
      sourceUrls: const [
        onlinePayslipUrl,
        jobWageBenefitsUrl,
        welfareWageBenefitsUrl,
        taxSsoDeductibleUrl,
        salaryTaxUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
        _field(
          'shift_rate',
          'ضریب نوبت کاری',
          defaultValue: (_) => AppConstants.shiftWorkRate,
        ),
        _moneyField('job_related_benefits', 'مزایای به تبع شغل'),
        _moneyField('employee_related_benefits', 'مزایای به تبع شاغل'),
        _moneyField('welfare_benefits', 'مزایای رفاهی و انگیزشی'),
        _moneyField('supplementary_insurance', 'بیمه تکمیلی سهم کارگر'),
        _field('tax_relief_rate', 'نرخ تخفیف مالیات'),
        _moneyField('loan_installment', 'قسط وام'),
        _moneyField('advance', 'مساعده'),
        _moneyField('other_deductions', 'سایر کسورات'),
      ],
      outputs: const [
        CalculatorOutput(key: 'gross_salary', label: 'جمع ناخالص'),
        CalculatorOutput(key: 'shift_work', label: 'نوبت کاری'),
        CalculatorOutput(
          key: 'job_related_benefits',
          label: 'مزایای به تبع شغل',
        ),
        CalculatorOutput(
          key: 'employee_related_benefits',
          label: 'مزایای به تبع شاغل',
        ),
        CalculatorOutput(key: 'welfare_benefits', label: 'مزایای رفاهی'),
        CalculatorOutput(key: 'insurance', label: 'بیمه سهم کارگر'),
        CalculatorOutput(
          key: 'supplementary_insurance',
          label: 'بیمه تکمیلی سهم کارگر',
        ),
        CalculatorOutput(key: 'tax_relief', label: 'تخفیف مالیات'),
        CalculatorOutput(key: 'tax', label: 'مالیات'),
        CalculatorOutput(key: 'absence_deduction', label: 'کسر غیبت'),
        CalculatorOutput(key: 'net_salary', label: 'خالص پرداختی'),
      ],
      formula: (inputs, settings) {
        final dailyWage = _value(inputs, 'daily_wage', settings.dailyWage);
        final days = _value(inputs, 'payable_days', 30);
        final jobRelatedBenefits = _positive(inputs, 'job_related_benefits');
        final jobRelatedDaily = days > 0 ? jobRelatedBenefits / days : 0.0;
        final wageBasisDaily =
            dailyWage + settings.dailySeniority + jobRelatedDaily;
        final hourly = _hourly(wageBasisDaily);
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
        final shiftRate = _rate(
          _value(inputs, 'shift_rate', AppConstants.shiftWorkRate),
        );
        final shiftWorkBase = wageBasisDaily * days;
        final shiftWork = shiftWorkBase * shiftRate;
        final hasRotatingShift = shiftWork > 0;
        final nightWork = hasRotatingShift
            ? 0.0
            : hourly *
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
            wageBasisDaily *
            settings.missionDailyMultiplier *
            _value(inputs, 'mission_days');
        final absenceDeduction =
            hourly *
            settings.absenceHourlyMultiplier *
            _value(inputs, 'absence_hours');
        final employeeRelatedBenefits = _positive(
          inputs,
          'employee_related_benefits',
        );
        final welfareBenefits = _positive(inputs, 'welfare_benefits');
        final supplementaryInsurance = _positive(
          inputs,
          'supplementary_insurance',
        );
        final gross =
            baseSalary +
            fixedBenefits +
            childAllowance +
            shiftWork +
            jobRelatedBenefits +
            employeeRelatedBenefits +
            welfareBenefits +
            overtime +
            nightWork +
            fridayWork +
            holidayWork +
            mission;
        final uncappedInsuranceBase = (gross - childAllowance)
            .clamp(0, double.infinity)
            .toDouble();
        final insuranceCap =
            settings.dailyWage * AppConstants.insuranceCapMultiplier * days;
        final insuranceBase = uncappedInsuranceBase < insuranceCap
            ? uncappedInsuranceBase
            : insuranceCap;
        final insurance = insuranceBase * settings.employeeInsuranceRate;
        final twoSevenExemption = SalaryCalculator.calculateTwoSevenExemption(
          insurance: insurance,
          exemptionRate: settings.twoSevenBaseRate,
        );
        final taxBase = (gross - twoSevenExemption - supplementaryInsurance)
            .clamp(0, double.infinity)
            .toDouble();
        final grossTax = SalaryCalculator.calculateTax(taxBase);
        final taxReliefRate = _rate(_value(inputs, 'tax_relief_rate'));
        final taxRelief = grossTax * taxReliefRate;
        final tax = (grossTax - taxRelief).clamp(0, double.infinity).toDouble();
        final net =
            gross -
            insurance -
            tax -
            supplementaryInsurance -
            absenceDeduction -
            _value(inputs, 'loan_installment') -
            _value(inputs, 'advance') -
            _value(inputs, 'other_deductions');
        return {
          'gross_salary': gross,
          'shift_work': shiftWork,
          'shift_work_base': shiftWorkBase,
          'job_related_benefits': jobRelatedBenefits,
          'employee_related_benefits': employeeRelatedBenefits,
          'welfare_benefits': welfareBenefits,
          'insurance': insurance,
          'supplementary_insurance': supplementaryInsurance,
          'tax_relief': taxRelief,
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
      sourceUrls: const [
        overtimeWorkUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        nightWorkUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        shiftWorkUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
      fields: [
        _moneyField(
          'base_salary',
          'مزد مبنای ماهانه',
          defaultValue: (settings) =>
              (settings.dailyWage + settings.dailySeniority) * 30,
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
      sourceUrls: const [
        fridayWorkUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        holidayWorkUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        missionUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        salaryTaxUrl,
        taxSsoDeductibleUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        employeeEmployerInsurancePremiumsUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        grossSalaryToNetSalaryUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        grossSalaryToNetSalaryUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [
        leaveBalanceDaysUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
      sourceUrls: const [rewardUrl, onlinePayslipUrl, salaryHubUrl, sitemapUrl],
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
      sourceUrls: const [
        calculationOfAnnuitiesUrl,
        baseAnnuitiesUrl,
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
        workerSettlementUrl,
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
      sourceUrls: const [
        partTimeWageUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
      fields: [
        _dailyWageField(),
        _field(
          'payable_days',
          'روزهای ماه',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
        _field(
          'mandatory_hours',
          'ساعت موظفی ماه',
          suffix: 'ساعت',
          defaultValue: (_) => AppConstants.standardMonthlyHours,
        ),
        _field('work_hours', 'ساعت کارکرد', suffix: 'ساعت'),
      ],
      outputs: const [
        CalculatorOutput(
          key: 'equivalent_days',
          label: 'روز معادل قابل پرداخت',
          isCurrency: false,
          suffix: 'روز',
        ),
        CalculatorOutput(key: 'part_time_amount', label: 'مزد کارکرد'),
        CalculatorOutput(
          key: 'part_time_overtime_hours',
          label: 'اضافه‌کاری مازاد موظفی',
          isCurrency: false,
          suffix: 'ساعت',
        ),
        CalculatorOutput(
          key: 'part_time_overtime_amount',
          label: 'مبلغ اضافه‌کاری',
        ),
      ],
      formula: (inputs, _) {
        final dailyWage = _value(inputs, 'daily_wage');
        final days = _value(inputs, 'payable_days', 30);
        final mandatoryHours = _value(
          inputs,
          'mandatory_hours',
          AppConstants.standardMonthlyHours,
        );
        final workHours = _value(inputs, 'work_hours');
        final regularHours = mandatoryHours > 0
            ? workHours.clamp(0.0, mandatoryHours).toDouble()
            : 0.0;
        final overtimeHours = mandatoryHours > 0
            ? (workHours - mandatoryHours)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : 0.0;
        final equivalentDays = mandatoryHours > 0
            ? (regularHours / mandatoryHours) * days
            : 0.0;
        return {
          'equivalent_days': equivalentDays,
          'part_time_amount': dailyWage * equivalentDays,
          'part_time_overtime_hours': overtimeHours,
          'part_time_overtime_amount':
              _hourly(dailyWage) *
              AppConstants.overtimeMultiplier *
              overtimeHours,
        };
      },
    ),
    _simpleAmount(
      id: 'minimum_wage',
      title: 'حداقل مزد و مزایا',
      category: CalculatorCategory.worktime,
      sourceUrls: const [
        minimumWageUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
          'year',
          'سال',
          defaultValue: (_) => AppConstants.currentYear.toDouble(),
        ),
        _field('month', 'ماه', defaultValue: (_) => 1),
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
          key: 'official_mandatory_hours',
          label: 'ساعت موظفی جدول',
          isCurrency: false,
          suffix: 'ساعت',
        ),
        CalculatorOutput(
          key: 'mandatory_hours',
          label: 'ساعات موظفی',
          isCurrency: false,
          suffix: 'ساعت',
        ),
      ],
      formula: (inputs, _) {
        final year = _value(
          inputs,
          'year',
          AppConstants.currentYear.toDouble(),
        ).round();
        final month = _value(inputs, 'month', 1).round();
        return {
          'official_mandatory_hours': AppConstants.mandatoryMonthlyHoursFor(
            year: year,
            month: month,
          ),
          'mandatory_hours':
              _value(inputs, 'work_days') * _value(inputs, 'daily_hours'),
        };
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
    _proratedPayslipAmount(
      id: 'job_wage_benefits',
      title: 'مزایای به تبع شغل',
      amountLabel: 'مبلغ ماهانه مزایای شغل',
      outputKey: 'job_related_benefits',
      outputLabel: 'مبلغ قابل درج در فیش',
      sourceUrls: const [
        jobWageBenefitsUrl,
        fixedAndVariableWageBenefitsUrl,
        salaryComponentsUrl,
        otherWagesUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
    ),
    _proratedPayslipAmount(
      id: 'employee_related_benefits',
      title: 'مزایای به تبع شاغل',
      amountLabel: 'مبلغ ماهانه مزایای شاغل',
      outputKey: 'employee_related_benefits',
      outputLabel: 'مبلغ قابل درج در فیش',
      sourceUrls: const [
        welfareWageBenefitsUrl,
        fixedAndVariableWageBenefitsUrl,
        salaryComponentsUrl,
        otherWagesUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
    ),
    _proratedPayslipAmount(
      id: 'welfare_wage_benefits',
      title: 'مزایای رفاهی و انگیزشی',
      amountLabel: 'مبلغ ماهانه مزایای رفاهی',
      outputKey: 'welfare_benefits',
      outputLabel: 'مبلغ قابل درج در فیش',
      sourceUrls: const [
        welfareWageBenefitsUrl,
        fixedAndVariableWageBenefitsUrl,
        salaryComponentsUrl,
        otherWagesUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
    ),
    _simpleAmount(
      id: 'supplementary_insurance',
      title: 'بیمه تکمیلی',
      category: CalculatorCategory.insurance,
      appliesToPayslip: true,
      sourceUrls: const [
        taxSsoDeductibleUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
      fields: [_moneyField('premium_amount', 'سهم کارگر')],
      outputs: const [
        CalculatorOutput(key: 'deduction_amount', label: 'کسر از پرداختی'),
        CalculatorOutput(key: 'tax_deduction', label: 'کاهش مبنای مالیات'),
      ],
      formula: (inputs, _) {
        final amount = _positive(inputs, 'premium_amount');
        return {'deduction_amount': amount, 'tax_deduction': amount};
      },
    ),
    _simpleAmount(
      id: 'salary_tax_relief',
      title: 'تخفیف مالیات حقوق',
      category: CalculatorCategory.tax,
      appliesToPayslip: true,
      sourceUrls: const [
        salaryTaxUrl,
        taxSsoDeductibleUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
      fields: [
        _moneyField('taxable_income', 'حقوق مشمول مالیات'),
        _field('relief_rate', 'نرخ تخفیف', defaultValue: (_) => 0.5),
      ],
      outputs: const [
        CalculatorOutput(key: 'gross_tax', label: 'مالیات قبل از تخفیف'),
        CalculatorOutput(key: 'tax_relief', label: 'مبلغ تخفیف'),
        CalculatorOutput(key: 'payable_tax', label: 'مالیات قابل پرداخت'),
      ],
      formula: (inputs, _) {
        final grossTax = SalaryCalculator.calculateTax(
          _positive(inputs, 'taxable_income'),
        );
        final relief = grossTax * _rate(_value(inputs, 'relief_rate'));
        return {
          'gross_tax': grossTax,
          'tax_relief': relief,
          'payable_tax': (grossTax - relief)
              .clamp(0, double.infinity)
              .toDouble(),
        };
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
      sourceUrls: const [
        workerCouponUrl,
        welfareWageBenefitsUrl,
        onlinePayslipUrl,
        salaryHubUrl,
        sitemapUrl,
      ],
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
        _moneyField(
          'daily_seniority',
          'پایه سنوات روزانه',
          defaultValue: (settings) => settings.dailySeniority,
        ),
        _moneyField('job_related_benefits_daily', 'مزایای به تبع شغل روزانه'),
        _field(inputKey, inputLabel, suffix: 'ساعت'),
      ],
      outputs: [CalculatorOutput(key: outputKey, label: outputLabel)],
      formula: (inputs, settings) {
        final wageBasisDaily =
            _value(inputs, 'daily_wage') +
            _value(inputs, 'daily_seniority') +
            _value(inputs, 'job_related_benefits_daily');
        return {
          outputKey:
              _hourly(wageBasisDaily) *
              multiplier(settings) *
              _value(inputs, inputKey),
        };
      },
    );
  }

  static PayrollCalculatorDefinition _proratedPayslipAmount({
    required String id,
    required String title,
    required String amountLabel,
    required String outputKey,
    required String outputLabel,
    required List<String> sourceUrls,
  }) {
    return _definition(
      id: id,
      title: title,
      category: CalculatorCategory.payroll,
      sourceUrls: sourceUrls,
      appliesToPayslip: true,
      fields: [
        _moneyField('monthly_amount', amountLabel),
        _field(
          'payable_days',
          'روز قابل پرداخت',
          suffix: 'روز',
          defaultValue: (_) => 30,
        ),
      ],
      outputs: [CalculatorOutput(key: outputKey, label: outputLabel)],
      formula: (inputs, _) => {
        outputKey:
            _positive(inputs, 'monthly_amount') *
            _value(inputs, 'payable_days', 30) /
            30,
      },
    );
  }

  static PayrollCalculatorDefinition _benefit(
    String id,
    String title,
    String quantityKey,
    String quantityLabel,
    double Function(AppSettings settings) monthlyAmount, {
    List<String> sourceUrls = const [
      onlinePayslipUrl,
      salaryHubUrl,
      sitemapUrl,
    ],
  }) {
    return _definition(
      id: id,
      title: title,
      category: CalculatorCategory.payroll,
      sourceUrls: sourceUrls,
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

  static double _positive(Map<String, double> inputs, String key) =>
      _value(inputs, key).clamp(0, double.infinity).toDouble();

  static double _rate(double value) => value.clamp(0.0, 1.0).toDouble();

  static double _hourly(double dailyWage) =>
      dailyWage / AppConstants.dailyWorkHours;
}
