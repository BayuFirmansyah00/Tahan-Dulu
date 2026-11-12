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
    this.date,
  });

  final String rawText;
  final TransactionType type;
  final double amount;
  final String description;
  final TransactionCategory? category;
  final String? accountId;
  final String? accountName;
  final DateTime? date;

  bool get hasAmount => amount > 0;
  bool get hasCategory => category != null;
  bool get hasAccount => accountId != null;
  bool get hasDate => date != null;
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
  const VoiceTransactionParser({this.clock});

  /// Injeksi referensi waktu untuk pengujian deterministik
  final DateTime Function()? clock;

  DateTime get _now => clock?.call() ?? DateTime.now();

  /// Parse teks masukan suara menjadi objek [ParsedVoiceTransaction].
  ParsedVoiceTransaction parse(
    String input, {
    List<FinancialAccount> userAccounts = const [],
    DateTime? referenceDate,
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
    final now = referenceDate ?? _now;

    // 1. Deteksi Tanggal (Relatif atau Eksplisit)
    final dateMatch = _detectDate(lower, now);

    // Bersihkan teks tanggal dari pendeteksian nominal agar angka pada tanggal (misal "tanggal 5")
    // tidak keliru dianggap sebagai bagian dari nominal transaksi.
    var textForAmount = lower;
    if (dateMatch != null && dateMatch.matchedText.isNotEmpty) {
      textForAmount = textForAmount.replaceAll(dateMatch.matchedText.toLowerCase(), ' ');
    }

    // 2. Deteksi Jenis Transaksi (Income vs Expense)
    final type = _detectType(lower);

    // 3. Deteksi Nominal
    final amount = _detectAmount(textForAmount);

    // 4. Deteksi Akun Pengguna
    final matchedAccount = _detectAccount(lower, userAccounts);

    // 5. Deteksi Kategori
    final category = _detectCategory(lower, type);

    // 6. Ekstraksi Deskripsi Bersih (bersihkan akun, angka, dan frasa tanggal)
    final description = _extractDescription(
      cleanInput,
      matchedAccount: matchedAccount,
      datePhrase: dateMatch?.matchedText,
    );

    return ParsedVoiceTransaction(
      rawText: cleanInput,
      type: type,
      amount: amount,
      description: description,
      category: category,
      accountId: matchedAccount?.id,
      accountName: matchedAccount?.name,
      date: dateMatch?.date,
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
      'dapat transfer',
      'dapat kiriman',
      'ditransfer',
      'transferan',
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
    const units = {
      'satu': 1.0,
      'se': 1.0,
      'dua': 2.0,
      'tiga': 3.0,
      'empat': 4.0,
      'lima': 5.0,
      'enam': 6.0,
      'tujuh': 7.0,
      'delapan': 8.0,
      'sembilan': 9.0,
      'sepuluh': 10.0,
      'sebelas': 11.0,
    };

    final tokens = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    double total = 0;
    double currentGroup = 0;
    double currentUnit = 0;
    bool foundNumber = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == 'seratus') {
        currentGroup += 100;
        currentUnit = 0;
        foundNumber = true;
        continue;
      }

      if (token == 'seribu') {
        currentGroup += currentUnit;
        currentUnit = 0;
        if (currentGroup == 0) {
          total += 1000;
        } else {
          total += currentGroup * 1000;
          currentGroup = 0;
        }
        foundNumber = true;
        continue;
      }

      if (token == 'sejuta') {
        currentGroup += currentUnit;
        currentUnit = 0;
        total += (currentGroup == 0 ? 1 : currentGroup) * 1000000;
        currentGroup = 0;
        foundNumber = true;
        continue;
      }

      if (token == 'setengah') {
        if (i + 1 < tokens.length && tokens[i + 1] == 'juta') {
          currentUnit += 0.5;
          foundNumber = true;
          continue;
        }
      }

      if (units.containsKey(token)) {
        currentUnit += units[token]!;
        foundNumber = true;
      } else if (token == 'belas') {
        final val = (currentUnit == 0 ? 10.0 : currentUnit + 10.0);
        currentGroup += val;
        currentUnit = 0;
        foundNumber = true;
      } else if (token == 'puluh') {
        final val = (currentUnit == 0 ? 1.0 : currentUnit) * 10;
        currentGroup += val;
        currentUnit = 0;
        foundNumber = true;
      } else if (token == 'ratus') {
        final val = (currentUnit == 0 ? 1.0 : currentUnit) * 100;
        currentGroup += val;
        currentUnit = 0;
        foundNumber = true;
      } else if (token == 'ribu') {
        currentGroup += currentUnit;
        currentUnit = 0;
        final multiplier = (currentGroup == 0 ? 1.0 : currentGroup);
        total += multiplier * 1000;
        currentGroup = 0;
        foundNumber = true;
      } else if (token == 'juta') {
        currentGroup += currentUnit;
        currentUnit = 0;
        final multiplier = (currentGroup == 0 ? 1.0 : currentGroup);
        total += multiplier * 1000000;
        currentGroup = 0;
        foundNumber = true;
      } else {
        final parsed = double.tryParse(token);
        if (parsed != null) {
          currentUnit += parsed;
          foundNumber = true;
        }
      }
    }

    currentGroup += currentUnit;
    total += currentGroup;
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

  _VoiceDateMatch? _detectDate(String lower, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    // 1. Tanggal Relatif (prioritas multi-kata terlebih dahulu)
    if (lower.contains('kemarin dulu') || lower.contains('kemarin lusa')) {
      final match = RegExp(r'\b(kemarin dulu|kemarin lusa)\b').firstMatch(lower);
      return _VoiceDateMatch(
        date: today.subtract(const Duration(days: 2)),
        matchedText: match?.group(0) ?? 'kemarin lusa',
      );
    }
    if (lower.contains('kemarin')) {
      final match = RegExp(r'\bkemarin\b').firstMatch(lower);
      return _VoiceDateMatch(
        date: today.subtract(const Duration(days: 1)),
        matchedText: match?.group(0) ?? 'kemarin',
      );
    }
    if (lower.contains('hari ini')) {
      final match = RegExp(r'\bhari ini\b').firstMatch(lower);
      return _VoiceDateMatch(
        date: today,
        matchedText: match?.group(0) ?? 'hari ini',
      );
    }
    final tadiMatch = RegExp(r'\b(tadi pagi|tadi siang|tadi sore|tadi malam|tadi)\b').firstMatch(lower);
    if (tadiMatch != null) {
      return _VoiceDateMatch(
        date: today,
        matchedText: tadiMatch.group(0)!,
      );
    }
    if (lower.contains('lusa')) {
      final match = RegExp(r'\blusa\b').firstMatch(lower);
      return _VoiceDateMatch(
        date: today.add(const Duration(days: 2)),
        matchedText: match?.group(0) ?? 'lusa',
      );
    }
    if (lower.contains('besok')) {
      final match = RegExp(r'\bbesok\b').firstMatch(lower);
      return _VoiceDateMatch(
        date: today.add(const Duration(days: 1)),
        matchedText: match?.group(0) ?? 'besok',
      );
    }

    // 2. Tanggal Eksplisit Kalender: "tanggal 5 november", "5 nov 2026", "tgl 12 oktober"
    const monthMap = <String, int>{
      'januari': 1, 'jan': 1,
      'februari': 2, 'feb': 2,
      'maret': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'mei': 5, 'may': 5,
      'juni': 6, 'jun': 6,
      'juli': 7, 'jul': 7,
      'agustus': 8, 'agt': 8, 'ags': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'oktober': 10, 'okt': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'desember': 12, 'des': 12, 'dec': 12,
    };

    final explicitPattern = RegExp(
      r'\b(?:tanggal|tgl)?\s*(\d{1,2})\s+([a-zA-Z]{3,10})(?:\s+(20\d{2}|\d{2}))?\b',
      caseSensitive: false,
    );
    final match = explicitPattern.firstMatch(lower);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final monthName = match.group(2)?.toLowerCase() ?? '';
      var year = int.tryParse(match.group(3) ?? '');
      if (year != null && year < 100) year += 2000;
      year ??= now.year;

      final month = monthMap[monthName];
      if (day != null && month != null && day >= 1 && day <= 31) {
        try {
          final dt = DateTime(year, month, day);
          if (dt.year == year && dt.month == month && dt.day == day) {
            return _VoiceDateMatch(
              date: dt,
              matchedText: match.group(0)!,
            );
          }
        } catch (_) {}
      }
    }

    return null;
  }

  String _extractDescription(
    String raw, {
    FinancialAccount? matchedAccount,
    String? datePhrase,
  }) {
    String desc = raw;

    // Bersihkan tanda baca di akhir
    desc = desc.replaceAll(RegExp(r'[.!?,]+$'), '').trim();

    // Hapus frasa tanggal yang terdeteksi
    if (datePhrase != null && datePhrase.isNotEmpty) {
      desc = desc.replaceAll(
        RegExp('\\b${RegExp.escape(datePhrase)}\\b', caseSensitive: false),
        '',
      );
    }
    // Bersihkan juga kata penunjuk tanggal umum jika masih tersisa di awal kalimat
    desc = desc.replaceAll(
      RegExp(r'^(kemarin dulu|kemarin lusa|kemarin|hari ini|tadi pagi|tadi siang|tadi sore|tadi malam|tadi|besok|lusa)\b\s*', caseSensitive: false),
      '',
    );

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

class _VoiceDateMatch {
  const _VoiceDateMatch({required this.date, required this.matchedText});
  final DateTime date;
  final String matchedText;
}
