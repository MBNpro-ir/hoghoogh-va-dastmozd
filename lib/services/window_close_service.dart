import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

enum WindowCloseBehavior { ask, minimizeToTray, exit }

class WindowClosePreferences {
  static const _key = 'hvm_window_close_behavior_v1';

  static Future<WindowCloseBehavior> getBehavior() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return WindowCloseBehavior.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => WindowCloseBehavior.ask,
    );
  }

  static Future<void> setBehavior(WindowCloseBehavior behavior) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, behavior.name);
  }
}

extension WindowCloseBehaviorLabel on WindowCloseBehavior {
  String get label => switch (this) {
    WindowCloseBehavior.ask => 'هر بار بپرس',
    WindowCloseBehavior.minimizeToTray => 'رفتن کنار ساعت ویندوز',
    WindowCloseBehavior.exit => 'بستن کامل برنامه',
  };

  String get description => switch (this) {
    WindowCloseBehavior.ask => 'هنگام بستن پنجره، انتخاب را از کاربر بپرس.',
    WindowCloseBehavior.minimizeToTray =>
      'پنجره پنهان شود و برنامه از آیکون کنار ساعت باز بماند.',
    WindowCloseBehavior.exit => 'با بستن پنجره، برنامه کامل بسته شود.',
  };
}

class DesktopWindowCloseHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DesktopWindowCloseHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<DesktopWindowCloseHost> createState() => _DesktopWindowCloseHostState();
}

class _DesktopWindowCloseHostState extends State<DesktopWindowCloseHost>
    with WindowListener, TrayListener {
  bool _forceExit = false;
  bool _handlingClose = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      unawaited(_initDesktopWindow());
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initDesktopWindow() async {
    await windowManager.setPreventClose(true);
    await _initTray();
  }

  Future<void> _initTray() async {
    final iconPath = await _trayIconPath();
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('HvM');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: 'باز کردن'),
          MenuItem.separator(),
          MenuItem(key: 'close', label: 'بستن کامل'),
        ],
      ),
    );
  }

  Future<String> _trayIconPath() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}hvm_tray_icon.ico');
    if (!await file.exists()) {
      final data = await rootBundle.load(
        'windows/runner/resources/app_icon.ico',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  @override
  void onWindowClose() {
    unawaited(_handleWindowClose());
  }

  Future<void> _handleWindowClose() async {
    if (_forceExit || _handlingClose) return;
    _handlingClose = true;
    try {
      final behavior = await WindowClosePreferences.getBehavior();
      switch (behavior) {
        case WindowCloseBehavior.exit:
          await _exitApp();
          return;
        case WindowCloseBehavior.minimizeToTray:
          await _hideToTray();
          return;
        case WindowCloseBehavior.ask:
          final dialogContext =
              widget.navigatorKey.currentState?.overlay?.context ??
              widget.navigatorKey.currentContext;
          if (dialogContext == null || !dialogContext.mounted || !mounted) {
            return;
          }
          final decision = await _askCloseBehavior(dialogContext);
          if (decision == null) return;
          if (decision.remember) {
            await WindowClosePreferences.setBehavior(decision.behavior);
          }
          if (decision.behavior == WindowCloseBehavior.exit) {
            await _exitApp();
          } else {
            await _hideToTray();
          }
          return;
      }
    } finally {
      _handlingClose = false;
    }
  }

  Future<void> _hideToTray() async {
    await windowManager.hide();
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.maximize();
    await windowManager.focus();
  }

  Future<void> _exitApp() async {
    if (_forceExit) return;
    _forceExit = true;
    try {
      await windowManager.setPreventClose(false);
    } catch (_) {}
    try {
      await trayManager.destroy();
    } catch (_) {}
    try {
      await windowManager.close();
    } catch (_) {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        unawaited(_showWindow());
        return;
      case 'close':
        unawaited(_exitApp());
        return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CloseDecision {
  final WindowCloseBehavior behavior;
  final bool remember;

  const _CloseDecision({required this.behavior, required this.remember});
}

Future<_CloseDecision?> _askCloseBehavior(BuildContext context) {
  var remember = false;
  var behavior = WindowCloseBehavior.minimizeToTray;
  return showDialog<_CloseDecision>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('بستن برنامه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<WindowCloseBehavior>(
              groupValue: behavior,
              onChanged: (value) {
                if (value != null) setState(() => behavior = value);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<WindowCloseBehavior>(
                    value: WindowCloseBehavior.minimizeToTray,
                    title: Text('رفتن کنار ساعت ویندوز'),
                  ),
                  RadioListTile<WindowCloseBehavior>(
                    value: WindowCloseBehavior.exit,
                    title: Text('بستن کامل برنامه'),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              value: remember,
              onChanged: (value) => setState(() => remember = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('همیشه همین کار را انجام بده'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              _CloseDecision(behavior: behavior, remember: remember),
            ),
            child: const Text('تأیید'),
          ),
        ],
      ),
    ),
  );
}
