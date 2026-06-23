import 'package:flutter/material.dart';

/// سایدبار تطبیق‌پذیر (Persistent Drawer) - راست چین برای فارسی
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<SidebarItem> items;
  final Widget? header;
  final Widget? footer;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.items,
    this.header,
    this.footer,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final compact = constraints.maxWidth < 200;
        return Material(
          color: scheme.surfaceContainerLow,
          elevation: 0,
          child: SafeArea(
            child: Column(
              children: [
                if (onToggleCollapsed != null)
                  _SidebarCollapseControl(
                    compact: compact,
                    collapsed: collapsed,
                    onTap: onToggleCollapsed!,
                  ),
                ?header,
                SizedBox(height: compact ? 4 : 8),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final isActive = i == currentIndex;
                      return _SidebarTile(
                        item: item,
                        isActive: isActive,
                        compact: compact,
                        onTap: () => onSelect(i),
                      );
                    },
                  ),
                ),
                ?footer,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarCollapseControl extends StatelessWidget {
  final bool compact;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarCollapseControl({
    required this.compact,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Align(
        alignment: compact ? Alignment.center : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
          child: Tooltip(
            message: collapsed ? 'باز کردن منو' : 'جمع کردن منو',
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: AppDurations.short,
                  curve: AppCurves.smoothInOut,
                  width: compact ? 48 : 44,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppDurations.micro,
                    switchInCurve: AppCurves.smoothOut,
                    transitionBuilder: (child, animation) => RotationTransition(
                      turns: Tween<double>(
                        begin: 0.35,
                        end: 0,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      collapsed
                          ? Icons.keyboard_double_arrow_left_rounded
                          : Icons.keyboard_double_arrow_right_rounded,
                      key: ValueKey(collapsed),
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarItem {
  final String label;
  final IconData icon;
  final String? badge;
  const SidebarItem({required this.label, required this.icon, this.badge});
}

class _SidebarTile extends StatelessWidget {
  final SidebarItem item;
  final bool isActive;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: compact ? item.label : '',
      waitDuration: const Duration(milliseconds: 450),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: isActive ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppDurations.short,
              curve: AppCurves.emphasizedDecelerate,
              height: compact ? 50 : 52,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 16,
                vertical: compact ? 10 : 14,
              ),
              child: AnimatedSwitcher(
                duration: AppDurations.short,
                switchInCurve: AppCurves.emphasizedDecelerate,
                switchOutCurve: AppCurves.emphasizedAccelerate,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                ),
                child: compact
                    ? Stack(
                        key: const ValueKey('compact'),
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 23,
                            color: isActive
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          if (item.badge != null)
                            Positioned(
                              top: 0,
                              left: 4,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: scheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (isActive)
                            Positioned(
                              right: 0,
                              child: Container(
                                width: 3,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('expanded'),
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: isActive
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (item.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          if (isActive)
                            Container(
                              width: 4,
                              height: 20,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppDurations {
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 320);
  static const Duration medium = Duration(milliseconds: 480);
  static const Duration long = Duration(milliseconds: 680);
  static const Duration extraLong = Duration(milliseconds: 900);
}

class AppCurves {
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve smoothOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve smoothInOut = Cubic(0.65, 0, 0.35, 1);
}
