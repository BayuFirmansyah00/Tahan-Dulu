import 'package:equatable/equatable.dart';

import 'api_financial_instrument.dart';
import 'api_transaction.dart';

/// Model respons transaksi goal dari Laravel (GoalTransactionResource).
class ApiGoalTransaction extends Equatable {
  const ApiGoalTransaction({
    required this.id,
    required this.goalId,
    required this.type,
    required this.amount,
    this.amountFormatted,
    this.notes,
    this.instrument,
    this.transaction,
    this.createdAt,
  });

  final int id;
  final int goalId;
  final String type; // 'deposit' | 'withdraw'
  final int amount;
  final String? amountFormatted;
  final String? notes;
  final ApiFinancialInstrument? instrument;
  final ApiTransaction? transaction;
  final String? createdAt;

  factory ApiGoalTransaction.fromJson(Map<String, dynamic> json) {
    return ApiGoalTransaction(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      goalId: json['goal_id'] is int
          ? json['goal_id'] as int
          : int.tryParse('${json['goal_id']}') ?? 0,
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
      'goal_id': goalId,
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

  ApiGoalTransaction copyWith({
    int? id,
    int? goalId,
    String? type,
    int? amount,
    String? Function()? amountFormatted,
    String? Function()? notes,
    ApiFinancialInstrument? Function()? instrument,
    ApiTransaction? Function()? transaction,
    String? Function()? createdAt,
  }) {
    return ApiGoalTransaction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
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
        goalId,
        type,
        amount,
        amountFormatted,
        notes,
        instrument,
        transaction,
        createdAt,
      ];
}

/// Envelope respons daftar transaksi goal: {success, message, data: [...]}.
class ApiGoalTransactionsResponse extends Equatable {
  const ApiGoalTransactionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiGoalTransaction> data;

  factory ApiGoalTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return ApiGoalTransactionsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiGoalTransaction.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons transaksi goal tunggal: {success, message, data}.
class ApiGoalTransactionResponse extends Equatable {
  const ApiGoalTransactionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiGoalTransaction data;

  factory ApiGoalTransactionResponse.fromJson(Map<String, dynamic> json) {
    return ApiGoalTransactionResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiGoalTransaction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
