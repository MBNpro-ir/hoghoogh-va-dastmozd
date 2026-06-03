import 'package:flutter/material.dart';

/// انیمیشن شمارش عددی برای نمایش تدریجی مقادیر
class CountUpText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String Function(double value) formatter;
  final Duration duration;
  final Duration delay;
  final TextAlign? textAlign;
  final Curve curve;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = Duration.zero,
    this.textAlign,
    this.curve = const Cubic(0.16, 1, 0.3, 1),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: widget.curve),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          widget.formatter(_animation.value),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
