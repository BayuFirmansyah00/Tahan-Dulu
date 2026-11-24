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
  final Map<String, Map<String, dynamic>> storedByKey = {};
  List<Map<String, dynamic>> existingInstruments = [];
  List<Map<String, dynamic>> existingExpenses = [];
  List<Map<String, dynamic>> existingGoals = [];

  bool simulateFailureAfterBackendStore = false;
  String? failOnKey;

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    calls.add((method: 'GET', path: path, body: null));
    if (path == '/financial-instruments') {
      return {'data': existingInstruments};
    }
    if (path == '/recurring-expenses') {
      return {'data': existingExpenses};
    }
    if (path == '/goals') {
      return {'data': existingGoals};
    }
    if (path == '/me') {
      return {'data': {'monthly_income': 5000000, 'salary_day': 25}};
    }
    return {'data': null};
  }

  @override
  Future<Map<String, dynamic>> post(String path, dynamic body, {String? token}) async {
    calls.add((method: 'POST', path: path, body: body));

    final key = body is Map ? body['idempotency_key'] as String? : null;

    if (key != null && storedByKey.containsKey(key)) {
      // Backend idempotency: return previously stored entity
      return storedByKey[key]!;
    }

    if (key != null && key == failOnKey) {
      throw ApiException('Simulated connection failure during POST', statusCode: 500);
    }

    final uuid = '550e8400-e29b-41d4-a716-${calls.length.toString().padLeft(12, '0')}';
    Map<String, dynamic> responseData;

    if (path == '/financial-instruments') {
      responseData = {
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
      existingInstruments.add(responseData['data'] as Map<String, dynamic>);
    } else if (path == '/recurring-expenses') {
      responseData = {
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
      existingExpenses.add(responseData['data'] as Map<String, dynamic>);
    } else if (path == '/goals') {
      responseData = {
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
      existingGoals.add(responseData['data'] as Map<String, dynamic>);
    } else {
      responseData = {'data': body};
    }

    if (key != null) {
      storedByKey[key] = responseData;
    }

    if (simulateFailureAfterBackendStore) {
      simulateFailureAfterBackendStore = false;
      throw ApiException('Network dropped after backend commit (Lost Response)', statusCode: 504);
    }

    return responseData;
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

    test('Scenario A: Lost response simulation - retry sends identical key and deduplicates safely', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(client: client, tokens: tokens);

      const draftId = 'inst-timeout-123';
      const inst = FinancialInstrument(
        id: draftId,
        name: 'Bank BCA Timeout',
        type: InstrumentType.bank,
        initialBalance: 2000000,
      );

      // Backend commits record, but network drops right before response reaches Flutter
      client.simulateFailureAfterBackendStore = true;

      try {
        await repo.saveInstruments([inst]);
        fail('Should have thrown ApiException on network drop');
      } catch (e) {
        expect(e, isA<ApiException>());
      }

      // Backend already has exactly 1 instrument
      expect(client.existingInstruments.length, 1);
      final committedId = client.existingInstruments.first['id'];

      // User / app retries with the same draft instrument
      final result = await repo.saveInstruments([inst]);

      // Exactly 1 instrument in backend, same ID returned, no duplicate account!
      expect(client.existingInstruments.length, 1);
      expect(result.financialInstruments.length, 1);
      expect(result.financialInstruments.first.id, committedId);
    });

    test('Scenario B: Process restart simulation - hydrateAll reloads state and prevents duplicate POST', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();

      // Pre-existing account in backend (e.g. from previous session)
      client.existingInstruments.add({
        'id': '550e8400-e29b-41d4-a716-446655440001',
        'name': 'Bank Mandiri Restart',
        'type': {'id': 'type-uuid-1', 'name': 'Bank', 'type': 'bank'},
        'balance': 7500000,
        'monthly_admin_fee': 0,
        'admin_fee_day': 15,
        'admin_fee_enabled': false,
        'is_active': true,
      });

      // App process starts fresh: new repository instance created
      final freshRepo = RemoteOnboardingRepository(client: client, tokens: tokens);

      // Rehydrate state on startup
      final hydratedData = await freshRepo.hydrateAll();
      expect(hydratedData, isNotNull);
      expect(hydratedData!.financialInstruments.length, 1);

      // Save instruments called again (e.g. user continues onboarding without changes)
      await freshRepo.saveInstruments(hydratedData.financialInstruments);

      // No new POST or PUT calls made to backend
      final postOrPutCalls = client.calls.where((c) => c.method == 'POST' || c.method == 'PUT');
      expect(postOrPutCalls.isEmpty, isTrue);
    });

    test('Scenario C: Partial failure recovery - first succeeds, second fails, retry only posts second', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(client: client, tokens: tokens);

      const instA = FinancialInstrument(
        id: 'inst-draft-A',
        name: 'Account A',
        type: InstrumentType.bank,
        initialBalance: 1000000,
      );
      const instB = FinancialInstrument(
        id: 'inst-draft-B',
        name: 'Account B',
        type: InstrumentType.bank,
        initialBalance: 2000000,
      );

      // Make Inst B fail on network
      client.failOnKey = 'onboarding-inst-draft-B';

      try {
        await repo.saveInstruments([instA, instB]);
        fail('Should have thrown ApiException for Inst B');
      } catch (e) {
        expect(e, isA<ApiException>());
      }

      // Inst A succeeded and was stored
      expect(client.existingInstruments.length, 1);
      final idA = client.existingInstruments.first['id'];

      // Clear network failure
      client.failOnKey = null;

      // Retry with the current cached/onboarding instruments
      // instA now has backend ID idA, instB still has draft ID
      final instACached = instA.copyWith(id: idA.toString());
      final retryResult = await repo.saveInstruments([instACached, instB]);

      // Both instruments now successfully exist in backend
      expect(client.existingInstruments.length, 2);
      expect(retryResult.financialInstruments.length, 2);

      // Inst A was NOT posted a second time
      final postCallsForA = client.calls.where(
        (c) => c.method == 'POST' && c.body is Map && c.body['name'] == 'Account A',
      );
      expect(postCallsForA.length, 1);
    });

    test('Scenario D: Rapid multiple submit taps - concurrent calls do not duplicate entities', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(client: client, tokens: tokens);

      const inst = FinancialInstrument(
        id: 'inst-rapid-tap-1',
        name: 'BCA Rapid',
        type: InstrumentType.bank,
        initialBalance: 5000000,
      );

      // Simulate rapid double submit
      final results = await Future.wait([
        repo.saveInstruments([inst]),
        repo.saveInstruments([inst]),
      ]);

      expect(results[0].financialInstruments.length, 1);
      expect(results[1].financialInstruments.length, 1);
      expect(client.existingInstruments.length, 1);
    });

    test('Scenario E: Logout / switch account - clear resets persisted sets and prevents cross-user contamination', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(client: client, tokens: tokens);

      // User 1 completes onboarding
      await repo.saveInstruments([
        const FinancialInstrument(
          id: 'inst-user1',
          name: 'BCA User 1',
          type: InstrumentType.bank,
          initialBalance: 10000000,
        ),
      ]);
      expect(repo.getOnboardingData()!.financialInstruments.length, 1);

      // User 1 logs out
      repo.clear();
      expect(repo.getOnboardingData(), isNull);

      // User 2 logs in and adds their own account
      final user2Data = await repo.saveInstruments([
        const FinancialInstrument(
          id: 'inst-user2',
          name: 'BCA User 2',
          type: InstrumentType.bank,
          initialBalance: 500000,
        ),
      ]);

      expect(user2Data.financialInstruments.length, 1);
      expect(user2Data.financialInstruments.first.name, 'BCA User 2');
    });

    test('Scenario F: Legitimate two accounts with same name - key-based deduplication creates both', () async {
      final client = _TrackingApiClient();
      final tokens = _FakeTokenStore();
      final repo = RemoteOnboardingRepository(client: client, tokens: tokens);

      // User legitimately creates two BRI accounts with different draft IDs
      const bri1 = FinancialInstrument(
        id: 'inst-bri-primary',
        name: 'Bank BRI',
        type: InstrumentType.bank,
        initialBalance: 5000000,
      );
      const bri2 = FinancialInstrument(
        id: 'inst-bri-secondary',
        name: 'Bank BRI',
        type: InstrumentType.bank,
        initialBalance: 3000000,
      );

      final result = await repo.saveInstruments([bri1, bri2]);

      // Both accounts must be created with distinct backend IDs
      expect(result.financialInstruments.length, 2);
      expect(result.financialInstruments[0].id, isNot(equals(result.financialInstruments[1].id)));
      expect(client.existingInstruments.length, 2);
    });
  });
}
