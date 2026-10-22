/// Konstanta global aplikasi (non-string UI lihat [AppStrings]).
abstract final class AppConstants {
  static const String appName = 'TahanDulu';
  static const String tagline = 'Atur uang. Capai tujuan. Pikir sebelum beli.';

  /// Format lokal: IDR only, tidak ada multi-currency di v1.
  static const String localeId = 'id_ID';
  static const String currencyCode = 'IDR';
  static const String currencySymbol = 'Rp';

  /// Versi tampilan (sumber: pubspec.yaml `version: 1.0.0+1`).
  static const String appVersion = '1.0.0';

  static const int cardRadius = 20;
}
