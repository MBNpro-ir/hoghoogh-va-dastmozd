import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_sidebar.dart';

const _radiusFull = 9999.0;

class AndroidExpressiveNavDestination {
  final IconData icon;
  final String label;

  const AndroidExpressiveNavDestination({
    required this.icon,
    required this.label,
  });
}

class AndroidExpressiveNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AndroidExpressiveNavDestination> destinations;

  const AndroidExpressiveNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.short;
    final maxWidth = math.min(MediaQuery.sizeOf(context).width - 32, 252.0);
    final barColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.04),
      scheme.surfaceContainerHigh,
    ).withValues(alpha: 0.70);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radiusFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppCurves.emphasizedDecelerate,
                  height: 72,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(_radiusFull),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        _ExpressiveNavButton(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          duration: duration,
                          onTap: () {
                            Feedback.forTap(context);
                            onDestinationSelected(i);
                          },
                        ),
                    ],
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

class _ExpressiveNavButton extends StatelessWidget {
  final AndroidExpressiveNavDestination destination;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  const _ExpressiveNavButton({
    required this.destination,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFill = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.10),
      scheme.primaryContainer,
    );
    final iconColor = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant.withValues(alpha: 0.82);

    return Tooltip(
      message: destination.label,
      waitDuration: const Duration(milliseconds: 450),
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Center(
          child: AnimatedScale(
            duration: duration,
            curve: AppCurves.emphasizedDecelerate,
            scale: selected ? 1.02 : 1,
            child: AnimatedContainer(
              key: ValueKey('android-nav-${destination.label}'),
              duration: duration,
              curve: AppCurves.emphasizedDecelerate,
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected ? selectedFill : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: AppCurves.emphasizedDecelerate,
                    switchOutCurve: AppCurves.emphasizedAccelerate,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Icon(
                      destination.icon,
                      key: ValueKey('${destination.label}-$selected'),
                      size: selected ? 27 : 25,
                      color: iconColor,
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
