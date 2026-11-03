import 'package:equatable/equatable.dart';

import 'api_financial_instrument.dart';

/// Model respons transaksi berulang dari Laravel (RecurringTransactionResource).
class ApiRecurringTransaction extends Equatable {
  const ApiRecurringTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.amount,
    this.amountFormatted,
    required this.frequency,
    this.nextDueDate,
    required this.isActive,
    required this.makeAutomatic,
    this.instrument,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String type; // 'income' | 'expense'
  final String category;
  final int amount;
  final String? amountFormatted;
  final String frequency; // daily | weekly | monthly | yearly
  final String? nextDueDate; // 'Y-m-d'
  final bool isActive;
  final bool makeAutomatic;
  final ApiFinancialInstrument? instrument;
  final String? createdAt;
  final String? updatedAt;

  factory ApiRecurringTransaction.fromJson(Map<String, dynamic> json) {
    return ApiRecurringTransaction(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      category: '${json['category'] ?? ''}',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      amountFormatted: json['amount_formatted'] as String?,
      frequency: '${json['frequency'] ?? 'monthly'}',
      nextDueDate: json['next_due_date'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      makeAutomatic: json['make_automatic'] as bool? ?? false,
      instrument: json['instrument'] != null
          ? ApiFinancialInstrument.fromJson(json['instrument'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'category': category,
      'amount': amount,
      'amount_formatted': amountFormatted,
      'frequency': frequency,
      'next_due_date': nextDueDate,
      'is_active': isActive,
      'make_automatic': makeAutomatic,
      'instrument': instrument?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime? get parsedNextDueDate {
    if (nextDueDate == null) return null;
    try {
      return DateTime.parse(nextDueDate!);
    } catch (_) {
      return null;
    }
  }

  ApiRecurringTransaction copyWith({
    int? id,
    String? title,
    String? type,
    String? category,
    int? amount,
    String? Function()? amountFormatted,
    String? frequency,
    String? Function()? nextDueDate,
    bool? isActive,
    bool? makeAutomatic,
    ApiFinancialInstrument? Function()? instrument,
    String? Function()? createdAt,
    String? Function()? updatedAt,
  }) {
    return ApiRecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      amountFormatted: amountFormatted != null ? amountFormatted() : this.amountFormatted,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate != null ? nextDueDate() : this.nextDueDate,
      isActive: isActive ?? this.isActive,
      makeAutomatic: makeAutomatic ?? this.makeAutomatic,
      instrument: instrument != null ? instrument() : this.instrument,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        category,
        amount,
        amountFormatted,
        frequency,
        nextDueDate,
        isActive,
        makeAutomatic,
        instrument,
        createdAt,
        updatedAt,
      ];
}

/// Envelope respons daftar transaksi berulang: {success, message, data: [...]}.
class ApiRecurringTransactionsResponse extends Equatable {
  const ApiRecurringTransactionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiRecurringTransaction> data;

  factory ApiRecurringTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return ApiRecurringTransactionsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiRecurringTransaction.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons transaksi berulang tunggal: {success, message, data}.
class ApiRecurringTransactionResponse extends Equatable {
  const ApiRecurringTransactionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiRecurringTransaction data;

  factory ApiRecurringTransactionResponse.fromJson(Map<String, dynamic> json) {
    return ApiRecurringTransactionResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiRecurringTransaction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
