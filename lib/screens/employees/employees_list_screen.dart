import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../services/employee_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/persian_number_formatter.dart';
import '../../widgets/currency_text.dart';
import 'employee_form_screen.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final _service = EmployeeService();
  List<Employee> _employees = [];
  String _filter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  List<Employee> get _filteredEmployees {
    if (_filter.trim().isEmpty) return _employees;
    final f = PersianNumberFormatter.toEnglish(_filter.trim());
    return _employees.where((e) {
      return e.firstName.contains(_filter) ||
          e.lastName.contains(_filter) ||
          e.nationalId.contains(f) ||
          e.personnelCode.toString().contains(f);
    }).toList();
  }

  Future<void> _openForm({Employee? employee}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کارمند'),
        content: Text(
          'آیا از حذف کارمند «${employee.fullName}» مطمئن هستید؟\n'
          'تمام وام‌ها و فیش‌های حقوق این کارمند نیز حذف خواهد شد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && employee.id != null) {
      await _service.delete(employee.id!);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کارمند با موفقیت حذف شد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کارمندان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'بازخوانی',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('کارمند جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: const InputDecoration(
                      hintText: 'جستجو بر اساس نام، کد ملی یا کد پرسنلی...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'تعداد: ${PersianNumberFormatter.toPersian(_filteredEmployees.length.toString())} نفر',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? const _EmptyState()
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.tableHeaderPurple),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(fontSize: 13),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('کد پرسنلی')),
                DataColumn(label: Text('نام')),
                DataColumn(label: Text('نام خانوادگی')),
                DataColumn(label: Text('کد ملی')),
                DataColumn(label: Text('تاهل')),
                DataColumn(label: Text('فرزند')),
                DataColumn(label: Text('دستمزد روزانه ۱۴۰۵'), numeric: true),
                DataColumn(label: Text('حقوق پایه (۳۰روز)'), numeric: true),
                DataColumn(label: Text('تاریخ استخدام')),
                DataColumn(label: Text('عملیات')),
              ],
              rows: _filteredEmployees
                  .map((e) => DataRow(
                        cells: [
                          DataCell(
                            Text(PersianNumberFormatter.toPersian(e.personnelCode.toString())),
                          ),
                          DataCell(Text(e.firstName)),
                          DataCell(Text(e.lastName)),
                          DataCell(Text(PersianNumberFormatter.toPersian(e.nationalId))),
                          DataCell(
                            Icon(
                              e.isMarried ? Icons.check_circle : Icons.cancel,
                              color: e.isMarried ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ),
                          DataCell(
                            Text(PersianNumberFormatter.toPersian(e.childrenCount.toString())),
                          ),
                          DataCell(CurrencyText(e.dailyWage1405)),
                          DataCell(CurrencyText(e.baseSalary30Days)),
                          DataCell(Text(PersianNumberFormatter.toPersian(e.startDate))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: AppTheme.primaryColor),
                                tooltip: 'ویرایش',
                                onPressed: () => _openForm(employee: e),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                tooltip: 'حذف',
                                onPressed: () => _delete(e),
                              ),
                            ],
                          )),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 96, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'هنوز کارمندی ثبت نشده است',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('برای شروع روی دکمه «کارمند جدید» کلیک کنید'),
        ],
      ),
    );
  }
}
