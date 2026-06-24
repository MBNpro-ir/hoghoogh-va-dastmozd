import 'package:flutter/material.dart';

import '../utils/period_filter_helper.dart';
import 'mobile_collapsible_panel.dart';
import 'mouse_wheel_picker.dart';

class PeriodFilterBar extends StatelessWidget {
  final (int, int)? selectedPeriod;
  final List<(int, int)> availablePeriods;
  final ValueChanged<(int, int)?> onPeriodChanged;
  final TextEditingController searchController;
  final UndoHistoryController? searchUndoController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final Widget? trailing;

  const PeriodFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.availablePeriods,
    required this.onPeriodChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchHint,
    this.searchUndoController,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final periods = availablePeriods.toSet().toList();
    final selected = selectedPeriod != null && periods.contains(selectedPeriod)
        ? selectedPeriod
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final period = _periodDropdown(selected, periods);
        final search = _searchField();
        if (constraints.maxWidth < 720) {
          return MobileCollapsiblePanel(
            title: 'فیلتر و جستجو',
            icon: Icons.filter_alt_rounded,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                period,
                const SizedBox(height: 10),
                search,
                if (trailing != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: trailing!,
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'فیلتر دوره',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 230, child: period),
                  const SizedBox(width: 12),
                  Expanded(child: search),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _periodDropdown((int, int)? selected, List<(int, int)> periods) {
    final options = <(int, int)?>[null, ...periods];
    return MouseWheelPicker<(int, int)?>(
      value: selected,
      options: options,
      onChanged: onPeriodChanged,
      child: DropdownButtonFormField<(int, int)?>(
        key: ValueKey(
          'period-filter-${selected == null ? 'all' : '${selected.$1}-${selected.$2}'}',
        ),
        initialValue: selected,
        decoration: const InputDecoration(
          labelText: 'دوره',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<(int, int)?>(
            value: null,
            child: Text('همه دوره‌ها'),
          ),
          ...periods.map(
            (period) => DropdownMenuItem(
              value: period,
              child: Text(PeriodFilterHelper.label(period)),
            ),
          ),
        ],
        onChanged: onPeriodChanged,
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      key: const ValueKey('period-filter-search'),
      controller: searchController,
      undoController: searchUndoController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}
