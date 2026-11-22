import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/routing/notification_deep_link.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_goal_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_purchase_decision_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/goal_deposit.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/features/transactions/domain/receipt_parser.dart';
import 'package:tahan_dulu/features/transactions/domain/voice_transaction_parser.dart';

class InMemoryTokenStore implements TokenStore {
  String? _token = 'test-sanctum-token';

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 8C.2: Full Application End-to-End Integration Tests', () {
    late InMemoryTokenStore tokenStore;

    setUp(() {
      tokenStore = InMemoryTokenStore();
    });

    // =========================================================================
    // 1. MODUL PROFIL — INTEGRASI UUID, BIO, & AUTENTIKASI
    // =========================================================================
    test('1. Modul Profil: Profile updates and token lifecycle', () async {
      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/user/profile') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': '019315bc-5c20-72aa-99aa-7824128f0001',
                'name': 'Bayu Wicaksono',
                'email': 'bayu@email.com',
                'bio': 'Pecinta hidup hemat dan terencana',
                'phone': '08123456789',
                'monthly_budget': 5000000,
                'avatar': null,
              },
            }),
            200,
          );
        }

        if (request.method == 'PUT' && request.url.path == '/api/user/profile') {
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['bio'], equals('Target beli laptop Q1 2027'));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Profil berhasil diperbarui',
              'data': {
                'id': '019315bc-5c20-72aa-99aa-7824128f0001',
                'name': 'Bayu Wicaksono',
                'email': 'bayu@email.com',
                'bio': payload['bio'],
                'phone': '08123456789',
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final profile = await client.get('/user/profile', token: await tokenStore.readToken());
      expect(profile['data']['id'], equals('019315bc-5c20-72aa-99aa-7824128f0001'));
      expect(profile['data']['bio'], equals('Pecinta hidup hemat dan terencana'));

      final updated = await client.put(
        '/user/profile',
        {'bio': 'Target beli laptop Q1 2027'},
        token: await tokenStore.readToken(),
      );
      expect(updated['data']['bio'], equals('Target beli laptop Q1 2027'));
    });

    // =========================================================================
    // 2. MODUL TAHAN DULU / WISHLIST — TIGA METODE & RECORD PURCHASE
    // =========================================================================
    test('2. Modul Wishlist: Metadata Extraction, Image Upload, & Purchase Execution', () async {
      const wishlistUuid = '019315bc-5c20-72aa-99aa-7824128f0002';
      const instrumentUuid = '019315bc-5c20-72aa-99aa-7824128f0003';
      const purchaseTxUuid = '019315bc-5c20-72aa-99aa-7824128f0004';

      final mockHttp = MockClient((request) async {
        // Link Metadata Extraction
        if (request.method == 'POST' && request.url.path == '/api/wishlists/extract-metadata') {
          final payload = jsonDecode(request.body);
          expect(payload['url'], contains('tokopedia.com'));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Informasi produk berhasil diekstrak lengkap.',
              'data': {
                'extracted': true,
                'status': 'complete',
                'title': 'Sony WH-1000XM5 Wireless Headphones',
                'price': 4999000,
                'original_price': 5999000,
                'discount_percent': 16.67,
                'image_url': 'https://images.tokopedia.net/img/product-1.jpg',
                'marketplace': 'tokopedia',
              },
            }),
            200,
          );
        }

        // Store Wishlist Item
        if (request.method == 'POST' && request.url.path == '/api/wishlists') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Wishlist berhasil ditambahkan',
              'data': {
                'id': wishlistUuid,
                'item_name': 'Sony WH-1000XM5 Wireless Headphones',
                'price': 4999000,
                'status': 'considering',
                'wait_hours': 48,
                'product_url': 'https://www.tokopedia.com/product/123',
                'image_ref': 'wishlists/user-1/sample.jpg',
              },
            }),
            201,
          );
        }

        // Record Purchase Wishlist
        if (request.method == 'POST' && request.url.path == '/api/wishlists/$wishlistUuid/record-purchase') {
          final payload = jsonDecode(request.body);
          expect(payload['instrument_id'], equals(instrumentUuid));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pembelian berhasil dicatat ke buku kas dan saldo telah diperbarui.',
              'data': {
                'wishlist': {
                  'id': wishlistUuid,
                  'item_name': 'Sony WH-1000XM5 Wireless Headphones',
                  'status': 'bought',
                  'transaction_id': purchaseTxUuid,
                },
                'transaction_id': purchaseTxUuid,
                'amount': 4999000,
                'instrument_id': instrumentUuid,
                'already_recorded': false,
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final repo = RemotePurchaseDecisionRepository(client: client, tokens: tokenStore);

      // A. Extract metadata
      final metadata = await client.post(
        '/wishlists/extract-metadata',
        {'url': 'https://www.tokopedia.com/product/123'},
        token: await tokenStore.readToken(),
      );
      expect(metadata['data']['title'], contains('Sony WH-1000XM5'));
      expect(metadata['data']['price'], equals(4999000));

      // B. Save to Wishlist via repository
      final savedWishlist = await repo.addConsideration(
        PurchaseConsideration(
          id: 'temp',
          itemName: 'Sony WH-1000XM5 Wireless Headphones',
          price: 4999000,
          status: ConsiderationStatus.considering,
          waitHours: 48,
          createdAt: DateTime.now(),
        ),
      );
      expect(savedWishlist.id, equals(wishlistUuid));

      // C. Record Purchase (Decide & Buy)
      final recordResp = await client.post(
        '/wishlists/$wishlistUuid/record-purchase',
        {
          'instrument_id': instrumentUuid,
          'information': 'Dibeli setelah 48 jam pertimbangan',
        },
        token: await tokenStore.readToken(),
      );
      expect(recordResp['data']['wishlist']['status'], equals('bought'));
      expect(recordResp['data']['transaction_id'], equals(purchaseTxUuid));
    });

    // =========================================================================
    // 3. MODUL CATAT TRANSAKSI — VOICE, OCR STRUK, & REPOSITORY
    // =========================================================================
    test('3. Modul Transaksi: Voice Parser, Receipt OCR, & Transaction Creation', () async {
      // A. Voice Transaction Parsing
      const voiceText = 'Beli bensin pertamax di spbu lima puluh ribu rupiah';
      const voiceParser = VoiceTransactionParser();
      final voiceResult = voiceParser.parse(voiceText);
      expect(voiceResult.amount, equals(50000.0));
      expect(voiceResult.type, equals(TransactionType.expense));

      // B. Receipt OCR Parsing
      const ocrRawText = '''
      INDOMARET POINT
      JL. SUDIRMAN NO. 45
      =============================
      SUSU ULTRA MILK 1L    21.500
      ROTI TAWAR SARI ROTI  16.000
      MINYAK GORENG 2L      34.000
      -----------------------------
      SUBTOTAL              71.500
      DISKON MEMBER         (5.000)
      TOTAL BAYAR           66.500
      TUNAI                100.000
      KEMBALIAN             33.500
      =============================
      TERIMA KASIH
      ''';
      const receiptParser = ReceiptParser();
      final receiptResult = receiptParser.parse(ocrRawText);
      expect(receiptResult.total, equals(66500.0), reason: 'Total Bayar harus diutamakan di atas subtotal atau tunai');
      expect(receiptResult.merchantName, isNotEmpty);

      // C. Remote Transaction Repository Creation
      const createdTxUuid = '019315bc-5c20-72aa-99aa-7824128f0005';
      const instrumentUuid = '019315bc-5c20-72aa-99aa-7824128f0003';

      final mockHttp = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/transactions') {
          final payload = jsonDecode(request.body);
          expect(payload['amount'], equals(66500));
          expect(payload['instrument_id'], equals(instrumentUuid));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Transaksi berhasil dicatat',
              'data': {
                'id': createdTxUuid,
                'title': payload['title'],
                'type': 'expense',
                'category': 'makanan_minuman',
                'amount': 66500,
                'instrument_id': instrumentUuid,
                'created_at': '2026-11-22T10:00:00.000Z',
              },
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final txRepo = RemoteTransactionRepository(client: client, tokens: tokenStore);

      final newTx = await txRepo.addTransaction(
        AppTransaction(
          id: 'temp',
          title: receiptResult.merchantName ?? 'Belanja Indomaret',
          type: TransactionType.expense,
          category: 'makanan_minuman',
          amount: receiptResult.total,
          accountId: instrumentUuid,
          date: DateTime(2026, 11, 22),
        ),
      );

      expect(newTx.id, equals(createdTxUuid));
      expect(newTx.amount, equals(66500.0));
      expect(newTx.accountId, equals(instrumentUuid));
    });

    // =========================================================================
    // 4. MODUL GOALS / TARGET IMPIAN — UUID SAFETY & ALOKASI TABUNGAN
    // =========================================================================
    test('4. Modul Goals: UUID Persistence, Deposit Allocation, and Reordering', () async {
      const goalUuid = '019315bc-5c20-72aa-99aa-7824128f0006';
      const depositUuid = '019315bc-5c20-72aa-99aa-7824128f0007';
      const accountUuid = '019315bc-5c20-72aa-99aa-7824128f0003';

      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/goals') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': goalUuid,
                  'title': 'Dana Darurat 6 Bulan',
                  'type': 'emergency',
                  'target_amount': 30000000,
                  'current_amount': 5000000,
                  'priority': 0,
                  'frequency': 'monthly',
                }
              ],
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/goals/$goalUuid/transactions') {
          final payload = jsonDecode(request.body);
          expect(payload['type'], equals('deposit'));
          expect(payload['amount'], equals(2000000));
          expect(payload['instrument_id'], equals(accountUuid));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Transaksi dana goal berhasil dicatat',
              'data': {
                'id': depositUuid,
                'goal_id': goalUuid,
                'type': 'deposit',
                'amount': 2000000,
                'notes': 'Alokasi bulanan',
              },
            }),
            201,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/goals/reorder') {
          final payload = jsonDecode(request.body);
          expect(payload['ordered_ids'], contains(goalUuid));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Urutan goal berhasil diperbarui',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
      final goalRepo = RemoteGoalRepository(client: client, tokens: tokenStore);

      // A. Ambil daftar goals & verifikasi UUID tidak menjadi '0'
      final goals = await goalRepo.getGoals();
      expect(goals.length, equals(1));
      expect(goals.first.id, equals(goalUuid));
      expect(goals.first.id, isNot(equals('0')));

      // B. Setor alokasi tabungan
      final deposit = await goalRepo.addDeposit(
        GoalDeposit(
          id: 'temp',
          goalId: goalUuid,
          amount: 2000000,
          date: DateTime.now(),
          accountId: accountUuid,
          note: 'Alokasi bulanan',
        ),
      );
      expect(deposit.id, equals(depositUuid));
      expect(deposit.goalId, equals(goalUuid));
      expect(deposit.accountId, equals(accountUuid));

      // C. Reorder prioritas
      await goalRepo.saveGoalOrder([goalUuid]);
    });

    // =========================================================================
    // 5. NOTIFIKASI & DEEP LINK ROUTING DENGAN UUID ENTITAS
    // =========================================================================
    test('5. Deep Link Routing: UUID entities route to correct destinations', () {
      const validUuid = '019315bc-5c20-72aa-99aa-7824128f0008';

      // A. Savings Goal with UUID
      final goalRoute = NotificationDeepLink.resolve(
        type: 'savingsGoal',
        entityId: validUuid,
      );
      expect(goalRoute, equals('${AppRoutes.goals}/$validUuid'));

      // B. Tahan Dulu Wishlist with UUID
      final wishlistRoute = NotificationDeepLink.resolve(
        type: 'tahandulu',
        entityId: validUuid,
      );
      expect(wishlistRoute, equals('${AppRoutes.tahanDulu}/$validUuid'));

      // C. Saving Reminder
      final reminderRoute = NotificationDeepLink.resolve(
        type: 'savingsReminder',
      );
      expect(reminderRoute, equals(AppRoutes.notificationSavings));

      // D. Invalid arbitrary text should fallback safely
      final invalidRoute = NotificationDeepLink.resolve(
        type: 'savingsGoal',
        entityId: 'invalid-random-text',
      );
      expect(invalidRoute, equals(AppRoutes.goals));
    });
  });
}
