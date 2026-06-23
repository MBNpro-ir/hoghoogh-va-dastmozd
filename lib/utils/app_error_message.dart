import '../services/api_client.dart';
import 'business_validation.dart';

class AppErrorMessage {
  const AppErrorMessage._();

  static String from(Object error, {required String fallback}) {
    if (error is BusinessValidationException) return error.message;
    if (error is ApiException) return error.message;
    if (error is ArgumentError && error.message != null) {
      return error.message.toString();
    }

    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('unique constraint') ||
        lower.contains('unique failed') ||
        lower.contains('sqlite_constraint_unique')) {
      return 'این اطلاعات قبلاً ثبت شده است. صفحه را تازه کنید و دوباره بررسی کنید.';
    }
    if (lower.contains('foreign key')) {
      return 'رکورد وابسته پیدا نشد یا قبلاً حذف شده است. صفحه را تازه کنید.';
    }
    if (lower.contains('database is locked') || lower.contains('busy')) {
      return 'اطلاعات در حال استفاده است. چند لحظه صبر کنید و دوباره تلاش کنید.';
    }
    if (lower.contains('no such column') || lower.contains('no such table')) {
      return 'ساختار اطلاعات برنامه نیاز به به‌روزرسانی دارد. برنامه را یک‌بار ببندید و دوباره اجرا کنید.';
    }
    if (error is StateError && raw.contains('رکورد')) {
      return raw.replaceFirst('Bad state: ', '');
    }
    return fallback;
  }
}
