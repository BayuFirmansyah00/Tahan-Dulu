import '../../models/api_monthly_budget.dart';
import '../../repositories/budget_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

class RemoteBudgetRepository implements BudgetRepository {
  const RemoteBudgetRepository(this._client, this._tokens);

  final ApiClient _client;
  final TokenStore _tokens;

  Future<String> _requireToken() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Token tidak tersedia. Silakan login ulang.', statusCode: 401);
    }
    return token;
  }

  @override
  Future<ApiMonthlyBudget?> getCurrentBudget() async {
    final token = await _requireToken();
    final body = await _client.get('/budget/current', token: token);
    final data = body['data'];
    if (data == null || data is! Map<String, dynamic>) {
      return null;
    }
    return ApiMonthlyBudget.fromJson(data);
  }

  @override
  Future<ApiMonthlyBudget> storeBudget({
    required int monthlyIncome,
    required List<Map<String, dynamic>> allocations,
  }) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/budget',
      {
        'monthly_income': monthlyIncome,
        'allocations': allocations,
      },
      token: token,
    );
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons server tidak lengkap.');
    }
    return ApiMonthlyBudget.fromJson(data);
  }
}
