import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/uuid_generator.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_onboarding_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';

class _FakeTokenStore implements TokenStore {
  String? token = 'valid-test-token';
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<void> clearToken() async => token = null;
}

class _TrackingApiClient extends ApiClient {
  _TrackingApiClient() : super(baseUrl: 'https://example.com/api');

  final List<({String method, String path, dynamic body})> calls = [];

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    calls.add((method: 'GET', path: path, body: null));
    if (path == '/financial-instruments') {
      return {'data': []};
    }
    if (path == '/recurring-expenses') {
      return {'data': []};
    }
    if (path == '/goals') {
      return {'data': []};
    }
    if (path == '/me') {
      return {'data': {'monthly_income': 5000000, 'salary_day': 25}};
    }
    return {'data': null};
  }

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {String? token}) async {
    calls.add((method: 'POST', path: path, body: body));
    final uuid = '550e8400-e29b-41d4-a716-${calls.length.toString().padLeft(12, '0')}';
    if (path == '/financial-instruments') {
      return {
        'data': {
          'id': uuid,
          'name': body['name'],
          'balance': body['balance'],
          'monthly_admin_fee': body['monthly_admin_fee'] ?? 0,
          'admin_fee_day': body['admin_fee_day'] ?? 15,
          'admin_fee_enabled': body['admin_fee_enabled'] ?? false,
          'is_active': true,
        }
      };
    }
    if (path == '/recurring-expenses') {
      return {
        'data': {
          'id': uuid,
          'title': body['title'],
          'category': body['category'],
          'amount': body['amount'],
          'frequency': body['frequency'],
          'next_due_date': body['next_due_date'],
          'is_active': true,
        }
      };
    }
    if (path == '/goals') {
      return {
        'data': {
          'id': uuid,
          'title': body['title'],
          'type': body['type'],
          'target_amount': body['target_amount'],
          'current_amount': 0,
          'frequency': body['frequency'],
          'is_active': true,
        }
      };
    }
    return {'data': body};
  }

  @override
  Future<Map<String, dynamic>> put(String path, dynamic body, {String? token}) async {
    calls.add((method: 'PUT', path: path, body: body));
    if (path.startsWith('/financial-instruments/')) {
      final id = path.split('/').last;
      return {
        'data': {
          'id': id,
          'name': body['name'],
          'balance': body['balance'],
          'monthly_admin_fee': body['monthly_admin_fee'] ?? 0,
          'admin_fee_day': body['admin_fee_day'] ?? 15,
          'admin_fee_enabled': body['admin_fee_enabled'] ?? false,
          'is_active': true,
        }
      };
    }
    return {'data': body};
  }
}

void main() {
  group('F04 Onboarding UUID Deduplication & State Stabilization', () {
    test('isBackendId distinguishes local drafts from persistent IDs (including v4 and v7 UUIDs)', () {
      // Local drafts must return false
      expect(isBackendId('inst-1718000000000'), isFalse);
      expect(isBackendId('acc-1718000000000'), isFalse);
      expect(isBackendId('exp-1718000000000'), isFalse);
      expect(isBackendId('goal-onboarding'), isFalse);
      expect(isBackendId('trx-temp-1'), isFalse);
      expect(isBackendId('flt-temp-2'), isFalse);
      expect(isBackendId('draft-acc-1'), isFalse);
      expect(isBackendId('temp-uuid'), isFalse);
      expect(isBackendId('local-id'), isFalse);
      expect(isBackendId('mock-uuid'), isFalse);
      expect(isBackendId('client-uuid'), isFalse);
      expect(isBackendId(''), isFalse);
      expect(isBackendId(null), isFalse);

      // Legacy integer IDs return true
      expect(isBackendId('1'), isTrue);
      expect(isBackendId('42'), isTrue);

      // Standard RFC 4122 v4 UUID
      expect(isBackendId('550e8400-e29b-41d4-a716-446655440000'), isTrue);

      // UUID v7 format (time-ordered, e.g. from PostgreSQL v7)
      expect(isBackendId('018e39ad-6bc7-7a55-8e3b-9a9ec2b1cf59'), isTrue);
    });

    test('addInstrument followed by saveInstruments does NOT trigger redundant POST or PUT (prevents duplicate BRI accounts)', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(
        client: client,
        tokens: tokens,
      );

      // 1. User adds instrument in sheet -> addInstrument is called
      const tempId = 'inst-123456789';
      final added = await repo.addInstrument(
        const FinancialInstrument(
          id: tempId,
          name: 'Bank BRI',
          type: InstrumentType.bank,
          initialBalance: 5000000,
        ),
      );

      // Must have called POST /financial-instruments with idempotency key
      expect(client.calls.length, 1);
      expect(client.calls.first.method, 'POST');
      expect(client.calls.first.path, '/financial-instruments');
      expect(client.calls.first.body['idempotency_key'], 'onboarding-$tempId');
      expect(added.id, startsWith('550e8400-e29b-41d4-a716-'));

      // 2. User presses "Lanjut" (Next) -> saveInstruments is called with state.instruments
      await repo.saveInstruments([added]);

      // Verifikasi: TIDAK ada call tambahan! (upsert delta skips unchanged persisted instrument)
      expect(client.calls.length, 1);

      // 3. User navigates back and forth (Next -> Back -> Next)
      await repo.saveInstruments([added]);

      // Tetap tidak ada call tambahan! Saldo awal & akun tidak terduplikasi
      expect(client.calls.length, 1);
    });

    test('saveInstruments updates instrument via PUT only when properties are modified', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(
        client: client,
        tokens: tokens,
      );

      // Add instrument
      final added = await repo.addInstrument(
        const FinancialInstrument(
          id: 'inst-bca-1',
          name: 'BCA',
          type: InstrumentType.bank,
          initialBalance: 3000000,
        ),
      );
      expect(client.calls.length, 1);

      // Modify admin fee on existing instrument
      final modified = added.copyWith(
        adminFeeEnabled: true,
        monthlyAdminFee: 15000,
      );

      // Save again
      await repo.saveInstruments([modified]);

      // Call ke-2 harus berupa PUT, bukan POST!
      expect(client.calls.length, 2);
      expect(client.calls[1].method, 'PUT');
      expect(client.calls[1].path, '/financial-instruments/${added.id}');
      expect(client.calls[1].body['monthly_admin_fee'], 15000);
      expect(client.calls[1].body['admin_fee_enabled'], isTrue);
    });

    test('saveInstruments sends POST with idempotency key for new draft instruments', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(
        client: client,
        tokens: tokens,
      );

      const draftId = 'inst-new-draft-999';
      await repo.saveInstruments([
        const FinancialInstrument(
          id: draftId,
          name: 'Bank Mandiri',
          type: InstrumentType.bank,
          initialBalance: 10000000,
        ),
      ]);

      expect(client.calls.length, 1);
      expect(client.calls.first.method, 'POST');
      expect(client.calls.first.path, '/financial-instruments');
      expect(client.calls.first.body['idempotency_key'], 'onboarding-$draftId');
    });
  });
}
