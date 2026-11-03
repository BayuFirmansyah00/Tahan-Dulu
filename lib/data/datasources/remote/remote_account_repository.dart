import '../../../data/models/api_financial_instrument.dart';
import '../../../data/models/financial_account.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [AccountRepository] di atas Laravel API
/// (`/api/financial-instrumen`).
///
/// Instrument keuangan Laravel dipetakan ke [FinancialAccount] Flutter:
/// - `id`, `name`, `balance` → langsung
/// - `type` (object dari instrument_types) → [AccountType] via [mapAccountType]
/// - `is_active` → tidak ada padanan di FinancialAccount, diabaikan pada UI
class RemoteAccountRepository implements AccountRepository {
  RemoteAccountRepository({
    required this._client,
    required this._tokens,
    this.onUnauthorized,
  });

  final ApiClient _client;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;

  static AccountType mapAccountType(String? type) {
    switch (type?.toLowerCase()) {
      case 'bank':
        return AccountType.bank;
      case 'digitalbank':
      case 'digital bank':
        return AccountType.digitalBank;
      case 'ewallet':
      case 'e-wallet':
      case 'e wallet':
        return AccountType.ewallet;
      default:
        return AccountType.bank;
    }
  }

  /// Map AccountType ke type_id (instrument_types.id) untuk dikirim ke backend.
  ///
  /// Catatan: ID ini harus sinkron dengan data instrument_types di Laravel.
  /// Nilai default: 1 (Bank), 2 (Digital Bank), 3 (E-Wallet).
  static int? mapTypeId(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 1;
      case AccountType.digitalBank:
        return 2;
      case AccountType.ewallet:
        return 3;
    }
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
  Future<List<FinancialAccount>> getAccounts() async {
    final token = await _requireToken();
    final body = await _client.get('/financial-instruments', token: token);
    final resp = ApiFinancialInstrumentsResponse.fromJson(body);
    return resp.data
        .map((e) => FinancialAccount(
              id: e.id.toString(),
              name: e.name,
              type: mapAccountType(e.type?.type),
              typeId: e.type?.id,
              balance: e.balance.toDouble(),
              institutionName: e.type?.name,
              bankId: e.bank?.id,
              bankSlug: e.bank?.slug,
              bankName: e.bank?.name,
              bankLogoUrl: e.bank?.logoUrl,
            ))
        .toList();
  }

  @override
  Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    return accounts.fold<double>(0, (sum, a) => sum + a.balance);
  }

  @override
  Future<FinancialAccount> addAccount(FinancialAccount account) async {
    final token = await _requireToken();
    final body = await _client.post(
      '/financial-instruments',
      {
        'name': account.name,
        'type_id': account.typeId ?? mapTypeId(account.type),
        'balance': account.balance.round(),
        'is_active': true,
        if (account.bankId != null) 'bank_id': account.bankId,
        if (account.bankSlug != null) 'bank_slug': account.bankSlug,
      },
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    return FinancialAccount(
      id: resp.id.toString(),
      name: resp.name,
      type: mapAccountType(resp.type?.type),
      typeId: resp.type?.id,
      balance: resp.balance.toDouble(),
      institutionName: resp.type?.name,
      bankId: resp.bank?.id ?? account.bankId,
      bankSlug: resp.bank?.slug ?? account.bankSlug,
      bankName: resp.bank?.name ?? account.bankName,
      bankLogoUrl: resp.bank?.logoUrl ?? account.bankLogoUrl,
    );
  }

  @override
  Future<FinancialAccount> updateAccount(FinancialAccount account) async {
    final token = await _requireToken();
    final body = await _client.put(
      '/financial-instruments/${account.id}',
      {
        'name': account.name,
        'type_id': account.typeId ?? mapTypeId(account.type),
        'balance': account.balance.round(),
        'is_active': true,
        'bank_id': account.bankId,
        'bank_slug': account.bankSlug,
      },
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    return FinancialAccount(
      id: resp.id.toString(),
      name: resp.name,
      type: mapAccountType(resp.type?.type),
      typeId: resp.type?.id,
      balance: resp.balance.toDouble(),
      institutionName: resp.type?.name,
      bankId: resp.bank?.id,
      bankSlug: resp.bank?.slug,
      bankName: resp.bank?.name,
      bankLogoUrl: resp.bank?.logoUrl,
    );
  }

  @override
  Future<void> removeAccount(String id) async {
    final token = await _requireToken();
    await _client.delete('/financial-instruments/$id', token: token);
  }

  @override
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {
    final token = await _requireToken();
    await _client.post(
      '/transfers',
      {
        'from_id': int.tryParse(fromId) ?? fromId,
        'to_id': int.tryParse(toId) ?? toId,
        'amount': amount.round(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
          'idempotency_key': idempotencyKey.trim(),
      },
      token: token,
    );
  }
}
