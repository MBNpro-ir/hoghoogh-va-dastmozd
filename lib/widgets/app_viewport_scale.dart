import 'package:flutter/material.dart';

class AppViewportScale extends StatelessWidget {
  final double scale;
  final Widget child;

  const AppViewportScale({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final effectiveScale = scale.clamp(0.8, 1.3).toDouble();
    if (effectiveScale == 1) return child;

    final logicalSize = Size(
      mediaQuery.size.width / effectiveScale,
      mediaQuery.size.height / effectiveScale,
    );
    final scaledMediaQuery = mediaQuery.copyWith(
      size: logicalSize,
      padding: _divideInsets(mediaQuery.padding, effectiveScale),
      viewPadding: _divideInsets(mediaQuery.viewPadding, effectiveScale),
      viewInsets: _divideInsets(mediaQuery.viewInsets, effectiveScale),
      systemGestureInsets: _divideInsets(
        mediaQuery.systemGestureInsets,
        effectiveScale,
      ),
    );

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(
            size: logicalSize,
            child: MediaQuery(data: scaledMediaQuery, child: child),
          ),
        ),
      ),
    );
  }

  EdgeInsets _divideInsets(EdgeInsets insets, double divisor) =>
      EdgeInsets.only(
        left: insets.left / divisor,
        top: insets.top / divisor,
        right: insets.right / divisor,
        bottom: insets.bottom / divisor,
      );
}
