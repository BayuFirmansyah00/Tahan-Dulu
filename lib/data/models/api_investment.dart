import 'package:equatable/equatable.dart';

/// Model respons investasi dari Laravel (InvestmentResource).
class ApiInvestment extends Equatable {
  const ApiInvestment({
    required this.id,
    required this.title,
    required this.type,
    this.target,
    this.increase,
    required this.achieved,
    required this.progressPercentage,
    this.targetFormatted,
    this.increaseFormatted,
    this.achievedFormatted,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String type;
  final int? target;
  final int? increase;
  final int achieved;
  final double progressPercentage;
  final String? targetFormatted;
  final String? increaseFormatted;
  final String? achievedFormatted;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory ApiInvestment.fromJson(Map<String, dynamic> json) {
    return ApiInvestment(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      target: json['target'] != null
          ? (json['target'] is int ? json['target'] as int : int.tryParse('${json['target']}') ?? 0)
          : null,
      increase: json['increase'] != null
          ? (json['increase'] is int ? json['increase'] as int : int.tryParse('${json['increase']}') ?? 0)
          : null,
      achieved: json['achieved'] is int
          ? json['achieved'] as int
          : int.tryParse('${json['achieved']}') ?? 0,
      progressPercentage: (json['progress_percentage'] is num)
          ? (json['progress_percentage'] as num).toDouble()
          : double.tryParse('${json['progress_percentage']}') ?? 0.0,
      targetFormatted: json['target_formatted'] as String?,
      increaseFormatted: json['increase_formatted'] as String?,
      achievedFormatted: json['achieved_formatted'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'target': target,
      'increase': increase,
      'achieved': achieved,
      'progress_percentage': progressPercentage,
      'target_formatted': targetFormatted,
      'increase_formatted': increaseFormatted,
      'achieved_formatted': achievedFormatted,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ApiInvestment copyWith({
    int? id,
    String? title,
    String? type,
    int? target,
    int? increase,
    int? achieved,
    double? progressPercentage,
    String? Function()? targetFormatted,
    String? Function()? increaseFormatted,
    String? Function()? achievedFormatted,
    bool? isActive,
    String? Function()? createdAt,
    String? Function()? updatedAt,
  }) {
    return ApiInvestment(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      target: target ?? this.target,
      increase: increase ?? this.increase,
      achieved: achieved ?? this.achieved,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      targetFormatted: targetFormatted != null ? targetFormatted() : this.targetFormatted,
      increaseFormatted:
          increaseFormatted != null ? increaseFormatted() : this.increaseFormatted,
      achievedFormatted:
          achievedFormatted != null ? achievedFormatted() : this.achievedFormatted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        target,
        increase,
        achieved,
        progressPercentage,
        targetFormatted,
        increaseFormatted,
        achievedFormatted,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Envelope respons daftar investasi: {success, message, data: [...]}.
class ApiInvestmentsResponse extends Equatable {
  const ApiInvestmentsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiInvestment> data;

  factory ApiInvestmentsResponse.fromJson(Map<String, dynamic> json) {
    return ApiInvestmentsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiInvestment.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons investasi tunggal: {success, message, data}.
class ApiInvestmentResponse extends Equatable {
  const ApiInvestmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiInvestment data;

  factory ApiInvestmentResponse.fromJson(Map<String, dynamic> json) {
    return ApiInvestmentResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiInvestment.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
