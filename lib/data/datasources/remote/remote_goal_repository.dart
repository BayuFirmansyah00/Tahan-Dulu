import '../../../data/models/api_financial_goal.dart';
import '../../../data/models/api_goal_transaction.dart';
import '../../../data/models/financial_goal.dart';
import '../../../data/models/goal_deposit.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [GoalRepository] di atas Laravel API
/// (`/api/goals` dan `/api/goals/{id}/transactions`).
class RemoteGoalRepository implements GoalRepository {
  RemoteGoalRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

  static GoalCategory _toGoalCategory(String? type) {
    switch (type?.toLowerCase()) {
      case 'emergency':
        return GoalCategory.emergency;
      case 'savings':
        return GoalCategory.savings;
      case 'investment':
        return GoalCategory.investment;
      case 'house':
        return GoalCategory.house;
      case 'vehicle':
        return GoalCategory.vehicle;
      case 'gadget':
        return GoalCategory.gadget;
      case 'holiday':
        return GoalCategory.holiday;
      case 'education':
        return GoalCategory.education;
      default:
        return GoalCategory.others;
    }
  }

  static DepositFrequency _toDepositFrequency(String? frequency) {
    switch (frequency?.toLowerCase()) {
      case 'weekly':
        return DepositFrequency.weekly;
      default:
        return DepositFrequency.monthly;
    }
  }

  static int _toPriority(String? priority) {
    if (priority == null) return 0;
    final parsed = int.tryParse(priority);
    if (parsed != null) return parsed;
    switch (priority.toLowerCase()) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 0;
    }
  }

  static FinancialGoal _toFinancialGoal(ApiFinancialGoal api) {
    return FinancialGoal(
      id: api.id.toString(),
      name: api.title,
      targetAmount: api.targetAmount.toDouble(),
      currentAmount: api.currentAmount.toDouble(),
      deadline: api.parsedTargetDate,
      category: _toGoalCategory(api.type),
      frequency: _toDepositFrequency(api.frequency),
      sourceAccountId: null,
      priority: _toPriority(api.priority),
    );
  }

  static GoalDeposit _toGoalDeposit(ApiGoalTransaction api) {
    return GoalDeposit(
      id: api.id.toString(),
      goalId: api.goalId.toString(),
      amount: api.amount.toDouble(),
      date: api.parsedCreatedAt ?? DateTime.now(),
      accountId: null,
      note: api.notes,
    );
  }

  Future<String> _requireToken() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      onUnauthorized?.call();
      throw ApiException('Token tidak tersedia. Silakan login ulang.',
          statusCode: 401);
    }
    return token;
  }

  @override
  Future<List<FinancialGoal>> getGoals() async {
    final token = await _requireToken();
    final body = await _client.get('/goals', token: token);
    final resp = ApiFinancialGoalsResponse.fromJson(body);
    return resp.data.map(_toFinancialGoal).toList();
  }

  @override
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/goals',
      {
        'title': goal.name,
        'type': goal.category.name,
        'target_amount': goal.targetAmount.round(),
        'current_amount': goal.currentAmount.round(),
        'target_date': goal.deadline?.toIso8601String(),
        'reminder_date': null,
        'frequency':
            goal.frequency == DepositFrequency.weekly ? 'weekly' : 'monthly',
        'priority': goal.priority.toString(),
        'is_active': true,
      },
      token: token,
    );
    final resp = ApiFinancialGoalResponse.fromJson(body);
    return _toFinancialGoal(resp.data);
  }

  @override
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/goals/${goal.id}',
      {
        'title': goal.name,
        'type': goal.category.name,
        'target_amount': goal.targetAmount.round(),
        'current_amount': goal.currentAmount.round(),
        'target_date': goal.deadline?.toIso8601String(),
        'reminder_date': null,
        'frequency':
            goal.frequency == DepositFrequency.weekly ? 'weekly' : 'monthly',
        'priority': goal.priority.toString(),
        'is_active': true,
      },
      token: token,
    );
    final resp = ApiFinancialGoalResponse.fromJson(body);
    return _toFinancialGoal(resp.data);
  }

  @override
  Future<FinancialGoal> getGoalById(String id) async {
    final token = await _requireToken();
    final body = await _client.get('/goals/$id', token: token);
    final resp = ApiFinancialGoalResponse.fromJson(body);
    return _toFinancialGoal(resp.data);
  }

  @override
  Future<void> deleteGoal(String id) async {
    final token = await _requireToken();
    await _client.delete('/goals/$id', token: token);
  }

  @override
  Future<List<GoalDeposit>> getDeposits(String goalId) async {
    final token = await _requireToken();
    final body = await _client.get('/goals/$goalId/transactions', token: token);
    final resp = ApiGoalTransactionsResponse.fromJson(body);
    return resp.data.map(_toGoalDeposit).toList();
  }

  @override
  Future<GoalDeposit> addDeposit(GoalDeposit deposit) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/goals/${deposit.goalId}/transactions',
      {
        'type': 'deposit',
        'amount': deposit.amount.round(),
        'notes': deposit.note,
        'instrument_id': null,
      },
      token: token,
    );
    final resp = ApiGoalTransactionResponse.fromJson(body);
    return _toGoalDeposit(resp.data);
  }

  @override
  Future<GoalDeposit> updateDeposit(GoalDeposit deposit) async {
    final token = await _requireToken();
    final transactionId = int.tryParse(deposit.id);
    if (transactionId == null) throw StateError('ID setoran tidak valid');

    final body = await _client.put(
      '/goals/${deposit.goalId}/transactions/$transactionId',
      {
        'type': 'deposit',
        'amount': deposit.amount.round(),
        'notes': deposit.note,
        'instrument_id': null,
      },
      token: token,
    );
    final resp = ApiGoalTransactionResponse.fromJson(body);
    return _toGoalDeposit(resp.data);
  }

  @override
  Future<void> deleteDeposit(String id) async {
    final token = await _requireToken();
    final goals = await getGoals();
    for (final goal in goals) {
      final deposits = await getDeposits(goal.id);
      final match = deposits.firstWhere(
        (e) => e.id == id,
        orElse: () => throw StateError('Setoran tidak ditemukan'),
      );
      if (match.id == id) {
        final transactionId = int.tryParse(id);
        if (transactionId != null) {
          await _client.delete(
              '/goals/${goal.id}/transactions/$transactionId',
              token: token);
        }
        return;
      }
    }
  }

  @override
  Future<void> saveGoalOrder(List<String> orderedIds) async {
    final token = await _requireToken();
    final ids = orderedIds.map((id) => int.tryParse(id) ?? id).toList();
    await _client.post(
      '/goals/reorder',
      {
        'ordered_ids': ids,
      },
      token: token,
    );
  }
}
