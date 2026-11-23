import 'package:equatable/equatable.dart';
import 'api_bank.dart';

/// Model respons instrumen keuangan dari Laravel (FinancialInstrumenResource).
class ApiFinancialInstrument extends Equatable {
  const ApiFinancialInstrument({
    required this.id,
    required this.name,
    required this.balance,
    required this.isActive,
    this.balanceFormatted,
    this.monthlyAdminFee = 0,
    this.monthlyAdminFeeFormatted,
    this.adminFeeDay,
    this.adminFeeEnabled = false,
    this.nextAdminFeeDate,
    this.type,
    this.bank,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int balance;
  final bool isActive;
  final String? balanceFormatted;
  final int monthlyAdminFee;
  final String? monthlyAdminFeeFormatted;
  final int? adminFeeDay;
  final bool adminFeeEnabled;
  final String? nextAdminFeeDate;
  final ApiInstrumentType? type;
  final ApiBank? bank;
  final String? createdAt;
  final String? updatedAt;

  factory ApiFinancialInstrument.fromJson(Map<String, dynamic> json) {
    return ApiFinancialInstrument(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      balance: json['balance'] is int
          ? json['balance'] as int
          : int.tryParse('${json['balance']}') ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      balanceFormatted: json['balance_formatted'] as String?,
      monthlyAdminFee: json['monthly_admin_fee'] is int
          ? json['monthly_admin_fee'] as int
          : int.tryParse('${json['monthly_admin_fee']}') ?? 0,
      monthlyAdminFeeFormatted: json['monthly_admin_fee_formatted'] as String?,
      adminFeeDay: json['admin_fee_day'] is int
          ? json['admin_fee_day'] as int
          : int.tryParse('${json['admin_fee_day']}'),
      adminFeeEnabled: json['admin_fee_enabled'] as bool? ?? false,
      nextAdminFeeDate: json['next_admin_fee_date'] as String?,
      type: json['type'] is Map<String, dynamic>
          ? ApiInstrumentType.fromJson(json['type'] as Map<String, dynamic>)
          : null,
      bank: json['bank'] is Map<String, dynamic>
          ? ApiBank.fromJson(json['bank'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'is_active': isActive,
      'balance_formatted': balanceFormatted,
      'monthly_admin_fee': monthlyAdminFee,
      'monthly_admin_fee_formatted': monthlyAdminFeeFormatted,
      'admin_fee_day': adminFeeDay,
      'admin_fee_enabled': adminFeeEnabled,
      'next_admin_fee_date': nextAdminFeeDate,
      'type': type?.toJson(),
      'bank': bank?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ApiFinancialInstrument copyWith({
    String? id,
    String? name,
    int? balance,
    bool? isActive,
    String? Function()? balanceFormatted,
    int? monthlyAdminFee,
    String? Function()? monthlyAdminFeeFormatted,
    int? Function()? adminFeeDay,
    bool? adminFeeEnabled,
    String? Function()? nextAdminFeeDate,
    ApiInstrumentType? Function()? type,
    ApiBank? Function()? bank,
    String? Function()? createdAt,
    String? Function()? updatedAt,
  }) {
    return ApiFinancialInstrument(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      balanceFormatted: balanceFormatted != null ? balanceFormatted() : this.balanceFormatted,
      monthlyAdminFee: monthlyAdminFee ?? this.monthlyAdminFee,
      monthlyAdminFeeFormatted: monthlyAdminFeeFormatted != null ? monthlyAdminFeeFormatted() : this.monthlyAdminFeeFormatted,
      adminFeeDay: adminFeeDay != null ? adminFeeDay() : this.adminFeeDay,
      adminFeeEnabled: adminFeeEnabled ?? this.adminFeeEnabled,
      nextAdminFeeDate: nextAdminFeeDate != null ? nextAdminFeeDate() : this.nextAdminFeeDate,
      type: type != null ? type() : this.type,
      bank: bank != null ? bank() : this.bank,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        balance,
        isActive,
        balanceFormatted,
        monthlyAdminFee,
        monthlyAdminFeeFormatted,
        adminFeeDay,
        adminFeeEnabled,
        nextAdminFeeDate,
        type,
        bank,
        createdAt,
        updatedAt,
      ];
}

/// Jenis instrumen (dari instrument_types) yang dikemas dalam resource.
class ApiInstrumentType extends Equatable {
  const ApiInstrumentType({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String type;
  final String? logoUrl;

  factory ApiInstrumentType.fromJson(Map<String, dynamic> json) {
    return ApiInstrumentType(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      type: '${json['type'] ?? ''}',
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'logo_url': logoUrl,
    };
  }

  @override
  List<Object?> get props => [id, name, type, logoUrl];
}

/// Envelope respons daftar instrumen: {success, message, data: [...]}.
class ApiFinancialInstrumentsResponse extends Equatable {
  const ApiFinancialInstrumentsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiFinancialInstrument> data;

  factory ApiFinancialInstrumentsResponse.fromJson(Map<String, dynamic> json) {
    return ApiFinancialInstrumentsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiFinancialInstrument.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
