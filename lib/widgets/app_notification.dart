import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'floating_nav_safe_area.dart';

enum AppNotificationType { success, error, warning, info }

class AppNotification {
  static _NotificationHandle? _active;
  static int _requestId = 0;

  const AppNotification._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppNotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 6),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppNotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppNotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: AppNotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show(
    BuildContext context,
    String message, {
    required AppNotificationType type,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;

    final requestId = ++_requestId;
    final direction = Directionality.maybeOf(context) ?? TextDirection.rtl;
    final previous = _active;

    unawaited(() async {
      await previous?.dismiss();
      if (requestId != _requestId || !context.mounted) return;

      final key = GlobalKey<_AppNotificationOverlayState>();
      late final OverlayEntry entry;
      late final _NotificationHandle handle;
      entry = OverlayEntry(
        builder: (overlayContext) => _AppNotificationOverlay(
          key: key,
          message: message.trim(),
          type: type,
          duration: duration,
          textDirection: direction,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismissed: () {
            handle.remove();
            if (identical(_active, handle)) _active = null;
          },
        ),
      );
      handle = _NotificationHandle(entry: entry, key: key);
      _active = handle;
      overlay.insert(entry);

      if (type == AppNotificationType.error ||
          type == AppNotificationType.warning) {
        unawaited(HapticFeedback.lightImpact());
      }
    }());
  }

  static Future<void> dismissCurrent() async {
    _requestId++;
    final active = _active;
    _active = null;
    await active?.dismiss();
  }
}

class _NotificationHandle {
  final OverlayEntry entry;
  final GlobalKey<_AppNotificationOverlayState> key;
  bool _removed = false;

  _NotificationHandle({required this.entry, required this.key});

  Future<void> dismiss() async {
    if (_removed) return;
    final state = key.currentState;
    if (state == null) {
      remove();
      return;
    }
    await state.dismiss();
  }

  void remove() {
    if (_removed) return;
    _removed = true;
    entry.remove();
  }
}

class _AppNotificationOverlay extends StatefulWidget {
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final TextDirection textDirection;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _AppNotificationOverlay({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.textDirection,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_AppNotificationOverlay> createState() =>
      _AppNotificationOverlayState();
}

class _AppNotificationOverlayState extends State<_AppNotificationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _started = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = curved;
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entranceController.duration = Duration.zero;
      _entranceController.reverseDuration = Duration.zero;
    }
    _entranceController.forward();
    if (!reduceMotion) _progressController.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (_entranceController.isAnimating ||
        _entranceController.status == AnimationStatus.completed) {
      await _entranceController.reverse();
    }
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 12.0 : 24.0;
    final bottom = FloatingNavSafeArea.notificationBottomInset(context);

    return Positioned(
      left: horizontal,
      right: horizontal,
      bottom: bottom,
      child: Directionality(
        textDirection: widget.textDirection,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SlideTransition(
              key: const ValueKey('app-notification-slide'),
              position: _slide,
              child: FadeTransition(
                key: const ValueKey('app-notification-fade'),
                opacity: _fade,
                child: ScaleTransition(
                  key: const ValueKey('app-notification-scale'),
                  scale: _scale,
                  child: _NotificationSurface(
                    message: widget.message,
                    type: widget.type,
                    progress: _progressController,
                    actionLabel: widget.actionLabel,
                    onAction: widget.onAction == null
                        ? null
                        : () {
                            widget.onAction!();
                            unawaited(dismiss());
                          },
                    onClose: () => unawaited(dismiss()),
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

class _NotificationSurface extends StatelessWidget {
  final String message;
  final AppNotificationType type;
  final Animation<double> progress;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  const _NotificationSurface({
    required this.message,
    required this.type,
    required this.progress,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationVisual.resolve(context, type);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      container: true,
      label: '${visual.title}: $message',
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: visual.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: visual.border),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: visual.accent,
                    child: const SizedBox(width: 4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: visual.iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          visual.icon,
                          size: 22,
                          color: visual.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visual.title,
                              style: textTheme.labelLarge?.copyWith(
                                color: visual.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: visual.foreground.withValues(
                                  alpha: 0.88,
                                ),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onAction != null && actionLabel != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            foregroundColor: visual.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          child: Text(actionLabel!),
                        ),
                      ],
                      IconButton(
                        onPressed: onClose,
                        tooltip: 'بستن اعلان',
                        icon: const Icon(Icons.close_rounded, size: 19),
                        color: visual.foreground.withValues(alpha: 0.72),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 4,
                  end: 0,
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: progress,
                    builder: (context, _) => Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: 1 - progress.value,
                        child: ColoredBox(
                          color: visual.accent.withValues(alpha: 0.72),
                          child: const SizedBox(height: 3),
                        ),
                      ),
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
}

class _NotificationVisual {
  final String title;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color border;
  final Color iconBackground;

  const _NotificationVisual({
    required this.title,
    required this.icon,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.border,
    required this.iconBackground,
  });

  factory _NotificationVisual.resolve(
    BuildContext context,
    AppNotificationType type,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final (title, icon, accent, container, onContainer) = switch (type) {
      AppNotificationType.success => (
        'انجام شد',
        Icons.check_rounded,
        dark ? const Color(0xFF62D6A3) : const Color(0xFF137A4B),
        dark ? const Color(0xFF123B2C) : const Color(0xFFE4F6EC),
        dark ? const Color(0xFFD8F7E7) : const Color(0xFF123B2A),
      ),
      AppNotificationType.error => (
        'خطا',
        Icons.error_outline_rounded,
        scheme.error,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      AppNotificationType.warning => (
        'نیاز به توجه',
        Icons.warning_amber_rounded,
        dark ? const Color(0xFFFFC857) : const Color(0xFF9A5B00),
        dark ? const Color(0xFF463511) : const Color(0xFFFFF0CC),
        dark ? const Color(0xFFFFE7AE) : const Color(0xFF432B00),
      ),
      AppNotificationType.info => (
        'اطلاع‌رسانی',
        Icons.info_outline_rounded,
        scheme.primary,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };

    final background = Color.alphaBlend(
      container.withValues(alpha: dark ? 0.72 : 0.82),
      scheme.surfaceContainerHigh,
    );
    return _NotificationVisual(
      title: title,
      icon: icon,
      accent: accent,
      background: background,
      foreground: onContainer,
      border: accent.withValues(alpha: dark ? 0.48 : 0.34),
      iconBackground: accent.withValues(alpha: dark ? 0.18 : 0.12),
    );
  }
}
