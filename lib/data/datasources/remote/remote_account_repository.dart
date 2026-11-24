import '../../../data/models/api_financial_instrument.dart';
import '../../../data/models/financial_account.dart';
import '../../../data/models/transfer_model.dart';
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

  static AccountType mapAccountType(String? type, [String? name, String? bankSlug]) {
    final t = type?.toLowerCase().trim();
    final n = name?.toLowerCase().trim() ?? '';
    final s = bankSlug?.toLowerCase().trim() ?? '';

    if (t == 'cash' ||
        t == 'uang tunai' ||
        t == 'tunai' ||
        const ['cash', 'uang tunai', 'tunai', 'uang kas', 'kas', 'petty cash'].contains(n) ||
        const ['cash', 'uang-tunai', 'tunai'].contains(s)) {
      return AccountType.legacyCash;
    }

    switch (t) {
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

  /// Map AccountType ke type_id fallback ('bank', 'digitalBank', 'ewallet') untuk dikirim ke backend.
  static String? mapTypeId(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'bank';
      case AccountType.digitalBank:
        return 'digitalBank';
      case AccountType.ewallet:
        return 'ewallet';
      case AccountType.legacyCash:
        return 'cash';
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
              type: mapAccountType(e.type?.type, e.name, e.bank?.slug),
              typeId: e.type?.id,
              balance: e.balance.toDouble(),
              institutionName: e.type?.name,
              bankId: e.bank?.id,
              bankSlug: e.bank?.slug,
              bankName: e.bank?.name,
              bankLogoUrl: e.bank?.logoUrl,
              monthlyAdminFee: e.monthlyAdminFee.toDouble(),
              adminFeeDay: e.adminFeeDay,
              adminFeeEnabled: e.adminFeeEnabled,
              isActive: e.isActive,
              maxBudget: e.maxBudget?.toDouble(),
              budgetFrequency: e.budgetFrequency,
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
        'monthly_admin_fee': account.adminFeeEnabled
            ? account.monthlyAdminFee.round()
            : 0,
        'admin_fee_day':
            account.adminFeeEnabled ? account.adminFeeDay : null,
        'admin_fee_enabled': account.adminFeeEnabled,
        'is_active': account.isActive,
        if (account.maxBudget != null) 'max_budget': account.maxBudget!.round(),
        if (account.budgetFrequency != null) 'budget_frequency': account.budgetFrequency,
        if (account.bankId != null) 'bank_id': account.bankId,
        if (account.bankSlug != null) 'bank_slug': account.bankSlug,
        if (account.idempotencyKey != null)
          'idempotency_key': account.idempotencyKey,
      },
      token: token,
    );
    final resp =
        ApiFinancialInstrument.fromJson(body['data'] as Map<String, dynamic>);
    return FinancialAccount(
      id: resp.id.toString(),
      name: resp.name,
      type: mapAccountType(resp.type?.type, resp.name, resp.bank?.slug),
      typeId: resp.type?.id,
      balance: resp.balance.toDouble(),
      institutionName: resp.type?.name,
      bankId: resp.bank?.id ?? account.bankId,
      bankSlug: resp.bank?.slug ?? account.bankSlug,
      bankName: resp.bank?.name ?? account.bankName,
      bankLogoUrl: resp.bank?.logoUrl ?? account.bankLogoUrl,
      monthlyAdminFee: resp.monthlyAdminFee.toDouble(),
      adminFeeDay: resp.adminFeeDay ?? account.adminFeeDay,
      adminFeeEnabled: resp.adminFeeEnabled,
      isActive: resp.isActive,
      maxBudget: resp.maxBudget?.toDouble(),
      budgetFrequency: resp.budgetFrequency,
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
        'monthly_admin_fee': account.adminFeeEnabled
            ? account.monthlyAdminFee.round()
            : 0,
        'admin_fee_day':
            account.adminFeeEnabled ? account.adminFeeDay : null,
        'admin_fee_enabled': account.adminFeeEnabled,
        'is_active': account.isActive,
        if (account.maxBudget != null) 'max_budget': account.maxBudget!.round(),
        if (account.budgetFrequency != null) 'budget_frequency': account.budgetFrequency,
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
      type: mapAccountType(resp.type?.type, resp.name, resp.bank?.slug),
      typeId: resp.type?.id,
      balance: resp.balance.toDouble(),
      institutionName: resp.type?.name,
      bankId: resp.bank?.id,
      bankSlug: resp.bank?.slug,
      bankName: resp.bank?.name,
      bankLogoUrl: resp.bank?.logoUrl,
      monthlyAdminFee: resp.monthlyAdminFee.toDouble(),
      adminFeeDay: resp.adminFeeDay ?? account.adminFeeDay,
      adminFeeEnabled: resp.adminFeeEnabled,
      isActive: resp.isActive,
      maxBudget: resp.maxBudget?.toDouble(),
      budgetFrequency: resp.budgetFrequency,
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

  @override
  Future<void> reconcileLegacyCash({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {
    final token = await _requireToken();
    await _client.post(
      '/transfers/reconcile-legacy-cash',
      {
        'from_id': int.tryParse(fromId) ?? fromId,
        'to_id': int.tryParse(toId) ?? toId,
        'amount': amount.round(),
        'confirmed': true,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
          'idempotency_key': idempotencyKey.trim(),
      },
      token: token,
    );
  }

  @override
  Future<List<TransferItem>> getTransfers() async {
    final token = await _requireToken();
    final res = await _client.get('/transfers', token: token);
    final data = res['data'];
    if (data is List) {
      return data
          .map((e) => TransferItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    final token = await _requireToken();
    await _client.delete('/transfers/$transferId', token: token);
  }
}
