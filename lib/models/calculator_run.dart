class CalculatorRun {
  final int? id;
  final int? employeeId;
  final String calculatorId;
  final int year;
  final int? month;
  final String inputsJson;
  final String outputsJson;
  final String formulaVersion;
  final String sourceUrlsJson;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? syncId;
  final String? serverUpdatedAt;
  final String syncState;

  CalculatorRun({
    this.id,
    this.employeeId,
    required this.calculatorId,
    required this.year,
    this.month,
    required this.inputsJson,
    required this.outputsJson,
    required this.formulaVersion,
    required this.sourceUrlsJson,
    DateTime? createdAt,
    this.deletedAt,
    this.syncId,
    this.serverUpdatedAt,
    this.syncState = 'synced',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'calculator_id': calculatorId,
    'year': year,
    'month': month,
    'inputs_json': inputsJson,
    'outputs_json': outputsJson,
    'formula_version': formulaVersion,
    'source_urls_json': sourceUrlsJson,
    'created_at': createdAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'sync_id': syncId,
    'server_updated_at': serverUpdatedAt,
    'sync_state': syncState,
  };

  factory CalculatorRun.fromMap(Map<String, dynamic> map) => CalculatorRun(
    id: (map['id'] as num?)?.toInt(),
    employeeId: (map['employee_id'] as num?)?.toInt(),
    calculatorId: map['calculator_id']?.toString() ?? '',
    year: (map['year'] as num?)?.toInt() ?? 0,
    month: (map['month'] as num?)?.toInt(),
    inputsJson: map['inputs_json']?.toString() ?? '{}',
    outputsJson: map['outputs_json']?.toString() ?? '{}',
    formulaVersion: map['formula_version']?.toString() ?? '1',
    sourceUrlsJson: map['source_urls_json']?.toString() ?? '[]',
    createdAt:
        DateTime.tryParse(map['created_at']?.toString() ?? '') ??
        DateTime.now(),
    deletedAt: DateTime.tryParse(map['deleted_at']?.toString() ?? ''),
    syncId: map['sync_id']?.toString(),
    serverUpdatedAt: map['server_updated_at']?.toString(),
    syncState: map['sync_state']?.toString() ?? 'synced',
  );
}
