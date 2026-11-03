import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formatter Rupiah terpusat. Seluruh aplikasi IDR, tanpa multi-currency.
abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: AppConstants.localeId,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  /// 5000000 -> "Rp 5.000.000", -50000 -> "-Rp 50.000"
  static String format(num value) {
    if (value < 0) {
      return '-${_format.format(-value)}';
    }
    return _format.format(value);
  }

  /// 5000000 -> "Rp5.000.000", -50000 -> "-Rp50.000"
  static String formatCompact(num value) {
    if (value < 0) {
      final formattedPos = _format.format(-value).replaceAll('${AppConstants.currencySymbol} ', '');
      return '-${AppConstants.currencySymbol}$formattedPos';
    }
    return '${AppConstants.currencySymbol}${_format.format(value).replaceAll('${AppConstants.currencySymbol} ', '')}';
  }
}
