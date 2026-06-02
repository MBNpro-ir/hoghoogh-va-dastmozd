import 'package:flutter/material.dart';

/// سایدبار تطبیق‌پذیر (Persistent Drawer) - راست چین برای فارسی
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<SidebarItem> items;
  final Widget? header;
  final Widget? footer;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.items,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            ?header,
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isActive = i == currentIndex;
                  return _SidebarTile(
                    item: item,
                    isActive: isActive,
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
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.short,
            curve: AppCurves.emphasizedDecelerate,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (item.badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
