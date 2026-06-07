import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/theme_controller.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  await DatabaseHelper.instance.database;
  runApp(const PayrollApp());
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
                home: const HomeScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
