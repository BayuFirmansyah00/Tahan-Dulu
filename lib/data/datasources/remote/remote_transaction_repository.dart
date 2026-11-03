import '../../../data/models/api_transaction.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [TransactionRepository] di atas Laravel API
/// (`/api/transactions`).
class RemoteTransactionRepository implements TransactionRepository {
  RemoteTransactionRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

  static TransactionType _toTransactionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
      default:
        return TransactionType.expense;
    }
  }

  static AppTransaction _toAppTransaction(ApiTransaction api) {
    return AppTransaction(
      id: api.id.toString(),
      title: api.title,
      amount: api.amount.toDouble(),
      type: _toTransactionType(api.type),
      date: api.parsedCreatedAt ?? DateTime.now(),
      category: api.category,
      accountId: api.instrument?.id.toString(),
      note: api.information,
      fee: 0,
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
  Future<List<AppTransaction>> getRecentTransactions() async {
    final token = await _requireToken();
    final body = await _client.get('/transactions', token: token);
    final resp = ApiTransactionsResponse.fromJson(body);
    return resp.data.map(_toAppTransaction).toList();
  }

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/transactions',
      {
        'title': transaction.title,
        'type': transaction.type == TransactionType.income ? 'income' : 'expense',
        'category': transaction.category ?? '',
        'amount': transaction.amount.round(),
        'instrument_id': int.tryParse(transaction.accountId ?? ''),
        'information': transaction.note,
      },
      token: token,
    );
    final resp = ApiTransactionResponse.fromJson(body);
    return _toAppTransaction(resp.data);
  }

  @override
  Future<AppTransaction> getTransactionById(String id) async {
    final token = await _requireToken();
    final body = await _client.get('/transactions/$id', token: token);
    final resp = ApiTransactionResponse.fromJson(body);
    return _toAppTransaction(resp.data);
  }

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    int? instrumentId,
    int? perPage,
  }) async {
    final token = await _requireToken();
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (category != null) query['category'] = category;
    if (instrumentId != null) query['instrument_id'] = instrumentId.toString();
    if (perPage != null) query['per_page'] = perPage.toString();

    final path = query.isNotEmpty
        ? '/transactions?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '/transactions';
    final body = await _client.get(path, token: token);
    final resp = ApiTransactionsResponse.fromJson(body);
    return resp.data.map(_toAppTransaction).toList();
  }

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/transactions/${transaction.id}',
      {
        'title': transaction.title,
        'type': transaction.type == TransactionType.income ? 'income' : 'expense',
        'category': transaction.category ?? '',
        'amount': transaction.amount.round(),
        'instrument_id': int.tryParse(transaction.accountId ?? ''),
        'information': transaction.note,
      },
      token: token,
    );
    final resp = ApiTransactionResponse.fromJson(body);
    return _toAppTransaction(resp.data);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final token = await _requireToken();
    await _client.delete('/transactions/$id', token: token);
  }
}
