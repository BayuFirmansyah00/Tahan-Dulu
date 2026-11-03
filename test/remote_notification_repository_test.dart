import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_notification_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/app_notification.dart';
import 'package:tahan_dulu/data/models/reminder_settings.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/saving_reminder_screen.dart';

void main() {
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tokenStore = MemoryTokenStore();
    await tokenStore.saveToken('valid-test-token');
  });

  group('1. RemoteNotificationRepository - Data Parsing & Feed', () {
    test('getNotifications parses complete JSON list and maps to AppNotification', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/notifications');
        expect(request.headers['Authorization'], 'Bearer valid-test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'b8d4f400-32b0-466d-893f-c6ad3fb38f5a',
                'user_id': 1,
                'title': 'Gaji Masuk',
                'message': 'Gaji bulanan telah masuk.',
                'category': 'salary',
                'is_reminder': true,
                'target_route': '/transactions',
                'is_read': false,
                'read_at': null,
                'created_at': '2026-10-30T10:00:00.000000Z',
              },
              {
                'id': 'a1c2e3f4-5678-90ab-cdef-1234567890ab',
                'user_id': 1,
                'title': 'Tagihan Listrik',
                'message': 'Kategori unknown/bills fallback.',
                'category': 'bills', // Kategori bills / unknown
                'is_reminder': false,
                'target_route': '/reports',
                'is_read': true,
                'read_at': '2026-10-30T11:00:00.000000Z',
                'created_at': '2026-10-30T09:00:00.000000Z',
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final notifs = await repo.getNotifications();
      expect(notifs.length, 2);

      // Item 1
      expect(notifs[0].id, 'b8d4f400-32b0-466d-893f-c6ad3fb38f5a');
      expect(notifs[0].title, 'Gaji Masuk');
      expect(notifs[0].message, 'Gaji bulanan telah masuk.');
      expect(notifs[0].category, NotificationCategory.salary);
      expect(notifs[0].isReminder, isTrue);
      expect(notifs[0].isRead, isFalse);
      expect(notifs[0].targetRoute, '/transactions');

      // Item 2 - unknown/bills category gracefully maps to budget
      expect(notifs[1].id, 'a1c2e3f4-5678-90ab-cdef-1234567890ab');
      expect(notifs[1].category, NotificationCategory.budget);
      expect(notifs[1].isRead, isTrue);
    });

    test('getNotifications passes query parameter for filters', () async {
      String? requestedQuery;
      final mockHttp = MockClient((request) async {
        requestedQuery = request.url.query;
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      await repo.getNotifications('unread');
      expect(requestedQuery, 'filter=unread');

      await repo.getNotifications('reminder');
      expect(requestedQuery, 'filter=reminder');

      await repo.getNotifications('all');
      expect(requestedQuery, isEmpty);
    });

    test('getUnreadCount parses integer count from /notifications/unread-count', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/notifications/unread-count');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': {'unread_count': 5},
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final count = await repo.getUnreadCount();
      expect(count, 5);
    });

    test('markAsRead sends PATCH to /notifications/{id}/read', () async {
      bool patched = false;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/notifications/test-uuid-1/read');
        patched = true;
        return http.Response(
          jsonEncode({'success': true, 'message': 'OK', 'data': {}}),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      await repo.markAsRead('test-uuid-1');
      expect(patched, isTrue);
    });

    test('markAllAsRead sends POST to /notifications/mark-all-read', () async {
      bool posted = false;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/notifications/mark-all-read');
        posted = true;
        return http.Response(
          jsonEncode({'success': true, 'message': 'OK', 'data': {'updated_count': 3}}),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      await repo.markAllAsRead();
      expect(posted, isTrue);
    });
  });

  group('2. RemoteNotificationRepository - Settings', () {
    test('getPreferences loads all 6 preferences including overspending', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/notification-settings');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'salary_reminder': true,
              'saving_reminder': false,
              'bill_reminder': true,
              'budget_reminder': false,
              'wishlist_reminder': true,
              'overspending_reminder': true,
            },
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final prefs = await repo.getPreferences();
      expect(prefs.length, 6);

      final map = {for (final p in prefs) p.type: p.enabled};
      expect(map[ReminderType.salary], isTrue);
      expect(map[ReminderType.savings], isFalse);
      expect(map[ReminderType.bills], isTrue);
      expect(map[ReminderType.budget], isFalse);
      expect(map[ReminderType.tahandulu], isTrue);
      expect(map[ReminderType.overspending], isTrue);
    });

    test('setPreference sends partial PUT payload to /notification-settings', () async {
      Map<String, dynamic>? receivedPayload;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/notification-settings');
        receivedPayload = jsonDecode(request.body);
        return http.Response(
          jsonEncode({'success': true, 'message': 'Updated', 'data': {}}),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      await repo.setPreference(ReminderType.overspending, false);
      expect(receivedPayload, {'overspending_reminder': false});

      await repo.setPreference(ReminderType.salary, true);
      expect(receivedPayload, {'salary_reminder': true});
    });
  });

  group('3. RemoteNotificationRepository - Saving Reminders', () {
    test('getSavingReminder returns default when data is null', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/saving-reminders');
        return http.Response(
          jsonEncode({'success': true, 'message': 'Not set', 'data': null}),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final config = await repo.getSavingReminder();
      expect(config.amount, 200000.0);
      expect(config.frequency, SavingFrequency.monthly);
      expect(config.enabled, isTrue);
    });

    test('getSavingReminder parses full configuration from backend', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'user_id': 1,
              'goal_id': 3,
              'amount': 350000,
              'frequency': 'weekly',
              'weekday': 2, // Selasa
              'day_of_month': null,
              'hour': 8,
              'minute': 30,
              'time_label': '08:30',
              'enabled': true,
            },
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final config = await repo.getSavingReminder();
      expect(config.goalId, '3');
      expect(config.amount, 350000.0);
      expect(config.frequency, SavingFrequency.weekly);
      expect(config.weekday, 2);
      expect(config.hour, 8);
      expect(config.minute, 30);
      expect(config.timeLabel, '08:30');
      expect(config.enabled, isTrue);
    });

    test('saveSavingReminder sends payload and parses result', () async {
      Map<String, dynamic>? sentPayload;
      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/saving-reminders');
        sentPayload = jsonDecode(request.body);

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'goal_id': 10,
              'amount': 500000,
              'frequency': 'monthly',
              'day_of_month': 25,
              'hour': 20,
              'minute': 15,
              'enabled': true,
            },
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      const toSave = SavingReminderConfig(
        goalId: '10',
        amount: 500000,
        frequency: SavingFrequency.monthly,
        dayOfMonth: 25,
        hour: 20,
        minute: 15,
      );

      final saved = await repo.saveSavingReminder(toSave);
      expect(sentPayload?['amount'], 500000);
      expect(sentPayload?['frequency'], 'monthly');
      expect(sentPayload?['day_of_month'], 25);
      expect(sentPayload?['goal_id'], 10);
      expect(saved.amount, 500000.0);
      expect(saved.goalId, '10');
    });

    test('saveSavingReminder validates positive amount client-side', () {
      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: MockClient((_) async => http.Response('', 200)));
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      expect(
        () => repo.saveSavingReminder(const SavingReminderConfig(amount: 0)),
        throwsArgumentError,
      );
    });

    test('deactivateSavingReminder calls /saving-reminders/deactivate and disables config', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/saving-reminders/deactivate');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'amount': 200000,
              'frequency': 'monthly',
              'day_of_month': 10,
              'hour': 19,
              'minute': 0,
              'enabled': false,
            },
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final deactivated = await repo.deactivateSavingReminder();
      expect(deactivated.enabled, isFalse);
    });
  });

  group('4. RemoteNotificationRepository - Error Handling', () {
    test('401 triggers onUnauthorized callback and throws ApiException', () async {
      bool unauthorizedCalled = false;
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401);
      });

      final client = ApiClient(
        baseUrl: 'https://api.test/api',
        httpClient: mockHttp,
        onUnauthorized: () => unauthorizedCalled = true,
      );
      final repo = RemoteNotificationRepository(
        client: client,
        tokens: tokenStore,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      expect(() => repo.getNotifications(), throwsA(isA<ApiException>()));
      await pumpEventQueue();
      expect(unauthorizedCalled, isTrue);
    });

    test('404 Not Found throws ApiException with statusCode 404', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Notifikasi tidak ditemukan.'}), 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      expect(
        () => repo.markAsRead('non-existent-uuid'),
        throwsA(predicate((e) => e is ApiException && e.statusCode == 404)),
      );
    });

    test('422 Validation Error throws ApiException with field errors', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Data tidak valid.',
            'errors': {
              'goal_id': ['Target tabungan tidak ditemukan.'],
            },
          }),
          422,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      expect(
        () => repo.saveSavingReminder(const SavingReminderConfig(goalId: '999')),
        throwsA(predicate((e) => e is ApiException && e.statusCode == 422 && e.hasFieldError('goal_id'))),
      );
    });

    test('500 Server Error throws ApiException', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Internal Server Error'}), 500);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      expect(
        () => repo.getPreferences(),
        throwsA(predicate((e) => e is ApiException && e.statusCode == 500)),
      );
    });
  });

  group('5. Provider & Navigation Integration with Remote Repository', () {
    test('notificationRepositoryProvider returns RemoteNotificationRepository when useRemoteApi is true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(notificationRepositoryProvider);
      expect(repo, isA<RemoteNotificationRepository>());
    });

    test('Remote error does NOT fallback silently to mock data', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Server down'}), 500);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final remoteRepo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(remoteRepo),
        ],
      );
      addTearDown(container.dispose);

      // Must throw/error, NOT return seed mock notifications
      final repo = container.read(notificationRepositoryProvider);
      expect(
        () => repo.getNotifications(),
        throwsA(isA<ApiException>()),
      );
    });

    testWidgets('Layar Notifikasi renders items fetched from remote repository', (tester) async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/unread-count')) {
          return http.Response(jsonEncode({'success': true, 'data': {'unread_count': 1}}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'remote-uuid-1',
                'title': 'Remote Alert Title',
                'message': 'Pesan dari Laravel Remote.',
                'category': 'salary',
                'is_reminder': true,
                'target_route': '/transactions',
                'is_read': false,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final remoteRepo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final router = GoRouter(
        initialLocation: AppRoutes.notifications,
        routes: [
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const Scaffold(body: Text('Dummy Transactions')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(remoteRepo),
            goalRepositoryProvider.overrideWithValue(MockGoalRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Remote Alert Title'), findsOneWidget);
      expect(find.text('Pesan dari Laravel Remote.'), findsOneWidget);
    });

    testWidgets('Layar Pengaturan Notifikasi loads and updates remote preferences', (tester) async {
      bool putSent = false;
      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/notification-settings') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'salary_reminder': true,
                'saving_reminder': true,
                'bill_reminder': true,
                'budget_reminder': true,
                'wishlist_reminder': true,
                'overspending_reminder': true,
              },
            }),
            200,
          );
        }
        if (request.method == 'PUT' && request.url.path == '/api/notification-settings') {
          putSent = true;
          return http.Response(
            jsonEncode({'success': true, 'message': 'OK', 'data': {}}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final remoteRepo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final router = GoRouter(
        initialLocation: AppRoutes.notificationSettings,
        routes: [
          GoRoute(
            path: AppRoutes.notificationSettings,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const Scaffold(body: Text('Dummy Dashboard')),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const Scaffold(body: Text('Dummy Notifications')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(remoteRepo),
            goalRepositoryProvider.overrideWithValue(MockGoalRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderSalaryTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderOverspendTitle), findsOneWidget);

      // Tap first switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(6));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(putSent, isTrue);
    });

    testWidgets('Layar Pengingat Menabung loads and saves remote configuration', (tester) async {
      bool postSent = false;
      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/saving-reminders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'amount': 250000,
                'frequency': 'monthly',
                'day_of_month': 10,
                'hour': 19,
                'minute': 0,
                'enabled': true,
              },
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/saving-reminders') {
          postSent = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'amount': 250000,
                'frequency': 'monthly',
                'day_of_month': 10,
                'hour': 19,
                'minute': 0,
                'enabled': true,
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final remoteRepo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final router = GoRouter(
        initialLocation: AppRoutes.notificationSavings,
        routes: [
          GoRoute(
            path: AppRoutes.notificationSavings,
            builder: (context, state) => const SavingReminderScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const Scaffold(body: Text('Dummy Dashboard')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(remoteRepo),
            goalRepositoryProvider.overrideWithValue(MockGoalRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.savingReminderTitle), findsWidgets);
      expect(find.text('250.000'), findsOneWidget);

      final saveFinder = find.text(AppStrings.savingSaveAction);
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(postSent, isTrue);
    });

    testWidgets('Deep link navigates to target route and marks as read', (tester) async {
      bool readPatched = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/read')) {
          readPatched = true;
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        if (request.url.path.contains('/unread-count')) {
          return http.Response(jsonEncode({'success': true, 'data': {'unread_count': 1}}), 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'notif-valid-route',
                'title': 'Salary Notification',
                'message': 'Gaji telah dialokasikan.',
                'category': 'salary',
                'is_reminder': true,
                'target_route': AppRoutes.transactions,
                'is_read': false,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final remoteRepo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      final router = GoRouter(
        initialLocation: AppRoutes.notifications,
        routes: [
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const Scaffold(body: Text('Transactions Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(remoteRepo),
            goalRepositoryProvider.overrideWithValue(MockGoalRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Salary Notification'));
      await tester.pumpAndSettle();

      expect(readPatched, isTrue);
      expect(find.text('Transactions Screen'), findsOneWidget);
    });
  });
}
