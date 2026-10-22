import 'package:equatable/equatable.dart';

/// Kategori target keuangan (diperluas Tahap 10 sesuai desain).
enum GoalCategory {
  emergency,
  savings,
  investment,
  house,
  vehicle,
  gadget,
  holiday,
  education,
  others,
}

/// Frekuensi setoran berkala rencana target.
enum DepositFrequency { monthly, weekly }

/// Target keuangan (mis. Target Investasi Rp3.500.000 / Rp10.000.000).
///
/// Catatan keuangan (Tahap 10, terdokumentasi):
/// - [currentAmount] adalah nilai tersimpan otoritatif. Untuk target baru
///   dimulai dari 0 dan HANYA bertambah via setoran tercatat
///   ([GoalRepository.addDeposit]). Progres % selalu dihitung ulang,
///   tidak pernah disimpan.
/// - [recurringAmount]/[frequency]/[sourceAccountId] adalah RENCANA
///   (preferensi user), bukan histori.
/// - [priority] adalah urutan (0 = tertinggi).
class FinancialGoal extends Equatable {
  const FinancialGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.category = GoalCategory.savings,
    this.recurringAmount = 0,
    this.frequency = DepositFrequency.monthly,
    this.sourceAccountId,
    this.priority = 0,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalCategory category;
  final double recurringAmount;
  final DepositFrequency frequency;
  final String? sourceAccountId;
  final int priority;

  double get progress => targetAmount <= 0 ? 0 : currentAmount / targetAmount;

  bool get isReached => targetAmount > 0 && currentAmount >= targetAmount;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity).toDouble();

  FinancialGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalCategory? category,
    double? recurringAmount,
    DepositFrequency? frequency,
    String? sourceAccountId,
    int? priority,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      recurringAmount: recurringAmount ?? this.recurringAmount,
      frequency: frequency ?? this.frequency,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        currentAmount,
        deadline,
        category,
        recurringAmount,
        frequency,
        sourceAccountId,
        priority,
      ];
}
