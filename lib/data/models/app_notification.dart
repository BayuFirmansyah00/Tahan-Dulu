import 'package:equatable/equatable.dart';

/// Kategori notifikasi keuangan (Tahap 13).
///
/// Penambahan field bersifat backward-compatible: konstruktor lama
/// (id, title, message, createdAt, isRead) tetap valid.
enum NotificationCategory {
  salary,
  savingsGoal,
  tahandulu,
  savingsReminder,
  budget,
  overspending,
}

/// Notifikasi / pengingat keuangan.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.category = NotificationCategory.budget,
    this.isReminder = false,
    this.targetRoute,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Kategori untuk ikon & warna.
  final NotificationCategory category;

  /// True bila termasuk pengingat (untuk tab "Pengingat").
  final bool isReminder;

  /// Route tujuan saat item diketuk (null = tidak navigasi).
  final String? targetRoute;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    NotificationCategory? category,
    bool? isReminder,
    String? targetRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      isReminder: isReminder ?? this.isReminder,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        createdAt,
        isRead,
        category,
        isReminder,
        targetRoute,
      ];
}
