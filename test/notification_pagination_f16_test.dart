import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/routing/notification_deep_link.dart';
import 'package:tahan_dulu/data/models/app_notification.dart';
import 'package:tahan_dulu/data/models/reminder_settings.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/notifications/presentation/providers/notifications_providers.dart';

class _FakePaginatedNotificationRepository extends NotificationRepository {
  _FakePaginatedNotificationRepository(this._allNotifications);

  final List<AppNotification> _allNotifications;

  @override
  Future<List<AppNotification>> getNotifications([dynamic filter]) async {
    return _applyFilter(_allNotifications, filter);
  }

  @override
  Future<NotificationPaginationResult> getPaginatedNotifications({
    dynamic filter,
    int? page,
    int? perPage,
  }) async {
    final filtered = _applyFilter(_allNotifications, filter);
    final p = page ?? 1;
    final limit = perPage ?? 20;
    final total = filtered.length;
    final lastPage = (total / limit).ceil() == 0 ? 1 : (total / limit).ceil();
    final startIndex = (p - 1) * limit;
    final items = filtered.skip(startIndex).take(limit).toList();

    return NotificationPaginationResult(
      items: items,
      currentPage: p,
      lastPage: lastPage,
      perPage: limit,
      total: total,
      hasNextPage: p < lastPage,
    );
  }

  List<AppNotification> _applyFilter(
    List<AppNotification> items,
    dynamic filter,
  ) {
    if (filter == null) return items;
    final filterName = filter is Enum ? filter.name : filter.toString();
    if (filterName == 'unread') {
      return items.where((e) => !e.isRead).toList();
    }
    if (filterName == 'reminder') {
      return items.where((e) => e.isReminder).toList();
    }
    return items;
  }

  @override
  Future<int> getUnreadCount() async {
    return _allNotifications.where((e) => !e.isRead).length;
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _allNotifications.indexWhere((e) => e.id == id);
    if (index != -1) {
      _allNotifications[index] =
          _allNotifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _allNotifications.length; i++) {
      _allNotifications[i] = _allNotifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<List<ReminderPreference>> getPreferences() async => [];
  @override
  Future<void> setPreference(ReminderType type, bool enabled) async {}
  @override
  Future<SavingReminderConfig> getSavingReminder() async =>
      const SavingReminderConfig();
  @override
  Future<SavingReminderConfig> saveSavingReminder(
    SavingReminderConfig config,
  ) async =>
      config;
  @override
  Future<SavingReminderConfig> deactivateSavingReminder() async =>
      const SavingReminderConfig(enabled: false);
}

void main() {
  group('F16 Notification Pagination & Deep Link Verification', () {
    late List<AppNotification> seedNotifications;
    late _FakePaginatedNotificationRepository repo;

    setUp(() {
      // 50 notifications total: 30 unread (0..29), 20 read (30..49); 25 reminders
      seedNotifications = List.generate(50, (i) {
        final isReminder = i % 2 == 0;
        final isRead = i >= 30;
        return AppNotification(
          id: 'notif-uuid-$i',
          title: 'Notifikasi #$i',
          message: 'Isi notifikasi ke-$i untuk pengujian paginasi F16',
          category: isReminder
              ? NotificationCategory.savingsReminder
              : NotificationCategory.budget,
          isReminder: isReminder,
          createdAt: DateTime(2026, 11, 24, 10).subtract(Duration(hours: i)),
          isRead: isRead,
          targetRoute: i == 5 ? AppRoutes.investments : null,
        );
      });
      repo = _FakePaginatedNotificationRepository(seedNotifications);
    });

    test('Loads first page of 20 items and detects hasNextPage', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedNotificationsProvider.notifier);
      await notifier.loadFirstPage();

      final state = container.read(paginatedNotificationsProvider);
      expect(state.items.length, 20);
      expect(state.page, 1);
      expect(state.total, 50);
      expect(state.hasNextPage, isTrue);
      expect(state.items.first.id, 'notif-uuid-0');
      expect(state.items.last.id, 'notif-uuid-19');
    });

    test('Loads next page, merges items, and deduplicates by UUID', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedNotificationsProvider.notifier);
      await notifier.loadFirstPage();
      await notifier.loadNextPage();

      final state = container.read(paginatedNotificationsProvider);
      expect(state.items.length, 40);
      expect(state.page, 2);
      expect(state.hasNextPage, isTrue);

      // Load page 3 (last 10 items)
      await notifier.loadNextPage();
      final stateP3 = container.read(paginatedNotificationsProvider);
      expect(stateP3.items.length, 50);
      expect(stateP3.page, 3);
      expect(stateP3.hasNextPage, isFalse);

      // Calling loadNextPage when hasNextPage is false does nothing
      await notifier.loadNextPage();
      expect(container.read(paginatedNotificationsProvider).items.length, 50);
    });

    test('Tab filter switching updates paginated results cleanly', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Set filter unread
      container
          .read(notificationFilterProvider.notifier)
          .set(NotificationFilter.unread);
      final notifier = container.read(paginatedNotificationsProvider.notifier);
      await notifier.loadFirstPage();

      var state = container.read(paginatedNotificationsProvider);
      expect(state.items.length, 20);
      expect(state.total, 30);
      expect(state.items.every((n) => !n.isRead), isTrue);

      // Load page 2 of unread (remaining 10 items)
      await notifier.loadNextPage();
      state = container.read(paginatedNotificationsProvider);
      expect(state.items.length, 30);
      expect(state.hasNextPage, isFalse);
    });

    test('Local markAsRead and markAllAsRead synchronizes UI state', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedNotificationsProvider.notifier);
      await notifier.loadFirstPage();

      expect(
        container
            .read(paginatedNotificationsProvider)
            .items
            .firstWhere((n) => n.id == 'notif-uuid-0')
            .isRead,
        isFalse,
      );

      notifier.markItemReadLocally('notif-uuid-0');
      expect(
        container
            .read(paginatedNotificationsProvider)
            .items
            .firstWhere((n) => n.id == 'notif-uuid-0')
            .isRead,
        isTrue,
      );

      notifier.markAllReadLocally();
      expect(
        container
            .read(paginatedNotificationsProvider)
            .items
            .every((n) => n.isRead),
        isTrue,
      );
    });

    test('NotificationDeepLink resolves investments and recurring routes safely', () {
      // Direct route allowlist
      expect(
        NotificationDeepLink.resolve(
          route: '/investments',
          type: 'investment',
        ),
        AppRoutes.investments,
      );

      // Type-based resolution without explicit route
      expect(
        NotificationDeepLink.resolve(
          type: 'investment',
        ),
        AppRoutes.investments,
      );
      expect(
        NotificationDeepLink.resolve(
          type: 'recurring_income',
        ),
        AppRoutes.recurringIncomes,
      );
      expect(
        NotificationDeepLink.resolve(
          type: 'recurring_expense',
        ),
        AppRoutes.recurringExpenses,
      );

      // Unknown / malicious route falls back to notifications screen
      expect(
        NotificationDeepLink.resolve(
          route: '/malicious/arbitrary/path',
          type: 'unknown',
        ),
        AppRoutes.notifications,
      );
    });
  });
}
