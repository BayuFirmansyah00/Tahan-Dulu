/// Konfigurasi koneksi API backend Laravel.
///
/// Base URL dan mode remote diatur via `--dart-define` agar fleksibel untuk
/// berbagai environment:
/// - Android Emulator: `http://10.0.2.2:8000/api` (default)
/// - Perangkat Fisik (LAN Wi-Fi): `flutter run --dart-define=API_BASE_URL=http://<IP_LAPTOP>:8000/api`
/// - Production: `flutter build apk --dart-define=API_BASE_URL=https://tahandulu.kreasikan.site/api`
///
/// Nonaktifkan remote via `--dart-define=USE_REMOTE_API=false` untuk pengujian mock.
abstract final class ApiConfig {
  /// Base URL backend. Default menunjuk ke loopback Android emulator standard.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
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
}
