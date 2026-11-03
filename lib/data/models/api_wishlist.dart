import 'package:equatable/equatable.dart';
import 'purchase_consideration.dart';

/// Model respons Wishlist / Tahan Dulu dari backend Laravel.
class ApiWishlist extends Equatable {
  const ApiWishlist({
    required this.id,
    required this.itemName,
    required this.title,
    required this.price,
    this.estimatedPrice,
    required this.status,
    required this.category,
    this.productUrl,
    this.link,
    this.imageRef,
    this.reason,
    this.note,
    this.priority,
    this.waitHours,
    this.waitStartedAt,
    this.waitEndsAt,
    this.isWaiting,
    this.remainingWaitSeconds,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String itemName;
  final String title;
  final double price;
  final int? estimatedPrice;
  final String status;
  final String category;
  final String? productUrl;
  final String? link;
  final String? imageRef;
  final String? reason;
  final String? note;
  final String? priority;
  final int? waitHours;
  final String? waitStartedAt;
  final String? waitEndsAt;
  final bool? isWaiting;
  final int? remainingWaitSeconds;
  final String? createdAt;
  final String? updatedAt;

  factory ApiWishlist.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? json['estimated_price'] ?? 0;
    final priceVal = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse('$rawPrice') ?? 0.0;

    final rawEstimated = json['estimated_price'] ?? json['price'];
    final estimatedVal = rawEstimated is num
        ? rawEstimated.toInt()
        : int.tryParse('$rawEstimated');

    final name = '${json['item_name'] ?? json['title'] ?? ''}';

    return ApiWishlist(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      itemName: name,
      title: '${json['title'] ?? name}',
      price: priceVal,
      estimatedPrice: estimatedVal,
      status: '${json['status'] ?? 'considering'}',
      category: '${json['category'] ?? 'others'}',
      productUrl: json['product_url'] as String? ?? json['link'] as String?,
      link: json['link'] as String? ?? json['product_url'] as String?,
      imageRef: json['image_ref'] as String?,
      reason: json['reason'] as String? ?? json['note'] as String?,
      note: json['note'] as String? ?? json['reason'] as String?,
      priority: json['priority'] != null ? '${json['priority']}' : null,
      waitHours: json['wait_hours'] is int
          ? json['wait_hours'] as int
          : int.tryParse('${json['wait_hours']}'),
      waitStartedAt: json['wait_started_at'] as String?,
      waitEndsAt: json['wait_ends_at'] as String?,
      isWaiting: json['is_waiting'] as bool?,
      remainingWaitSeconds: json['remaining_wait_seconds'] is int
          ? json['remaining_wait_seconds'] as int
          : int.tryParse('${json['remaining_wait_seconds']}'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'title': title,
      'price': price.round(),
      'estimated_price': estimatedPrice ?? price.round(),
      'status': status,
      'category': category,
      'product_url': productUrl,
      'link': link,
      'image_ref': imageRef,
      'reason': reason,
      'note': note,
      'priority': priority,
      'wait_hours': waitHours,
      'wait_started_at': waitStartedAt,
      'wait_ends_at': waitEndsAt,
      'is_waiting': isWaiting,
      'remaining_wait_seconds': remainingWaitSeconds,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime? get parsedCreatedAt {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedWaitStartedAt {
    if (waitStartedAt == null) return null;
    try {
      return DateTime.parse(waitStartedAt!);
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedWaitEndsAt {
    if (waitEndsAt == null) return null;
    try {
      return DateTime.parse(waitEndsAt!);
    } catch (_) {
      return null;
    }
  }

  static ConsiderationStatus toConsiderationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'wishlist':
        return ConsiderationStatus.wishlist;
      case 'bought':
        return ConsiderationStatus.bought;
      case 'cancelled':
        return ConsiderationStatus.cancelled;
      case 'considering':
      default:
        return ConsiderationStatus.considering;
    }
  }

  static ProductCategory toProductCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'fashion':
        return ProductCategory.fashion;
      case 'electronics':
        return ProductCategory.electronics;
      case 'food':
        return ProductCategory.food;
      case 'transport':
        return ProductCategory.transport;
      case 'entertainment':
        return ProductCategory.entertainment;
      case 'household':
        return ProductCategory.household;
      case 'education':
        return ProductCategory.education;
      case 'others':
      default:
        return ProductCategory.others;
    }
  }

  PurchaseConsideration toPurchaseConsideration() {
    return PurchaseConsideration(
      id: id.toString(),
      itemName: itemName.isNotEmpty ? itemName : title,
      price: price,
      status: toConsiderationStatus(status),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      reason: reason ?? note,
      category: toProductCategory(category),
      productUrl: productUrl ?? link,
      imageRef: imageRef,
      waitHours: waitHours,
      waitStartedAt: parsedWaitStartedAt,
      waitEndsAt: parsedWaitEndsAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemName,
        title,
        price,
        estimatedPrice,
        status,
        category,
        productUrl,
        link,
        imageRef,
        reason,
        note,
        priority,
        waitHours,
        waitStartedAt,
        waitEndsAt,
        isWaiting,
        remainingWaitSeconds,
        createdAt,
        updatedAt,
      ];
}

/// Envelope respons satu wishlist: {success, message, data: {...}}.
class ApiWishlistResponse extends Equatable {
  const ApiWishlistResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final ApiWishlist data;

  factory ApiWishlistResponse.fromJson(Map<String, dynamic> json) {
    return ApiWishlistResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: ApiWishlist.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Envelope respons daftar wishlist: {success, message, data: [...]}.
class ApiWishlistsResponse extends Equatable {
  const ApiWishlistsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final List<ApiWishlist> data;

  factory ApiWishlistsResponse.fromJson(Map<String, dynamic> json) {
    return ApiWishlistsResponse(
      success: json['success'] as bool? ?? false,
      message: '${json['message'] ?? ''}',
      data: (json['data'] as List? ?? const [])
          .map((item) => ApiWishlist.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

