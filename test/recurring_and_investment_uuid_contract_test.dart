import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_recurring_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/api_investment.dart';
import 'package:tahan_dulu/data/models/api_investment_transaction.dart';
import 'package:tahan_dulu/data/models/api_recurring_transaction.dart';

class _FakeTokenStore implements TokenStore {
  @override
  Future<String?> readToken() async => 'test-token';
  @override
  Future<void> saveToken(String t) async {}
  @override
  Future<void> clearToken() async {}
}

class _TrackingClient extends ApiClient {
  _TrackingClient() : super(baseUrl: 'https://example.com/api');
  final List<({String method, String path, dynamic body})> calls = [];

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {String? token}) async {
    calls.add((method: 'POST', path: path, body: body));
    return {
      'data': {
        'id': 'rec-uuid-9999',
        'title': body['title'],
        'type': path.contains('income') ? 'income' : 'expense',
        'category': body['category'],
        'amount': body['amount'],
        'frequency': body['frequency'],
        'next_due_date': body['next_due_date'],
        'instrument_id': body['instrument_id'],
        'is_active': true,
        'make_automatic': false,
      }
    };
  }
}

void main() {
  group('F05 Recurring and Investment UUID Contracts Test', () {
    test('ApiRecurringTransaction preserves full UUID string without coercing to 0', () {
      const uuidString = '550e8400-e29b-41d4-a716-446655440000';
      final json = {
        'id': uuidString,
        'title': 'Gaji Bulanan',
        'type': 'income',
        'category': 'gaji',
        'amount': 8000000,
        'frequency': 'monthly',
        'next_due_date': '2026-11-25',
        'is_active': true,
        'make_automatic': true,
      };

      final model = ApiRecurringTransaction.fromJson(json);

      expect(model.id, equals(uuidString));
      expect(model.id, isNot('0'));
    });

    test('ApiInvestment preserves full UUID string without coercing to 0', () {
      const uuidString = 'c81d4e2e-bcf2-4a7b-a39c-2f8352654bc0';
      final json = {
        'id': uuidString,
        'title': 'Reksadana Saham',
        'type': 'mutual_fund',
        'target': 50000000,
        'achieved': 12000000,
        'progress_percentage': 24.0,
        'is_active': true,
      };

      final model = ApiInvestment.fromJson(json);

      expect(model.id, equals(uuidString));
      expect(model.id, isNot('0'));
    });

    test('ApiInvestmentTransaction preserves full UUID string for id and investmentId', () {
      const txUuid = '018e39ad-6bc7-7a55-8e3b-9a9ec2b1cf59';
      const invUuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

      final json = {
        'id': txUuid,
        'investment_id': invUuid,
        'type': 'deposit',
        'amount': 1000000,
        'notes': 'Top up rutin',
      };

      final model = ApiInvestmentTransaction.fromJson(json);

      expect(model.id, equals(txUuid));
      expect(model.investmentId, equals(invUuid));
      expect(model.id, isNot('0'));
      expect(model.investmentId, isNot('0'));
    });

    test('RemoteRecurringRepository sends String UUID instrument_id in API request payload', () async {
      final client = _TrackingClient();
      final repo = RemoteRecurringRepository(client: client, tokens: _FakeTokenStore());

      const uuidAccount = '550e8400-e29b-41d4-a716-446655440000';

      await repo.addRecurringIncome(
        title: 'Dividen Saham',
        category: 'investasi',
        amount: 500000,
        frequency: 'monthly',
        nextDueDate: '2026-12-01',
        instrumentId: uuidAccount,
      );

      expect(client.calls.length, 1);
      expect(client.calls.first.path, '/recurring-incomes');
      expect(client.calls.first.body['instrument_id'], equals(uuidAccount));
      expect(client.calls.first.body['instrument_id'], isA<String>());
    });
  });
}
