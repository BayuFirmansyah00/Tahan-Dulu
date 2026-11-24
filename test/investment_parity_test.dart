import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_investment_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';

class _FakeTokenStore implements TokenStore {
  @override
  Future<String?> readToken() async => 'test-auth-token';
  @override
  Future<void> saveToken(String t) async {}
  @override
  Future<void> clearToken() async {}
}

class _MockInvestmentClient extends ApiClient {
  _MockInvestmentClient() : super(baseUrl: 'https://example.com/api');

  final List<({String method, String path, dynamic body})> history = [];

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    history.add((method: 'GET', path: path, body: null));
    if (path == '/investments') {
      return {
        'data': [
          {
            'id': 'inv-uuid-1',
            'title': 'Portofolio Saham',
            'type': 'saham',
            'target': 50000000,
            'achieved': 15000000,
            'increase': 1500000,
            'progress_percentage': 30.0,
            'is_active': true,
          }
        ]
      };
    }
    if (path.contains('/transactions')) {
      return {
        'data': [
          {
            'id': 'itx-uuid-1',
            'investment_id': 'inv-uuid-1',
            'type': 'deposit',
            'amount': 5000000,
            'notes': 'Top up dividen',
            'created_at': '2026-11-24T12:00:00Z',
          }
        ]
      };
    }
    return {'data': []};
  }

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {String? token}) async {
    history.add((method: 'POST', path: path, body: body));
    return {
      'data': {
        'id': 'itx-new-uuid',
        'investment_id': 'inv-uuid-1',
        'type': body['type'],
        'amount': body['amount'],
        'notes': body['notes'],
        'created_at': '2026-11-24T14:00:00Z',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? payload, String? token}) async {
    history.add((method: 'DELETE', path: path, body: payload));
    return {'success': true};
  }
}

void main() {
  group('F14 Investment Domain & Parity Integration Tests', () {
    late _MockInvestmentClient client;
    late _FakeTokenStore tokens;
    late RemoteInvestmentRepository repository;

    setUp(() {
      client = _MockInvestmentClient();
      tokens = _FakeTokenStore();
      repository = RemoteInvestmentRepository(client: client, tokens: tokens);
    });

    test('getApiInvestments fetches and maps portfolio list with UUID and fields intact', () async {
      final list = await repository.getApiInvestments();

      expect(list.length, equals(1));
      final inv = list.first;
      expect(inv.id, equals('inv-uuid-1'));
      expect(inv.title, equals('Portofolio Saham'));
      expect(inv.achieved, equals(15000000));
      expect(inv.increase, equals(1500000));
      expect(inv.isActive, isTrue);
      expect(client.history.any((h) => h.method == 'GET' && h.path == '/investments'), isTrue);
    });

    test('addInvestmentTransaction records deposit correctly', () async {
      final itx = await repository.addInvestmentTransaction(
        investmentId: 'inv-uuid-1',
        type: 'deposit',
        amount: 2500000,
        instrumentId: 'acc-uuid-bca',
        notes: 'Top Up Bulanan',
      );

      expect(itx.id, equals('itx-new-uuid'));
      expect(itx.amount, equals(2500000));
      expect(itx.type, equals('deposit'));
      expect(itx.notes, equals('Top Up Bulanan'));

      final call = client.history.firstWhere((h) => h.method == 'POST');
      expect(call.path, equals('/investments/inv-uuid-1/transactions'));
      expect(call.body['type'], equals('deposit'));
      expect(call.body['amount'], equals(2500000));
      expect(call.body['instrument_id'], equals('acc-uuid-bca'));
    });

    test('addInvestmentTransaction records withdraw correctly', () async {
      final itx = await repository.addInvestmentTransaction(
        investmentId: 'inv-uuid-1',
        type: 'withdraw',
        amount: 1000000,
        instrumentId: 'acc-uuid-bca',
        notes: 'Pencairan darurat',
      );

      expect(itx.type, equals('withdraw'));
      expect(itx.amount, equals(1000000));

      final call = client.history.firstWhere((h) => h.method == 'POST');
      expect(call.path, equals('/investments/inv-uuid-1/transactions'));
      expect(call.body['type'], equals('withdraw'));
      expect(call.body['amount'], equals(1000000));
    });

    test('deleteInvestmentTransaction calls DELETE endpoint', () async {
      await repository.deleteInvestmentTransaction(
        investmentId: 'inv-uuid-1',
        transactionId: 'itx-uuid-1',
      );

      final call = client.history.firstWhere((h) => h.method == 'DELETE');
      expect(call.path, equals('/investments/inv-uuid-1/transactions/itx-uuid-1'));
    });

    test('FinancialAccount preserves isActive, maxBudget, and budgetFrequency', () {
      const account = FinancialAccount(
        id: 'acc-uuid-1',
        name: 'Rekening Operasional',
        type: AccountType.bank,
        balance: 10000000,
        isActive: false,
        maxBudget: 5000000,
        budgetFrequency: 'monthly',
      );

      expect(account.isActive, isFalse);
      expect(account.maxBudget, equals(5000000));
      expect(account.budgetFrequency, equals('monthly'));

      final updated = account.copyWith(isActive: true);
      expect(updated.isActive, isTrue);
      expect(updated.maxBudget, equals(5000000));
    });
  });
}
