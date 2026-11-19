import 'dart:async';

import '../../models/api_financial_report.dart';
import '../../repositories/report_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi remote [ReportRepository] yang memanggil endpoint Laravel:
/// - GET /api/reports/financial
/// - GET /api/reports/financial/export
class RemoteReportRepository implements ReportRepository {
  RemoteReportRepository({
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
        'Token autentikasi tidak tersedia. Silakan login kembali.',
        statusCode: 401,
      );
    }
    return token;
  }

  @override
  Future<ApiFinancialReport> getFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    final token = await _requireToken();
    final params = <String, String>{'period': period};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }

    final query = Uri(queryParameters: params).query;
    final path = '/reports/financial?$query';

    final body = await client.get(path, token: token);
    final data = body['data'] as Map<String, dynamic>? ?? {};
    return ApiFinancialReport.fromJson(data);
  }

  @override
  Future<List<int>> exportFinancialReport({
    String period = 'this_month',
    String? startDate,
    String? endDate,
  }) async {
    final token = await _requireToken();
    final params = <String, String>{'period': period};
    if (startDate != null && startDate.isNotEmpty) {
      params['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      params['end_date'] = endDate;
    }

    final query = Uri(queryParameters: params).query;
    final path = '/reports/financial/export?$query';

    return await client.getBytes(path, token: token);
  }
}
