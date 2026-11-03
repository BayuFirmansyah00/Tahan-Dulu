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
    this.type,
    this.bank,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final int balance;
  final bool isActive;
  final String? balanceFormatted;
  final ApiInstrumentType? type;
  final ApiBank? bank;
  final String? createdAt;
  final String? updatedAt;

  factory ApiFinancialInstrument.fromJson(Map<String, dynamic> json) {
    return ApiFinancialInstrument(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      balance: json['balance'] is int
          ? json['balance'] as int
          : int.tryParse('${json['balance']}') ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      balanceFormatted: json['balance_formatted'] as String?,
      type: json['type'] != null
          ? ApiInstrumentType.fromJson(json['type'] as Map<String, dynamic>)
          : null,
      bank: json['bank'] != null
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
      'type': type?.toJson(),
      'bank': bank?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ApiFinancialInstrument copyWith({
    int? id,
    String? name,
    int? balance,
    bool? isActive,
    String? Function()? balanceFormatted,
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
      type: type != null ? type() : this.type,
      bank: bank != null ? bank() : this.bank,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, balance, isActive, balanceFormatted, type, bank, createdAt, updatedAt];
}

/// Jenis instrumen (dari instrument_types) yang dikemas dalam resource.
class ApiInstrumentType extends Equatable {
  const ApiInstrumentType({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String type;
  final String? logoUrl;

  factory ApiInstrumentType.fromJson(Map<String, dynamic> json) {
    return ApiInstrumentType(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
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
