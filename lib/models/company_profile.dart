class CompanyProfile {
  final String id;
  final String name;
  final String dbName;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.dbName,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'db_name': dbName};

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    dbName: json['db_name'] as String? ?? CompanyServiceDefaults.defaultDbName,
  );

  CompanyProfile copyWith({String? name}) =>
      CompanyProfile(id: id, name: name ?? this.name, dbName: dbName);
}

class CompanyServiceDefaults {
  static const defaultId = 'default';
  static const defaultDbName = 'payroll.db';
  static const defaultName = 'شرکت اصلی';
}
