import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/company_profile.dart';

class CompanyService {
  static const companiesPrefsKey = 'payroll_companies';
  static const currentCompanyDbPrefsKey = 'payroll_current_company_db';

  Future<List<CompanyProfile>> getCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(companiesPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      final defaults = [_defaultCompany];
      await _saveCompanies(prefs, defaults);
      await prefs.setString(
        currentCompanyDbPrefsKey,
        CompanyServiceDefaults.defaultDbName,
      );
      return defaults;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final companies = decoded
        .map((item) => CompanyProfile.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id.isNotEmpty && item.dbName.isNotEmpty)
        .toList();
    if (companies.isEmpty) {
      final defaults = [_defaultCompany];
      await _saveCompanies(prefs, defaults);
      return defaults;
    }
    return companies;
  }

  Future<CompanyProfile> getCurrentCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await getCompanies();
    final currentDb =
        prefs.getString(currentCompanyDbPrefsKey) ??
        CompanyServiceDefaults.defaultDbName;
    return companies.firstWhere(
      (company) => company.dbName == currentDb,
      orElse: () => companies.first,
    );
  }

  Future<String> getCurrentDbName() async {
    final current = await getCurrentCompany();
    return current.dbName;
  }

  Future<CompanyProfile> addCompany(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final companies = await getCompanies();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final company = CompanyProfile(
      id: timestamp.toString(),
      name: name.trim(),
      dbName: 'payroll_company_$timestamp.db',
    );
    final next = [...companies, company];
    await _saveCompanies(prefs, next);
    await prefs.setString(currentCompanyDbPrefsKey, company.dbName);
    return company;
  }

  Future<void> switchCompany(CompanyProfile company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentCompanyDbPrefsKey, company.dbName);
  }

  Future<void> syncCurrentCompanyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCurrentCompany();
    final companies = await getCompanies();
    final next = companies
        .map(
          (company) => company.id == current.id
              ? company.copyWith(name: name.trim())
              : company,
        )
        .toList();
    await _saveCompanies(prefs, next);
  }

  CompanyProfile get _defaultCompany => const CompanyProfile(
    id: CompanyServiceDefaults.defaultId,
    name: CompanyServiceDefaults.defaultName,
    dbName: CompanyServiceDefaults.defaultDbName,
  );

  Future<void> _saveCompanies(
    SharedPreferences prefs,
    List<CompanyProfile> companies,
  ) {
    return prefs.setString(
      companiesPrefsKey,
      jsonEncode(companies.map((item) => item.toJson()).toList()),
    );
  }
}
