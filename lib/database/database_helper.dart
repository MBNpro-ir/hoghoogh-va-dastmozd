import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_settings.dart';

/// مدیریت پایگاه داده SQLite برای ویندوز
class DatabaseHelper {
  static const String _dbName = 'payroll.db';
  static const int _dbVersion = 2;

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
    final dbPath = p.join(dbDir.path, _dbName);

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
        start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT
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
        total_installments INTEGER NOT NULL,
        paid_installments INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');

    // جدول فیش‌های حقوق
    await db.execute('''
      CREATE TABLE salary_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total_days INTEGER NOT NULL,
        leave_days INTEGER NOT NULL DEFAULT 0,
        work_days INTEGER NOT NULL,
        overtime_hours REAL DEFAULT 0,
        overtime_amount REAL DEFAULT 0,
        shift_work REAL DEFAULT 0,
        hourly_benefits_amount REAL DEFAULT 0,
        base_salary REAL NOT NULL,
        housing REAL DEFAULT 0,
        food REAL DEFAULT 0,
        marriage REAL DEFAULT 0,
        child_allowance REAL DEFAULT 0,
        seniority REAL DEFAULT 0,
        other_benefits REAL DEFAULT 0,
        total_earnings REAL NOT NULL,
        insurance REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        loan_installment REAL DEFAULT 0,
        advance REAL DEFAULT 0,
        other_deductions REAL DEFAULT 0,
        total_deductions REAL NOT NULL,
        insurance_base REAL NOT NULL,
        tax_base REAL NOT NULL,
        two_seven_exemption REAL DEFAULT 0,
        net_salary REAL NOT NULL,
        rounding INTEGER DEFAULT 0,
        final_payment REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        UNIQUE (employee_id, year, month),
        FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
      );
    ''');

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
        company_name TEXT NOT NULL,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final defaults = AppSettings().toMap()..remove('id');
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
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  Future<String> get databasePath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'payroll_app', _dbName);
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
