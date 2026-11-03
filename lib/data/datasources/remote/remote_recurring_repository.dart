import '../../../data/models/api_recurring_transaction.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi transaksi berulang di atas Laravel API
/// (`/api/recurring-incomes` dan `/api/recurring-expenses`).
class RemoteRecurringRepository implements RecurringRepository {
  RemoteRecurringRepository({
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
  Future<List<ApiRecurringTransaction>> getRecurringIncomes() async {
    final token = await _requireToken();
    final body = await _client.get('/recurring-incomes', token: token);
    final resp = ApiRecurringTransactionsResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<List<ApiRecurringTransaction>> getRecurringExpenses() async {
    final token = await _requireToken();
    final body = await _client.get('/recurring-expenses', token: token);
    final resp = ApiRecurringTransactionsResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<ApiRecurringTransaction> addRecurringIncome({
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    required int instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/recurring-incomes',
      {
        'title': title,
        'category': category,
        'amount': amount.round(),
        'frequency': frequency,
        'next_due_date': nextDueDate,
        'instrument_id': instrumentId,
        'is_active': isActive,
        'make_automatic': makeAutomatic,
      },
      token: token,
    );
    final resp = ApiRecurringTransactionResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<ApiRecurringTransaction> addRecurringExpense({
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    int? instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/recurring-expenses',
      {
        'title': title,
        'category': category,
        'amount': amount.round(),
        'frequency': frequency,
        'next_due_date': nextDueDate,
        if (instrumentId != null) ...{'instrument_id': instrumentId},
        'is_active': isActive,
        'make_automatic': makeAutomatic,
      },
      token: token,
    );
    final resp = ApiRecurringTransactionResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<ApiRecurringTransaction> updateRecurringIncome({
    required String id,
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    int? instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/recurring-incomes/$id',
      {
        'title': title,
        'category': category,
        'amount': amount.round(),
        'frequency': frequency,
        'next_due_date': nextDueDate,
        if (instrumentId != null) ...{'instrument_id': instrumentId},
        'is_active': isActive,
        'make_automatic': makeAutomatic,
      },
      token: token,
    );
    final resp = ApiRecurringTransactionResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<ApiRecurringTransaction> updateRecurringExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    required String frequency,
    required String nextDueDate,
    int? instrumentId,
    bool isActive = true,
    bool makeAutomatic = false,
  }) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/recurring-expenses/$id',
      {
        'title': title,
        'category': category,
        'amount': amount.round(),
        'frequency': frequency,
        'next_due_date': nextDueDate,
        if (instrumentId != null) ...{'instrument_id': instrumentId},
        'is_active': isActive,
        'make_automatic': makeAutomatic,
      },
      token: token,
    );
    final resp = ApiRecurringTransactionResponse.fromJson(body);
    return resp.data;
  }

  @override
  Future<void> removeRecurringIncome(String id) async {
    final token = await _requireToken();
    await _client.delete('/recurring-incomes/$id', token: token);
  }

  @override
  Future<void> removeRecurringExpense(String id) async {
    final token = await _requireToken();
    await _client.delete('/recurring-expenses/$id', token: token);
  }
}
