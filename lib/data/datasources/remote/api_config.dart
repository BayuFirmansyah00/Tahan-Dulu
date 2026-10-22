/// Konfigurasi koneksi API backend Laravel.
///
/// Base URL dan mode remote diisi via `--dart-define` agar biner default
/// (termasuk saat test) tetap memakai mock lokal yang deterministik:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api \
///     --dart-define=USE_REMOTE_AUTH=true
abstract final class ApiConfig {
  /// Contoh emulator: http://10.0.2.2:8000/api (host loopback).
  /// Contoh perangkat fisik: http://192.168.1.10:8000/api (IP LAN PC).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// true = repository auth memakai backend; false = mock lokal.
  static const bool useRemoteAuth = bool.fromEnvironment(
    'USE_REMOTE_AUTH',
    defaultValue: false,
  );
}
