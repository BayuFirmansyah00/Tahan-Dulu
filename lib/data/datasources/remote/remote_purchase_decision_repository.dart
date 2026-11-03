import '../../../data/models/api_wishlist.dart';
import '../../../data/models/purchase_consideration.dart';
import '../../../data/repositories/repositories.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [PurchaseDecisionRepository] yang terhubung ke backend Laravel (/api/wishlists).
class RemotePurchaseDecisionRepository implements PurchaseDecisionRepository {
  RemotePurchaseDecisionRepository({
    required this.client,
    required this.tokens,
    this.onUnauthorized,
  });

  final ApiClient client;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  Future<String> _requireToken() async {
    final token = await tokens.readToken();
    if (token == null || token.isEmpty) {
      onUnauthorized?.call();
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  @override
  Future<List<PurchaseConsideration>> getConsiderations() async {
    final token = await _requireToken();
    final body = await client.get('/wishlists', token: token);
    final response = ApiWishlistsResponse.fromJson(body);
    return response.data.map((e) => e.toPurchaseConsideration()).toList();
  }

  @override
  Future<PurchaseConsideration> addConsideration(
    PurchaseConsideration item,
  ) async {
    final token = await _requireToken();
    final payload = {
      'item_name': item.itemName,
      'title': item.itemName,
      'price': item.price.round(),
      'status': item.status.name,
      'category': item.category.name,
      if (item.productUrl != null && item.productUrl!.isNotEmpty)
        'product_url': item.productUrl,
      if (item.imageRef != null && item.imageRef!.isNotEmpty)
        'image_ref': item.imageRef,
      if (item.reason != null && item.reason!.isNotEmpty)
        'reason': item.reason,
      if (item.waitHours != null && item.waitHours! > 0)
        'wait_hours': item.waitHours,
      if (item.waitStartedAt != null)
        'wait_started_at': item.waitStartedAt!.toIso8601String(),
      if (item.waitEndsAt != null)
        'wait_ends_at': item.waitEndsAt!.toIso8601String(),
    };

    final body = await client.post('/wishlists', payload, token: token);
    final response = ApiWishlistResponse.fromJson(body);
    return response.data.toPurchaseConsideration();
  }

  @override
  Future<PurchaseConsideration> updateConsideration(
    PurchaseConsideration item,
  ) async {
    final token = await _requireToken();
    final payload = {
      'item_name': item.itemName,
      'title': item.itemName,
      'price': item.price.round(),
      'status': item.status.name,
      'category': item.category.name,
      'product_url': item.productUrl,
      'image_ref': item.imageRef,
      'reason': item.reason,
      'wait_hours': item.waitHours,
      'wait_started_at': item.waitStartedAt?.toIso8601String(),
      'wait_ends_at': item.waitEndsAt?.toIso8601String(),
    };

    final body = await client.put('/wishlists/${item.id}', payload, token: token);
    final response = ApiWishlistResponse.fromJson(body);
    return response.data.toPurchaseConsideration();
  }

  @override
  Future<void> deleteConsideration(String id) async {
    final token = await _requireToken();
    await client.delete('/wishlists/$id', token: token);
  }

  @override
  void clear() {
    // Stateless remote repository tidak menyimpan cache in-memory yang persisten.
  }
}
