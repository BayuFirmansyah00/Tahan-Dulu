import '../../models/financial_settings.dart';
import '../../repositories/financial_settings_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

class RemoteFinancialSettingsRepository implements FinancialSettingsRepository {
  RemoteFinancialSettingsRepository({
    required this.client,
    required this.tokens,
  });

  final ApiClient client;
  final TokenStore tokens;

  Future<String> _requireToken() async {
    final token = await tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  @override
  Future<FinancialSettings> getSettings() async {
    final token = await _requireToken();
    final body = await client.get('/financial-settings', token: token);
    final data = body['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw ApiException('Data pengaturan keuangan tidak ditemukan pada respons server.');
    }
    return FinancialSettings.fromJson(data);
  }

  @override
  Future<FinancialTransitionInfo> getPreview({
    required int monthlyIncome,
    required int salaryDay,
  }) async {
    final token = await _requireToken();
    final body = await client.post(
      '/financial-settings/preview',
      {
        'monthly_income': monthlyIncome,
        'salary_day': salaryDay,
      },
      token: token,
    );
    final data = body['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw ApiException('Data simulasi tidak valid dari server.');
    }
    return FinancialTransitionInfo.fromJson(data);
  }

  @override
  Future<FinancialSettings> updateSettings({
    required int monthlyIncome,
    required int salaryDay,
    List<Map<String, dynamic>>? allocations,
    int? transitionBudget,
    bool transitionConfirmed = false,
  }) async {
    final token = await _requireToken();
    final payload = <String, dynamic>{
      'monthly_income': monthlyIncome,
      'salary_day': salaryDay,
      'transition_confirmed': transitionConfirmed,
    };
    if (allocations != null) {
      payload['allocations'] = allocations;
    }
    if (transitionBudget != null) {
      payload['transition_budget'] = transitionBudget;
    }
    final body = await client.put(
      '/financial-settings',
      payload,
      token: token,
    );
    final data = body['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw ApiException('Gagal memperbarui pengaturan keuangan di server.');
    }
    return FinancialSettings.fromJson(data);
  }

  @override
  Future<FinancialSettings> cancelPending() async {
    final token = await _requireToken();
    final body = await client.post(
      '/financial-settings/cancel-pending',
      {},
      token: token,
    );
    final data = body['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw ApiException('Gagal membatalkan jadwal di server.');
    }
    return FinancialSettings.fromJson(data);
  }
}

