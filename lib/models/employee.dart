class Employee {
  final int? id;
  final int personnelCode;
  final String firstName;
  final String lastName;
  final String nationalId;
  final String fatherName;
  final String birthCertificateNumber;
  final String gender;
  final String workplace;
  final String bankName;
  final String bankAccountType;
  final String bankAccountNumber;
  final String jobCode;
  final String jobTitle;
  final String birthDate;
  final String birthPlace;
  final String phone;
  final bool hasPriorExperience;
  final bool isMarried;
  final int childrenCount;
  final double lastYearSeniority;
  final double baseSalary30Days;
  final double dailyWage1405;
  final double dailyWage1404;
  final double dailyHousing;
  final double dailyFood;
  final double dailyMarriage;
  final double dailyChildAllowance;
  final double dailySeniority;
  final double otherBenefitsDaily;
  final double hourlyBenefits;
  final bool hasShiftWork;
  final bool useCustomOvertimeBase;
  final double overtimeBaseDaily;
  final String startDate;
  final bool isActive;
  final String endDate;
  final String cardNumber;
  final String insuranceNumber;
  final String education;
  final String position;
  final String employmentType;
  final String address;
  final bool hardAndHarmfulJob;
  final String payslipFooterNote;
  final String? notes;

  Employee({
    this.id,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    this.fatherName = '',
    this.birthCertificateNumber = '',
    this.gender = 'مرد',
    this.workplace = '',
    this.bankName = '',
    this.bankAccountType = '',
    this.bankAccountNumber = '',
    this.jobCode = '',
    this.jobTitle = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.phone = '',
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
    this.hasShiftWork = false,
    this.useCustomOvertimeBase = false,
    this.overtimeBaseDaily = 0,
    required this.startDate,
    this.isActive = true,
    this.endDate = '',
    this.cardNumber = '',
    this.insuranceNumber = '',
    this.education = '',
    this.position = '',
    this.employmentType = 'قراردادی',
    this.address = '',
    this.hardAndHarmfulJob = false,
    this.payslipFooterNote = '',
    this.notes,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayJob {
    if (jobTitle.trim().isNotEmpty && jobCode.trim().isNotEmpty) {
      return '$jobTitle - $jobCode';
    }
    if (jobTitle.trim().isNotEmpty) return jobTitle;
    if (position.trim().isNotEmpty) return position;
    return '';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'personnel_code': personnelCode,
    'first_name': firstName,
    'last_name': lastName,
    'national_id': nationalId,
    'father_name': fatherName,
    'birth_certificate_number': birthCertificateNumber,
    'gender': gender,
    'workplace': workplace,
    'bank_name': bankName,
    'bank_account_type': bankAccountType,
    'bank_account_number': bankAccountNumber,
    'job_code': jobCode,
    'job_title': jobTitle,
    'birth_date': birthDate,
    'birth_place': birthPlace,
    'phone': phone,
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
    'has_shift_work': hasShiftWork ? 1 : 0,
    'use_custom_overtime_base': useCustomOvertimeBase ? 1 : 0,
    'overtime_base_daily': overtimeBaseDaily,
    'start_date': startDate,
    'is_active': isActive ? 1 : 0,
    'end_date': endDate,
    'card_number': cardNumber,
    'insurance_number': insuranceNumber,
    'education': education,
    'position': position,
    'employment_type': employmentType,
    'address': address,
    'hard_and_harmful_job': hardAndHarmfulJob ? 1 : 0,
    'payslip_footer_note': payslipFooterNote,
    'notes': notes,
  };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'] as int?,
    personnelCode: (map['personnel_code'] as num).toInt(),
    firstName: map['first_name'] as String? ?? '',
    lastName: map['last_name'] as String? ?? '',
    nationalId: map['national_id'] as String? ?? '',
    fatherName: map['father_name'] as String? ?? '',
    birthCertificateNumber: map['birth_certificate_number'] as String? ?? '',
    gender: map['gender'] as String? ?? 'مرد',
    workplace: map['workplace'] as String? ?? '',
    bankName: map['bank_name'] as String? ?? '',
    bankAccountType: map['bank_account_type'] as String? ?? '',
    bankAccountNumber: map['bank_account_number'] as String? ?? '',
    jobCode: map['job_code'] as String? ?? '',
    jobTitle: map['job_title'] as String? ?? '',
    birthDate: map['birth_date'] as String? ?? '',
    birthPlace: map['birth_place'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    hasPriorExperience: (map['has_prior_experience'] as int? ?? 0) == 1,
    isMarried: (map['is_married'] as int? ?? 0) == 1,
    childrenCount: (map['children_count'] as num?)?.toInt() ?? 0,
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
    hasShiftWork: (map['has_shift_work'] as int? ?? 0) == 1,
    useCustomOvertimeBase: (map['use_custom_overtime_base'] as int? ?? 0) == 1,
    overtimeBaseDaily: (map['overtime_base_daily'] as num?)?.toDouble() ?? 0,
    startDate: map['start_date'] as String? ?? '',
    isActive: (map['is_active'] as int? ?? 1) == 1,
    endDate: map['end_date'] as String? ?? '',
    cardNumber: map['card_number'] as String? ?? '',
    insuranceNumber: map['insurance_number'] as String? ?? '',
    education: map['education'] as String? ?? '',
    position: map['position'] as String? ?? '',
    employmentType: map['employment_type'] as String? ?? 'قراردادی',
    address: map['address'] as String? ?? '',
    hardAndHarmfulJob: (map['hard_and_harmful_job'] as int? ?? 0) == 1,
    payslipFooterNote: map['payslip_footer_note'] as String? ?? '',
    notes: map['notes'] as String?,
  );

  Employee copyWith({
    int? id,
    int? personnelCode,
    String? firstName,
    String? lastName,
    String? nationalId,
    String? fatherName,
    String? birthCertificateNumber,
    String? gender,
    String? workplace,
    String? bankName,
    String? bankAccountType,
    String? bankAccountNumber,
    String? jobCode,
    String? jobTitle,
    String? birthDate,
    String? birthPlace,
    String? phone,
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
    bool? hasShiftWork,
    bool? useCustomOvertimeBase,
    double? overtimeBaseDaily,
    String? startDate,
    bool? isActive,
    String? endDate,
    String? cardNumber,
    String? insuranceNumber,
    String? education,
    String? position,
    String? employmentType,
    String? address,
    bool? hardAndHarmfulJob,
    String? payslipFooterNote,
    String? notes,
  }) => Employee(
    id: id ?? this.id,
    personnelCode: personnelCode ?? this.personnelCode,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    nationalId: nationalId ?? this.nationalId,
    fatherName: fatherName ?? this.fatherName,
    birthCertificateNumber:
        birthCertificateNumber ?? this.birthCertificateNumber,
    gender: gender ?? this.gender,
    workplace: workplace ?? this.workplace,
    bankName: bankName ?? this.bankName,
    bankAccountType: bankAccountType ?? this.bankAccountType,
    bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
    jobCode: jobCode ?? this.jobCode,
    jobTitle: jobTitle ?? this.jobTitle,
    birthDate: birthDate ?? this.birthDate,
    birthPlace: birthPlace ?? this.birthPlace,
    phone: phone ?? this.phone,
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
    hasShiftWork: hasShiftWork ?? this.hasShiftWork,
    useCustomOvertimeBase: useCustomOvertimeBase ?? this.useCustomOvertimeBase,
    overtimeBaseDaily: overtimeBaseDaily ?? this.overtimeBaseDaily,
    startDate: startDate ?? this.startDate,
    isActive: isActive ?? this.isActive,
    endDate: endDate ?? this.endDate,
    cardNumber: cardNumber ?? this.cardNumber,
    insuranceNumber: insuranceNumber ?? this.insuranceNumber,
    education: education ?? this.education,
    position: position ?? this.position,
    employmentType: employmentType ?? this.employmentType,
    address: address ?? this.address,
    hardAndHarmfulJob: hardAndHarmfulJob ?? this.hardAndHarmfulJob,
    payslipFooterNote: payslipFooterNote ?? this.payslipFooterNote,
    notes: notes ?? this.notes,
  );
}
