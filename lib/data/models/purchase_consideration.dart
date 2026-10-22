import 'package:equatable/equatable.dart';

/// Status pertimbangan pembelian di fitur TahanDulu.
/// Tab: Menunggu (considering), Wishlist (wishlist),
/// Selesai (bought, cancelled).
enum ConsiderationStatus { considering, wishlist, bought, cancelled }

/// Kategori produk TahanDulu (taksonomi produk, berbeda dari kategori
/// transaksi maupun pengeluaran rutin).
enum ProductCategory {
  fashion,
  electronics,
  food,
  transport,
  entertainment,
  household,
  education,
  others,
}

/// Item "TahanDulu" — pembelian yang ditahan untuk dipikirkan dulu.
///
/// Aturan waktu (terdokumentasi): masa tunggu disimpan eksplisit sebagai
/// [waitStartedAt]/[waitEndsAt]; sisa waktu selalu dihitung dari timestamp
/// (bukan timer layar) sehingga konsisten saat dibuka ulang.
class PurchaseConsideration extends Equatable {
  const PurchaseConsideration({
    required this.id,
    required this.itemName,
    required this.price,
    required this.status,
    required this.createdAt,
    this.reason,
    this.category = ProductCategory.others,
    this.productUrl,
    this.imageRef,
    this.waitHours,
    this.waitStartedAt,
    this.waitEndsAt,
  });

  final String id;
  final String itemName;
  final double price;
  final ConsiderationStatus status;
  final DateTime createdAt;
  final String? reason;
  final ProductCategory category;

  /// URL produk opsional (referensi, tanpa klaim scraping).
  final String? productUrl;

  /// Referensi gambar: URL http(s) atau path file lokal.
  final String? imageRef;

  /// Durasi tunggu jam (24/48/168) bila masa tunggu dimulai.
  final int? waitHours;
  final DateTime? waitStartedAt;
  final DateTime? waitEndsAt;

  /// Status final: keputusan sudah diambil.
  bool get isFinal =>
      status == ConsiderationStatus.bought ||
      status == ConsiderationStatus.cancelled;

  /// Masa tunggu sedang berjalan (ada batas akhir di masa depan).
  bool isWaitingAt(DateTime now) =>
      waitEndsAt != null && waitEndsAt!.isAfter(now);

  PurchaseConsideration copyWith({
    String? id,
    String? itemName,
    double? price,
    ConsiderationStatus? status,
    DateTime? createdAt,
    String? reason,
    ProductCategory? category,
    String? productUrl,
    String? imageRef,
    int? waitHours,
    DateTime? waitStartedAt,
    DateTime? waitEndsAt,
  }) {
    return PurchaseConsideration(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      productUrl: productUrl ?? this.productUrl,
      imageRef: imageRef ?? this.imageRef,
      waitHours: waitHours ?? this.waitHours,
      waitStartedAt: waitStartedAt ?? this.waitStartedAt,
      waitEndsAt: waitEndsAt ?? this.waitEndsAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemName,
        price,
        status,
        createdAt,
        reason,
        category,
        productUrl,
        imageRef,
        waitHours,
        waitStartedAt,
        waitEndsAt,
      ];
}
