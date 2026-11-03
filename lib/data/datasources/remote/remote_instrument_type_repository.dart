import '../../../data/models/api_financial_instrument.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [InstrumentTypeRepository] di atas Laravel API
/// (`/api/instrument-types`).
///
/// Hanya read-only: data master dikelola admin melalui website.
class RemoteInstrumentTypeRepository implements InstrumentTypeRepository {
  RemoteInstrumentTypeRepository({
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
  Future<List<ApiInstrumentType>> getInstrumentTypes() async {
    final token = await _requireToken();
    final body = await _client.get('/instrument-types', token: token);
    final data = body['data'] as List? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => ApiInstrumentType.fromJson(e))
        .toList();
  }
}
