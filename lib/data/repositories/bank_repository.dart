import '../datasources/mock/mock_bank_catalog.dart';
import '../models/api_bank.dart';

/// Repository untuk data katalog bank (dari API Laravel / idn-finlogos).
abstract class BankRepository {
  Future<List<ApiBank>> getBanks({String? search, String? category});
  Future<ApiBank> getBank(String idOrSlug);
}

/// Mock bank repository untuk pengujian offline dan fallback offline mandiri.
/// Menyediakan katalog lengkap 166 penyedia (143 Bank, 18 Bank Digital, 5 E-Wallet).
class MockBankRepository implements BankRepository {
  static final List<ApiBank> _sampleBanks = kMasterBankCatalog;

  @override
  Future<List<ApiBank>> getBanks({String? search, String? category}) async {
    var list = _sampleBanks.where((b) => b.isActive).toList();
    if (category != null && category.trim().isNotEmpty) {
      final cleanCat = category.trim().toLowerCase();
      list = list.where((b) {
        if (cleanCat == 'bank') {
          return b.category.toLowerCase() == 'bank' ||
              b.category.toLowerCase() == 'bank-logo';
        }
        return b.category.toLowerCase() == cleanCat;
      }).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      list = list.where((b) => b.matchesSearch(search)).toList();
    }
    return list;
  }

  @override
  Future<ApiBank> getBank(String idOrSlug) async {
    final clean = idOrSlug.trim();
    try {
      // 1. Coba cocokkan berdasarkan ID atau slug kanonik
      return _sampleBanks.firstWhere(
        (b) => b.id.toString() == clean || b.slug == clean,
        orElse: () => throw Exception('Bank tidak ditemukan'),
      );
    } catch (_) {
      // 2. Fallback: cari melalui alias untuk kompatibilitas mundur dengan
      // slug duplikat yang telah dinonaktifkan (contoh: bri-alt, btn-old)
      return _sampleBanks.firstWhere(
        (b) => b.aliases.any((a) => a.toLowerCase() == clean.toLowerCase()),
        orElse: () => throw Exception('Bank tidak ditemukan'),
      );
    }
  }
}
