import 'package:equatable/equatable.dart';
import 'api_financial_instrument.dart';

/// Model transaksi transfer antar-rekening dari endpoint `/api/transfers`.
class TransferItem extends Equatable {
  const TransferItem({
    required this.id,
    required this.amount,
    this.amountFormatted,
    this.notes,
    this.fromInstrument,
    this.toInstrument,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int amount;
  final String? amountFormatted;
  final String? notes;
  final ApiFinancialInstrument? fromInstrument;
  final ApiFinancialInstrument? toInstrument;
  final String? createdAt;
  final String? updatedAt;

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: '${json['id'] ?? ''}',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      amountFormatted: json['amount_formatted'] as String?,
      notes: json['notes'] as String?,
      fromInstrument: json['from_instrument'] is Map<String, dynamic>
          ? ApiFinancialInstrument.fromJson(
              json['from_instrument'] as Map<String, dynamic>)
          : null,
      toInstrument: json['to_instrument'] is Map<String, dynamic>
          ? ApiFinancialInstrument.fromJson(
              json['to_instrument'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        amountFormatted,
        notes,
        fromInstrument,
        toInstrument,
        createdAt,
        updatedAt,
      ];
}
