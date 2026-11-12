import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';

void main() {
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tokenStore = MemoryTokenStore();
    await tokenStore.saveToken('valid-test-token');
  });

  group('P0-01 RemoteTransactionRepository Date Field Tests', () {
    test('addTransaction sends date in ISO-8601 format to Laravel API', () async {
      final testDate = DateTime(2026, 11, 5, 14, 30);
      Map<String, dynamic>? capturedBody;

      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/transactions');
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer valid-test-token');

        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Transaksi berhasil dicatat',
            'data': {
              'id': 101,
              'title': 'Makanan & Minuman',
              'type': 'expense',
              'category': 'Makanan & Minuman',
              'amount': 35500,
              'amount_formatted': 'Rp 35.500',
              'information': 'Makan Siang',
              'created_at': testDate.toIso8601String(),
              'updated_at': testDate.toIso8601String(),
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.tahandulu.test/api',
        httpClient: mockHttp,
      );

      final repo = RemoteTransactionRepository(
        client: apiClient,
        tokens: tokenStore,
      );

      final result = await repo.addTransaction(
        AppTransaction(
          id: 'temp-id',
          title: 'Makanan & Minuman',
          amount: 35500,
          type: TransactionType.expense,
          date: testDate,
          category: 'Makanan & Minuman',
          accountId: '1',
          note: 'Makan Siang',
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['date'], equals(testDate.toIso8601String()));
      expect(capturedBody!['amount'], equals(35500));
      expect(capturedBody!['title'], equals('Makanan & Minuman'));
      expect(capturedBody!['type'], equals('expense'));
      expect(capturedBody!['instrument_id'], equals(1));
      expect(capturedBody!['information'], equals('Makan Siang'));

      expect(result.id, equals('101'));
      expect(result.amount, equals(35500.0));
      expect(result.date, equals(testDate));
    });

    test('updateTransaction sends date in ISO-8601 format to Laravel API', () async {
      final testDate = DateTime(2026, 10, 30, 9, 15);
      Map<String, dynamic>? capturedBody;

      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/transactions/101');
        expect(request.method, 'PUT');

        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Transaksi berhasil diperbarui',
            'data': {
              'id': 101,
              'title': 'Belanja',
              'type': 'expense',
              'category': 'Belanja',
              'amount': 121000,
              'amount_formatted': 'Rp 121.000',
              'information': 'Indomaret Point',
              'created_at': testDate.toIso8601String(),
              'updated_at': testDate.toIso8601String(),
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.tahandulu.test/api',
        httpClient: mockHttp,
      );

      final repo = RemoteTransactionRepository(
        client: apiClient,
        tokens: tokenStore,
      );

      final result = await repo.updateTransaction(
        AppTransaction(
          id: '101',
          title: 'Belanja',
          amount: 121000,
          type: TransactionType.expense,
          date: testDate,
          category: 'Belanja',
          accountId: '2',
          note: 'Indomaret Point',
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['date'], equals(testDate.toIso8601String()));
      expect(capturedBody!['amount'], equals(121000));
      expect(result.date, equals(testDate));
    });

    test('addTransaction sends idempotency_key when present in AppTransaction', () async {
      final testDate = DateTime(2026, 11, 8, 10, 0);
      const testKey = '550e8400-e29b-41d4-a716-446655440000';
      Map<String, dynamic>? capturedBody;

      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/transactions');
        expect(request.method, 'POST');
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Transaksi berhasil dicatat',
            'data': {
              'id': 202,
              'title': 'Makan Siang',
              'type': 'expense',
              'category': 'Makanan & Minuman',
              'amount': 50000,
              'amount_formatted': 'Rp 50.000',
              'information': null,
              'created_at': testDate.toIso8601String(),
              'updated_at': testDate.toIso8601String(),
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.tahandulu.test/api',
        httpClient: mockHttp,
      );

      final repo = RemoteTransactionRepository(
        client: apiClient,
        tokens: tokenStore,
      );

      await repo.addTransaction(
        AppTransaction(
          id: 'temp-202',
          title: 'Makan Siang',
          amount: 50000,
          type: TransactionType.expense,
          date: testDate,
          category: 'Makanan & Minuman',
          accountId: '1',
          idempotencyKey: testKey,
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['idempotency_key'], equals(testKey));
    });

    test('addTransaction omits idempotency_key when null or empty', () async {
      final testDate = DateTime(2026, 11, 8, 10, 0);
      Map<String, dynamic>? capturedBody;

      final mockHttp = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Transaksi berhasil dicatat',
            'data': {
              'id': 203,
              'title': 'Kopi',
              'type': 'expense',
              'category': 'Makanan & Minuman',
              'amount': 20000,
              'created_at': testDate.toIso8601String(),
              'updated_at': testDate.toIso8601String(),
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.tahandulu.test/api',
        httpClient: mockHttp,
      );

      final repo = RemoteTransactionRepository(
        client: apiClient,
        tokens: tokenStore,
      );

      await repo.addTransaction(
        AppTransaction(
          id: 'temp-203',
          title: 'Kopi',
          amount: 20000,
          type: TransactionType.expense,
          date: testDate,
          category: 'Makanan & Minuman',
          accountId: '1',
          idempotencyKey: null,
        ),
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!.containsKey('idempotency_key'), isFalse);
    });
  });
}

