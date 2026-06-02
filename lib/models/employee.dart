/// مدل کارمند - مطابق ستون‌های فایل اکسل حقوق مصوب 1405
class Employee {
  final int? id;
  final int personnelCode; // کد پرسنلی
  final String firstName; // نام
  final String lastName; // نام خانوادگی
  final String nationalId; // شماره ملی
  final bool hasPriorExperience; // بیش از 4 سال سابقه
  final bool isMarried; // تاهل
  final int childrenCount; // تعداد فرزند
  final double lastYearSeniority; // پایه سنوات سال گذشته (روزانه)
  final double baseSalary30Days; // حقوق پایه (30 روز)
  final double dailyWage1405; // دستمزد روزانه 1405
  final double dailyWage1404; // دستمزد روزانه 1404
  final double dailyHousing; // حق مسکن روزانه
  final double dailyFood; // حق خواروبار روزانه
  final double dailyMarriage; // حق تاهل روزانه
  final double dailyChildAllowance; // حق فرزند روزانه
  final double dailySeniority; // پایه سنوات روزانه
  final double otherBenefitsDaily; // سایر مزایا نسبت به کارکرد (روزانه)
  final double hourlyBenefits; // مزایای ساعتی
  final String startDate; // تاریخ شروع به کار (شمسی - YYYY/MM/DD)
  final bool isActive; // فعال
  final String? notes; // یادداشت

  Employee({
    this.id,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    this.hasPriorExperience = true,
    this.isMarried = false,
    this.childrenCount = 0,
    this.lastYearSeniority = 0,
    this.baseSalary30Days = 0,
    this.dailyWage1405 = 0,
    this.dailyWage1404 = 0,
    this.dailyHousing = 1000000,
    this.dailyFood = 733333,
    this.dailyMarriage = 0,
    this.dailyChildAllowance = 554185,
    this.dailySeniority = 0,
    this.otherBenefitsDaily = 0,
    this.hourlyBenefits = 0,
    required this.startDate,
    this.isActive = true,
    this.notes,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
    'id': id,
    'personnel_code': personnelCode,
    'first_name': firstName,
    'last_name': lastName,
    'national_id': nationalId,
    'has_prior_experience': hasPriorExperience ? 1 : 0,
    'is_married': isMarried ? 1 : 0,
    'children_count': childrenCount,
    'last_year_seniority': lastYearSeniority,
    'base_salary_30_days': baseSalary30Days,
    'daily_wage_1405': dailyWage1405,
    'daily_wage_1404': dailyWage1404,
    'daily_housing': dailyHousing,
    'daily_food': dailyFood,
    'daily_marriage': dailyMarriage,
    'daily_child_allowance': dailyChildAllowance,
    'daily_seniority': dailySeniority,
    'other_benefits_daily': otherBenefitsDaily,
    'hourly_benefits': hourlyBenefits,
    'start_date': startDate,
    'is_active': isActive ? 1 : 0,
    'notes': notes,
  };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'] as int?,
    personnelCode: map['personnel_code'] as int,
    firstName: map['first_name'] as String,
    lastName: map['last_name'] as String,
    nationalId: map['national_id'] as String,
    hasPriorExperience: (map['has_prior_experience'] as int? ?? 0) == 1,
    isMarried: (map['is_married'] as int? ?? 0) == 1,
    childrenCount: map['children_count'] as int? ?? 0,
    lastYearSeniority: (map['last_year_seniority'] as num?)?.toDouble() ?? 0,
    baseSalary30Days: (map['base_salary_30_days'] as num?)?.toDouble() ?? 0,
    dailyWage1405: (map['daily_wage_1405'] as num?)?.toDouble() ?? 0,
    dailyWage1404: (map['daily_wage_1404'] as num?)?.toDouble() ?? 0,
    dailyHousing: (map['daily_housing'] as num?)?.toDouble() ?? 0,
    dailyFood: (map['daily_food'] as num?)?.toDouble() ?? 0,
    dailyMarriage: (map['daily_marriage'] as num?)?.toDouble() ?? 0,
    dailyChildAllowance:
        (map['daily_child_allowance'] as num?)?.toDouble() ?? 0,
    dailySeniority: (map['daily_seniority'] as num?)?.toDouble() ?? 0,
    otherBenefitsDaily: (map['other_benefits_daily'] as num?)?.toDouble() ?? 0,
    hourlyBenefits: (map['hourly_benefits'] as num?)?.toDouble() ?? 0,
    startDate: map['start_date'] as String? ?? '',
    isActive: (map['is_active'] as int? ?? 1) == 1,
    notes: map['notes'] as String?,
  );

  Employee copyWith({
    int? id,
    int? personnelCode,
    String? firstName,
    String? lastName,
    String? nationalId,
    bool? hasPriorExperience,
    bool? isMarried,
    int? childrenCount,
    double? lastYearSeniority,
    double? baseSalary30Days,
    double? dailyWage1405,
    double? dailyWage1404,
    double? dailyHousing,
    double? dailyFood,
    double? dailyMarriage,
    double? dailyChildAllowance,
    double? dailySeniority,
    double? otherBenefitsDaily,
    double? hourlyBenefits,
    String? startDate,
    bool? isActive,
    String? notes,
  }) => Employee(
    id: id ?? this.id,
    personnelCode: personnelCode ?? this.personnelCode,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    nationalId: nationalId ?? this.nationalId,
    hasPriorExperience: hasPriorExperience ?? this.hasPriorExperience,
    isMarried: isMarried ?? this.isMarried,
    childrenCount: childrenCount ?? this.childrenCount,
    lastYearSeniority: lastYearSeniority ?? this.lastYearSeniority,
    baseSalary30Days: baseSalary30Days ?? this.baseSalary30Days,
    dailyWage1405: dailyWage1405 ?? this.dailyWage1405,
    dailyWage1404: dailyWage1404 ?? this.dailyWage1404,
    dailyHousing: dailyHousing ?? this.dailyHousing,
    dailyFood: dailyFood ?? this.dailyFood,
    dailyMarriage: dailyMarriage ?? this.dailyMarriage,
    dailyChildAllowance: dailyChildAllowance ?? this.dailyChildAllowance,
    dailySeniority: dailySeniority ?? this.dailySeniority,
    otherBenefitsDaily: otherBenefitsDaily ?? this.otherBenefitsDaily,
    hourlyBenefits: hourlyBenefits ?? this.hourlyBenefits,
    startDate: startDate ?? this.startDate,
    isActive: isActive ?? this.isActive,
    notes: notes ?? this.notes,
  );
}
