import 'package:flutter/material.dart';

class MobileCollapsiblePanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;
  final bool initiallyExpanded;

  const MobileCollapsiblePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.margin = const EdgeInsets.all(12),
    this.accentColor,
    this.initiallyExpanded = false,
  });

  @override
  State<MobileCollapsiblePanel> createState() => _MobileCollapsiblePanelState();
}

class _MobileCollapsiblePanelState extends State<MobileCollapsiblePanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;
    return Padding(
      padding: widget.margin,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: accent, size: 21),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(height: 1, color: scheme.outlineVariant),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: widget.child,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
