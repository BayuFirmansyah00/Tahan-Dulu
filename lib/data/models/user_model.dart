import 'package:equatable/equatable.dart';

/// Pengguna aplikasi.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.bio,
    this.avatarUrl,
    this.monthlyIncome,
    this.salaryDay,
    this.isOnboarded = false,
    this.isEmailVerified = true,
    this.emailVerifiedAt,
  });

  final String id;
  final String name;
  final String? email;

  /// URL foto profil pengguna (opsional).
  final String? avatarUrl;

  /// Deskripsi singkat profil (opsional, maks 120 karakter di form).
  final String? bio;

  /// Gaji bulanan pengguna (dalam satuan mata uang, opsional).
  final int? monthlyIncome;

  /// Hari gaji dalam satu bulan (1-31, opsional).
  final int? salaryDay;

  /// Status apakah onboarding wajib telah selesai.
  final bool isOnboarded;

  /// Status apakah email akun sudah diverifikasi.
  final bool isEmailVerified;

  /// Timestamp verifikasi email (null jika belum diverifikasi).
  final DateTime? emailVerifiedAt;

  UserModel copyWith({
    String? id,
    String? name,
    String? Function()? email,
    String? Function()? bio,
    String? Function()? avatarUrl,
    int? Function()? monthlyIncome,
    int? Function()? salaryDay,
    bool? isOnboarded,
    bool? isEmailVerified,
    DateTime? Function()? emailVerifiedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email != null ? email() : this.email,
      bio: bio != null ? bio() : this.bio,
      avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
      monthlyIncome: monthlyIncome != null ? monthlyIncome() : this.monthlyIncome,
      salaryDay: salaryDay != null ? salaryDay() : this.salaryDay,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      emailVerifiedAt: emailVerifiedAt != null ? emailVerifiedAt() : this.emailVerifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        bio,
        avatarUrl,
        monthlyIncome,
        salaryDay,
        isOnboarded,
        isEmailVerified,
        emailVerifiedAt,
      ];
}
