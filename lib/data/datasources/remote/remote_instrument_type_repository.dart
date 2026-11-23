import '../../../data/models/api_financial_instrument.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'api_config.dart';
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

  static const List<ApiInstrumentType> defaultTypes = [
    ApiInstrumentType(id: 'bank', name: 'Bank', type: 'bank'),
    ApiInstrumentType(id: 'digitalBank', name: 'Bank Digital', type: 'digitalBank'),
    ApiInstrumentType(id: 'ewallet', name: 'E-Wallet', type: 'ewallet'),
    ApiInstrumentType(id: 'cash', name: 'Uang Tunai', type: 'cash'),
  ];

  @override
  Future<List<ApiInstrumentType>> getInstrumentTypes() async {
    try {
      final token = await _requireToken();
      final body = await _client.get('/instrument-types', token: token);
      final data = body['data'] as List? ?? const [];
      final list = data
          .cast<Map<String, dynamic>>()
          .map((e) => ApiInstrumentType.fromJson(e))
          .toList();
      if (list.isNotEmpty) return list;
      if (ApiConfig.useRemoteApi) {
        throw ApiException('Master tipe instrumen kosong dari server.', statusCode: 500);
      }
      return defaultTypes;
    } catch (e) {
      if (ApiConfig.useRemoteApi) {
        rethrow;
      }
      return defaultTypes;
    }
  }
}
