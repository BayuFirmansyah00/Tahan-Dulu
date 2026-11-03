import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';

/// Status onboarding per akun.
///
/// Sumber kebenaran: field `is_onboarded` pada model pengguna dari backend
/// (dikirim via `GET /api/me` setelah autentikasi). Field ini diset `true`
/// secara eksplisit setelah pengguna menyelesaikan langkah onboarding wajib
/// (salary → instrumen → plan) melalui `PUT /user { is_onboarded: true }`.
///
/// Fallback kompatibilitas: pengguna lama yang belum punya field ini di
/// backend akan mendapat `is_onboarded=true` dari accessor Eloquent jika
/// sudah punya instrumen terdaftar (backward compatibility).
class OnboardingStatus extends Equatable {
  const OnboardingStatus({
    required this.userId,
    required this.isCompleted,
  });

  /// Id pengguna yang sedang login (null bila sesi belum/tidak valid).
  final String? userId;

  final bool isCompleted;

  @override
  List<Object?> get props => [userId, isCompleted];
}

/// Provider status onboarding.
///
/// - Selama profil pengguna masih dimuat, provider berada dalam AsyncLoading
///   sehingga UI tidak boleh menampilkan apa pun.
/// - Bila profil gagal dimuat, provider berada dalam AsyncError; UI tidak
///   menampilkan popup dan TIDAK memaksa logout (dibiarkan saja).
/// - Begitu profil tersedia, status diselesaikan dari `user.isOnboarded`.
final onboardingStatusProvider = FutureProvider<OnboardingStatus>((ref) async {
  // Await profil agar status loading/error tercermin pada AsyncValue.
  final user = await ref.watch(profileUserProvider.future);
  return OnboardingStatus(userId: user.id, isCompleted: user.isOnboarded);
});

/// Menandai bahwa popup ajakan sudah ditampilkan pada sesi berjalan.
///
/// State menyimpan id pengguna yang terakhir ditampilkan sehingga:
/// - rebuild / perpindahan halaman dalam sesi yang sama tidak menampilkan
///   popup ganda untuk akun yang sama;
/// - berganti akun (logout -> login sebagai lain) otomatis diizinkan tampil
///   lagi karena id-nya berbeda.
class OnboardingPopupShownNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void markShown(String? userId) => state = userId;
}

final onboardingPopupShownNotifierProvider =
    NotifierProvider<OnboardingPopupShownNotifier, String?>(
  OnboardingPopupShownNotifier.new,
);
