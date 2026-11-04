/// Konfigurasi koneksi API backend Laravel.
///
/// Base URL dan mode remote diisi via `--dart-define` agar dapat di-override
/// saat build produksi atau pengujian:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///
/// Defaultnya menggunakan backend Laravel agar aplikasi dapat dijalankan
/// secara normal dengan data asli. Aktifkan mock lokal via
/// --dart-define=USE_REMOTE_API=false untuk development tanpa backend.
abstract final class ApiConfig {
  /// Contoh emulator Android: http://10.0.2.2:8000/api (host loopback).
  /// Contoh perangkat fisik: http://192.168.1.10:8000/api (IP LAN PC).
  /// Produksi: gunakan domain production (mis. https://api.tahandulu.id/api).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.9:8000/api',
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
