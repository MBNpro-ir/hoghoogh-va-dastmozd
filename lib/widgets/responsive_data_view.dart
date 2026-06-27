import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'floating_nav_safe_area.dart';
import 'mobile_collapsible_panel.dart';

class ResponsiveTableColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final Object? Function(T item)? sortValue;
  final bool numeric;
  final double? width;

  const ResponsiveTableColumn({
    required this.label,
    required this.cellBuilder,
    this.sortValue,
    this.numeric = false,
    this.width,
  });
}

class ResponsiveDataView<T> extends StatelessWidget {
  final List<T> items;
  final List<ResponsiveTableColumn<T>> columns;
  final Widget Function(BuildContext context, T item, int index)
  mobileCardBuilder;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSortColumnChanged;
  final ValueChanged<bool> onSortDirectionChanged;
  final Color? accentColor;
  final Widget? mobileHeader;

  const ResponsiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.mobileCardBuilder,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSortColumnChanged,
    required this.onSortDirectionChanged,
    this.accentColor,
    this.mobileHeader,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              _MobileSortStrip<T>(
                columns: columns,
                selectedIndex: sortColumnIndex,
                ascending: sortAscending,
                onColumnChanged: onSortColumnChanged,
                onDirectionChanged: onSortDirectionChanged,
                accentColor: accentColor,
              ),
              ?mobileHeader,
              Expanded(
                child: ListView.separated(
                  padding: FloatingNavSafeArea.scrollPadding(
                    context,
                    left: 12,
                    top: 8,
                    right: 12,
                    minimumBottom: 88,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      mobileCardBuilder(context, items[index], index),
                ),
              ),
            ],
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final headerColor = accentColor ?? scheme.primary;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: _DesktopDataTable<T>(
            items: items,
            columns: columns,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            onSortColumnChanged: onSortColumnChanged,
            onSortDirectionChanged: onSortDirectionChanged,
            headerColor: headerColor,
          ),
        );
      },
    );
  }
}

class _DesktopDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<ResponsiveTableColumn<T>> columns;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSortColumnChanged;
  final ValueChanged<bool> onSortDirectionChanged;
  final Color headerColor;

  const _DesktopDataTable({
    required this.items,
    required this.columns,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSortColumnChanged,
    required this.onSortDirectionChanged,
    required this.headerColor,
  });

  @override
  State<_DesktopDataTable<T>> createState() => _DesktopDataTableState<T>();
}

class _DesktopDataTableState<T> extends State<_DesktopDataTable<T>> {
  static const _frozenColumnCount = 3;
  static const _headerHeight = 58.0;
  static const _rowHeight = 48.0;
  static const _scrollbarThickness = 10.0;
  static const _minColumnWidth = 64.0;
  static const _maxColumnWidth = 360.0;

  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final _frozenVerticalController = ScrollController();
  final Map<int, double> _columnWidthOverrides = {};
  bool _syncingVertical = false;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_syncFrozenToBody);
    _frozenVerticalController.addListener(_syncBodyToFrozen);
  }

  @override
  void dispose() {
    _verticalController.removeListener(_syncFrozenToBody);
    _frozenVerticalController.removeListener(_syncBodyToFrozen);
    _horizontalController.dispose();
    _verticalController.dispose();
    _frozenVerticalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DesktopDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _columnWidthOverrides.removeWhere(
      (index, _) => index >= widget.columns.length,
    );
  }

  void _syncFrozenToBody() {
    _syncVertical(_verticalController, _frozenVerticalController);
  }

  void _syncBodyToFrozen() {
    _syncVertical(_frozenVerticalController, _verticalController);
  }

  void _syncVertical(ScrollController source, ScrollController target) {
    if (_syncingVertical || !source.hasClients || !target.hasClients) return;
    if (!source.position.hasContentDimensions ||
        !target.position.hasContentDimensions) {
      return;
    }

    final targetOffset = source.offset
        .clamp(target.position.minScrollExtent, target.position.maxScrollExtent)
        .toDouble();
    if ((target.offset - targetOffset).abs() < 0.5) return;

    _syncingVertical = true;
    target.jumpTo(targetOffset);
    _syncingVertical = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final specs = [
      for (var i = 0; i < widget.columns.length; i++)
        _TableColumnSpec<T>(
          index: i,
          column: widget.columns[i],
          width: _effectiveColumnWidth(widget.columns[i], i),
        ),
    ];
    final frozenCount = math.min(_frozenColumnCount, specs.length);
    final frozenSpecs = specs.take(frozenCount).toList(growable: false);
    final scrollableSpecs = specs.skip(frozenCount).toList(growable: false);
    final frozenWidth = frozenSpecs.fold<double>(
      0,
      (total, spec) => total + spec.width,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : math.max(
                  360.0,
                  math.min(620.0, widget.items.length * _rowHeight + 96),
                );
          final scrollableWidth = math.max(
            scrollableSpecs.fold<double>(
              0,
              (total, spec) => total + spec.width,
            ),
            constraints.maxWidth.isFinite
                ? math.max(0.0, constraints.maxWidth - frozenWidth)
                : 0.0,
          );

          return SizedBox(
            height: tableHeight,
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _frozenPane(frozenSpecs, frozenWidth, scheme),
                if (scrollableSpecs.isNotEmpty)
                  Expanded(
                    child: _scrollablePane(
                      scrollableSpecs,
                      scrollableWidth,
                      scheme,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _effectiveColumnWidth(ResponsiveTableColumn<T> column, int index) {
    return _columnWidthOverrides[index] ?? _defaultColumnWidth(column, index);
  }

  double _defaultColumnWidth(ResponsiveTableColumn<T> column, int index) {
    if (column.width != null) {
      return column.width!.clamp(_minColumnWidth, _maxColumnWidth).toDouble();
    }

    final label = column.label;
    if (index == 0 || label.contains('ردیف')) return 70;
    if (index == 1 || label == 'کد' || label.contains('کد کارمند')) return 92;
    if (index == 2 || label.contains('نام')) return 210;
    if (label.contains('عملیات')) return 118;
    if (label.contains('توضیحات') || label.contains('شرح')) return 240;
    if (label.contains('دوره')) return 126;
    if (label.contains('کارکرد') || label.contains('استعلاجی')) return 104;
    if (label.contains('خالص')) return 156;
    if (label.contains('جمع')) return 150;
    if (label.contains('مالیات') ||
        label.contains('بیمه') ||
        label.contains('قسط') ||
        label.contains('مساعده')) {
      return 132;
    }
    if (column.numeric) return 126;
    final textDrivenWidth = 88 + math.min(128, label.runes.length * 7);
    return textDrivenWidth.clamp(_minColumnWidth, _maxColumnWidth).toDouble();
  }

  Widget _frozenPane(
    List<_TableColumnSpec<T>> specs,
    double width,
    ColorScheme scheme,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            _headerRow(specs, scheme, frozen: true),
            Expanded(
              child: Scrollbar(
                controller: _frozenVerticalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                thickness: _scrollbarThickness,
                radius: const Radius.circular(8),
                scrollbarOrientation: ScrollbarOrientation.right,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: _withoutAutomaticScrollbars(
                  child: SingleChildScrollView(
                    controller: _frozenVerticalController,
                    primary: false,
                    child: _bodyRows(specs, scheme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollablePane(
    List<_TableColumnSpec<T>> specs,
    double width,
    ColorScheme scheme,
  ) {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: _scrollbarThickness,
      radius: const Radius.circular(8),
      scrollbarOrientation: ScrollbarOrientation.bottom,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: _withoutAutomaticScrollbars(
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          primary: false,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _headerRow(specs, scheme),
                Expanded(
                  child: _withoutAutomaticScrollbars(
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      primary: false,
                      child: _bodyRows(specs, scheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(
    List<_TableColumnSpec<T>> specs,
    ColorScheme scheme, {
    bool frozen = false,
  }) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: widget.headerColor.withValues(alpha: frozen ? 0.18 : 0.14),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [for (final spec in specs) _headerCell(spec, scheme)],
      ),
    );
  }

  Widget _headerCell(_TableColumnSpec<T> spec, ColorScheme scheme) {
    final sortable = spec.column.sortValue != null;
    final selected = widget.sortColumnIndex == spec.index;
    final icon = selected
        ? (widget.sortAscending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded)
        : Icons.unfold_more_rounded;

    return SizedBox(
      key: ValueKey('responsive-header-cell-${spec.index}'),
      width: spec.width,
      height: _headerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: sortable ? () => _sortBy(spec.index) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: spec.column.numeric
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          spec.column.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (sortable) ...[
                        const SizedBox(width: 6),
                        Icon(
                          icon,
                          size: 16,
                          color: selected
                              ? widget.headerColor
                              : scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                key: ValueKey('responsive-column-resize-${spec.index}'),
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) =>
                    _resizeColumn(spec, details.delta.dx),
                child: SizedBox(
                  width: 12,
                  child: Center(
                    child: Container(
                      width: 1,
                      height: 24,
                      color: scheme.outlineVariant.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resizeColumn(_TableColumnSpec<T> spec, double deltaX) {
    final nextWidth = (spec.width - deltaX)
        .clamp(_minColumnWidth, _maxColumnWidth)
        .toDouble();
    if ((nextWidth - spec.width).abs() < 0.5) return;
    setState(() {
      _columnWidthOverrides[spec.index] = nextWidth;
    });
  }

  void _sortBy(int index) {
    final nextAscending = widget.sortColumnIndex == index
        ? !widget.sortAscending
        : true;
    widget.onSortColumnChanged(index);
    widget.onSortDirectionChanged(nextAscending);
  }

  Widget _bodyRows(List<_TableColumnSpec<T>> specs, ColorScheme scheme) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: 136,
        child: Center(
          child: Text(
            'داده‌ای برای نمایش وجود ندارد',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          for (var rowIndex = 0; rowIndex < widget.items.length; rowIndex++)
            _bodyRow(specs, widget.items[rowIndex], rowIndex, scheme),
        ],
      ),
    );
  }

  Widget _bodyRow(
    List<_TableColumnSpec<T>> specs,
    T item,
    int rowIndex,
    ColorScheme scheme,
  ) {
    final fill = rowIndex.isEven
        ? scheme.surface
        : scheme.surfaceContainerLowest.withValues(alpha: 0.38);
    return ColoredBox(
      color: fill,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [for (final spec in specs) _bodyCell(spec, item, scheme)],
      ),
    );
  }

  Widget _bodyCell(_TableColumnSpec<T> spec, T item, ColorScheme scheme) {
    final alignment = spec.column.numeric
        ? Alignment.centerLeft
        : Alignment.centerRight;
    return Container(
      width: spec.width,
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      alignment: alignment,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onSurface, fontSize: 13),
        child: IconTheme.merge(
          data: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
          child: ClipRect(
            child: Align(
              alignment: alignment,
              child: spec.column.cellBuilder(item),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withoutAutomaticScrollbars({required Widget child}) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: child,
    );
  }
}

class _TableColumnSpec<T> {
  final int index;
  final ResponsiveTableColumn<T> column;
  final double width;

  const _TableColumnSpec({
    required this.index,
    required this.column,
    required this.width,
  });
}

class MobileDataCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> metrics;
  final List<Widget> actions;

  const MobileDataCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.metrics = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: metrics),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class MobileMetric extends StatelessWidget {
  final String label;
  final Widget value;
  final Color? color;

  const MobileMetric({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            child: value,
          ),
        ],
      ),
    );
  }
}

class _MobileSortStrip<T> extends StatelessWidget {
  final List<ResponsiveTableColumn<T>> columns;
  final int? selectedIndex;
  final bool ascending;
  final ValueChanged<int> onColumnChanged;
  final ValueChanged<bool> onDirectionChanged;
  final Color? accentColor;

  const _MobileSortStrip({
    required this.columns,
    required this.selectedIndex,
    required this.ascending,
    required this.onColumnChanged,
    required this.onDirectionChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sortable = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].sortValue != null) i,
    ];
    if (sortable.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.primary;
    final chipBackground = scheme.surfaceContainerLowest;
    final chipSelected = color.withValues(alpha: 0.16);
    return MobileCollapsiblePanel(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      title: 'مرتب‌سازی',
      icon: Icons.sort_rounded,
      accentColor: color,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final index in sortable)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        label: Text(columns[index].label),
                        selected: selectedIndex == index,
                        onSelected: (_) => onColumnChanged(index),
                        backgroundColor: chipBackground,
                        selectedColor: chipSelected,
                        side: BorderSide(
                          color: selectedIndex == index
                              ? color.withValues(alpha: 0.55)
                              : scheme.outlineVariant,
                        ),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          color: selectedIndex == index
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => onDirectionChanged(!ascending),
            icon: Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
            ),
            tooltip: ascending ? 'صعودی' : 'نزولی',
          ),
        ],
      ),
    );
  }
}

List<T> sortResponsiveItems<T>(
  List<T> items,
  List<ResponsiveTableColumn<T>> columns,
  int? sortColumnIndex,
  bool ascending,
) {
  final sorted = List<T>.of(items);
  final index = sortColumnIndex;
  if (index == null || index < 0 || index >= columns.length) return sorted;
  final getter = columns[index].sortValue;
  if (getter == null) return sorted;
  sorted.sort((a, b) {
    final av = getter(a);
    final bv = getter(b);
    final result = _compareSortValues(av, bv);
    return ascending ? result : -result;
  });
  return sorted;
}

int _compareSortValues(Object? a, Object? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  return a.toString().compareTo(b.toString());
}
