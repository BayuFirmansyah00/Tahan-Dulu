import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/routing/notification_deep_link.dart';

void main() {
  group('NotificationDeepLink', () {
    test('menerima route internal valid dan menolak URL eksternal', () {
      expect(
        NotificationDeepLink.resolve(route: '/tahan-dulu/42'),
        '/tahan-dulu/42',
      );
      expect(
        NotificationDeepLink.resolve(route: '/goals/7'),
        '/goals/7',
      );
      expect(
        NotificationDeepLink.resolve(
          route: 'https://evil.example/phish',
          type: 'budget',
        ),
        AppRoutes.dashboard,
      );
      expect(
        NotificationDeepLink.resolve(route: '/unknown-secret-route'),
        AppRoutes.notifications,
      );
    });

    test('fallback menggunakan type dan entityId numeric yang aman', () {
      expect(
        NotificationDeepLink.resolve(type: 'tahandulu', entityId: '99'),
        '/tahan-dulu/99',
      );
      expect(
        NotificationDeepLink.resolve(type: 'savingsGoal', entityId: 'abc'),
        AppRoutes.goals,
      );
      expect(
        NotificationDeepLink.resolve(type: 'bill'),
        AppRoutes.recurringExpenses,
      );
    });
  });
}

