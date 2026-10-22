import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formatter Rupiah terpusat. Seluruh aplikasi IDR, tanpa multi-currency.
abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: AppConstants.localeId,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 0,
  );

  /// 5000000 -> "Rp 5.000.000"
  static String format(num value) => _format.format(value);

  /// 5000000 -> "Rp5.000.000" (compact, tanpa spasi).
  static String formatCompact(num value) =>
      '${AppConstants.currencySymbol}${_format.format(value).replaceAll('${AppConstants.currencySymbol} ', '')}';
}
