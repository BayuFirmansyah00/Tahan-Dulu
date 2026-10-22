import 'package:equatable/equatable.dart';

/// Pengguna aplikasi.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.bio,
  });

  final String id;
  final String name;
  final String? email;

  /// Deskripsi singkat profil (opsional, maks 120 karakter di form).
  final String? bio;

  UserModel copyWith({
    String? id,
    String? name,
    String? Function()? email,
    String? Function()? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email != null ? email() : this.email,
      bio: bio != null ? bio() : this.bio,
    );
  }

  @override
  List<Object?> get props => [id, name, email, bio];
}
