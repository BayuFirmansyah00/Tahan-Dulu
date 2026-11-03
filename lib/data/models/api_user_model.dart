import 'package:equatable/equatable.dart';

/// Model respons autentikasi dari Laravel (envelope {success, message, data}).
///
/// data berisi {user, access_token, token_type} pada login/register,
/// atau {user} pada /me.
class ApiUserModel extends Equatable {
  const ApiUserModel({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.accessToken,
    this.tokenType,
    this.monthlyIncome,
    this.salaryDay,
  });

  /// ID user (int dari Laravel, disimpan sebagai String).
  final int id;

  final String name;
  final String? email;
  final String? role;

  /// Access token Sanctum (plainText).
  final String? accessToken;

  final String? tokenType;

  /// Gaji bulanan pengguna (dalam satuan mata uang, opsional).
  final int? monthlyIncome;

  /// Hari gaji dalam satu bulan (1-31, opsional).
  final int? salaryDay;

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: json['email'] as String?,
      role: json['role'] as String?,
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      monthlyIncome: json['monthly_income'] != null
          ? (json['monthly_income'] is int
              ? json['monthly_income'] as int
              : int.tryParse('${json['monthly_income']}'))
          : null,
      salaryDay: json['salary_day'] != null
          ? (json['salary_day'] is int
              ? json['salary_day'] as int
              : int.tryParse('${json['salary_day']}'))
          : null,
  );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'access_token': accessToken,
      'token_type': tokenType,
      'monthly_income': monthlyIncome,
      'salary_day': salaryDay,
    };
  }

  ApiUserModel copyWith({
    int? id,
    String? name,
    String? Function()? email,
    String? Function()? role,
    String? Function()? accessToken,
    String? Function()? tokenType,
    int? Function()? monthlyIncome,
    int? Function()? salaryDay,
  }) {
    return ApiUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email != null ? email() : this.email,
      role: role != null ? role() : this.role,
      accessToken: accessToken != null ? accessToken() : this.accessToken,
      tokenType: tokenType != null ? tokenType() : this.tokenType,
      monthlyIncome: monthlyIncome != null ? monthlyIncome() : this.monthlyIncome,
      salaryDay: salaryDay != null ? salaryDay() : this.salaryDay,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, accessToken, tokenType, monthlyIncome, salaryDay];
}

/// Envelope respons autentikasi: {success, message, data}.
class ApiAuthResponse extends Equatable {
  const ApiAuthResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiUserModel data;

  factory ApiAuthResponse.fromJson(Map<String, dynamic> json) {
    return ApiAuthResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiUserModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
