/// Konfigurasi koneksi API backend Laravel Tahan Dulu.
///
/// Base URL secara default sekarang mengarah langsung ke server VPS production:
/// `https://tahandulu.kreasikan.site/api`
/// sehingga aplikasi dapat langsung dijalankan (`flutter run`) tanpa perlu menyalakan
/// `php artisan serve` di komputer lokal.
///
/// Pengembang tetap dapat beralih ke server lokal jika diperlukan via `--dart-define`:
/// - Android Emulator (Local): `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
/// - Perangkat Fisik (LAN Wi-Fi): `flutter run --dart-define=API_BASE_URL=http://<IP_LAPTOP>:8000/api`
/// - Desktop / Web (Local): `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api`
///
/// Nonaktifkan remote via `--dart-define=USE_REMOTE_API=false` untuk pengujian mock.
abstract final class ApiConfig {
  /// Production VPS API URL (default utama).
  static const String productionBaseUrl =
      'https://tahandulu.kreasikan.site/api';

  /// Local development URL untuk Android Emulator standard loopback.
  static const String devEmulatorBaseUrl = 'http://10.0.2.2:8000/api';

  /// Local development URL untuk Desktop / Web localhost.
  static const String devLocalhostBaseUrl = 'http://localhost:8000/api';

  /// Base URL backend aktif.
  /// Default: [productionBaseUrl] (https://tahandulu.kreasikan.site/api).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// true = repository auth memakai backend Laravel (Sanctum).
  /// Nonaktifkan via: --dart-define=USE_REMOTE_AUTH=false
  static const bool useRemoteAuth = bool.fromEnvironment(
    'USE_REMOTE_AUTH',
    defaultValue: true,
  );

  /// true = repository data (akun, transaksi, target, dashboard) memakai
  /// backend Laravel; false = mock lokal.
  /// Nonaktifkan via: --dart-define=USE_REMOTE_API=false
  static const bool useRemoteApi = bool.fromEnvironment(
    'USE_REMOTE_API',
    defaultValue: true,
  );

  /// true = Scan Struk memakai pipeline backend hybrid (OpenCV + RapidOCR + validasi keuangan).
  /// Nonaktif secara default agar fallback on-device tetap aman; aktifkan via:
  /// --dart-define=USE_HYBRID_RECEIPT_SCANNER=true
  static const bool useHybridReceiptScanner = bool.fromEnvironment(
    'USE_HYBRID_RECEIPT_SCANNER',
    defaultValue: false,
  );

  /// Status apakah aplikasi sedang terhubung ke VPS production.
  static bool get isProduction => baseUrl.contains('tahandulu.kreasikan.site');

  /// Status apakah aplikasi sedang terhubung ke server lokal.
  static bool get isLocal => !isProduction;
}
