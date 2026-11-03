import 'package:equatable/equatable.dart';

/// Model respons target keuangan dari Laravel (GoalResource).
class ApiFinancialGoal extends Equatable {
  const ApiFinancialGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    this.targetAmountFormatted,
    this.currentAmountFormatted,
    this.imageUrl,
    this.targetDate,
    this.reminderDate,
    required this.frequency,
    required this.isActive,
    this.priority,
    this.isReached,
    this.remainingAmount,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String type;
  final int targetAmount;
  final int currentAmount;
  final double progressPercentage;
  final String? targetAmountFormatted;
  final String? currentAmountFormatted;
  final String? imageUrl;
  final String? targetDate;
  final String? reminderDate;
  final String frequency; // daily | weekly | monthly | yearly
  final bool isActive;
  final String? priority;
  final bool? isReached;
  final int? remainingAmount;
  final String? createdAt;
  final String? updatedAt;

  factory ApiFinancialGoal.fromJson(Map<String, dynamic> json) {
    return ApiFinancialGoal(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      type: '${json['type'] ?? ''}',
      targetAmount: json['target_amount'] is int
          ? json['target_amount'] as int
          : int.tryParse('${json['target_amount']}') ?? 0,
      currentAmount: json['current_amount'] is int
          ? json['current_amount'] as int
          : int.tryParse('${json['current_amount']}') ?? 0,
      progressPercentage: (json['progress_percentage'] is num)
          ? (json['progress_percentage'] as num).toDouble()
          : double.tryParse('${json['progress_percentage']}') ?? 0.0,
      targetAmountFormatted: json['target_amount_formatted'] as String?,
      currentAmountFormatted: json['current_amount_formatted'] as String?,
      imageUrl: json['image_url'] as String?,
      targetDate: json['target_date'] as String?,
      reminderDate: json['reminder_date'] as String?,
      frequency: '${json['frequency'] ?? 'monthly'}',
      isActive: json['is_active'] as bool? ?? false,
      priority: json['priority'] != null ? '${json['priority']}' : null,
      isReached: json['is_reached'] as bool?,
      remainingAmount: json['remaining_amount'] is int
          ? json['remaining_amount'] as int
          : int.tryParse('${json['remaining_amount']}'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'progress_percentage': progressPercentage,
      'target_amount_formatted': targetAmountFormatted,
      'current_amount_formatted': currentAmountFormatted,
      'image_url': imageUrl,
      'target_date': targetDate,
      'reminder_date': reminderDate,
      'frequency': frequency,
      'is_active': isActive,
      'priority': priority,
      'is_reached': isReached,
      'remaining_amount': remainingAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime? get parsedTargetDate {
    if (targetDate == null) return null;
    try {
      return DateTime.parse(targetDate!);
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedReminderDate {
    if (reminderDate == null) return null;
    try {
      return DateTime.parse(reminderDate!);
    } catch (_) {
      return null;
    }
  }

  ApiFinancialGoal copyWith({
    int? id,
    String? title,
    String? type,
    int? targetAmount,
    int? currentAmount,
    double? progressPercentage,
    String? Function()? targetAmountFormatted,
    String? Function()? currentAmountFormatted,
    String? Function()? imageUrl,
    String? Function()? targetDate,
    String? Function()? reminderDate,
    String? frequency,
    bool? isActive,
    String? priority,
    bool? isReached,
    int? remainingAmount,
    String? Function()? createdAt,
    String? Function()? updatedAt,
  }) {
    return ApiFinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      targetAmountFormatted:
          targetAmountFormatted != null ? targetAmountFormatted() : this.targetAmountFormatted,
      currentAmountFormatted:
          currentAmountFormatted != null ? currentAmountFormatted() : this.currentAmountFormatted,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      targetDate: targetDate != null ? targetDate() : this.targetDate,
      reminderDate: reminderDate != null ? reminderDate() : this.reminderDate,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      isReached: isReached ?? this.isReached,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        targetAmount,
        currentAmount,
        progressPercentage,
        targetAmountFormatted,
        currentAmountFormatted,
        imageUrl,
        targetDate,
        reminderDate,
        frequency,
        isActive,
        priority,
        isReached,
        remainingAmount,
        createdAt,
        updatedAt,
      ];
}

/// Envelope respons daftar goal: {success, message, data: [...]}.
class ApiFinancialGoalsResponse extends Equatable {
  const ApiFinancialGoalsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiFinancialGoal> data;

  factory ApiFinancialGoalsResponse.fromJson(Map<String, dynamic> json) {
    return ApiFinancialGoalsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ApiFinancialGoal.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons goal tunggal: {success, message, data}.
class ApiFinancialGoalResponse extends Equatable {
  const ApiFinancialGoalResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiFinancialGoal data;

  factory ApiFinancialGoalResponse.fromJson(Map<String, dynamic> json) {
    return ApiFinancialGoalResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiFinancialGoal.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
