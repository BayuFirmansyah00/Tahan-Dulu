import '../../../data/models/api_bank.dart';
import '../../../data/repositories/bank_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [BankRepository] di atas Laravel API (`/api/banks`).
class RemoteBankRepository implements BankRepository {
  RemoteBankRepository({
    required this.client,
    required this.tokens,
    this.onUnauthorized,
  });

  final ApiClient client;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  Future<String> _requireToken() async {
    final token = await tokens.readToken();
    if (token == null || token.isEmpty) {
      onUnauthorized?.call();
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  @override
  Future<List<ApiBank>> getBanks({String? search, String? category}) async {
    final token = await _requireToken();
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }

    final queryString = queryParams.isNotEmpty
        ? '?${Uri(queryParameters: queryParams).query}'
        : '';

    final body = await client.get('/banks$queryString', token: token);
    final response = ApiBanksResponse.fromJson(body);
    return response.data;
  }

  @override
  Future<ApiBank> getBank(String idOrSlug) async {
    final token = await _requireToken();
    final body = await client.get('/banks/$idOrSlug', token: token);
    final response = ApiBankResponse.fromJson(body);
    return response.data;
  }
}

