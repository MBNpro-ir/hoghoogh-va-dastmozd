import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/theme_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // مقداردهی اولیه SQLite برای ویندوز/لینوکس/اندروید
  await DatabaseHelper.init();
  // باز کردن دیتابیس (ایجاد جداول در صورت لزوم)
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
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: themeController.themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
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
              // اعمال ضریب مقیاس فونت بر اساس دسترسی‌پذیری و پلتفرم
              final mq = MediaQuery.of(context);
              final isAndroid = Theme.of(context).platform == TargetPlatform.android;
              final baseScale = themeController.textScale;
              // برای موبایل اندروید ضریب کمی کمتر شود
              final adjustedScale = (isAndroid && mq.size.width < Responsive.compact)
                  ? baseScale * 0.92
                  : baseScale;
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(adjustedScale.clamp(0.85, 1.6)),
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
      ),
    );
  }
}
