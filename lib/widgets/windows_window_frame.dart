import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class WindowPinPreferences {
  static const _key = 'hvm_window_always_on_top_v1';

  static Future<bool> getPinned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setPinned(bool pinned) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, pinned);
  }
}

class WindowsWindowFrame extends StatefulWidget {
  final Widget child;

  const WindowsWindowFrame({super.key, required this.child});

  @override
  State<WindowsWindowFrame> createState() => _WindowsWindowFrameState();
}

class _WindowsWindowFrameState extends State<WindowsWindowFrame>
    with WindowListener {
  bool _isAlwaysOnTop = false;
  bool _isFocused = true;
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      _loadWindowState();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _loadWindowState() async {
    final pinned = await WindowPinPreferences.getPinned();
    final maximized = await windowManager.isMaximized();
    final fullScreen = await windowManager.isFullScreen();
    await windowManager.setAlwaysOnTop(pinned);
    if (!mounted) return;
    setState(() {
      _isAlwaysOnTop = pinned;
      _isMaximized = maximized;
      _isFullScreen = fullScreen;
    });
  }

  Future<void> _toggleAlwaysOnTop() async {
    final next = !_isAlwaysOnTop;
    await WindowPinPreferences.setPinned(next);
    await windowManager.setAlwaysOnTop(next);
    if (!mounted) return;
    setState(() => _isAlwaysOnTop = next);
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  void onWindowFocus() {
    if (mounted) setState(() => _isFocused = true);
  }

  @override
  void onWindowBlur() {
    if (mounted) setState(() => _isFocused = false);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isFullScreen = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) setState(() => _isFullScreen = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    final showBorder = !_isMaximized && !_isFullScreen;
    final borderColor = _isFocused ? scheme.primary : scheme.outlineVariant;

    return VirtualWindowFrame(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: showBorder ? Border.all(color: borderColor) : null,
        ),
        child: Column(
          children: [
            if (!_isFullScreen)
              _WindowsTitleBar(
                isAlwaysOnTop: _isAlwaysOnTop,
                isMaximized: _isMaximized,
                onToggleAlwaysOnTop: _toggleAlwaysOnTop,
                onToggleMaximize: _toggleMaximize,
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _WindowsTitleBar extends StatelessWidget {
  final bool isAlwaysOnTop;
  final bool isMaximized;
  final VoidCallback onToggleAlwaysOnTop;
  final VoidCallback onToggleMaximize;

  const _WindowsTitleBar({
    required this.isAlwaysOnTop,
    required this.isMaximized,
    required this.onToggleAlwaysOnTop,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleBarColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: dark ? 0.10 : 0.06),
      dark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLow,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 40,
        child: ColoredBox(
          color: titleBarColor,
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _ThemedTitleLogo(color: scheme.primary),
                    ),
                  ),
                ),
              ),
              _WindowControlButton(
                icon: Icons.push_pin_rounded,
                tooltip: isAlwaysOnTop
                    ? 'برداشتن pin پنجره'
                    : 'نگه داشتن پنجره روی بقیه',
                isActive: isAlwaysOnTop,
                onPressed: onToggleAlwaysOnTop,
              ),
              _WindowControlButton(
                icon: Icons.minimize_rounded,
                tooltip: 'کوچک کردن',
                onPressed: () => windowManager.minimize(),
              ),
              _WindowControlButton(
                icon: isMaximized
                    ? Icons.filter_none_rounded
                    : Icons.crop_square_rounded,
                tooltip: isMaximized ? 'بازگردانی' : 'بزرگ کردن',
                onPressed: onToggleMaximize,
              ),
              _WindowControlButton(
                icon: Icons.close_rounded,
                tooltip: 'بستن',
                isClose: true,
                onPressed: () => windowManager.close(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isClose;
  final VoidCallback onPressed;

  const _WindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.isClose = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overlayColor = scheme.onSurface;
    final background = widget.isClose && _hovered
        ? scheme.error
        : _pressed
        ? overlayColor.withValues(alpha: 0.10)
        : _hovered
        ? overlayColor.withValues(alpha: 0.07)
        : Colors.transparent;
    final color = widget.isClose && _hovered
        ? scheme.onError
        : widget.isActive
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
            height: 40,
            color: background,
            child: Center(child: Icon(widget.icon, color: color, size: 18)),
          ),
        ),
      ),
    );
  }
}

class _ThemedTitleLogo extends StatelessWidget {
  final Color color;

  const _ThemedTitleLogo({required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'لوگوی برنامه',
      image: true,
      child: ExcludeSemantics(
        child: ColorFiltered(
          colorFilter: _whiteToTransparentTint(color),
          child: Image.asset(
            'assets/logo.png',
            width: 42,
            height: 28,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  ColorFilter _whiteToTransparentTint(Color color) {
    final r = color.r * 255;
    final g = color.g * 255;
    final b = color.b * 255;
    const strength = 1.35;
    return ColorFilter.matrix(<double>[
      0,
      0,
      0,
      0,
      r,
      0,
      0,
      0,
      0,
      g,
      0,
      0,
      0,
      0,
      b,
      -0.2126 * strength,
      -0.7152 * strength,
      -0.0722 * strength,
      0,
      255 * strength,
    ]);
  }
}
