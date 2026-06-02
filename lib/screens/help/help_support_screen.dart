import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('راهنما و پشتیبانی')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroHelpCard(scheme: scheme),
                const SizedBox(height: 16),
                _HelpSection(
                  icon: Icons.play_circle_rounded,
                  title: 'شروع سریع',
                  children: const [
                    'ابتدا اطلاعات کارکنان را از بخش مدیریت کارکنان بررسی یا ثبت کنید.',
                    'در بخش محاسبه حقوق، کارمند، ماه، کارکرد، مرخصی، اضافه‌کاری و کسورات را وارد کنید.',
                    'بعد از محاسبه، فیش را ذخیره کنید تا در بخش فیش‌های حقوقی قابل مشاهده و چاپ باشد.',
                  ],
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.calculate_rounded,
                  title: 'منطق محاسبات حقوق ۱۴۰۵',
                  children: const [
                    'اعداد پایه و فرمول‌ها از فایل اکسل حقوق ۱۴۰۵ استخراج شده‌اند.',
                    'مزایای ثابت مانند مسکن، خواربار، تاهل و فرزند با سقف ۳۰ روز محاسبه می‌شوند.',
                    'مبنای بیمه مطابق اکسل سقف‌دار است و حق فرزند از آن کسر می‌شود.',
                    'معافیت دو هفتم مالیات از حق بیمه کارگر محاسبه می‌شود.',
                  ],
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.table_view_rounded,
                  title: 'کار با جدول‌ها',
                  children: const [
                    'در نمای دسکتاپ روی عنوان ستون‌ها بزنید تا جدول مرتب شود.',
                    'در نمای گوشی، داده‌ها به شکل کارت نمایش داده می‌شوند و مرتب‌سازی از نوار بالای لیست انجام می‌شود.',
                    'فیلتر و جستجو قبل از مرتب‌سازی اعمال می‌شوند تا خروجی همیشه قابل پیش‌بینی باشد.',
                  ],
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.backup_rounded,
                  title: 'بکاپ و بازیابی',
                  children: const [
                    'از بخش تنظیمات می‌توانید یک فایل بکاپ از دیتابیس برنامه ذخیره کنید.',
                    'برای ریستور، فایل بکاپ را انتخاب کنید؛ برنامه دیتابیس فعلی را جایگزین می‌کند.',
                    'پیشنهاد می‌شود قبل از ریستور، از دیتای فعلی هم یک بکاپ جداگانه بگیرید.',
                  ],
                ),
                const SizedBox(height: 12),
                _SupportTemplateCard(scheme: scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHelpCard extends StatelessWidget {
  final ColorScheme scheme;
  const _HeroHelpCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevation2(scheme.shadow),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرکز راهنمای حقوق و دستمزد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Template راهنما برای نسخه ${AppConstants.appVersion}؛ متن‌های نهایی و اطلاعات تماس بعدا جایگزین می‌شوند.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> children;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 20),
            ...children.map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text, style: const TextStyle(height: 1.6)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTemplateCard extends StatelessWidget {
  final ColorScheme scheme;
  const _SupportTemplateCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support_rounded, color: scheme.secondary),
                const SizedBox(width: 10),
                Text(
                  'اطلاعات پشتیبانی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            const _TemplateRow(
              label: 'مسئول پشتیبانی',
              value: 'نام/سمت بعدا تکمیل شود',
            ),
            const _TemplateRow(label: 'شماره تماس', value: '۰۹xxxxxxxxx'),
            const _TemplateRow(label: 'ایمیل', value: 'support@example.com'),
            const _TemplateRow(
              label: 'ساعات پاسخ‌گویی',
              value: 'شنبه تا چهارشنبه، ۸ تا ۱۶',
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final String label;
  final String value;

  const _TemplateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
