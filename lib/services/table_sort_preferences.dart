import 'package:shared_preferences/shared_preferences.dart';

class TableSortState {
  final int columnIndex;
  final bool ascending;

  const TableSortState({required this.columnIndex, required this.ascending});
}

class TableSortPreferences {
  static const _prefix = 'hvm_table_sort_v1';
  static final Map<String, TableSortState> _cache = {};

  static TableSortState cached(
    String tableKey, {
    required int defaultColumnIndex,
    required bool defaultAscending,
  }) {
    return _cache[tableKey] ??
        TableSortState(
          columnIndex: defaultColumnIndex,
          ascending: defaultAscending,
        );
  }

  static Future<TableSortState> load(
    String tableKey, {
    required int defaultColumnIndex,
    required bool defaultAscending,
  }) async {
    final cachedState = _cache[tableKey];
    if (cachedState != null) return cachedState;

    final preferences = await SharedPreferences.getInstance();
    final stateSavedWhileLoading = _cache[tableKey];
    if (stateSavedWhileLoading != null) return stateSavedWhileLoading;

    final state = TableSortState(
      columnIndex:
          preferences.getInt('${_prefix}_${tableKey}_column') ??
          defaultColumnIndex,
      ascending:
          preferences.getBool('${_prefix}_${tableKey}_ascending') ??
          defaultAscending,
    );
    _cache[tableKey] = state;
    return state;
  }

  static Future<void> save(
    String tableKey, {
    required int columnIndex,
    required bool ascending,
  }) async {
    final state = TableSortState(
      columnIndex: columnIndex,
      ascending: ascending,
    );
    _cache[tableKey] = state;

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setInt('${_prefix}_${tableKey}_column', columnIndex),
      preferences.setBool('${_prefix}_${tableKey}_ascending', ascending),
    ]);
  }

  static void clearMemoryCache() => _cache.clear();
}
