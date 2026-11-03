import 'package:equatable/equatable.dart';

import 'api_financial_instrument.dart';

/// Model respons transaksi dari Laravel (TransactionResource).
class ApiTransaction extends Equatable {
  const ApiTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.amount,
    this.amountFormatted,
    this.information,
    this.instrument,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String type; // 'income' | 'expense'
  final String category;
  final int amount;
  final String? amountFormatted;
  final String? information;
  final ApiFinancialInstrument? instrument;
  final List<String> attachments;
  final String? createdAt;
  final String? updatedAt;

  factory ApiTransaction.fromJson(Map<String, dynamic> json) {
    return ApiTransaction(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      category: '${json['category'] ?? ''}',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      amountFormatted: json['amount_formatted'] as String?,
      information: json['information'] as String?,
      instrument: json['instrument'] != null
          ? ApiFinancialInstrument.fromJson(json['instrument'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List? ?? const [])
          .cast<String>()
          .toList(),
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
      'information': information,
      'instrument': instrument?.toJson(),
      'attachments': attachments,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Parse ISO8601 string dari Laravel ke DateTime.
  DateTime? get parsedCreatedAt {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedUpdatedAt {
    if (updatedAt == null) return null;
    try {
      return DateTime.parse(updatedAt!);
    } catch (_) {
      return null;
    }
  }

  ApiTransaction copyWith({
    int? id,
    String? title,
    String? type,
    String? category,
    int? amount,
    String? Function()? amountFormatted,
    String? Function()? information,
    ApiFinancialInstrument? Function()? instrument,
    List<String>? attachments,
    String? Function()? createdAt,
    String? Function()? updatedAt,
  }) {
    return ApiTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      amountFormatted: amountFormatted != null ? amountFormatted() : this.amountFormatted,
      information: information != null ? information() : this.information,
      instrument: instrument != null ? instrument() : this.instrument,
      attachments: attachments ?? this.attachments,
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
        information,
        instrument,
        attachments,
        createdAt,
        updatedAt,
      ];
}

/// Envelope respons daftar transaksi: {success, message, data: [...], pagination: {...}}.
class ApiTransactionsResponse extends Equatable {
  const ApiTransactionsResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  final bool success;
  final String message;
  final List<ApiTransaction> data;
  final ApiPagination? pagination;

  factory ApiTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return ApiTransactionsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiTransaction.fromJson)
          .toList(),
      pagination: json['pagination'] != null
          ? ApiPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data, pagination];
}

/// Envelope respons transaksi tunggal: {success, message, data}.
class ApiTransactionResponse extends Equatable {
  const ApiTransactionResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiTransaction data;

  factory ApiTransactionResponse.fromJson(Map<String, dynamic> json) {
    return ApiTransactionResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiTransaction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Meta paginasi dari Laravel.
class ApiPagination extends Equatable {
  const ApiPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory ApiPagination.fromJson(Map<String, dynamic> json) {
    return ApiPagination(
      currentPage: json['current_page'] is int
          ? json['current_page'] as int
          : int.tryParse('${json['current_page']}') ?? 1,
      lastPage: json['last_page'] is int
          ? json['last_page'] as int
          : int.tryParse('${json['last_page']}') ?? 1,
      perPage: json['per_page'] is int
          ? json['per_page'] as int
          : int.tryParse('${json['per_page']}') ?? 15,
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse('${json['total']}') ?? 0,
    );
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total];
}
