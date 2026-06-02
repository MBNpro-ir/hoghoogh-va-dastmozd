import 'package:flutter/material.dart';

/// انیمیشن‌های سفارشی اپ
class AppAnimations {
  // -------- مدت زمان‌های استاندارد --------
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 320);
  static const Duration medium = Duration(milliseconds: 480);
  static const Duration long = Duration(milliseconds: 680);
  static const Duration extraLong = Duration(milliseconds: 900);

  // -------- منحنی‌های سفارشی --------
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve bouncyOut = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve smoothOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve smoothInOut = Cubic(0.65, 0, 0.35, 1);

  // -------- Page Transitions --------
  static PageTransitionsTheme get pageTransitions => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _FadeThroughPageTransitionsBuilder(),
        },
      );

  // -------- Page Route با Fade Through Material 3 --------
  static PageRoute<T> fadeThroughRoute<T>(WidgetBuilder builder, {Duration? duration}) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? medium,
      reverseTransitionDuration: duration ?? short,
      pageBuilder: (context, anim, secondary) => builder(context),
      transitionsBuilder: (context, anim, secondary, child) {
        final fadeIn = CurvedAnimation(parent: anim, curve: emphasizedDecelerate);
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(fadeIn),
            child: child,
          ),
        );
      },
    );
  }

  /// انتقال کشویی از پایین (برای موبایل)
  static PageRoute<T> bottomUpRoute<T>(WidgetBuilder builder, {Duration? duration}) {
    return PageRouteBuilder<T>(
      transitionDuration: duration ?? long,
      reverseTransitionDuration: duration ?? short,
      pageBuilder: (context, anim, secondary) => builder(context),
      transitionsBuilder: (context, anim, secondary, child) {
        final curve = CurvedAnimation(parent: anim, curve: emphasizedDecelerate);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
    );
  }

  /// انتقال مقیاس‌پذیر (برای کارت‌ها)
  static Widget scaleIn(BuildContext context, Widget child,
      {Duration delay = Duration.zero, double begin = 0.92}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: 1.0),
      duration: medium + delay,
      curve: emphasizedDecelerate,
      builder: (context, value, c) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: value, child: c),
        );
      },
      child: child,
    );
  }
}

/// Page Transitions Builder سفارشی
class _FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.emphasizedDecelerate,
      reverseCurve: AppAnimations.emphasizedAccelerate,
    );
    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppAnimations.emphasized,
    );
    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(fadeIn),
          child: child,
        ),
      ),
    );
  }
}

/// ویجت‌های انیمیشنی آماده
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offset = 24,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: AppAnimations.emphasizedDecelerate);
    _slide = Tween<Offset>(begin: Offset(0, widget.offset / 100), end: Offset.zero)
        .animate(_fade);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// ویجت Bounce on Tap
class BounceOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const BounceOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<BounceOnTap> createState() => _BounceOnTapState();
}

class _BounceOnTapState extends State<BounceOnTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: AppAnimations.emphasized,
        child: widget.child,
      ),
    );
  }
}
