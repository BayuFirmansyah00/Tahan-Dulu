import '../../../data/models/api_investment.dart';
import '../../../data/models/api_investment_transaction.dart';
import '../../../data/models/financial_account.dart';
import '../../../data/models/financial_goal.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi investasi di atas Laravel API (`/api/investments`).
class RemoteInvestmentRepository implements InvestmentRepository {
  RemoteInvestmentRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

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
  Future<List<FinancialAccount>> getInvestments() async {
    final token = await _requireToken();
    final body = await _client.get('/investments', token: token);
    final resp = ApiInvestmentsResponse.fromJson(body);
    return resp.data
        .map((e) => FinancialAccount(
              id: e.id.toString(),
              name: e.title,
              type: AccountType.bank,
              balance: e.achieved.toDouble(),
              institutionName: e.type,
            ))
        .toList();
  }

  @override
  Future<FinancialAccount> addInvestment(FinancialAccount investment) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/investments',
      {
        'title': investment.name,
        'type': investment.institutionName ?? 'Investasi',
        'target': null,
        'increase': null,
        'achieved': investment.balance.round(),
        'is_active': true,
      },
      token: token,
    );
    final resp = ApiInvestmentResponse.fromJson(body);
    return FinancialAccount(
      id: resp.data.id.toString(),
      name: resp.data.title,
      type: AccountType.bank,
      balance: resp.data.achieved.toDouble(),
      institutionName: resp.data.type,
    );
  }

  @override
  Future<FinancialAccount> updateInvestment(FinancialAccount investment) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/investments/${investment.id}',
      {
        'title': investment.name,
        'type': investment.institutionName ?? 'Investasi',
        'target': null,
        'increase': null,
        'achieved': investment.balance.round(),
        'is_active': true,
      },
      token: token,
    );
    final resp = ApiInvestmentResponse.fromJson(body);
    return FinancialAccount(
      id: resp.data.id.toString(),
      name: resp.data.title,
      type: AccountType.bank,
      balance: resp.data.achieved.toDouble(),
      institutionName: resp.data.type,
    );
  }

  @override
  Future<void> removeInvestment(String id) async {
    final token = await _requireToken();
    await _client.delete('/investments/$id', token: token);
  }

  @override
  Future<List<FinancialGoal>> getInvestmentTransactions(
      String investmentId) async {
    final token = await _requireToken();
    final body =
        await _client.get('/investments/$investmentId/transactions', token: token);
    final resp = ApiInvestmentTransactionsResponse.fromJson(body);
    return resp.data
        .map((e) => FinancialGoal(
              id: e.id.toString(),
              name: e.type == 'deposit'
                  ? 'Setoran Investasi'
                  : 'Pencairan Investasi',
              targetAmount: e.amount.toDouble(),
              currentAmount: e.amount.toDouble(),
              category: GoalCategory.investment,
              frequency: DepositFrequency.monthly,
            ))
        .toList();
  }
}
