import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_purchase_decision_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';

void main() {
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tokenStore = MemoryTokenStore();
    await tokenStore.saveToken('valid-wishlist-token');
  });

  test('RemotePurchaseDecisionRepository getConsiderations maps JSON correctly', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/wishlists');
      expect(request.headers['Authorization'], 'Bearer valid-wishlist-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'OK',
          'data': [
            {
              'id': 101,
              'item_name': 'Sepatu Lari Ultraboost',
              'price': 2500000,
              'status': 'considering',
              'category': 'fashion',
              'product_url': 'https://adidas.com/ultraboost',
              'reason': 'Sepatu lama sudah aus',
              'wait_hours': 48,
              'wait_started_at': '2026-10-29T10:00:00.000000Z',
              'wait_ends_at': '2026-10-31T10:00:00.000000Z',
              'created_at': '2026-10-29T10:00:00.000000Z',
            },
            {
              'id': 102,
              'item_name': 'Monitor Ultrawide 34 inch',
              'price': 6500000,
              'status': 'wishlist',
              'category': 'electronics',
              'created_at': '2026-10-28T09:00:00.000000Z',
            },
          ],
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemotePurchaseDecisionRepository(client: client, tokens: tokenStore);

    final items = await repo.getConsiderations();
    expect(items.length, 2);

    expect(items[0].id, '101');
    expect(items[0].itemName, 'Sepatu Lari Ultraboost');
    expect(items[0].price, 2500000.0);
    expect(items[0].status, ConsiderationStatus.considering);
    expect(items[0].category, ProductCategory.fashion);
    expect(items[0].productUrl, 'https://adidas.com/ultraboost');
    expect(items[0].waitHours, 48);

    expect(items[1].id, '102');
    expect(items[1].itemName, 'Monitor Ultrawide 34 inch');
    expect(items[1].price, 6500000.0);
    expect(items[1].status, ConsiderationStatus.wishlist);
    expect(items[1].category, ProductCategory.electronics);
  });

  test('RemotePurchaseDecisionRepository addConsideration sends correct payload', () async {
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/wishlists');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['item_name'], 'Tablet Grafis Pen');
      expect(body['price'], 1200000);
      expect(body['status'], 'considering');
      expect(body['category'], 'electronics');
      expect(body['reason'], 'Untuk gambar digital');

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Created',
          'data': {
            'id': 105,
            'item_name': 'Tablet Grafis Pen',
            'price': 1200000,
            'status': 'considering',
            'category': 'electronics',
            'reason': 'Untuk gambar digital',
            'created_at': '2026-10-29T11:00:00.000000Z',
          },
        }),
        201,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemotePurchaseDecisionRepository(client: client, tokens: tokenStore);

    final result = await repo.addConsideration(
      PurchaseConsideration(
        id: 'client-temp-id',
        itemName: 'Tablet Grafis Pen',
        price: 1200000,
        status: ConsiderationStatus.considering,
        category: ProductCategory.electronics,
        createdAt: DateTime.now(),
        reason: 'Untuk gambar digital',
      ),
    );

    expect(result.id, '105');
    expect(result.itemName, 'Tablet Grafis Pen');
    expect(result.price, 1200000.0);
    expect(result.status, ConsiderationStatus.considering);
  });

  test('RemotePurchaseDecisionRepository updateConsideration updates status and wait times', () async {
    final now = DateTime.parse('2026-10-29T10:00:00.000Z');
    final ends = now.add(const Duration(hours: 24));

    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/wishlists/105');
      expect(request.method, 'PUT');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['status'], 'wishlist');
      expect(body['wait_hours'], 24);

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Updated',
          'data': {
            'id': 105,
            'item_name': 'Tablet Grafis Pen Pro',
            'price': 1500000,
            'status': 'wishlist',
            'category': 'electronics',
            'wait_hours': 24,
            'wait_started_at': now.toIso8601String(),
            'wait_ends_at': ends.toIso8601String(),
            'created_at': '2026-10-29T11:00:00.000000Z',
          },
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemotePurchaseDecisionRepository(client: client, tokens: tokenStore);

    final updated = await repo.updateConsideration(
      PurchaseConsideration(
        id: '105',
        itemName: 'Tablet Grafis Pen Pro',
        price: 1500000,
        status: ConsiderationStatus.wishlist,
        category: ProductCategory.electronics,
        createdAt: now,
        waitHours: 24,
        waitStartedAt: now,
        waitEndsAt: ends,
      ),
    );

    expect(updated.id, '105');
    expect(updated.status, ConsiderationStatus.wishlist);
    expect(updated.waitHours, 24);
  });

  test('RemotePurchaseDecisionRepository deleteConsideration sends DELETE request', () async {
    bool deleted = false;
    final mockHttp = MockClient((request) async {
      expect(request.url.path, '/api/wishlists/105');
      expect(request.method, 'DELETE');
      deleted = true;

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Wishlist berhasil dihapus',
        }),
        200,
      );
    });

    final client = ApiClient(baseUrl: 'https://api.test/api', httpClient: mockHttp);
    final repo = RemotePurchaseDecisionRepository(client: client, tokens: tokenStore);

    await repo.deleteConsideration('105');
    expect(deleted, isTrue);
  });

  test('RemotePurchaseDecisionRepository triggers onUnauthorized on 401', () async {
    bool unauthorizedCalled = false;
    final mockHttp = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Unauthenticated.'}),
        401,
      );
    });

    final client = ApiClient(
      baseUrl: 'https://api.test/api',
      httpClient: mockHttp,
      onUnauthorized: () {
        unauthorizedCalled = true;
      },
    );
    final repo = RemotePurchaseDecisionRepository(
      client: client,
      tokens: tokenStore,
      onUnauthorized: () {
        unauthorizedCalled = true;
      },
    );

    expect(
      () => repo.getConsiderations(),
      throwsA(isA<ApiException>()),
    );
    await pumpEventQueue();
    expect(unauthorizedCalled, isTrue);
  });
}

