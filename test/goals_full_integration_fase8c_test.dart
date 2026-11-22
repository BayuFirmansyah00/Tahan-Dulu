import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/routing/notification_deep_link.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_notification_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/api_financial_goal.dart';
import 'package:tahan_dulu/data/models/api_goal_transaction.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/models/reminder_settings.dart';

void main() {
  group('Fase 8C: Full Goals Integration Audit & UUID Verification', () {
    late MemoryTokenStore tokenStore;

    setUp(() async {
      tokenStore = MemoryTokenStore();
      await tokenStore.saveToken('valid-uuid-session-token');
    });

    test('1. Model UUID Safety: ApiFinancialGoal and ApiGoalTransaction preserve UUID strings', () {
      const sampleGoalUuid = '9df4164b-b519-48fe-a511-b0db44ea244d';
      const sampleTxUuid = 'e8b15d2a-7c93-4e89-a212-32fca0199f5b';

      // JSON returned by Laravel PostgreSQL
      final goalJson = {
        'id': sampleGoalUuid,
        'title': 'Beli Laptop M3',
        'type': 'gadget',
        'target_amount': 25000000,
        'current_amount': 5000000,
        'progress_percentage': 20.0,
        'frequency': 'monthly',
        'is_active': true,
        'priority': '0',
      };

      final apiGoal = ApiFinancialGoal.fromJson(goalJson);
      expect(apiGoal.id, equals(sampleGoalUuid));
      expect(apiGoal.id, isNot(equals('0')));
      expect(apiGoal.targetAmount, equals(25000000));
      expect(apiGoal.currentAmount, equals(5000000));

      final txJson = {
        'id': sampleTxUuid,
        'goal_id': sampleGoalUuid,
        'type': 'deposit',
        'amount': 2500000,
        'notes': 'Alokasi bulanan',
        'created_at': '2026-11-22T10:00:00Z',
      };

      final apiTx = ApiGoalTransaction.fromJson(txJson);
      expect(apiTx.id, equals(sampleTxUuid));
      expect(apiTx.id, isNot(equals('0')));
      expect(apiTx.goalId, equals(sampleGoalUuid));
      expect(apiTx.goalId, isNot(equals('0')));
    });

    test('2. CRUD Target with UUID over RemoteGoalRepository', () async {
      const goalUuid = '9df4164b-b519-48fe-a511-b0db44ea244d';

      final mockHttp = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer valid-uuid-session-token');

        if (request.method == 'GET' && request.url.path == '/api/goals') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': goalUuid,
                  'title': 'Dana Darurat 2026',
                  'type': 'emergency',
                  'target_amount': 10000000,
                  'current_amount': 2000000,
                  'progress_percentage': 20.0,
                  'priority': '0',
                  'frequency': 'monthly',
                  'is_active': true,
                }
              ],
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/goals') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['title'], equals('Target Investasi'));
          expect(body['target_amount'], equals(50000000));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Target keuangan berhasil ditambahkan',
              'data': {
                'id': goalUuid,
                'title': body['title'],
                'type': body['type'],
                'target_amount': body['target_amount'],
                'current_amount': 0,
                'progress_percentage': 0.0,
                'priority': body['priority'],
                'frequency': body['frequency'],
                'is_active': true,
              },
            }),
            201,
          );
        }

        if (request.method == 'GET' && request.url.path == '/api/goals/$goalUuid') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': {
                'id': goalUuid,
                'title': 'Dana Darurat 2026',
                'type': 'emergency',
                'target_amount': 10000000,
                'current_amount': 2000000,
                'progress_percentage': 20.0,
                'priority': '0',
                'frequency': 'monthly',
                'is_active': true,
              },
            }),
            200,
          );
        }

        if (request.method == 'PUT' && request.url.path == '/api/goals/$goalUuid') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Target keuangan berhasil diperbarui',
              'data': {
                'id': goalUuid,
                'title': body['title'],
                'type': body['type'],
                'target_amount': body['target_amount'],
                'current_amount': 2000000,
                'progress_percentage': 16.67,
                'priority': body['priority'],
                'frequency': body['frequency'],
                'is_active': true,
              },
            }),
            200,
          );
        }

        if (request.method == 'DELETE' && request.url.path == '/api/goals/$goalUuid') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Target keuangan berhasil dihapus',
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/goals/reorder') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['ordered_ids'], equals([goalUuid]));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Urutan target berhasil diperbarui',
              'data': [],
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

      // 1. Get Goals List
      final goals = await repo.getGoals();
      expect(goals.length, equals(1));
      expect(goals.first.id, equals(goalUuid));
      expect(goals.first.name, equals('Dana Darurat 2026'));

      // 2. Create Goal
      final newGoal = const FinancialGoal(
        id: 'temp-id',
        name: 'Target Investasi',
        targetAmount: 50000000,
        currentAmount: 0,
        category: GoalCategory.investment,
      );
      final created = await repo.addGoal(newGoal);
      expect(created.id, equals(goalUuid));
      expect(created.name, equals('Target Investasi'));

      // 3. Get Goal By ID
      final detail = await repo.getGoalById(goalUuid);
      expect(detail.id, equals(goalUuid));
      expect(detail.targetAmount, equals(10000000));

      // 4. Update Goal
      final updated = await repo.updateGoal(
        detail.copyWith(name: 'Dana Darurat Updated', targetAmount: 12000000),
      );
      expect(updated.id, equals(goalUuid));
      expect(updated.name, equals('Dana Darurat Updated'));
      expect(updated.targetAmount, equals(12000000));

      // 5. Reorder Goals
      await repo.saveGoalOrder([goalUuid]);

      // 6. Delete Goal
      await repo.deleteGoal(goalUuid);
    });

    test('3. Goal Progress Calculation & Cap Rules', () {
      // Skenario A: Target baru Rp0
      const g1 = FinancialGoal(
        id: '1',
        name: 'Baru',
        targetAmount: 5000000,
        currentAmount: 0,
      );
      expect(g1.progress, equals(0.0));
      expect(g1.remaining, equals(5000000.0));
      expect(g1.isReached, isFalse);

      // Skenario B: Target laptop Rp5.000.000, terkumpul Rp1.500.000 (30%)
      const g2 = FinancialGoal(
        id: '2',
        name: 'Laptop',
        targetAmount: 5000000,
        currentAmount: 1500000,
      );
      expect(g2.progress, equals(0.3));
      expect(g2.remaining, equals(3500000.0));
      expect(g2.isReached, isFalse);

      // Skenario C: Target tercapai pas 100%
      const g3 = FinancialGoal(
        id: '3',
        name: 'Motor',
        targetAmount: 20000000,
        currentAmount: 20000000,
      );
      expect(g3.progress, equals(1.0));
      expect(g3.remaining, equals(0.0));
      expect(g3.isReached, isTrue);

      // Skenario D: Dana melebihi target (120%)
      const g4 = FinancialGoal(
        id: '4',
        name: 'Liburan',
        targetAmount: 10000000,
        currentAmount: 12000000,
      );
      expect(g4.progress, equals(1.2));
      expect(g4.remaining, equals(0.0));
      expect(g4.isReached, isTrue);

      // Skenario E: Target amount nol atau tidak valid
      const g5 = FinancialGoal(
        id: '5',
        name: 'Invalid',
        targetAmount: 0,
        currentAmount: 0,
      );
      expect(g5.progress, equals(0.0));
      expect(g5.remaining, equals(0.0));
      expect(g5.isReached, isFalse);
    });

    test('4. Goal Deposit Operations with UUID & Multi-Goal Delete Search', () async {
      const goal1Uuid = '11111111-1111-1111-1111-111111111111';
      const goal2Uuid = '22222222-2222-2222-2222-222222222222';
      const depositUuid = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

      bool deleteApiCalled = false;

      final mockHttp = MockClient((request) async {
        // Return 2 goals
        if (request.method == 'GET' && request.url.path == '/api/goals') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': goal1Uuid,
                  'title': 'Goal 1',
                  'type': 'savings',
                  'target_amount': 10000000,
                  'current_amount': 1000000,
                  'progress_percentage': 10.0,
                  'frequency': 'monthly',
                  'is_active': true,
                },
                {
                  'id': goal2Uuid,
                  'title': 'Goal 2',
                  'type': 'emergency',
                  'target_amount': 20000000,
                  'current_amount': 5000000,
                  'progress_percentage': 25.0,
                  'frequency': 'monthly',
                  'is_active': true,
                },
              ],
            }),
            200,
          );
        }

        // Goal 1 has no deposits
        if (request.method == 'GET' && request.url.path == '/api/goals/$goal1Uuid/transactions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': [],
            }),
            200,
          );
        }

        // Goal 2 has the deposit
        if (request.method == 'GET' && request.url.path == '/api/goals/$goal2Uuid/transactions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': depositUuid,
                  'goal_id': goal2Uuid,
                  'type': 'deposit',
                  'amount': 1000000,
                  'notes': 'Setoran tabungan',
                  'created_at': '2026-11-22T10:00:00Z',
                }
              ],
            }),
            200,
          );
        }

        // Add deposit to Goal 2
        if (request.method == 'POST' && request.url.path == '/api/goals/$goal2Uuid/transactions') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Transaksi dana goal berhasil dicatat',
              'data': {
                'id': depositUuid,
                'goal_id': goal2Uuid,
                'type': body['type'],
                'amount': body['amount'],
                'notes': body['notes'],
                'created_at': '2026-11-22T10:00:00Z',
              },
            }),
            201,
          );
        }

        // Delete deposit from Goal 2
        if (request.method == 'DELETE' && request.url.path == '/api/goals/$goal2Uuid/transactions/$depositUuid') {
          deleteApiCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Transaksi dana goal berhasil dihapus',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

      // Add Deposit to Goal 2
      final addedDeposit = await repo.addDeposit(
        GoalDeposit(
          id: 'temp',
          goalId: goal2Uuid,
          amount: 1000000,
          date: DateTime.now(),
          accountId: 'acc-bca-uuid',
          note: 'Setoran tabungan',
        ),
      );
      expect(addedDeposit.id, equals(depositUuid));
      expect(addedDeposit.goalId, equals(goal2Uuid));
      expect(addedDeposit.amount, equals(1000000.0));
      expect(addedDeposit.accountId, equals('acc-bca-uuid'));

      // Delete Deposit (must search past Goal 1 and find it in Goal 2 without throwing StateError)
      await repo.deleteDeposit(depositUuid);
      expect(deleteApiCalled, isTrue);
    });

    test('5. Saving Reminder & Notification Deep Linking with UUID', () async {
      const targetGoalUuid = '33333333-3333-3333-3333-333333333333';

      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/saving-reminders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': {
                'id': 1,
                'user_id': 'user-uuid',
                'goal_id': targetGoalUuid,
                'amount': 250000,
                'frequency': 'monthly',
                'day_of_month': 15,
                'hour': 20,
                'minute': 0,
                'enabled': true,
              },
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/saving-reminders') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['goal_id'], equals(targetGoalUuid));
          expect(body['amount'], equals(300000));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Konfigurasi pengingat menabung berhasil disimpan',
              'data': {
                'id': 1,
                'user_id': 'user-uuid',
                'goal_id': targetGoalUuid,
                'amount': body['amount'],
                'frequency': body['frequency'],
                'day_of_month': body['day_of_month'],
                'hour': body['hour'],
                'minute': body['minute'],
                'enabled': body['enabled'],
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteNotificationRepository(client: client, tokens: tokenStore);

      // Get Reminder
      final reminder = await repo.getSavingReminder();
      expect(reminder.goalId, equals(targetGoalUuid));
      expect(reminder.amount, equals(250000.0));
      expect(reminder.frequency, equals(SavingFrequency.monthly));

      // Save Reminder with UUID goal_id
      final saved = await repo.saveSavingReminder(
        reminder.copyWith(amount: 300000.0),
      );
      expect(saved.goalId, equals(targetGoalUuid));
      expect(saved.amount, equals(300000.0));

      // Verify Deep Link Resolver with UUID
      final resolvedRoute = NotificationDeepLink.resolve(
        type: 'savingsGoal',
        entityId: targetGoalUuid,
      );
      expect(resolvedRoute, equals('${AppRoutes.goals}/$targetGoalUuid'));
      expect(NotificationDeepLink.isAllowedRoute(resolvedRoute), isTrue);

      // Verify Deep Link with invalid entityId falls back safely to /goals
      final fallbackRoute = NotificationDeepLink.resolve(
        type: 'savingsGoal',
        entityId: 'invalid!entity!id',
      );
      expect(fallbackRoute, equals(AppRoutes.goals));
    });
  });
}
