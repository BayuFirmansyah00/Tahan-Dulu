import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_dashboard_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';

class MockTokenStore implements TokenStore {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'fake-jwt-token';

  @override
  Future<void> saveToken(String token) async {}
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'https://test.example.com');

  bool failSummary = false;
  bool failGeneric = false;
  int getCalls = 0;
  final List<String> calledPaths = [];

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    getCalls++;
    calledPaths.add(path);

    if (path == '/dashboard/summary') {
      if (failSummary) {
        throw ApiException('Server error 500', statusCode: 500);
      }
      if (failGeneric) {
        throw StateError('Generic socket failure');
      }
      return {
        'success': true,
        'message': 'OK',
        'data': {
          'overview': {
            'total_investment_value': 5000000,
          },
          'monthly_cashflow': {
            'income': 15000000,
            'expense': 6500000,
            'cash_flow': 8500000,
          },
        },
      };
    }

    if (path == '/goals') {
      return {
        'success': true,
        'message': 'OK',
        'data': [],
      };
    }

    if (path == '/transactions') {
      return {
        'success': true,
        'message': 'OK',
        'data': [],
      };
    }

    return {'success': true, 'data': {}};
  }
}

void main() {
  group('F06C — Authoritative Dashboard & Safe Fallback', () {
    late FakeApiClient client;
    late MockTokenStore tokens;
    late RemoteDashboardRepository repository;

    setUp(() {
      client = FakeApiClient();
      tokens = MockTokenStore();
      repository = RemoteDashboardRepository(
        client: client,
        tokens: tokens,
      );
    });

    test('getSummary returns authoritative figures from /dashboard/summary on success', () async {
      final summary = await repository.getSummary();

      expect(summary.income, 15000000.0);
      expect(summary.expense, 6500000.0);
      expect(summary.saving, 8500000.0);
      expect(summary.investment, 5000000.0);
      expect(summary.isStale, isFalse);
      expect(client.calledPaths, contains('/dashboard/summary'));
      expect(client.calledPaths, isNot(contains('/transactions')));
    });

    test('getSummary returns cached summary marked as stale when /dashboard/summary fails after initial success', () async {
      // 1. Initial success caches data
      final initial = await repository.getSummary();
      expect(initial.isStale, isFalse);

      // 2. Server failure happens
      client.failSummary = true;
      final fallback = await repository.getSummary();

      // Menghasilkan cache bertanda isStale = true
      expect(fallback.isStale, isTrue);
      expect(fallback.income, 15000000.0);
      expect(fallback.expense, 6500000.0);
      expect(fallback.saving, 8500000.0);
      // Memastikan TIDAK memanggil /transactions untuk menghitung parsial diam-diam!
      expect(client.calledPaths.where((p) => p == '/transactions'), isEmpty);
    });

    test('getSummary throws explicit ApiException when no cached data exists and server fails', () async {
      client.failSummary = true;

      expect(
        () => repository.getSummary(),
        throwsA(isA<ApiException>()),
      );

      // Memastikan TIDAK memanggil /transactions untuk fallback diam-diam
      expect(client.calledPaths.where((p) => p == '/transactions'), isEmpty);
    });

    test('getSummary wraps generic exceptions in explicit authoritative ApiException when no cache exists', () async {
      client.failGeneric = true;

      expect(
        () => repository.getSummary(),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Gagal memuat ringkasan keuangan otoritatif'),
        )),
      );

      expect(client.calledPaths.where((p) => p == '/transactions'), isEmpty);
    });
  });
}
