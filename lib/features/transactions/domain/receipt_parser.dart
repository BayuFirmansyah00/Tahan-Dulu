/// Item rincian barang dari struk belanja.
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String name;
  final double price;
  final int quantity;
}

/// Hasil ekstraksi informasi dari struk belanja.
class ParsedReceipt {
  const ParsedReceipt({
    required this.rawText,
    this.merchantName,
    this.date,
    this.total = 0,
    this.subtotal,
    this.paymentMethod,
    this.items = const [],
  });

  final String rawText;
  final String? merchantName;
  final DateTime? date;
  final double total;
  final double? subtotal;
  final String? paymentMethod;
  final List<ReceiptItem> items;

  bool get hasTotal => total > 0;
  bool get hasMerchant => merchantName != null && merchantName!.trim().isNotEmpty;
}

/// Parser untuk mengekstrak informasi transaksi dari teks struk belanja.
///
/// Aturan TahanDulu:
/// - Jika nominal tidak terbaca, minta pengguna mengisinya (total = 0).
/// - Jangan menganggap subtotal sebagai total pembayaran jika total akhir tersedia.
/// - Jangan membuat kategori atau akun secara sembarangan (dikosongkan agar dipilih pengguna).
class ReceiptParser {
  const ReceiptParser();

  ParsedReceipt parse(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const ParsedReceipt(rawText: '');
    }

    final lines = cleanText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final date = _extractDate(lines);
    final totals = _extractTotals(lines);
    final items = _extractItems(lines);
    final payment = _extractPaymentMethod(lines);

    return ParsedReceipt(
      rawText: cleanText,
      merchantName: merchant,
      date: date,
      total: totals.total,
      subtotal: totals.subtotal,
      paymentMethod: payment,
      items: items,
    );
  }

  String? _extractMerchant(List<String> lines) {
    const skipKeywords = [
      'struk',
      'receipt',
      'selamat datang',
      'terima kasih',
      'welcome',
      'thank you',
      'npwp',
      'jl.',
      'jalan',
      'telp',
      'phone',
      'no.',
      'tgl',
      'tanggal',
      'kasir',
      'pos',
      'trx',
      'order',
    ];

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Abaikan garis pemisah atau simbol
      if (RegExp(r'^[-=*#._\s]+$').hasMatch(line)) continue;

      bool shouldSkip = false;
      for (final kw in skipKeywords) {
        if (lower.startsWith(kw) || lower.contains('jl.') || lower.contains('jalan')) {
          shouldSkip = true;
          break;
        }
      }

      if (!shouldSkip && line.length >= 3) {
        return line;
      }
    }

    return null;
  }

  DateTime? _extractDate(List<String> lines) {
    // Format: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD
    final datePattern = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b');
    final isoPattern = RegExp(r'\b(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b');

    for (final line in lines) {
      final isoMatch = isoPattern.firstMatch(line);
      if (isoMatch != null) {
        final year = int.tryParse(isoMatch.group(1) ?? '');
        final month = int.tryParse(isoMatch.group(2) ?? '');
        final day = int.tryParse(isoMatch.group(3) ?? '');
        if (year != null && month != null && day != null) {
          try {
            return DateTime(year, month, day);
          } catch (_) {}
        }
      }

      final match = datePattern.firstMatch(line);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        var year = int.tryParse(match.group(3) ?? '');
        if (year != null && year < 100) {
          year += 2000;
        }
        if (day != null && month != null && year != null) {
          if (day <= 31 && month <= 12) {
            try {
              return DateTime(year, month, day);
            } catch (_) {}
          }
        }
      }
    }

    return null;
  }

  _TotalResult _extractTotals(List<String> lines) {
    double? subtotal;
    double? total;

    final subtotalKeywords = ['subtotal', 'sub total', 'sub-total'];
    final totalKeywords = [
      'grand total',
      'total bayar',
      'total akhir',
      'jumlah bayar',
      'jumlah total',
      'total',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Cek apakah ini baris subtotal
      bool isSubtotal = false;
      for (final kw in subtotalKeywords) {
        if (lower.contains(kw)) {
          isSubtotal = true;
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0) {
            subtotal = amount;
          }
          break;
        }
      }

      if (isSubtotal) continue;

      // Cek apakah ini baris total akhir (bukan subtotal)
      for (final kw in totalKeywords) {
        if (lower.contains(kw) && !lower.contains('kembalian') && !lower.contains('diskon') && !lower.contains('item')) {
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0) {
            total = amount;
            break;
          }
        }
      }
    }

    // Jika total akhir tidak ditemukan tetapi subtotal ada, jangan langsung asumsikan tanpa konfirmasi pengguna
    return _TotalResult(
      total: total ?? 0,
      subtotal: subtotal,
    );
  }

  double? _parseAmountFromLine(String line) {
    final numberPattern = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+)');
    final matches = numberPattern.allMatches(line).toList();
    if (matches.isEmpty) return null;

    // Ambil angka terakhir di baris tersebut (posisi kolom harga)
    for (int i = matches.length - 1; i >= 0; i--) {
      final text = matches[i].group(0) ?? '';
      final cleaned = text.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(cleaned);
      if (val != null && val >= 100) {
        return val;
      }
    }

    return null;
  }

  List<ReceiptItem> _extractItems(List<String> lines) {
    final List<ReceiptItem> items = [];
    final itemPattern = RegExp(r'^(.+?)\s+(\d{1,3}(?:[.,]\d{3})*|\d+)$');

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('tunai') ||
          lower.contains('kembali') ||
          lower.contains('diskon') ||
          RegExp(r'^[-=*#._\s]+$').hasMatch(line)) {
        continue;
      }

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim();
        final rawPrice = match.group(2)?.replaceAll('.', '').replaceAll(',', '');
        final price = double.tryParse(rawPrice ?? '');
        if (name != null && name.length >= 2 && price != null && price > 0) {
          items.add(ReceiptItem(name: name, price: price));
        }
      }
    }

    return items;
  }

  String? _extractPaymentMethod(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('qris')) return 'QRIS';
      if (lower.contains('tunai') || lower.contains('cash')) return 'Tunai';
      if (lower.contains('bca')) return 'BCA';
      if (lower.contains('mandiri')) return 'Mandiri';
      if (lower.contains('debit')) return 'Kartu Debit';
      if (lower.contains('kredit') || lower.contains('credit')) return 'Kartu Kredit';
      if (lower.contains('gopay')) return 'GoPay';
      if (lower.contains('ovo')) return 'OVO';
      if (lower.contains('shopeepay')) return 'ShopeePay';
    }
    return null;
  }
}

class _TotalResult {
  const _TotalResult({required this.total, this.subtotal});
  final double total;
  final double? subtotal;
}
