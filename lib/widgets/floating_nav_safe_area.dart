import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class FloatingNavSafeArea {
  static const double _androidNavHeight = 72;
  static const double _androidNavVerticalMargin = 22;
  static const double _scrollBreathingRoom = 64;
  static const double _fabBottomInset = 80;

  const FloatingNavSafeArea._();

  static bool isActive(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android &&
        MediaQuery.sizeOf(context).width < Responsive.sidebarBreakpoint;
  }

  static double scrollBottomInset(BuildContext context, {double minimum = 0}) {
    if (!isActive(context)) return minimum;
    final bottom =
        _androidNavHeight +
        _androidNavVerticalMargin +
        _scrollBreathingRoom +
        MediaQuery.viewPaddingOf(context).bottom;
    return math.max(minimum, bottom);
  }

  static EdgeInsets scrollPadding(
    BuildContext context, {
    required double left,
    required double top,
    required double right,
    double minimumBottom = 0,
  }) {
    return EdgeInsets.fromLTRB(
      left,
      top,
      right,
      scrollBottomInset(context, minimum: minimumBottom),
    );
  }

  static double notificationBottomInset(
    BuildContext context, {
    double minimum = 18,
  }) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    if (!isActive(context)) return minimum + viewPadding;
    return _androidNavHeight + _androidNavVerticalMargin + viewPadding + 12;
  }

  static Widget padFloatingActionButton(BuildContext context, Widget child) {
    if (!isActive(context)) return child;
    final bottom = _fabBottomInset + MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: child,
    );
  }
}
