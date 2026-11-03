import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';

void main() {
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tokenStore = MemoryTokenStore();
    await tokenStore.saveToken('valid-test-token');
  });

  test('RemoteGoalRepository getGoals maps priority correctly', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/goals');
      expect(request.headers['Authorization'], 'Bearer valid-test-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'OK',
          'data': [
            {
              'id': 1,
              'title': 'Emergency Fund',
              'type': 'emergency',
              'target_amount': 10000000,
              'current_amount': 2000000,
              'progress_percentage': 20,
              'priority': '0',
              'frequency': 'monthly',
              'is_active': true,
            },
            {
              'id': 2,
              'title': 'House Down Payment',
              'type': 'house',
              'target_amount': 50000000,
              'current_amount': 10000000,
              'progress_percentage': 20,
              'priority': 'high',
              'frequency': 'monthly',
              'is_active': true,
            },
          ],
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    final goals = await repo.getGoals();
    expect(goals.length, 2);
    expect(goals[0].name, 'Emergency Fund');
    expect(goals[0].priority, 0);
    expect(goals[1].name, 'House Down Payment');
    expect(goals[1].priority, 0);
  });

  test('RemoteGoalRepository addGoal sends priority and fields', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/goals');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['title'], 'Beli Gadget');
      expect(body['priority'], '2');
      expect(body['target_amount'], 15000000);

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Created',
          'data': {
            'id': 10,
            'title': 'Beli Gadget',
            'type': 'gadget',
            'target_amount': 15000000,
            'current_amount': 0,
            'progress_percentage': 0,
            'priority': '2',
            'frequency': 'monthly',
            'is_active': true,
          },
        }),
        201,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    const goal = FinancialGoal(
      id: 'g-temp',
      name: 'Beli Gadget',
      targetAmount: 15000000,
      currentAmount: 0,
      category: GoalCategory.gadget,
      priority: 2,
    );

    final saved = await repo.addGoal(goal);
    expect(saved.id, '10');
    expect(saved.name, 'Beli Gadget');
    expect(saved.priority, 2);
  });

  test('RemoteGoalRepository saveGoalOrder calls /goals/reorder', () async {
    bool reorderCalled = false;
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/goals/reorder');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['ordered_ids'], [5, 2, 8]);
      reorderCalled = true;

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Urutan berhasil diperbarui',
          'data': [],
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    await repo.saveGoalOrder(['5', '2', '8']);
    expect(reorderCalled, isTrue);
  });

  test('RemoteGoalRepository deleteGoal calls DELETE /goals/{id}', () async {
    bool deleteCalled = false;
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/goals/42');
      expect(request.method, 'DELETE');
      deleteCalled = true;

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Deleted',
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    await repo.deleteGoal('42');
    expect(deleteCalled, isTrue);
  });

  test('RemoteGoalRepository addDeposit posts transaction', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/goals/7/transactions');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['amount'], 500000);
      expect(body['type'], 'deposit');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Deposit recorded',
          'data': {
            'id': 101,
            'goal_id': 7,
            'type': 'deposit',
            'amount': 500000,
            'created_at': '2026-10-29T10:00:00Z',
          },
        }),
        201,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    final deposit = await repo.addDeposit(
      GoalDeposit(
        id: 'temp',
        goalId: '7',
        amount: 500000,
        date: DateTime.now(),
      ),
    );

    expect(deposit.id, '101');
    expect(deposit.amount, 500000);
  });

  test('RemoteGoalRepository throws ApiException on 422', () async {
    final mockHttp = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'message': 'Validation failed',
          'errors': {
            'target_amount': ['Target nominal harus lebih dari 0.'],
          },
        }),
        422,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemoteGoalRepository(client: client, tokens: tokenStore);

    expect(
      () => repo.addGoal(const FinancialGoal(
        id: '1',
        name: 'Invalid Goal',
        targetAmount: 0,
        currentAmount: 0,
      )),
      throwsA(isA<ApiException>()),
    );
  });
}
