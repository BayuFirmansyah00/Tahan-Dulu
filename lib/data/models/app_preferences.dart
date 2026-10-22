import 'package:equatable/equatable.dart';

/// Pilihan tema aplikasi.
enum AppThemeChoice { system, light, dark }

/// Preferensi aplikasi (Tahap 14).
///
/// Penyimpanan in-memory via [AppPreferencesController]: bertahan selama
/// aplikasi berjalan, diatur ulang saat aplikasi dimulai ulang. Tidak ada
/// backend atau penyimpanan lokal pada tahap ini.
class AppPreferences extends Equatable {
  const AppPreferences({
    this.theme = AppThemeChoice.system,
    this.reduceMotion = false,
    this.showInAppNotifications = true,
    this.showTips = true,
  });

  /// Ikuti Sistem / Terang berlaku penuh. Gelap belum tersedia.
  final AppThemeChoice theme;

  /// Kurangi animasi transisi (berlaku pada FAQ dan komponen profil).
  final bool reduceMotion;

  /// Tampilkan titik pengingat pada bel Dashboard.
  final bool showInAppNotifications;

  /// Tampilkan kartu tips pada Profil.
  final bool showTips;

  AppPreferences copyWith({
    AppThemeChoice? theme,
    bool? reduceMotion,
    bool? showInAppNotifications,
    bool? showTips,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      showInAppNotifications:
          showInAppNotifications ?? this.showInAppNotifications,
      showTips: showTips ?? this.showTips,
    );
  }

  @override
  List<Object?> get props =>
      [theme, reduceMotion, showInAppNotifications, showTips];
}
