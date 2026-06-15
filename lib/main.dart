import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app_lifecycle_observer.dart';
import 'database/database_helper.dart';
import 'providers/theme_controller.dart';
import 'screens/auth/local_unlock_screen.dart';
import 'screens/auth/server_login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/local_security_service.dart';
import 'services/sync_service.dart';
import 'services/window_close_service.dart';
import 'utils/constants.dart';
import 'utils/responsive.dart';
import 'widgets/windows_window_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: AppConstants.appName,
        minimumSize: Size(960, 640),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
    );
  }
  HttpOverrides.global = _TrustedServerHttpOverrides();
  await DatabaseHelper.init();
  await DatabaseHelper.instance.database;
  await SyncService().initialize();
  runApp(
    Provider(
      create: (_) => LocalSecurityService(),
      child: ChangeNotifierProvider(
        create: (_) => ThemeController()..initialize(),
        child: const AppLifecycleObserver(child: _RootAppHost()),
      ),
    ),
  );
}

class _RootAppHost extends StatelessWidget {
  const _RootAppHost();

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DesktopWindowCloseHost(
      navigatorKey: navigatorKey,
      child: PayrollApp(navigatorKey: navigatorKey),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  Widget _child = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final security = context.read<LocalSecurityService>();
    final api = ApiClient();
    Widget next;
    if (await api.hasSession()) {
      final shouldUnlock =
          await security.hasCredential() && await security.requiresUnlock();
      next = shouldUnlock ? const LocalUnlockScreen() : const HomeScreen();
    } else {
      next = const ServerLoginScreen();
    }
    if (!mounted) return;
    setState(() => _child = next);
  }

  @override
  Widget build(BuildContext context) => _child;
}

class PayrollApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const PayrollApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeController.setDynamicSchemes(lightDynamic, darkDynamic);
            });

            return MaterialApp(
              navigatorKey: navigatorKey,
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              themeMode: themeController.themeMode,
              theme: themeController.lightTheme,
              darkTheme: themeController.darkTheme,
              locale: const Locale('fa', 'IR'),
              supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                final isAndroid =
                    Theme.of(context).platform == TargetPlatform.android;
                final baseScale = themeController.textScale;
                final adjustedScale =
                    (isAndroid && mq.size.width < Responsive.compact)
                    ? baseScale * 0.92
                    : baseScale;
                final directedChild = Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                );
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(
                      adjustedScale.clamp(0.85, 1.6),
                    ),
                    disableAnimations: themeController.reduceMotion,
                  ),
                  child: Platform.isWindows
                      ? WindowsWindowFrame(child: directedChild)
                      : directedChild,
                );
              },
              home: const BootScreen(),
            );
          },
        );
      },
    );
  }
}

class _TrustedServerHttpOverrides extends HttpOverrides {
  static const _trustedHosts = {'payroll.mbnpro.ir', '81.30.108.248'};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      return port == 443 && _trustedHosts.contains(host);
    };
    return client;
  }
}
