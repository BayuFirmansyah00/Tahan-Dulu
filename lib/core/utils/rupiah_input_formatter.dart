import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Masker input Rupiah saat mengetik: digit -> "5.000.000".
/// Bukan formatter display (itu [CurrencyFormatter]) — khusus input.
/// Simbol "Rp" dipasang via prefixText, bukan di formatter ini.
class RupiahInputFormatter extends TextInputFormatter {
  static final NumberFormat _group = NumberFormat.decimalPattern('id_ID');

  /// Batas digit agar tidak overflow int.
  static const int maxDigits = 15;

  /// Ambil numeric value dari teks terformat. "5.000.000" -> 5000000.
  static double parse(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.parse(digits);
  }

  /// Numeric -> teks grup ("5000000" -> "5.000.000").
  static String format(num value) => _group.format(value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final formatted = _group.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
