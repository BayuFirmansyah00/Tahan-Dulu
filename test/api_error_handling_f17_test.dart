import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';

void main() {
  group('F17 API Client Error Handling & Fallback Provenance', () {
    test('HTTP 401 triggers onUnauthorized callback and Indonesian message', () async {
      var unauthorizedCalled = false;
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );

      try {
        await client.get('/test');
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(unauthorizedCalled, isTrue);
        expect(e.message, contains('Unauthenticated'));
      }
    });

    test('HTTP 403 Forbidden maps permission message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Akses ditolak.'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.get('/test');
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.message, 'Akses ditolak.');
      }
    });

    test('HTTP 404 Not Found maps clear message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.get('/test');
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.message, 'Data atau sumber daya tidak ditemukan.');
      }
    });

    test('HTTP 409 Conflict maps duplicate/concurrency notice', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.post('/test', {});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.message, contains('konflik data atau duplikasi'));
      }
    });

    test('HTTP 422 Unprocessable Entity preserves field validation errors', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Data tidak valid.',
            'errors': {
              'amount': ['Nominal harus lebih dari 0'],
              'account_id': ['Akun tidak ditemukan'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.post('/test', {});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 422);
        expect(e.message, 'Data tidak valid.');
        expect(e.hasFieldError('amount'), isTrue);
        expect(e.fieldErrors['amount']!.first, 'Nominal harus lebih dari 0');
      }
    });

    test('HTTP 429 Too Many Requests surfaces rate limiting advice', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({}),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.get('/test');
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 429);
        expect(e.message, contains('Terlalu banyak permintaan'));
      }
    });

    test('HTTP 500 strips raw SQL and internal exceptions', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message':
                'SQLSTATE[42601]: Syntax error: 7 ERROR: syntax for type "uuid" PDOException',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.get('/test');
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, 'Terjadi kesalahan pada server. Silakan coba lagi.');
        expect(e.message.contains('SQLSTATE'), isFalse);
      }
    });

    test('HTTP 503 preserves fail-closed security notice', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message':
                'Fitur penulisan transaksi investasi sedang digembok demi keamanan.',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'https://example.com/api',
        httpClient: mockClient,
      );

      try {
        await client.post('/investments/test/transactions', {});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 503);
        expect(
          e.message,
          'Fitur penulisan transaksi investasi sedang digembok demi keamanan.',
        );
      }
    });
  });
}
