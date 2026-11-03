import 'package:equatable/equatable.dart';

import 'api_financial_instrument.dart';
import 'api_transaction.dart';

/// Model respons transaksi investasi dari Laravel (InvestmentTransactionResource).
class ApiInvestmentTransaction extends Equatable {
  const ApiInvestmentTransaction({
    required this.id,
    required this.investmentId,
    required this.type,
    required this.amount,
    this.amountFormatted,
    this.notes,
    this.instrument,
    this.transaction,
    this.createdAt,
  });

  final int id;
  final int investmentId;
  final String type; // 'deposit' | 'withdraw'
  final int amount;
  final String? amountFormatted;
  final String? notes;
  final ApiFinancialInstrument? instrument;
  final ApiTransaction? transaction;
  final String? createdAt;

  factory ApiInvestmentTransaction.fromJson(Map<String, dynamic> json) {
    return ApiInvestmentTransaction(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      investmentId: json['investment_id'] is int
          ? json['investment_id'] as int
          : int.tryParse('${json['investment_id']}') ?? 0,
      type: '${json['type'] ?? ''}',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      amountFormatted: json['amount_formatted'] as String?,
      notes: json['notes'] as String?,
      instrument: json['instrument'] != null
          ? ApiFinancialInstrument.fromJson(json['instrument'] as Map<String, dynamic>)
          : null,
      transaction: json['transaction'] != null
          ? ApiTransaction.fromJson(json['transaction'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'investment_id': investmentId,
      'type': type,
      'amount': amount,
      'amount_formatted': amountFormatted,
      'notes': notes,
      'instrument': instrument?.toJson(),
      'transaction': transaction?.toJson(),
      'created_at': createdAt,
    };
  }

  DateTime? get parsedCreatedAt {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (_) {
      return null;
    }
  }

  ApiInvestmentTransaction copyWith({
    int? id,
    int? investmentId,
    String? type,
    int? amount,
    String? Function()? amountFormatted,
    String? Function()? notes,
    ApiFinancialInstrument? Function()? instrument,
    ApiTransaction? Function()? transaction,
    String? Function()? createdAt,
  }) {
    return ApiInvestmentTransaction(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      amountFormatted: amountFormatted != null ? amountFormatted() : this.amountFormatted,
      notes: notes != null ? notes() : this.notes,
      instrument: instrument != null ? instrument() : this.instrument,
      transaction: transaction != null ? transaction() : this.transaction,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        investmentId,
        type,
        amount,
        amountFormatted,
        notes,
        instrument,
        transaction,
        createdAt,
      ];
}

/// Envelope respons daftar transaksi investasi: {success, message, data: [...]}.
class ApiInvestmentTransactionsResponse extends Equatable {
  const ApiInvestmentTransactionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiInvestmentTransaction> data;

  factory ApiInvestmentTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return ApiInvestmentTransactionsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiInvestmentTransaction.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons transaksi investasi tunggal: {success, message, data}.
class ApiInvestmentTransactionResponse extends Equatable {
  const ApiInvestmentTransactionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiInvestmentTransaction data;

  factory ApiInvestmentTransactionResponse.fromJson(Map<String, dynamic> json) {
    return ApiInvestmentTransactionResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiInvestmentTransaction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
