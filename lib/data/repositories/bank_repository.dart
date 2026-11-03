import '../models/api_bank.dart';

/// Repository untuk data katalog bank (dari API Laravel / idn-finlogos).
abstract class BankRepository {
  Future<List<ApiBank>> getBanks({String? search, String? category});
  Future<ApiBank> getBank(String idOrSlug);
}

/// Mock bank repository untuk pengujian offline.
class MockBankRepository implements BankRepository {
  static const List<ApiBank> _sampleBanks = [
    ApiBank(
      id: 1,
      slug: 'bca',
      name: 'Bank Central Asia',
      aliases: ['BCA', '014'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
      isActive: true,
    ),
    ApiBank(
      id: 2,
      slug: 'mandiri',
      name: 'Bank Mandiri',
      aliases: ['Mandiri', '008', 'BMRI'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg',
      isActive: true,
    ),
    ApiBank(
      id: 3,
      slug: 'bri',
      name: 'Bank Rakyat Indonesia',
      aliases: ['BRI', '002', 'BBRI'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bri.svg',
      isActive: true,
    ),
    ApiBank(
      id: 4,
      slug: 'bni',
      name: 'Bank Negara Indonesia',
      aliases: ['BNI', '009', 'BBNI'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bni.svg',
      isActive: true,
    ),
    ApiBank(
      id: 5,
      slug: 'jago',
      name: 'Bank Jago',
      aliases: ['Jago', '542', 'ARTO'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/jago.svg',
      isActive: true,
    ),
    ApiBank(
      id: 6,
      slug: 'seabank',
      name: 'SeaBank Indonesia',
      aliases: ['SeaBank', '535', 'Shopee'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/seabank.svg',
      isActive: true,
    ),
  ];

  @override
  Future<List<ApiBank>> getBanks({String? search, String? category}) async {
    var list = _sampleBanks.where((b) => b.isActive).toList();
    if (search != null && search.trim().isNotEmpty) {
      list = list.where((b) => b.matchesSearch(search)).toList();
    }
    return list;
  }

  @override
  Future<ApiBank> getBank(String idOrSlug) async {
    return _sampleBanks.firstWhere(
      (b) => b.id.toString() == idOrSlug || b.slug == idOrSlug,
      orElse: () => throw Exception('Bank tidak ditemukan'),
    );
  }
}

