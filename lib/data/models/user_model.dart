import 'package:equatable/equatable.dart';

/// Pengguna aplikasi.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.bio,
    this.monthlyIncome,
    this.salaryDay,
    this.isOnboarded = false,
  });

  final String id;
  final String name;
  final String? email;

  /// Deskripsi singkat profil (opsional, maks 120 karakter di form).
  final String? bio;

  /// Gaji bulanan pengguna (dalam satuan mata uang, opsional).
  final int? monthlyIncome;

  /// Hari gaji dalam satu bulan (1-31, opsional).
  final int? salaryDay;

  /// Status apakah onboarding wajib telah selesai.
  final bool isOnboarded;

  UserModel copyWith({
    String? id,
    String? name,
    String? Function()? email,
    String? Function()? bio,
    int? Function()? monthlyIncome,
    int? Function()? salaryDay,
    bool? isOnboarded,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email != null ? email() : this.email,
      bio: bio != null ? bio() : this.bio,
      monthlyIncome: monthlyIncome != null ? monthlyIncome() : this.monthlyIncome,
      salaryDay: salaryDay != null ? salaryDay() : this.salaryDay,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  @override
  List<Object?> get props => [id, name, email, bio, monthlyIncome, salaryDay, isOnboarded];
}
