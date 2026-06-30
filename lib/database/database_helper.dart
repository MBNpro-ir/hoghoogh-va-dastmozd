import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_settings.dart';
import '../models/company_profile.dart';
import '../services/company_service.dart';
import '../utils/constants.dart';

/// مدیریت پایگاه داده SQLite برای ویندوز
class DatabaseHelper {
  static const int _dbVersion = 22;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// مقداردهی اولیه SQLite برای ویندوز/لینوکس
  static Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docsDir.path, 'payroll_app'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final dbPath = p.join(dbDir.path, await _activeDbName());

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول کارمندان
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personnel_code INTEGER NOT NULL UNIQUE,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        national_id TEXT NOT NULL,
        father_name TEXT DEFAULT '',
        birth_certificate_number TEXT DEFAULT '',
        gender TEXT DEFAULT 'مرد',
        workplace TEXT DEFAULT '',
        bank_name TEXT DEFAULT '',
        bank_account_type TEXT DEFAULT '',
        bank_account_number TEXT DEFAULT '',
        job_code TEXT DEFAULT '',
        job_title TEXT DEFAULT '',
        birth_date TEXT DEFAULT '',
        birth_place TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        has_prior_experience INTEGER NOT NULL DEFAULT 1,
        is_married INTEGER NOT NULL DEFAULT 0,
        children_count INTEGER NOT NULL DEFAULT 0,
        last_year_seniority REAL DEFAULT 0,
        base_salary_30_days REAL DEFAULT 0,
        daily_wage_1405 REAL DEFAULT 0,
        daily_wage_1404 REAL DEFAULT 0,
        daily_housing REAL DEFAULT 1000000,
        daily_food REAL DEFAULT 733333,
        daily_marriage REAL DEFAULT 0,
        daily_child_allowance REAL DEFAULT 554185,
        daily_seniority REAL DEFAULT 0,
        other_benefits_daily REAL DEFAULT 0,
        hourly_benefits REAL DEFAULT 0,
        contract_monthly_hours REAL NOT NULL DEFAULT 176,
        has_shift_work INTEGER NOT NULL DEFAULT 0,
        use_custom_overtime_base INTEGER NOT NULL DEFAULT 0,
        overtime_base_daily REAL NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        end_date TEXT DEFAULT '',
        card_number TEXT DEFAULT '',
        insurance_number TEXT DEFAULT '',
        education TEXT DEFAULT '',
        position TEXT DEFAULT '',
        employment_type TEXT DEFAULT 'قراردادی',
        address TEXT DEFAULT '',
        hard_and_harmful_job INTEGER NOT NULL DEFAULT 0,
        payslip_footer_note TEXT DEFAULT '',
        notes TEXT,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced'
      );
    ''');

    // جدول وام‌ها
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        loan_number INTEGER NOT NULL DEFAULT 1,
        amount REAL NOT NULL,
        installment_amount REAL NOT NULL,
        total_installments REAL NOT NULL,
        paid_installments REAL NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');

    // جدول فیش‌های حقوق
    await _createAdvancesTable(db);
    await _createLeavesTable(db);

    await db.execute('''
      CREATE TABLE salary_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_full_name_snapshot TEXT,
        employee_personnel_code_snapshot INTEGER,
        employee_national_id_snapshot TEXT,
        employee_payslip_footer_note_snapshot TEXT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total_days INTEGER NOT NULL,
        leave_days REAL NOT NULL DEFAULT 0,
        sick_leave_days REAL NOT NULL DEFAULT 0,
        work_days REAL NOT NULL,
        overtime_hours REAL DEFAULT 0,
        overtime_amount REAL DEFAULT 0,
        night_work_hours REAL DEFAULT 0,
        night_work_amount REAL DEFAULT 0,
        friday_work_hours REAL DEFAULT 0,
        friday_work_amount REAL DEFAULT 0,
        holiday_work_hours REAL DEFAULT 0,
        holiday_work_amount REAL DEFAULT 0,
        mission_days REAL DEFAULT 0,
        mission_amount REAL DEFAULT 0,
        use_part_time_wage INTEGER NOT NULL DEFAULT 0,
        part_time_work_hours REAL NOT NULL DEFAULT 0,
        use_custom_overtime_base INTEGER NOT NULL DEFAULT 0,
        overtime_base_daily REAL NOT NULL DEFAULT 0,
        shift_work REAL DEFAULT 0,
        shift_work_rate REAL NOT NULL DEFAULT 0,
        hourly_benefits_amount REAL DEFAULT 0,
        hourly_benefit_hours REAL DEFAULT 0,
        base_salary REAL NOT NULL,
        housing REAL DEFAULT 0,
        food REAL DEFAULT 0,
        marriage REAL DEFAULT 0,
        child_allowance REAL DEFAULT 0,
        seniority REAL DEFAULT 0,
        other_benefits REAL DEFAULT 0,
        job_related_benefits REAL NOT NULL DEFAULT 0,
        employee_related_benefits REAL NOT NULL DEFAULT 0,
        welfare_benefits REAL NOT NULL DEFAULT 0,
        total_earnings REAL NOT NULL,
        insurance REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        loan_installment REAL DEFAULT 0,
        advance REAL DEFAULT 0,
        supplementary_insurance REAL NOT NULL DEFAULT 0,
        other_deductions REAL DEFAULT 0,
        absence_days REAL DEFAULT 0,
        absence_hours REAL DEFAULT 0,
        absence_deduction REAL DEFAULT 0,
        include_leave_in_payslip INTEGER NOT NULL DEFAULT 1,
        housing_exempt INTEGER NOT NULL DEFAULT 0,
        food_exempt INTEGER NOT NULL DEFAULT 0,
        seniority_exempt INTEGER NOT NULL DEFAULT 0,
        leave_allowance_days REAL NOT NULL DEFAULT 2.5,
        excess_leave_days REAL NOT NULL DEFAULT 0,
        leave_deduction REAL NOT NULL DEFAULT 0,
        total_deductions REAL NOT NULL,
        insurance_base REAL NOT NULL,
        tax_base REAL NOT NULL,
        two_seven_exemption REAL DEFAULT 0,
        tax_relief_rate REAL NOT NULL DEFAULT 0,
        tax_relief_amount REAL NOT NULL DEFAULT 0,
        net_salary REAL NOT NULL,
        rounding INTEGER DEFAULT 0,
        final_payment REAL NOT NULL,
        payroll_calculation_details_json TEXT NOT NULL DEFAULT '{}',
        notes TEXT,
        created_at TEXT NOT NULL,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        UNIQUE (employee_id, year, month),
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');

    await _createSalaryDraftsTable(db);
    await _createSalaryPaymentStatusesTable(db);
    await _createCalculatorRunsTable(db);

    // جدول تنظیمات
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        daily_wage REAL NOT NULL,
        monthly_food REAL NOT NULL,
        monthly_housing REAL NOT NULL,
        monthly_marriage REAL NOT NULL,
        monthly_child REAL NOT NULL,
        daily_seniority REAL NOT NULL,
        salary_rate_a REAL NOT NULL,
        salary_rate_b REAL NOT NULL,
        fixed_rial REAL NOT NULL,
        employee_insurance_rate REAL NOT NULL,
        employer_insurance_rate REAL NOT NULL,
        unemployment_insurance_rate REAL NOT NULL,
        two_seven_base_rate REAL NOT NULL,
        monthly_leave_allowance REAL NOT NULL DEFAULT 2.5,
        annual_leave_allowance REAL NOT NULL DEFAULT 30,
        night_work_rate REAL NOT NULL DEFAULT 0.35,
        friday_work_rate REAL NOT NULL DEFAULT 0.40,
        holiday_work_multiplier REAL NOT NULL DEFAULT 1.40,
        mission_daily_multiplier REAL NOT NULL DEFAULT 1.0,
        absence_hourly_multiplier REAL NOT NULL DEFAULT 1.0,
        company_name TEXT NOT NULL,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        UNIQUE (year)
      );
    ''');

    // افزودن تنظیمات پیش‌فرض سال 1405
    await db.insert('app_settings', AppSettings().toMap()..remove('id'));

    // ایندکس برای سرعت
    await db.execute('CREATE INDEX idx_loans_employee ON loans(employee_id);');
    await db.execute(
      'CREATE INDEX idx_salary_employee ON salary_records(employee_id);',
    );
    await db.execute(
      'CREATE INDEX idx_salary_year_month ON salary_records(year, month);',
    );
    await _createSyncIndexes(db);
    await _createLeavesNaturalKeyIndex(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final defaults = AppSettings().toMap()..remove('id');
      defaults.remove('monthly_leave_allowance');
      defaults.remove('annual_leave_allowance');
      await db.update(
        'app_settings',
        defaults,
        where: 'year = ?',
        whereArgs: [AppSettings().year],
      );
      await db.update(
        'employees',
        {'daily_child_allowance': 554185},
        where: 'daily_child_allowance = ?',
        whereArgs: [166667],
      );
    }
    if (oldVersion < 3) {
      await _safeAddColumn(
        db,
        'salary_records',
        'hourly_benefit_hours REAL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'include_leave_in_payslip INTEGER NOT NULL DEFAULT 1',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'leave_allowance_days REAL NOT NULL DEFAULT 2.5',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'excess_leave_days REAL NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'leave_deduction REAL NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'app_settings',
        'monthly_leave_allowance REAL NOT NULL DEFAULT 2.5',
      );
      await _safeAddColumn(
        db,
        'app_settings',
        'annual_leave_allowance REAL NOT NULL DEFAULT 30',
      );
    }
    if (oldVersion < 4) {
      await _safeAddColumn(
        db,
        'salary_records',
        'employee_full_name_snapshot TEXT',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'employee_personnel_code_snapshot INTEGER',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'employee_national_id_snapshot TEXT',
      );
      await db.execute('''
        UPDATE salary_records
        SET employee_full_name_snapshot = (
          SELECT TRIM(first_name || ' ' || last_name)
          FROM employees
          WHERE employees.id = salary_records.employee_id
        )
        WHERE employee_full_name_snapshot IS NULL;
      ''');
      await db.execute('''
        UPDATE salary_records
        SET employee_personnel_code_snapshot = (
          SELECT personnel_code
          FROM employees
          WHERE employees.id = salary_records.employee_id
        )
        WHERE employee_personnel_code_snapshot IS NULL;
      ''');
      await db.execute('''
        UPDATE salary_records
        SET employee_national_id_snapshot = (
          SELECT national_id
          FROM employees
          WHERE employees.id = salary_records.employee_id
        )
        WHERE employee_national_id_snapshot IS NULL;
      ''');
    }
    if (oldVersion < 5) {
      await _safeAddColumn(db, 'employees', "father_name TEXT DEFAULT ''");
      await _safeAddColumn(
        db,
        'employees',
        "birth_certificate_number TEXT DEFAULT ''",
      );
      await _safeAddColumn(db, 'employees', "gender TEXT DEFAULT 'مرد'");
      await _safeAddColumn(db, 'employees', "workplace TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "bank_name TEXT DEFAULT ''");
      await _safeAddColumn(
        db,
        'employees',
        "bank_account_type TEXT DEFAULT ''",
      );
      await _safeAddColumn(
        db,
        'employees',
        "bank_account_number TEXT DEFAULT ''",
      );
      await _safeAddColumn(db, 'employees', "job_code TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "job_title TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "birth_date TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "birth_place TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "phone TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "end_date TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "card_number TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "insurance_number TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "education TEXT DEFAULT ''");
      await _safeAddColumn(db, 'employees', "position TEXT DEFAULT ''");
      await _safeAddColumn(
        db,
        'employees',
        "employment_type TEXT DEFAULT 'قراردادی'",
      );
      await _safeAddColumn(db, 'employees', "address TEXT DEFAULT ''");
      await _safeAddColumn(
        db,
        'employees',
        'hard_and_harmful_job INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'employees',
        "payslip_footer_note TEXT DEFAULT ''",
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'employee_payslip_footer_note_snapshot TEXT',
      );
    }
    if (oldVersion < 6) {
      await _addSyncColumns(db, 'employees');
      await _addSyncColumns(db, 'loans');
      await _addSyncColumns(db, 'salary_records');
      await _addSyncColumns(db, 'app_settings');
      await _createAdvancesTable(db);
      await _createLeavesTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 7) {
      for (final table in [
        'employees',
        'loans',
        'salary_records',
        'app_settings',
      ]) {
        await _safeAddColumn(db, table, 'server_updated_at TEXT');
      }
    }
    if (oldVersion < 8) {
      await _createAdvancesTable(db);
      await _createLeavesTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 9) {
      await _safeAddColumn(
        db,
        'salary_records',
        'sick_leave_days REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 10) {
      await _safeAddColumn(
        db,
        'employees',
        'has_shift_work INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'employees',
        'use_custom_overtime_base INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'employees',
        'overtime_base_daily REAL NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'use_custom_overtime_base INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'overtime_base_daily REAL NOT NULL DEFAULT 0',
      );
      await _createSalaryDraftsTable(db);
      await _createLeavesTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 11) {
      await _createLeavesTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 12) {
      await _createLeavesTable(db);
      await _migrateSalaryRecordLeaves(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 13) {
      await _safeAddColumn(
        db,
        'salary_records',
        'housing_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'food_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_records',
        'seniority_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_drafts',
        'housing_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_drafts',
        'food_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        'salary_drafts',
        'seniority_exempt INTEGER NOT NULL DEFAULT 0',
      );
      await _createSyncIndexes(db);
    }
    if (oldVersion < 14) {
      await _deduplicateLeaves(db);
      await _createLeavesNaturalKeyIndex(db);
    }
    if (oldVersion < 15) {
      await _createSalaryPaymentStatusesTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 16) {
      await _safeAddColumn(
        db,
        'salary_payment_statuses',
        "change_log TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute('''
        UPDATE salary_payment_statuses
        SET change_log = '[]'
        WHERE change_log IS NULL OR TRIM(change_log) = '';
      ''');
    }
    if (oldVersion < 17) {
      await _safeAddColumn(
        db,
        'salary_payment_statuses',
        'status_set INTEGER NOT NULL DEFAULT 1',
      );
      await _safeAddColumn(
        db,
        'salary_payment_statuses',
        'payment_unlocked INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 18) {
      await _safeAddColumn(
        db,
        'salary_drafts',
        'daily_seniority_override REAL NOT NULL DEFAULT -1',
      );
      await _safeAddColumn(
        db,
        'salary_drafts',
        'auto_seniority INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 19) {
      await _addPayrollCalculatorColumns(db);
      await _createCalculatorRunsTable(db);
      await _createSyncIndexes(db);
    }
    if (oldVersion < 20) {
      await _addComplementaryPayslipColumns(db);
    }
    if (oldVersion < 21) {
      await _addBidbargPartTimeColumns(db);
    }
    if (oldVersion < 22) {
      await _migrateInsuranceTaxDeductionRate(db);
    }
  }

  Future<void> _migrateInsuranceTaxDeductionRate(Database db) async {
    await db.update(
      'app_settings',
      {'two_seven_base_rate': AppConstants.twoSevenBaseRate},
      where: 'two_seven_base_rate >= ? AND two_seven_base_rate <= ?',
      whereArgs: [0.28, 0.29],
    );
  }

  Future<void> _addBidbargPartTimeColumns(Database db) async {
    await _safeAddColumn(
      db,
      'employees',
      'contract_monthly_hours REAL NOT NULL DEFAULT 176',
    );
    const payrollTables = ['salary_records', 'salary_drafts'];
    for (final table in payrollTables) {
      await _safeAddColumn(
        db,
        table,
        'use_part_time_wage INTEGER NOT NULL DEFAULT 0',
      );
      await _safeAddColumn(
        db,
        table,
        'part_time_work_hours REAL NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _addPayrollCalculatorColumns(Database db) async {
    const salaryRecordColumns = [
      'night_work_hours REAL DEFAULT 0',
      'night_work_amount REAL DEFAULT 0',
      'friday_work_hours REAL DEFAULT 0',
      'friday_work_amount REAL DEFAULT 0',
      'holiday_work_hours REAL DEFAULT 0',
      'holiday_work_amount REAL DEFAULT 0',
      'mission_days REAL DEFAULT 0',
      'mission_amount REAL DEFAULT 0',
      'absence_days REAL DEFAULT 0',
      'absence_hours REAL DEFAULT 0',
      'absence_deduction REAL DEFAULT 0',
      'shift_work_rate REAL NOT NULL DEFAULT 0',
      'job_related_benefits REAL NOT NULL DEFAULT 0',
      'employee_related_benefits REAL NOT NULL DEFAULT 0',
      'welfare_benefits REAL NOT NULL DEFAULT 0',
      'supplementary_insurance REAL NOT NULL DEFAULT 0',
      'tax_relief_rate REAL NOT NULL DEFAULT 0',
      'tax_relief_amount REAL NOT NULL DEFAULT 0',
      "payroll_calculation_details_json TEXT NOT NULL DEFAULT '{}'",
    ];
    const salaryDraftColumns = [
      'night_work_hours REAL NOT NULL DEFAULT 0',
      'night_work_amount REAL NOT NULL DEFAULT 0',
      'friday_work_hours REAL NOT NULL DEFAULT 0',
      'friday_work_amount REAL NOT NULL DEFAULT 0',
      'holiday_work_hours REAL NOT NULL DEFAULT 0',
      'holiday_work_amount REAL NOT NULL DEFAULT 0',
      'mission_days REAL NOT NULL DEFAULT 0',
      'mission_amount REAL NOT NULL DEFAULT 0',
      'absence_days REAL NOT NULL DEFAULT 0',
      'absence_hours REAL NOT NULL DEFAULT 0',
      'absence_deduction REAL NOT NULL DEFAULT 0',
      'shift_work_rate REAL NOT NULL DEFAULT 0',
      'job_related_benefits REAL NOT NULL DEFAULT 0',
      'employee_related_benefits REAL NOT NULL DEFAULT 0',
      'welfare_benefits REAL NOT NULL DEFAULT 0',
      'supplementary_insurance REAL NOT NULL DEFAULT 0',
      'tax_relief_rate REAL NOT NULL DEFAULT 0',
      "payroll_calculation_details_json TEXT NOT NULL DEFAULT '{}'",
    ];
    const settingsColumns = [
      'night_work_rate REAL NOT NULL DEFAULT 0.35',
      'friday_work_rate REAL NOT NULL DEFAULT 0.40',
      'holiday_work_multiplier REAL NOT NULL DEFAULT 1.40',
      'mission_daily_multiplier REAL NOT NULL DEFAULT 1.0',
      'absence_hourly_multiplier REAL NOT NULL DEFAULT 1.0',
    ];
    for (final column in salaryRecordColumns) {
      await _safeAddColumn(db, 'salary_records', column);
    }
    for (final column in salaryDraftColumns) {
      await _safeAddColumn(db, 'salary_drafts', column);
    }
    for (final column in settingsColumns) {
      await _safeAddColumn(db, 'app_settings', column);
    }
  }

  Future<void> _addComplementaryPayslipColumns(Database db) async {
    const salaryRecordColumns = [
      'shift_work_rate REAL NOT NULL DEFAULT 0',
      'job_related_benefits REAL NOT NULL DEFAULT 0',
      'employee_related_benefits REAL NOT NULL DEFAULT 0',
      'welfare_benefits REAL NOT NULL DEFAULT 0',
      'supplementary_insurance REAL NOT NULL DEFAULT 0',
      'tax_relief_rate REAL NOT NULL DEFAULT 0',
      'tax_relief_amount REAL NOT NULL DEFAULT 0',
    ];
    const salaryDraftColumns = [
      'shift_work_rate REAL NOT NULL DEFAULT 0',
      'job_related_benefits REAL NOT NULL DEFAULT 0',
      'employee_related_benefits REAL NOT NULL DEFAULT 0',
      'welfare_benefits REAL NOT NULL DEFAULT 0',
      'supplementary_insurance REAL NOT NULL DEFAULT 0',
      'tax_relief_rate REAL NOT NULL DEFAULT 0',
    ];
    for (final column in salaryRecordColumns) {
      await _safeAddColumn(db, 'salary_records', column);
    }
    for (final column in salaryDraftColumns) {
      await _safeAddColumn(db, 'salary_drafts', column);
    }
  }

  Future<void> _createSalaryDraftsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salary_drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total_days INTEGER NOT NULL,
        leave_days REAL NOT NULL DEFAULT 0,
        sick_leave_days REAL NOT NULL DEFAULT 0,
        overtime_hours REAL NOT NULL DEFAULT 0,
        night_work_hours REAL NOT NULL DEFAULT 0,
        night_work_amount REAL NOT NULL DEFAULT 0,
        friday_work_hours REAL NOT NULL DEFAULT 0,
        friday_work_amount REAL NOT NULL DEFAULT 0,
        holiday_work_hours REAL NOT NULL DEFAULT 0,
        holiday_work_amount REAL NOT NULL DEFAULT 0,
        mission_days REAL NOT NULL DEFAULT 0,
        mission_amount REAL NOT NULL DEFAULT 0,
        use_part_time_wage INTEGER NOT NULL DEFAULT 0,
        part_time_work_hours REAL NOT NULL DEFAULT 0,
        use_custom_overtime_base INTEGER NOT NULL DEFAULT 0,
        overtime_base_daily REAL NOT NULL DEFAULT 0,
        shift_work REAL NOT NULL DEFAULT 0,
        shift_work_rate REAL NOT NULL DEFAULT 0,
        auto_shift_work INTEGER NOT NULL DEFAULT 0,
        hourly_benefits_amount REAL NOT NULL DEFAULT 0,
        hourly_benefit_hours REAL NOT NULL DEFAULT 0,
        auto_hourly_benefits INTEGER NOT NULL DEFAULT 1,
        other_benefits_override REAL NOT NULL DEFAULT -1,
        auto_other_benefits INTEGER NOT NULL DEFAULT 1,
        job_related_benefits REAL NOT NULL DEFAULT 0,
        employee_related_benefits REAL NOT NULL DEFAULT 0,
        welfare_benefits REAL NOT NULL DEFAULT 0,
        daily_seniority_override REAL NOT NULL DEFAULT -1,
        auto_seniority INTEGER NOT NULL DEFAULT 1,
        loan_installment REAL NOT NULL DEFAULT 0,
        auto_loan_installment INTEGER NOT NULL DEFAULT 1,
        skip_loan_installment INTEGER NOT NULL DEFAULT 0,
        advance REAL NOT NULL DEFAULT 0,
        auto_advances INTEGER NOT NULL DEFAULT 1,
        supplementary_insurance REAL NOT NULL DEFAULT 0,
        other_deductions REAL NOT NULL DEFAULT 0,
        absence_days REAL NOT NULL DEFAULT 0,
        absence_hours REAL NOT NULL DEFAULT 0,
        absence_deduction REAL NOT NULL DEFAULT 0,
        include_leave_in_payslip INTEGER NOT NULL DEFAULT 1,
        insurance_exempt INTEGER NOT NULL DEFAULT 0,
        tax_exempt INTEGER NOT NULL DEFAULT 0,
        housing_exempt INTEGER NOT NULL DEFAULT 0,
        food_exempt INTEGER NOT NULL DEFAULT 0,
        seniority_exempt INTEGER NOT NULL DEFAULT 0,
        tax_relief_rate REAL NOT NULL DEFAULT 0,
        payroll_calculation_details_json TEXT NOT NULL DEFAULT '{}',
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        UNIQUE (employee_id, year, month),
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salary_drafts_employee_period '
      'ON salary_drafts(employee_id, year, month);',
    );
  }

  Future<void> _createCalculatorRunsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS calculator_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculator_id TEXT NOT NULL,
        employee_id INTEGER,
        year INTEGER NOT NULL,
        month INTEGER,
        inputs_json TEXT NOT NULL DEFAULT '{}',
        outputs_json TEXT NOT NULL DEFAULT '{}',
        formula_version TEXT NOT NULL,
        source_urls_json TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE SET NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_calculator_runs_created '
      'ON calculator_runs(created_at DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_calculator_runs_calculator '
      'ON calculator_runs(calculator_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_calculator_runs_employee '
      'ON calculator_runs(employee_id);',
    );
  }

  Future<void> _createAdvancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS advances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_advances_employee ON advances(employee_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_advances_payment_date ON advances(payment_date);',
    );
  }

  Future<void> _createSalaryPaymentStatusesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salary_payment_statuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        status_set INTEGER NOT NULL DEFAULT 0,
        payment_unlocked INTEGER NOT NULL DEFAULT 0,
        unpaid_reason TEXT NOT NULL DEFAULT '',
        updated_by_username TEXT NOT NULL DEFAULT '',
        updated_by_role TEXT NOT NULL DEFAULT '',
        status_changed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        change_log TEXT NOT NULL DEFAULT '[]',
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        UNIQUE (employee_id, year, month),
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salary_payment_statuses_employee_period '
      'ON salary_payment_statuses(employee_id, year, month);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salary_payment_statuses_period '
      'ON salary_payment_statuses(year, month);',
    );
  }

  Future<void> _createLeavesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        from_date TEXT NOT NULL,
        to_date TEXT NOT NULL,
        days REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'annual',
        status TEXT NOT NULL DEFAULT 'approved',
        notes TEXT,
        sync_id TEXT UNIQUE,
        server_updated_at TEXT,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'synced',
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_leaves_employee ON leaves(employee_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_leaves_from_date ON leaves(from_date);',
    );
  }

  Future<void> _deduplicateLeaves(Database db) async {
    await db.execute('''
      DELETE FROM leaves
      WHERE id IN (
        SELECT id
        FROM (
          SELECT
            id,
            ROW_NUMBER() OVER (
              PARTITION BY employee_id, from_date, to_date, type
              ORDER BY
                CASE WHEN server_updated_at IS NOT NULL THEN 0 ELSE 1 END,
                CASE WHEN sync_state = 'synced' THEN 0 ELSE 1 END,
                id DESC
            ) AS duplicate_rank
          FROM leaves
          WHERE deleted_at IS NULL
        ) ranked
        WHERE duplicate_rank > 1
      );
    ''');
    await db.update(
      'leaves',
      {'sync_state': 'pending'},
      where: '''
        deleted_at IS NULL
        AND server_updated_at IS NULL
        AND sync_state = 'synced'
      ''',
    );
  }

  Future<void> _createLeavesNaturalKeyIndex(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_leaves_employee_period_type_active_unique
      ON leaves(employee_id, from_date, to_date, type)
      WHERE deleted_at IS NULL;
    ''');
  }

  Future<void> _migrateSalaryRecordLeaves(Database db) async {
    final rows = await db.query(
      'salary_records',
      columns: [
        'employee_id',
        'year',
        'month',
        'leave_days',
        'sick_leave_days',
        'include_leave_in_payslip',
        'deleted_at',
      ],
      where: '''
        deleted_at IS NULL
        AND (
          COALESCE(leave_days, 0) > 0
          OR COALESCE(sick_leave_days, 0) > 0
        )
      ''',
      orderBy: 'year ASC, month ASC, employee_id ASC',
    );
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final employeeId = (row['employee_id'] as num?)?.toInt();
      final year = (row['year'] as num?)?.toInt();
      final month = (row['month'] as num?)?.toInt();
      if (employeeId == null || year == null || month == null) continue;
      final fromDate = '$year/${month.toString().padLeft(2, '0')}/01';
      final prefix = '$year/${month.toString().padLeft(2, '0')}/';
      final annualDays = (row['leave_days'] as num?)?.toDouble() ?? 0;
      final sickDays = (row['sick_leave_days'] as num?)?.toDouble() ?? 0;
      final includeAnnual = (row['include_leave_in_payslip'] as num?) != 0;

      if (annualDays > 0) {
        await _insertLegacyLeaveIfMissing(
          db: db,
          employeeId: employeeId,
          prefix: prefix,
          fromDate: fromDate,
          days: annualDays,
          type: 'annual',
          status: includeAnnual ? 'approved' : 'pending',
          notes: 'انتقال خودکار از فیش حقوق',
          updatedAt: now,
        );
      }
      if (sickDays > 0) {
        await _insertLegacyLeaveIfMissing(
          db: db,
          employeeId: employeeId,
          prefix: prefix,
          fromDate: fromDate,
          days: sickDays,
          type: 'sick',
          status: 'approved',
          notes: 'انتقال خودکار استعلاجی از فیش حقوق',
          updatedAt: now,
        );
      }
    }
  }

  Future<void> _insertLegacyLeaveIfMissing({
    required Database db,
    required int employeeId,
    required String prefix,
    required String fromDate,
    required double days,
    required String type,
    required String status,
    required String notes,
    required String updatedAt,
  }) async {
    final existing = await db.query(
      'leaves',
      columns: ['id'],
      where: '''
        employee_id = ?
        AND from_date LIKE ?
        AND type = ?
        AND deleted_at IS NULL
      ''',
      whereArgs: [employeeId, '$prefix%', type],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await db.insert('leaves', {
      'employee_id': employeeId,
      'from_date': fromDate,
      'to_date': fromDate,
      'days': days,
      'type': type,
      'status': status,
      'notes': notes,
      'updated_at': updatedAt,
      'sync_state': 'pending',
    });
  }

  Future<void> _addSyncColumns(Database db, String table) async {
    await _safeAddColumn(db, table, 'sync_id TEXT');
    await _safeAddColumn(db, table, 'server_updated_at TEXT');
    await _safeAddColumnWithCurrentTimestampDefault(db, table, 'updated_at');
    await _safeAddColumn(db, table, 'deleted_at TEXT');
    await _safeAddColumn(
      db,
      table,
      "sync_state TEXT NOT NULL DEFAULT 'pending'",
    );
  }

  Future<void> _createSyncIndexes(Database db) async {
    for (final table in [
      'employees',
      'loans',
      'advances',
      'leaves',
      'salary_records',
      'salary_payment_statuses',
      'salary_drafts',
      'calculator_runs',
      'app_settings',
    ]) {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${table}_sync_id ON $table(sync_id);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_sync_state ON $table(sync_state);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_deleted_at ON $table(deleted_at);',
      );
    }
  }

  Future<void> _safeAddColumn(
    Database db,
    String table,
    String columnSql,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnSql;');
    } catch (e) {
      if (!e.toString().toLowerCase().contains('duplicate column')) {
        rethrow;
      }
    }
  }

  Future<void> _safeAddColumnWithCurrentTimestampDefault(
    Database db,
    String table,
    String column,
  ) async {
    final now = DateTime.now().toIso8601String().replaceAll("'", "''");
    await _safeAddColumn(db, table, "$column TEXT NOT NULL DEFAULT '$now'");
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  Future<String> _activeDbName() async {
    final prefs = await SharedPreferences.getInstance();
    final dbName = prefs.getString(CompanyService.currentCompanyDbPrefsKey);
    if (dbName == null || dbName.trim().isEmpty) {
      return CompanyServiceDefaults.defaultDbName;
    }
    return dbName;
  }

  Future<String> get databasePath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'payroll_app', await _activeDbName());
  }

  /// حذف کل دیتابیس (برای reset)
  Future<void> resetDatabase() async {
    final dbPath = await databasePath;
    await close();
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
