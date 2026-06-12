import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_lifecycle_observer.dart';
import 'database/database_helper.dart';
import 'providers/theme_controller.dart';
import 'screens/auth/local_unlock_screen.dart';
import 'screens/auth/local_unlock_setup_screen.dart';
import 'screens/auth/server_login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/local_security_service.dart';
import 'utils/constants.dart';
import 'utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  await DatabaseHelper.instance.database;
  runApp(
    Provider(
      create: (_) => LocalSecurityService(),
      child: ChangeNotifierProvider(
        create: (_) => ThemeController()..initialize(),
        child: const AppLifecycleObserver(child: PayrollApp()),
      ),
    ),
  );
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
    if (await security.requiresUnlock() && await security.hasCredential()) {
      next = const LocalUnlockScreen();
    } else if (await api.hasSession()) {
      next = await security.hasCredential()
          ? const HomeScreen()
          : const LocalUnlockSetupScreen();
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
  const PayrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController()..initialize(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              // همیشه schemes را به controller برسان (خود controller مدیریت می‌کند)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeController.setDynamicSchemes(lightDynamic, darkDynamic);
              });

              return MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                themeMode: themeController.themeMode,
                theme: themeController.lightTheme,
                darkTheme: themeController.darkTheme,
                locale: const Locale('fa', 'IR'),
                supportedLocales: const [
                  Locale('fa', 'IR'),
                  Locale('en', 'US'),
                ],
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
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaler: TextScaler.linear(
                        adjustedScale.clamp(0.85, 1.6),
                      ),
                      disableAnimations: themeController.reduceMotion,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: child!,
                    ),
                  );
                },
                home: const BootScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
