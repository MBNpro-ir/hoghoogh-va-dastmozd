import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/services/table_sort_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TableSortPreferences.clearMemoryCache();
  });

  test('returns table defaults when no sort preference exists', () async {
    final state = await TableSortPreferences.load(
      'test_defaults',
      defaultColumnIndex: 4,
      defaultAscending: false,
    );

    expect(state.columnIndex, 4);
    expect(state.ascending, isFalse);
  });

  test('restores saved sort after the memory cache is cleared', () async {
    await TableSortPreferences.save(
      'test_persistence',
      columnIndex: 2,
      ascending: true,
    );
    TableSortPreferences.clearMemoryCache();

    final state = await TableSortPreferences.load(
      'test_persistence',
      defaultColumnIndex: 0,
      defaultAscending: false,
    );

    expect(state.columnIndex, 2);
    expect(state.ascending, isTrue);
  });
}
