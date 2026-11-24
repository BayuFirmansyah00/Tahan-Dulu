import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(baseUrl: 'http://localhost');

  Map<String, dynamic>? lastPostedPayload;
  Map<String, dynamic>? lastPutPayload;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    final cleanPath = path.replaceFirst('/api', '');
    if (cleanPath.contains('/financial-instruments') || cleanPath.contains('/financial-instrumens')) {
      return {
        'success': true,
        'data': [
          {
            'id': 'acc-123',
            'name': 'Rekening BCA Operasional',
            'balance': 15000000.0,
            'initial_balance': 10000000.0,
            'is_active': false,
            'max_budget': 5000000,
            'max_budget_formatted': 'Rp 5.000.000',
            'budget_frequency': 'monthly',
            'monthly_admin_fee': 15000.0,
            'admin_fee_day': 10,
            'admin_fee_enabled': true,
            'type_name': 'Bank',
            'bank_slug': 'bca',
          }
        ]
      };
    }
    if (cleanPath.contains('/goals')) {
      return {
        'success': true,
        'data': [
          {
            'id': 'goal-456',
            'title': 'Beli Laptop Baru',
            'type': 'gadget',
            'product_link': 'https://example.com/laptop-pro',
            'link': 'https://example.com/laptop-pro',
            'note': 'Wajib RAM 32GB untuk development',
            'target_amount': 25000000,
            'target_amount_formatted': 'Rp 25.000.000',
            'current_amount': 5000000,
            'current_amount_formatted': 'Rp 5.000.000',
            'progress_percentage': 20.0,
            'recurring_amount': 2000000,
            'frequency': 'monthly',
            'source_account_id': 'acc-123',
            'is_active': true,
            'target_date': '2027-12-31 00:00:00',
            'reminder_date': '2027-01-01 09:00:00',
            'priority': '1',
          }
        ]
      };
    }
    return {'success': true, 'data': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
    String? idempotencyKey,
  }) async {
    lastPostedPayload = payload;
    return {
      'success': true,
      'data': {
        'id': 'new-id-999',
        ...payload,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    lastPutPayload = payload;
    return {
      'success': true,
      'data': {
        'id': 'updated-id-999',
        ...payload,
      }
    };
  }
}

void main() {
  group('F18 Advanced Financial Account & Goal Fields Parity Test', () {
    late _MockApiClient mockClient;
    late MemoryTokenStore tokenStore;
    late RemoteAccountRepository accountRepo;
    late RemoteGoalRepository goalRepo;

    setUp(() async {
      mockClient = _MockApiClient();
      tokenStore = MemoryTokenStore();
      await tokenStore.saveToken('test-token-123');
      accountRepo = RemoteAccountRepository(client: mockClient, tokens: tokenStore);
      goalRepo = RemoteGoalRepository(client: mockClient, tokens: tokenStore);
    });

    test('Financial account deserializes isActive, maxBudget, and budgetFrequency', () async {
      final accounts = await accountRepo.getAccounts();
      expect(accounts.length, 1);
      final acc = accounts.first;
      expect(acc.id, 'acc-123');
      expect(acc.name, 'Rekening BCA Operasional');
      expect(acc.balance, 15000000.0);
      expect(acc.isActive, false, reason: 'Deactivated account should preserve isActive=false');
      expect(acc.maxBudget, 5000000);
      expect(acc.budgetFrequency, 'monthly');
    });

    test('Financial account update preserves and sends isActive, maxBudget, budgetFrequency', () async {
      final updated = FinancialAccount(
        id: 'acc-123',
        name: 'Rekening BCA Operasional',
        type: AccountType.bank,
        balance: 15000000.0,
        isActive: false,
        maxBudget: 7500000,
        budgetFrequency: 'weekly',
        adminFeeEnabled: true,
        monthlyAdminFee: 15000,
        adminFeeDay: 10,
      );

      await accountRepo.updateAccount(updated);

      expect(mockClient.lastPutPayload, isNotNull);
      expect(mockClient.lastPutPayload!['is_active'], false);
      expect(mockClient.lastPutPayload!['max_budget'], 7500000);
      expect(mockClient.lastPutPayload!['budget_frequency'], 'weekly');
    });

    test('Financial goal deserializes productLink, note, reminderDate, isActive, sourceAccountId', () async {
      final goals = await goalRepo.getGoals();
      expect(goals.length, 1);
      final goal = goals.first;
      expect(goal.id, 'goal-456');
      expect(goal.name, 'Beli Laptop Baru');
      expect(goal.productLink, 'https://example.com/laptop-pro');
      expect(goal.note, 'Wajib RAM 32GB untuk development');
      expect(goal.sourceAccountId, 'acc-123');
      expect(goal.isActive, true);
      expect(goal.recurringAmount, 2000000);
      expect(goal.frequency, DepositFrequency.monthly);
      expect(goal.reminderDate, isNotNull);
      expect(goal.reminderDate!.year, 2027);
    });

    test('Financial goal update sends product_link, note, source_account_id without wiping current_amount', () async {
      final existingGoal = FinancialGoal(
        id: 'goal-456',
        name: 'Beli Laptop Baru Pro',
        targetAmount: 30000000,
        currentAmount: 5000000,
        category: GoalCategory.gadget,
        productLink: 'https://example.com/laptop-pro-m3',
        note: 'Update link referensi',
        sourceAccountId: 'acc-123',
        recurringAmount: 2500000,
        frequency: DepositFrequency.monthly,
      );

      await goalRepo.updateGoal(existingGoal);

      expect(mockClient.lastPutPayload, isNotNull);
      expect(mockClient.lastPutPayload!['product_link'], 'https://example.com/laptop-pro-m3');
      expect(mockClient.lastPutPayload!['note'], 'Update link referensi');
      expect(mockClient.lastPutPayload!['source_account_id'], 'acc-123');
      expect(mockClient.lastPutPayload!['target_amount'], 30000000);
      // current_amount must never be sent in update payload to prevent wiping balance
      expect(mockClient.lastPutPayload!.containsKey('current_amount'), false);
    });
  });
}
