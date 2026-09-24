class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'FinMate';
  static const String appVersion = '1.0.0';

  // Default Currency
  static const String defaultCurrency = 'NPR';
  static const String defaultCurrencySymbol = '\रु';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String monthYearFormat = 'MMM yyyy';
  static const String fullDateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // Budget Thresholds (for future alerts)
  static const List<double> budgetThresholds = [0.5, 0.75, 0.9, 1.0];

  // Pagination
  static const int defaultPageSize = 20;
}
