import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_bank_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/api_bank.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/repositories/bank_repository.dart';
import 'package:tahan_dulu/features/accounts/presentation/widgets/bank_logo_badge.dart';

void main() {
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tokenStore = MemoryTokenStore();
    await tokenStore.saveToken('test-bank-token');
  });

  group('ApiBank Model & Acronym Tests', () {
    test('ApiBank.fromJson parses complete catalog bank payload', () {
      final json = {
        'id': 14,
        'slug': 'bca',
        'name': 'Bank Central Asia',
        'aliases': ['BCA', '014', 'BBCA'],
        'category': 'bank-logo',
        'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
        'is_active': true,
      };

      final bank = ApiBank.fromJson(json);

      expect(bank.id, 14);
      expect(bank.slug, 'bca');
      expect(bank.name, 'Bank Central Asia');
      expect(bank.aliases, ['BCA', '014', 'BBCA']);
      expect(bank.category, 'bank-logo');
      expect(bank.logoUrl, contains('bca.svg'));
      expect(bank.isActive, isTrue);
    });

    test('ApiBank.matchesSearch finds matches across name, slug, and code aliases', () {
      const bank = ApiBank(
        id: 1,
        slug: 'mandiri',
        name: 'Bank Mandiri',
        aliases: ['BMRI', '008'],
        category: 'bank-logo',
        logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg',
        isActive: true,
      );

      expect(bank.matchesSearch('mandiri'), isTrue);
      expect(bank.matchesSearch('MANDIRI'), isTrue);
      expect(bank.matchesSearch('008'), isTrue);
      expect(bank.matchesSearch('bmri'), isTrue);
      expect(bank.matchesSearch('bca'), isFalse);
    });

    test('BankLogoBadge.deriveAcronym produces clean typography badges', () {
      expect(BankLogoBadge.deriveAcronym('Bank Central Asia', 'bca'), 'BCA');
      expect(BankLogoBadge.deriveAcronym('Bank Mandiri', 'mandiri'), 'BMRI');
      expect(BankLogoBadge.deriveAcronym('Bank Rakyat Indonesia', 'bri'), 'BRI');
      expect(BankLogoBadge.deriveAcronym('Bank Negara Indonesia', 'bni'), 'BNI');
      expect(BankLogoBadge.deriveAcronym('Bank Jago', 'jago'), 'JAGO');
      expect(BankLogoBadge.deriveAcronym('SeaBank Indonesia', 'seabank'), 'SEA');
      expect(BankLogoBadge.deriveAcronym('Bank Syariah Indonesia', 'bsi'), 'BSI');
      expect(BankLogoBadge.deriveAcronym('Bank Permata', 'permata'), 'BNLI');
      expect(BankLogoBadge.deriveAcronym('Bank Danamon', 'danamon'), 'BDMN');
      // Fallback untuk bank kustom/lokal
      expect(BankLogoBadge.deriveAcronym('Bank Nagari', 'nagari'), 'NAG');
    });
  });

  group('RemoteBankRepository Tests', () {
    test('getBanks returns list of active banks from /banks', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/banks');
        expect(request.headers['Authorization'], 'Bearer test-bank-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 1,
                'slug': 'bca',
                'name': 'Bank Central Asia',
                'aliases': ['BCA', '014'],
                'category': 'bank-logo',
                'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
                'is_active': true,
              },
              {
                'id': 2,
                'slug': 'jago',
                'name': 'Bank Jago',
                'aliases': ['Jago', '542'],
                'category': 'bank-logo',
                'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/jago.svg',
                'is_active': true,
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteBankRepository(client: client, tokens: tokenStore);

      final banks = await repo.getBanks();
      expect(banks.length, 2);
      expect(banks.first.slug, 'bca');
      expect(banks.first.name, 'Bank Central Asia');
      expect(banks.last.slug, 'jago');
    });

    test('getBanks with search param passes query string', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/banks');
        expect(request.url.queryParameters['search'], 'bca');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 1,
                'slug': 'bca',
                'name': 'Bank Central Asia',
                'aliases': ['BCA', '014'],
                'category': 'bank-logo',
                'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
                'is_active': true,
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteBankRepository(client: client, tokens: tokenStore);

      final banks = await repo.getBanks(search: 'bca');
      expect(banks.length, 1);
      expect(banks.first.slug, 'bca');
    });

    test('getBank by slug returns single bank detail', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/banks/mandiri');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': {
              'id': 2,
              'slug': 'mandiri',
              'name': 'Bank Mandiri',
              'aliases': ['BMRI', '008'],
              'category': 'bank-logo',
              'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg',
              'is_active': true,
            },
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteBankRepository(client: client, tokens: tokenStore);

      final bank = await repo.getBank('mandiri');
      expect(bank.slug, 'mandiri');
      expect(bank.name, 'Bank Mandiri');
    });

    test('MockBankRepository provides search & fallback', () async {
      final mockRepo = MockBankRepository();
      final all = await mockRepo.getBanks();
      expect(all.length, 6);

      final filtered = await mockRepo.getBanks(search: 'jago');
      expect(filtered.length, 1);
      expect(filtered.first.slug, 'jago');

      final bca = await mockRepo.getBank('bca');
      expect(bca.name, 'Bank Central Asia');
    });
  });

  group('RemoteAccountRepository Bank Mapping Integration', () {
    test('getAccounts parses nested bank catalog metadata', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/financial-instruments');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 101,
                'name': 'BCA Utama',
                'balance': 5000000,
                'type': {
                  'id': 1,
                  'name': 'Bank',
                  'type': 'bank',
                },
                'bank_id': 1,
                'bank_slug': 'bca',
                'bank': {
                  'id': 1,
                  'slug': 'bca',
                  'name': 'Bank Central Asia',
                  'aliases': ['BCA', '014'],
                  'category': 'bank-logo',
                  'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
                  'is_active': true,
                },
              },
              {
                'id': 102,
                'name': 'Dompet Tunai',
                'balance': 250000,
                'type': {
                  'id': 3,
                  'name': 'E-Wallet',
                  'type': 'ewallet',
                },
                'bank_id': null,
                'bank_slug': null,
                'bank': null,
              },
            ],
          }),
          200,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteAccountRepository(client: client, tokens: tokenStore);

      final accounts = await repo.getAccounts();
      expect(accounts.length, 2);

      final bcaAcc = accounts.first;
      expect(bcaAcc.name, 'BCA Utama');
      expect(bcaAcc.bankId, 1);
      expect(bcaAcc.bankSlug, 'bca');
      expect(bcaAcc.bankName, 'Bank Central Asia');
      expect(bcaAcc.bankLogoUrl, contains('bca.svg'));

      final cashAcc = accounts.last;
      expect(cashAcc.name, 'Dompet Tunai');
      expect(cashAcc.bankId, isNull);
      expect(cashAcc.bankSlug, isNull);
      expect(cashAcc.bankName, isNull);
    });

    test('addAccount sends bank_id and bank_slug to API', () async {
      final mockHttp = MockClient((request) async {
        expect(request.url.path, '/api/financial-instruments');
        expect(request.method, 'POST');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['name'], 'Tabungan Jago');
        expect(payload['bank_id'], 5);
        expect(payload['bank_slug'], 'jago');
        expect(payload['balance'], 1500000);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OK',
            'data': {
              'id': 202,
              'name': 'Tabungan Jago',
              'balance': 1500000,
              'type': {'id': 2, 'name': 'Bank Digital', 'type': 'digitalbank'},
              'bank_id': 5,
              'bank_slug': 'jago',
              'bank': {
                'id': 5,
                'slug': 'jago',
                'name': 'Bank Jago',
                'aliases': ['Jago', '542'],
                'category': 'bank-logo',
                'logo_url': 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/jago.svg',
                'is_active': true,
              },
            },
          }),
          201,
        );
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemoteAccountRepository(client: client, tokens: tokenStore);

      final created = await repo.addAccount(
        const FinancialAccount(
          id: 'temp-id',
          name: 'Tabungan Jago',
          type: AccountType.digitalBank,
          typeId: 2,
          balance: 1500000,
          bankId: 5,
          bankSlug: 'jago',
          bankName: 'Bank Jago',
        ),
      );

      expect(created.id, '202');
      expect(created.bankId, 5);
      expect(created.bankSlug, 'jago');
      expect(created.bankName, 'Bank Jago');
    });
  });
}
