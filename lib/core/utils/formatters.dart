import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  Formatters._();

  /// Format amount with currency symbol
  static String currency(double amount, {String? symbol}) {
    final currencySymbol = symbol ?? AppConstants.defaultCurrencySymbol;
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format amount without currency symbol (just number)
  static String amount(double value) {
    return NumberFormat('#,##0.00').format(value);
  }

  /// Format date → 22 Sep 2026
  static String date(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format month + year → Sep 2026
  static String monthYear(DateTime date) {
    return DateFormat(AppConstants.monthYearFormat).format(date);
  }

  /// Format full date time
  static String dateTime(DateTime date) {
    return DateFormat(AppConstants.fullDateTimeFormat).format(date);
  }

  /// Short day name (Mon, Tue...)
  static String dayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Percentage with 1 decimal
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}