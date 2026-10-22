import 'package:equatable/equatable.dart';

/// Jenis pengingat pada Pengaturan Notifikasi (Tahap 13).
enum ReminderType { salary, savings, bills, budget, tahandulu, overspending }

/// Preferensi satu jenis pengingat. In-memory pada tahap ini.
class ReminderPreference extends Equatable {
  const ReminderPreference({required this.type, this.enabled = true});

  final ReminderType type;
  final bool enabled;

  ReminderPreference copyWith({ReminderType? type, bool? enabled}) {
    return ReminderPreference(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [type, enabled];
}

/// Frekuensi Pengingat Menabung.
enum SavingFrequency { daily, weekly, monthly }

/// Konfigurasi Pengingat Menabung.
///
/// - [goalId]: target terkait (null = belum memilih).
/// - [weekday]: 1 (Senin)..7 (Minggu), berlaku untuk mingguan.
/// - [dayOfMonth]: 1..31, berlaku untuk bulanan. Pada bulan yang lebih
///   pendek, pengingat dikirim di hari terakhir (lihat [effectiveDayFor]).
class SavingReminderConfig extends Equatable {
  const SavingReminderConfig({
    this.goalId,
    this.amount = 200000,
    this.frequency = SavingFrequency.monthly,
    this.weekday = 1,
    this.dayOfMonth = 10,
    this.hour = 19,
    this.minute = 0,
    this.enabled = true,
  });

  final String? goalId;
  final double amount;
  final SavingFrequency frequency;
  final int weekday;
  final int dayOfMonth;
  final int hour;
  final int minute;
  final bool enabled;

  bool get isAmountValid => amount > 0;
  bool get isGoalValid => goalId != null && goalId!.isNotEmpty;
  bool get isValid => isAmountValid;

  /// Hari efektif untuk bulan tertentu (t-consistent untuk Februari, dst).
  int effectiveDayFor(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return dayOfMonth.clamp(1, lastDay);
  }

  /// "19:00".
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  SavingReminderConfig copyWith({
    String? Function()? goalId,
    double? amount,
    SavingFrequency? frequency,
    int? weekday,
    int? dayOfMonth,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return SavingReminderConfig(
      goalId: goalId != null ? goalId() : this.goalId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [
        goalId,
        amount,
        frequency,
        weekday,
        dayOfMonth,
        hour,
        minute,
        enabled,
      ];
}

/// Nama hari Indonesia untuk dropdown mingguan. Index 0 = Senin (1).
const List<String> indonesianWeekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
