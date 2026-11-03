import '../../models/app_notification.dart';
import '../../models/reminder_settings.dart';
import '../../repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi remote [NotificationRepository] yang berkomunikasi dengan
/// REST API Laravel TahanDulu.
class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository({
    required this.client,
    required this.tokens,
    this.onUnauthorized,
  });

  final ApiClient client;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  Future<String> _requireToken() async {
    final token = await tokens.readToken();
    if (token == null || token.isEmpty) {
      onUnauthorized?.call();
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  static NotificationCategory _parseCategory(dynamic raw) {
    final str = raw?.toString() ?? '';
    for (final cat in NotificationCategory.values) {
      if (cat.name == str) return cat;
    }
    // Fallback aman untuk kategori yang tidak dikenal (misal 'bills' bila dikirim).
    return NotificationCategory.budget;
  }

  @override
  Future<List<AppNotification>> getNotifications([
    dynamic filter,
  ]) async {
    final token = await _requireToken();
    final filterName = filter != null
        ? (filter is Enum ? filter.name : filter.toString())
        : null;
    final query = filterName != null && filterName != 'all'
        ? '?filter=$filterName'
        : '';

    final body = await client.get('/notifications$query', token: token);
    final data = body['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification(
              id: e['id']?.toString() ?? '',
              title: e['title']?.toString() ?? '',
              message: e['message']?.toString() ?? '',
              createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              isRead: e['is_read'] == true,
              isReminder: e['is_reminder'] == true,
              targetRoute: e['target_route'] as String?,
              category: _parseCategory(e['category']),
            ))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final token = await _requireToken();
    final body = await client.get('/notifications/unread-count', token: token);
    final data = body['data'];
    if (data is Map && data['unread_count'] is int) {
      return data['unread_count'] as int;
    }
    return 0;
  }

  @override
  Future<void> markAsRead(String id) async {
    final token = await _requireToken();
    await client.patch('/notifications/$id/read', {}, token: token);
  }

  @override
  Future<void> markAllAsRead() async {
    final token = await _requireToken();
    await client.post('/notifications/mark-all-read', {}, token: token);
  }

  @override
  Future<List<ReminderPreference>> getPreferences() async {
    final token = await _requireToken();
    final body = await client.get('/notification-settings', token: token);
    final data = body['data'] as Map<String, dynamic>? ?? {};

    return [
      ReminderPreference(
        type: ReminderType.salary,
        enabled: data['salary_reminder'] != false,
      ),
      ReminderPreference(
        type: ReminderType.savings,
        enabled: data['saving_reminder'] != false,
      ),
      ReminderPreference(
        type: ReminderType.bills,
        enabled: data['bill_reminder'] != false,
      ),
      ReminderPreference(
        type: ReminderType.budget,
        enabled: data['budget_reminder'] != false,
      ),
      ReminderPreference(
        type: ReminderType.tahandulu,
        enabled: data['wishlist_reminder'] != false,
      ),
      ReminderPreference(
        type: ReminderType.overspending,
        enabled: data['overspending_reminder'] != false,
      ),
    ];
  }

  @override
  Future<void> setPreference(ReminderType type, bool enabled) async {
    final token = await _requireToken();
    final String key;
    switch (type) {
      case ReminderType.salary:
        key = 'salary_reminder';
      case ReminderType.savings:
        key = 'saving_reminder';
      case ReminderType.bills:
        key = 'bill_reminder';
      case ReminderType.budget:
        key = 'budget_reminder';
      case ReminderType.tahandulu:
        key = 'wishlist_reminder';
      case ReminderType.overspending:
        key = 'overspending_reminder';
    }

    await client.put('/notification-settings', {key: enabled}, token: token);
  }

  @override
  Future<SavingReminderConfig> getSavingReminder() async {
    final token = await _requireToken();
    final body = await client.get('/saving-reminders', token: token);
    final data = body['data'];

    if (data == null || data is! Map<String, dynamic>) {
      return const SavingReminderConfig();
    }

    return _parseSavingReminder(data);
  }

  @override
  Future<SavingReminderConfig> saveSavingReminder(
    SavingReminderConfig config,
  ) async {
    if (config.amount <= 0) {
      throw ArgumentError('Nominal harus > 0');
    }

    final token = await _requireToken();
    final payload = <String, dynamic>{
      'amount': config.amount.toInt(),
      'frequency': config.frequency.name,
      'hour': config.hour,
      'minute': config.minute,
      'enabled': config.enabled,
      if (config.goalId != null && int.tryParse(config.goalId!) != null)
        'goal_id': int.parse(config.goalId!),
      if (config.frequency == SavingFrequency.weekly)
        'weekday': config.weekday,
      if (config.frequency == SavingFrequency.monthly)
        'day_of_month': config.dayOfMonth,
    };

    final body = await client.post('/saving-reminders', payload, token: token);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons server tidak valid.');
    }

    return _parseSavingReminder(data);
  }

  @override
  Future<SavingReminderConfig> deactivateSavingReminder() async {
    final token = await _requireToken();
    final body =
        await client.post('/saving-reminders/deactivate', {}, token: token);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons server tidak valid.');
    }

    return _parseSavingReminder(data);
  }

  SavingReminderConfig _parseSavingReminder(Map<String, dynamic> data) {
    final freqStr = data['frequency']?.toString();
    final frequency = SavingFrequency.values.firstWhere(
      (e) => e.name == freqStr,
      orElse: () => SavingFrequency.monthly,
    );

    return SavingReminderConfig(
      goalId: data['goal_id']?.toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 200000.0,
      frequency: frequency,
      weekday: (data['weekday'] as num?)?.toInt() ?? 1,
      dayOfMonth: (data['day_of_month'] as num?)?.toInt() ?? 10,
      hour: (data['hour'] as num?)?.toInt() ?? 19,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
      enabled: data['enabled'] != false,
    );
  }
}

