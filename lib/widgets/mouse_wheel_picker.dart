import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MouseWheelStepper extends StatelessWidget {
  final Widget child;
  final ValueChanged<int>? onStep;

  const MouseWheelStepper({
    super.key,
    required this.child,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: onStep == null
          ? null
          : (event) {
              if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) {
                return;
              }
              GestureBinding.instance.pointerSignalResolver.register(event, (
                resolvedEvent,
              ) {
                final scroll = resolvedEvent as PointerScrollEvent;
                onStep!(scroll.scrollDelta.dy > 0 ? 1 : -1);
              });
            },
      child: child,
    );
  }
}

class MouseWheelPicker<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final ValueChanged<T>? onChanged;
  final Widget child;
  final bool wrap;

  const MouseWheelPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.child,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseWheelStepper(
      onStep: onChanged == null ? null : _step,
      child: child,
    );
  }

  void _step(int delta) {
    if (options.isEmpty) return;
    final currentIndex = options.indexOf(value);
    if (currentIndex < 0) return;
    var nextIndex = currentIndex + delta;
    if (wrap) {
      nextIndex %= options.length;
    } else {
      nextIndex = nextIndex.clamp(0, options.length - 1);
    }
    if (nextIndex != currentIndex) onChanged?.call(options[nextIndex]);
  }
}
