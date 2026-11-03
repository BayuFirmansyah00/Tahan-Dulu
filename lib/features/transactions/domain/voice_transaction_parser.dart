import '../../../../data/models/financial_account.dart';
import '../../../../data/models/transaction_model.dart';

/// Hasil parsing suara ke struktur transaksi TahanDulu.
class ParsedVoiceTransaction {
  const ParsedVoiceTransaction({
    required this.rawText,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
    this.accountId,
    this.accountName,
  });

  final String rawText;
  final TransactionType type;
  final double amount;
  final String description;
  final TransactionCategory? category;
  final String? accountId;
  final String? accountName;

  bool get hasAmount => amount > 0;
  bool get hasCategory => category != null;
  bool get hasAccount => accountId != null;
}

/// Parser semantik untuk mengubah ucapan bahasa Indonesia menjadi
/// detail transaksi terstruktur.
///
/// Contoh: "Makan siang dua puluh lima ribu menggunakan BCA"
/// -> Type: expense
/// -> Amount: 25000
/// -> Description: "Makan siang"
/// -> Category: food
/// -> Account: BCA
class VoiceTransactionParser {
  const VoiceTransactionParser();

  /// Parse teks masukan suara menjadi objek [ParsedVoiceTransaction].
  ParsedVoiceTransaction parse(
    String input, {
    List<FinancialAccount> userAccounts = const [],
  }) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return const ParsedVoiceTransaction(
        rawText: '',
        type: TransactionType.expense,
        amount: 0,
        description: '',
      );
    }

    final lower = cleanInput.toLowerCase();

    // 1. Deteksi Jenis Transaksi (Income vs Expense)
    final type = _detectType(lower);

    // 2. Deteksi Nominal
    final amount = _detectAmount(lower);

    // 3. Deteksi Akun Pengguna
    final matchedAccount = _detectAccount(lower, userAccounts);

    // 4. Deteksi Kategori
    final category = _detectCategory(lower, type);

    // 5. Ekstraksi Deskripsi Bersih
    final description = _extractDescription(
      cleanInput,
      matchedAccount: matchedAccount,
    );

    return ParsedVoiceTransaction(
      rawText: cleanInput,
      type: type,
      amount: amount,
      description: description,
      category: category,
      accountId: matchedAccount?.id,
      accountName: matchedAccount?.name,
    );
  }

  TransactionType _detectType(String text) {
    const incomeKeywords = [
      'gaji',
      'gajian',
      'penghasilan',
      'terima uang',
      'terima transfer',
      'transfer masuk',
      'pemasukan',
      'dapat uang',
      'bonus',
      'thr',
      'dividen',
      'hasil jualan',
      'uang masuk',
    ];

    for (final kw in incomeKeywords) {
      if (text.contains(kw)) {
        return TransactionType.income;
      }
    }

    return TransactionType.expense;
  }

  double _detectAmount(String text) {
    // 1. Coba pola angka langsung seperti "25000", "25.000", "25,000", "Rp 25.000"
    final directPattern = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?|\d+)(?:\s*(k|rb|ribu|jt|juta))?',
      caseSensitive: false,
    );

    for (final match in directPattern.allMatches(text)) {
      final rawNum = match.group(1);
      final suffix = match.group(2)?.toLowerCase();
      if (rawNum != null) {
        String cleaned = rawNum.replaceAll('.', '').replaceAll(',', '');
        double? val = double.tryParse(cleaned);
        if (val != null && val > 0) {
          if (suffix == 'k' || suffix == 'rb' || suffix == 'ribu') {
            val *= 1000;
          } else if (suffix == 'jt' || suffix == 'juta') {
            val *= 1000000;
          }
          if (val > 100) {
            return val;
          }
        }
      }
    }

    // 2. Coba angka pecahan dengan juta (mis: "1.5 juta", "2,5 juta", "dua setengah juta")
    final decimalJuta = RegExp(r'(\d+)[.,](\d+)\s*(?:jt|juta)');
    final mJt = decimalJuta.firstMatch(text);
    if (mJt != null) {
      final integerPart = double.tryParse(mJt.group(1) ?? '0') ?? 0;
      final decimalPart = double.tryParse(mJt.group(2) ?? '0') ?? 0;
      final total = (integerPart + (decimalPart / 10)) * 1000000;
      if (total > 0) return total;
    }

    // 3. Konversi kata-kata angka bahasa Indonesia
    return _parseIndonesianWords(text);
  }

  double _parseIndonesianWords(String text) {
    // Map angka satuan & belasan
    const wordNumbers = {
      'satu': 1,
      'se': 1,
      'dua': 2,
      'tiga': 3,
      'empat': 4,
      'lima': 5,
      'enam': 6,
      'tujuh': 7,
      'delapan': 8,
      'sembilan': 9,
      'sepuluh': 10,
      'sebelas': 11,
      'seratus': 100,
      'seribu': 1000,
      'sejuta': 1000000,
    };

    final tokens = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    double total = 0;
    double current = 0;
    bool foundNumber = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == 'setengah' &&
          i + 1 < tokens.length &&
          tokens[i + 1] == 'juta') {
        current += 0.5;
        foundNumber = true;
        continue;
      }

      if (wordNumbers.containsKey(token)) {
        current += wordNumbers[token]!;
        foundNumber = true;
      } else if (token == 'belas') {
        current += 10;
        foundNumber = true;
      } else if (token == 'puluh') {
        current = (current == 0 ? 1 : current) * 10;
        foundNumber = true;
      } else if (token == 'ratus') {
        current = (current == 0 ? 1 : current) * 100;
        foundNumber = true;
      } else if (token == 'ribu') {
        current = (current == 0 ? 1 : current) * 1000;
        total += current;
        current = 0;
        foundNumber = true;
      } else if (token == 'juta') {
        current = (current == 0 ? 1 : current) * 1000000;
        total += current;
        current = 0;
        foundNumber = true;
      } else {
        final parsed = double.tryParse(token);
        if (parsed != null) {
          current += parsed;
          foundNumber = true;
        }
      }
    }

    total += current;
    return foundNumber ? total : 0;
  }

  FinancialAccount? _detectAccount(
    String text,
    List<FinancialAccount> userAccounts,
  ) {
    if (userAccounts.isEmpty) return null;

    FinancialAccount? bestMatch;
    int maxLen = 0;

    for (final account in userAccounts) {
      final name = account.name.toLowerCase().trim();
      final inst = (account.institutionName ?? '').toLowerCase().trim();

      if (name.isNotEmpty && _containsWord(text, name)) {
        if (name.length > maxLen) {
          maxLen = name.length;
          bestMatch = account;
        }
      } else if (inst.isNotEmpty && _containsWord(text, inst)) {
        if (inst.length > maxLen) {
          maxLen = inst.length;
          bestMatch = account;
        }
      }
    }

    return bestMatch;
  }

  bool _containsWord(String text, String target) {
    return RegExp('\\b${RegExp.escape(target)}\\b').hasMatch(text);
  }

  TransactionCategory? _detectCategory(String text, TransactionType type) {
    if (type == TransactionType.income) {
      if (text.contains('gaji') ||
          text.contains('salary') ||
          text.contains('upah')) {
        return TransactionCategory.salary;
      }
      if (text.contains('bonus') ||
          text.contains('hadiah') ||
          text.contains('thr') ||
          text.contains('dividen')) {
        return TransactionCategory.bonus;
      }
      return null;
    }

    // Expense categories
    if (text.contains('makan') ||
        text.contains('siang') ||
        text.contains('malam') ||
        text.contains('sarapan') ||
        text.contains('minum') ||
        text.contains('kopi') ||
        text.contains('cafe') ||
        text.contains('restoran') ||
        text.contains('resto') ||
        text.contains('warteg') ||
        text.contains('ayam') ||
        text.contains('bakso') ||
        text.contains('jajan') ||
        text.contains('snack')) {
      return TransactionCategory.food;
    }

    if (text.contains('bensin') ||
        text.contains('pertalite') ||
        text.contains('pertamax') ||
        text.contains('gojek') ||
        text.contains('grab') ||
        text.contains('ojol') ||
        text.contains('parkir') ||
        text.contains('tol') ||
        text.contains('angkot') ||
        text.contains('kereta') ||
        text.contains('krl') ||
        text.contains('mrt') ||
        text.contains('bus') ||
        text.contains('tiket')) {
      return TransactionCategory.transport;
    }

    if (text.contains('listrik') ||
        text.contains('pln') ||
        text.contains('air') ||
        text.contains('pdam') ||
        text.contains('internet') ||
        text.contains('wifi') ||
        text.contains('indihome') ||
        text.contains('pulsa') ||
        text.contains('kuota') ||
        text.contains('bpjs') ||
        text.contains('sewa') ||
        text.contains('kos') ||
        text.contains('kontrakan')) {
      return TransactionCategory.bills;
    }

    if (text.contains('buku') ||
        text.contains('kursus') ||
        text.contains('kuliah') ||
        text.contains('sekolah') ||
        text.contains('spp') ||
        text.contains('les') ||
        text.contains('seminar')) {
      return TransactionCategory.education;
    }

    if (text.contains('belanja') ||
        text.contains('baju') ||
        text.contains('sepatu') ||
        text.contains('tas') ||
        text.contains('supermarket') ||
        text.contains('indomaret') ||
        text.contains('alfamart') ||
        text.contains('tokopedia') ||
        _containsWord(text, 'shopee') ||
        text.contains('mall')) {
      return TransactionCategory.shopping;
    }

    if (text.contains('nonton') ||
        text.contains('bioskop') ||
        text.contains('cinema') ||
        text.contains('game') ||
        text.contains('steam') ||
        text.contains('netflix') ||
        text.contains('spotify') ||
        text.contains('hiburan') ||
        text.contains('konser') ||
        text.contains('liburan')) {
      return TransactionCategory.entertainment;
    }

    if (text.contains('obat') ||
        text.contains('apotek') ||
        text.contains('dokter') ||
        text.contains('rumah sakit') ||
        text.contains('klinik') ||
        text.contains('vitamin')) {
      return TransactionCategory.others;
    }

    return null;
  }

  String _extractDescription(String raw, {FinancialAccount? matchedAccount}) {
    String desc = raw;

    // Bersihkan tanda baca di akhir
    desc = desc.replaceAll(RegExp(r'[.!?,]+$'), '').trim();

    // Hapus bagian akun jika disebutkan
    if (matchedAccount != null) {
      desc = desc.replaceAll(
        RegExp(
          '\\b(menggunakan|pakai|lewat|dengan|ke|di)?\\s*${RegExp.escape(matchedAccount.name)}\\b',
          caseSensitive: false,
        ),
        '',
      );
      if (matchedAccount.institutionName != null &&
          matchedAccount.institutionName!.isNotEmpty) {
        desc = desc.replaceAll(
          RegExp(
            '\\b(menggunakan|pakai|lewat|dengan|ke|di)?\\s*${RegExp.escape(matchedAccount.institutionName!)}\\b',
            caseSensitive: false,
          ),
          '',
        );
      }
    }

    // Hapus frasa angka umum di Indonesia
    final numberPhrases = [
      RegExp(
        r'\b(sebesar|senilai|rp\.?|rupiah)?\s*(\d{1,3}(?:[.,]\d{3})*|\d+)\s*(ribu|k|rb|juta|jt)?\s*(rupiah)?\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|belas|puluh|ratus|ribu|juta|setengah)+\s*(rupiah)?\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(menggunakan|pakai|lewat|dengan|via|sebesar|senilai|rupiah)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in numberPhrases) {
      desc = desc.replaceAll(pattern, ' ');
    }

    // Rapikan spasi berlebih
    desc = desc.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (desc.isEmpty) {
      return 'Transaksi';
    }

    // Kapitalisasi huruf pertama
    return desc[0].toUpperCase() + desc.substring(1);
  }
}
