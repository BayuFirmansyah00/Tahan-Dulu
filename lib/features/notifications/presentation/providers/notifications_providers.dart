import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../data/models/app_notification.dart';
import '../../../../data/models/reminder_settings.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';

/// Filter tab layar Notifikasi.
enum NotificationFilter { all, unread, reminder }

/// Filter aktif tab (default Semua).
class NotificationFilterController extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => NotificationFilter.all;

  void set(NotificationFilter filter) => state = filter;
}

final notificationFilterProvider =
    NotifierProvider<NotificationFilterController, NotificationFilter>(
  NotificationFilterController.new,
);

/// Daftar notifikasi terurut terbaru, difilter sesuai tab aktif.
final notificationsListProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final items =
      await ref.watch(notificationRepositoryProvider).getNotifications();
  final sorted = List.of(items)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  switch (ref.watch(notificationFilterProvider)) {
    case NotificationFilter.all:
      return sorted;
    case NotificationFilter.unread:
      return sorted.where((e) => !e.isRead).toList();
    case NotificationFilter.reminder:
      return sorted.where((e) => e.isReminder).toList();
  }
});

/// Jumlah belum dibaca (untuk badge / indikator).
final unreadCountProvider = FutureProvider<int>((ref) async {
  final items =
      await ref.watch(notificationRepositoryProvider).getNotifications();
  return items.where((e) => !e.isRead).length;
});

/// Aksi baca notifikasi: tandai satu / semua. Guard ganda bawaan.
class NotificationsController extends Notifier<bool> {
  bool _busy = false;

  @override
  bool build() => false;

  void _refresh() {
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadCountProvider);
    // Legacy + agregat dashboard ikut reaktif (titik unread).
    ref.invalidate(notificationsProvider);
    ref.invalidate(dashboardDataProvider);
  }

  Future<bool> markAsRead(String id) async {
    if (_busy) return false;
    _busy = true;
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      _refresh();
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> markAllAsRead() async {
    if (_busy) return false;
    _busy = true;
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      _refresh();
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, bool>(
  NotificationsController.new,
);

/// Daftar preferensi pengingat (6 jenis).
final reminderPreferencesProvider =
    FutureProvider<List<ReminderPreference>>((ref) {
  return ref.watch(notificationRepositoryProvider).getPreferences();
});

/// Toggle preferensi + persistensi via repository.
class ReminderPrefsController extends Notifier<bool> {
  bool _busy = false;

  @override
  bool build() => false;

  Future<bool> setEnabled(ReminderType type, bool enabled) async {
    if (_busy) return false;
    _busy = true;
    try {
      await ref
          .read(notificationRepositoryProvider)
          .setPreference(type, enabled);
      ref.invalidate(reminderPreferencesProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }
}

final reminderPrefsControllerProvider =
    NotifierProvider<ReminderPrefsController, bool>(
  ReminderPrefsController.new,
);

/// Konfigurasi tersimpan Pengingat Menabung.
final savingReminderProvider =
    FutureProvider<SavingReminderConfig>((ref) {
  return ref.watch(notificationRepositoryProvider).getSavingReminder();
});

/// Draf form Pengingat Menabung (sumber kebenaran selama mengisi).
class SavingReminderDraft extends Equatable {
  const SavingReminderDraft({
    this.goalId,
    this.amount = 200000,
    this.frequency = SavingFrequency.monthly,
    this.weekday = 1,
    this.dayOfMonth = 10,
    this.hour = 19,
    this.minute = 0,
    this.enabled = true,
    this.loaded = false,
  });

  final String? goalId;
  final double amount;
  final SavingFrequency frequency;
  final int weekday;
  final int dayOfMonth;
  final int hour;
  final int minute;
  final bool enabled;
  final bool loaded;

  bool get isAmountValid => amount > 0;
  bool get isComplete => isAmountValid;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  SavingReminderDraft copyWith({
    String? Function()? goalId,
    double? amount,
    SavingFrequency? frequency,
    int? weekday,
    int? dayOfMonth,
    int? hour,
    int? minute,
    bool? enabled,
    bool? loaded,
  }) {
    return SavingReminderDraft(
      goalId: goalId != null ? goalId() : this.goalId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      loaded: loaded ?? this.loaded,
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
        loaded,
      ];
}

/// Controller form Pengingat Menabung: load, validasi, simpan anti-ganda.
class SavingReminderController extends Notifier<SavingReminderDraft> {
  bool _saving = false;

  @override
  SavingReminderDraft build() => const SavingReminderDraft();

  bool get isSaving => _saving;

  /// Muat konfigurasi tersimpan ke draf (sekali per siklus layar).
  Future<void> load() async {
    if (state.loaded) return;
    try {
      final saved =
          await ref.read(notificationRepositoryProvider).getSavingReminder();
      state = SavingReminderDraft(
        goalId: saved.goalId,
        amount: saved.amount,
        frequency: saved.frequency,
        weekday: saved.weekday,
        dayOfMonth: saved.dayOfMonth,
        hour: saved.hour,
        minute: saved.minute,
        enabled: saved.enabled,
        loaded: true,
      );
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  void setGoal(String? goalId) {
    state = state.copyWith(goalId: () => goalId);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setAmountText(String text) {
    setAmount(RupiahInputFormatter.parse(text));
  }

  void setFrequency(SavingFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setWeekday(int weekday) {
    state = state.copyWith(weekday: weekday.clamp(1, 7));
  }

  void setDayOfMonth(int day) {
    state = state.copyWith(dayOfMonth: day.clamp(1, 31));
  }

  void setTime(int hour, int minute) {
    state = state.copyWith(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  SavingReminderConfig _toConfig() => SavingReminderConfig(
        goalId: state.goalId,
        amount: state.amount,
        frequency: state.frequency,
        weekday: state.weekday,
        dayOfMonth: state.dayOfMonth,
        hour: state.hour,
        minute: state.minute,
        enabled: state.enabled,
      );

  /// Simpan draf. Aman dipanggil berulang (anti-ganda).
  Future<bool> save() async {
    if (_saving || !state.isComplete) return false;
    _saving = true;
    try {
      await ref
          .read(notificationRepositoryProvider)
          .saveSavingReminder(_toConfig());
      ref.invalidate(savingReminderProvider);
      ref.invalidate(reminderPreferencesProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Nonaktifkan tanpa menghapus target / riwayat (murni flag).
  Future<bool> deactivate() async {
    if (_saving) return false;
    _saving = true;
    try {
      final saved = await ref
          .read(notificationRepositoryProvider)
          .deactivateSavingReminder();
      state = state.copyWith(enabled: saved.enabled);
      ref.invalidate(savingReminderProvider);
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }
}

final savingReminderControllerProvider =
    NotifierProvider<SavingReminderController, SavingReminderDraft>(
  SavingReminderController.new,
);
