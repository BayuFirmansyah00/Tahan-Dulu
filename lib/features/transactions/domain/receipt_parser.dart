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
    this.time,
    this.total = 0,
    this.subtotal,
    this.discount,
    this.tax,
    this.serviceFee,
    this.paymentMethod,
    this.items = const [],
    this.hasMultipleTotals = false,
  });

  final String rawText;
  final String? merchantName;
  final DateTime? date;
  final String? time;
  final double total;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? serviceFee;
  final String? paymentMethod;
  final List<ReceiptItem> items;
  final bool hasMultipleTotals;

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
    final dateResult = _extractDate(lines);
    final totals = _extractTotals(lines);
    final items = _extractItems(lines);
    final payment = _extractPaymentMethod(lines);

    return ParsedReceipt(
      rawText: cleanText,
      merchantName: merchant,
      date: dateResult.date,
      time: dateResult.time,
      total: totals.total,
      subtotal: totals.subtotal,
      discount: totals.discount,
      tax: totals.tax,
      serviceFee: totals.serviceFee,
      hasMultipleTotals: totals.hasMultipleTotals,
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

  _ReceiptDateResult _extractDate(List<String> lines) {
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

    // 1. Pola ISO YYYY-MM-DD atau YYYY/MM/DD
    final isoPattern = RegExp(r'\b(20\d{2})[\/\-](\d{1,2})[\/\-](\d{1,2})\b');

    // 2. Pola teks bulan: DD [NamaBulan] YYYY atau DD-[NamaBulan]-YYYY (misal: 05 Nov 2026, 05 November 2026)
    final textMonthPattern = RegExp(
      r'\b(\d{1,2})[\s\-]+([a-zA-Z]{3,10})[\s\-]+(20\d{2}|\d{2})\b',
      caseSensitive: false,
    );

    // 3. Pola numerik standar: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    final numericPattern = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](20\d{2}|\d{2})\b');

    final timePattern = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)(?:[:.]([0-5]\d))?\b');

    DateTime? foundDate;
    String? foundTime;

    for (final line in lines) {
      if (foundDate == null) {
        // Prioritas 1: Format ISO (YYYY-MM-DD)
        final isoMatch = isoPattern.firstMatch(line);
        if (isoMatch != null) {
          final year = int.tryParse(isoMatch.group(1) ?? '');
          final month = int.tryParse(isoMatch.group(2) ?? '');
          final day = int.tryParse(isoMatch.group(3) ?? '');
          final validDate = _validateCalendarDate(year, month, day);
          if (validDate != null) {
            foundDate = validDate;
          }
        }

        // Prioritas 2: Format dengan nama/singkatan bulan (05 Nov 2026, 05 Oktober 2026)
        if (foundDate == null) {
          final textMatch = textMonthPattern.firstMatch(line);
          if (textMatch != null) {
            final day = int.tryParse(textMatch.group(1) ?? '');
            final monthName = textMatch.group(2)?.toLowerCase() ?? '';
            var year = int.tryParse(textMatch.group(3) ?? '');
            if (year != null && year < 100) year += 2000;

            final month = monthMap[monthName];
            if (month != null) {
              final validDate = _validateCalendarDate(year, month, day);
              if (validDate != null) {
                foundDate = validDate;
              }
            }
          }
        }

        // Prioritas 3: Format numerik standar (05/11/2026, 05-11-2026, 05.11.2026)
        if (foundDate == null) {
          final numMatch = numericPattern.firstMatch(line);
          if (numMatch != null) {
            final day = int.tryParse(numMatch.group(1) ?? '');
            final month = int.tryParse(numMatch.group(2) ?? '');
            var year = int.tryParse(numMatch.group(3) ?? '');
            if (year != null && year < 100) year += 2000;

            final validDate = _validateCalendarDate(year, month, day);
            if (validDate != null) {
              foundDate = validDate;
            }
          }
        }
      }

      // Deteksi waktu/jam jika baris mengandung format HH:MM
      if (foundTime == null) {
        final tMatch = timePattern.firstMatch(line);
        if (tMatch != null) {
          final h = int.tryParse(tMatch.group(1) ?? '');
          final m = int.tryParse(tMatch.group(2) ?? '');
          if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
            foundTime = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
          }
        }
      }

      if (foundDate != null && foundTime != null) {
        break;
      }
    }

    return _ReceiptDateResult(date: foundDate, time: foundTime);
  }

  static DateTime? _validateCalendarDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) return null;
    if (year < 2000 || year > 2099) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    try {
      final dt = DateTime(year, month, day);
      if (dt.year == year && dt.month == month && dt.day == day) {
        return dt;
      }
    } catch (_) {}
    return null;
  }

  _TotalResult _extractTotals(List<String> lines) {
    double? subtotal;
    double? discount;
    double? tax;
    double? serviceFee;
    final candidates = <_CandidateTotal>[];
    final subtotalKeywords = ['subtotal', 'sub total', 'sub-total'];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // 1. Cek apakah ini baris subtotal
      bool isSubtotal = false;
      for (final kw in subtotalKeywords) {
        if (lower.contains(kw) && !_isPromoOrLoyalty(lower)) {
          isSubtotal = true;
          final amount = _parseAmountForKeyword(line, kw);
          if (amount != null && amount > 0) {
            subtotal = amount;
          }
          break;
        }
      }

      // 2. Cek apakah ini baris diskon / potongan
      if (_isDiscountLine(lower)) {
        final dAmount = _parseAmountFromLine(line);
        if (dAmount != null && dAmount > 0) {
          discount = (discount ?? 0) + dAmount;
        }
      }

      // 3. Cek apakah ini baris pajak / PPN
      if (_isTaxLine(lower)) {
        final tAmount = _parseAmountFromLine(line);
        if (tAmount != null && tAmount > 0) {
          tax = (tax ?? 0) + tAmount;
        }
      }

      // 4. Cek apakah ini baris service charge / biaya layanan
      if (_isServiceFeeLine(lower)) {
        final sAmount = _parseAmountFromLine(line);
        if (sAmount != null && sAmount > 0) {
          serviceFee = (serviceFee ?? 0) + sAmount;
        }
      }

      // Jika baris hanya memuat subtotal tanpa payment total eksplisit, lewati ke baris berikutnya
      final hasExplicitTotalInSameLine = lower.contains('grand total') ||
          lower.contains('total bayar') ||
          lower.contains('total pembayaran') ||
          lower.contains('total tagihan');
      if (isSubtotal && !hasExplicitTotalInSameLine) continue;

      // Filter baris informasi terpisah / bukan total pembayaran tagihan
      if (_isPromoOrLoyalty(lower)) continue;
      if (_isItemCount(lower)) continue;
      if (_isChange(lower)) continue;
      if (_isReturnOrRefund(lower)) continue;
      if (_isTenderOnly(lower)) continue;
      if (_isDiscountOnly(lower)) continue;
      if (_isTaxOrFeeOnly(lower)) continue;

      // Tentukan priority tier jika baris mengandung keyword total yang sah
      final priorityMatch = _matchPriorityTier(lower);
      if (priorityMatch != null) {
        final amount = _parseAmountForKeyword(line, priorityMatch.keyword);
        if (amount != null && amount >= 100) {
          candidates.add(
            _CandidateTotal(
              priority: priorityMatch.priority,
              amount: amount,
              lineIndex: i,
            ),
          );
        }
      }
    }

    // Seleksi deterministik kandidat terbaik:
    // Prioritaskan tier tertinggi (angka terkecil: Tier 1 > Tier 2 > ... > Tier 8).
    // Jika tier sama, pilih kandidat kemunculan terakhir (baris paling bawah pada struk).
    double? total;
    bool hasMultipleTotals = false;
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final cmp = a.priority.compareTo(b.priority);
        if (cmp != 0) return cmp;
        return b.lineIndex.compareTo(a.lineIndex);
      });
      total = candidates.first.amount;

      // Cek apakah terdapat kandidat di top priority tier dengan nominal berbeda
      final topPriority = candidates.first.priority;
      final distinctAmountsInTopTier = candidates
          .where((c) => c.priority == topPriority)
          .map((c) => c.amount)
          .toSet();
      if (distinctAmountsInTopTier.length > 1) {
        hasMultipleTotals = true;
      }
    }

    return _TotalResult(
      total: total ?? 0,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      serviceFee: serviceFee,
      hasMultipleTotals: hasMultipleTotals,
    );
  }

  static bool _isDiscountLine(String lower) {
    if (lower.contains('grand total') || lower.contains('total bayar')) return false;
    return lower.contains('diskon') ||
        lower.contains('discount') ||
        lower.contains('potongan');
  }

  static bool _isTaxLine(String lower) {
    if (lower.contains('grand total') || lower.contains('total bayar')) return false;
    return lower.contains('ppn') ||
        lower.contains('pajak') ||
        lower.contains('pb1') ||
        lower.contains('tax');
  }

  static bool _isServiceFeeLine(String lower) {
    if (lower.contains('grand total') || lower.contains('total bayar')) return false;
    return lower.contains('biaya layanan') ||
        lower.contains('service charge') ||
        lower.contains('ongkir') ||
        lower.contains('ongkos kirim') ||
        (lower.contains('service') && !lower.contains('customer service'));
  }

  static bool _isPromoOrLoyalty(String lower) {
    const promoKeywords = [
      'hemat',
      'saving',
      'poin',
      'point',
      'cashback',
      'kupon',
      'coupon',
      'voucher',
      'reward',
    ];
    final hasPromo = promoKeywords.any((kw) => lower.contains(kw));
    if (!hasPromo) return false;

    final hasExplicitTotalPhrase = lower.contains('grand total') ||
        lower.contains('total bayar') ||
        lower.contains('total pembayaran') ||
        lower.contains('total tagihan') ||
        lower.contains('total akhir');
    return !hasExplicitTotalPhrase;
  }

  static bool _isItemCount(String lower) {
    final hasItemCountWord = lower.contains('total item') ||
        lower.contains('total items') ||
        lower.contains('total pcs') ||
        lower.contains('total qty') ||
        lower.contains('total quantity') ||
        lower.contains('item count') ||
        lower.contains('qty :') ||
        lower.contains('qty:');
    if (!hasItemCountWord) return false;

    final hasExplicitTotalPhrase = lower.contains('grand total') ||
        lower.contains('total bayar') ||
        lower.contains('total pembayaran') ||
        lower.contains('total tagihan') ||
        lower.contains('total akhir');
    return !hasExplicitTotalPhrase;
  }

  static bool _isChange(String lower) {
    final hasChangeWord = lower.contains('kembalian') ||
        lower.contains('kembali') ||
        lower.contains('change') ||
        lower.contains('uang kembali');
    if (!hasChangeWord) return false;

    final hasExplicitTotalPhrase = lower.contains('grand total') ||
        lower.contains('total bayar') ||
        lower.contains('total pembayaran') ||
        lower.contains('total tagihan') ||
        lower.contains('total akhir');
    return !hasExplicitTotalPhrase;
  }

  static bool _isReturnOrRefund(String lower) {
    return lower.contains('retur') || lower.contains('refund');
  }

  static bool _isTenderOnly(String lower) {
    if (lower.contains('total tunai') || lower.contains('total cash')) {
      return true;
    }
    final hasTenderWord = lower.contains('tunai') ||
        lower.contains('cash') ||
        lower.contains('tendered') ||
        lower.contains('bayar tunai') ||
        lower.contains('cash payment') ||
        lower.contains('uang tunai');
    if (!hasTenderWord) return false;

    // Jika baris mengandung total pembayaran definitif, bukan tender murni
    final hasExplicitTotalPhrase = lower.contains('total bayar') ||
        lower.contains('total pembayaran') ||
        lower.contains('grand total') ||
        lower.contains('total tagihan') ||
        lower.contains('total akhir');
    return !hasExplicitTotalPhrase;
  }

  static bool _isDiscountOnly(String lower) {
    final hasDiscountWord = lower.contains('diskon') ||
        lower.contains('discount') ||
        lower.contains('potongan');
    if (!hasDiscountWord) return false;

    final isAfterDiscountTotal = lower.contains('setelah diskon') ||
        lower.contains('sesudah diskon') ||
        lower.contains('after discount') ||
        lower.contains('termasuk diskon') ||
        lower.contains('inc discount');
    return !isAfterDiscountTotal;
  }

  static bool _isTaxOrFeeOnly(String lower) {
    final hasTaxOrFeeWord = lower.contains('ppn') ||
        lower.contains('pajak') ||
        lower.contains('tax') ||
        lower.contains('service') ||
        lower.contains('pb1') ||
        lower.contains('ongkir') ||
        lower.contains('ongkos kirim') ||
        lower.contains('shipping');
    if (!hasTaxOrFeeWord) return false;

    // Jika baris mengandung total pembayaran definitif atau keterangan inklusif,
    // maka baris ini adalah total tagihan inklusif, BUKAN rincian pajak saja.
    final hasExplicitTotalPhrase = lower.contains('grand total') ||
        lower.contains('total bayar') ||
        lower.contains('total pembayaran') ||
        lower.contains('jumlah bayar') ||
        lower.contains('total tagihan') ||
        lower.contains('total akhir');

    final hasInclusiveIndicator = lower.contains('termasuk') ||
        lower.contains('incl') ||
        lower.contains('inc ') ||
        lower.contains('inc.') ||
        lower.contains('including') ||
        lower.contains('sudah termasuk') ||
        lower.contains('plus');

    return !(hasExplicitTotalPhrase || hasInclusiveIndicator);
  }

  static _TierMatch? _matchPriorityTier(String lower) {
    // Tier 1: GRAND TOTAL
    if (lower.contains('grand total')) return const _TierMatch(1, 'grand total');
    if (lower.contains('grand-total')) return const _TierMatch(1, 'grand-total');

    // Tier 2: TOTAL BAYAR / TOTAL PEMBAYARAN
    if (lower.contains('total bayar')) return const _TierMatch(2, 'total bayar');
    if (lower.contains('total pembayaran')) return const _TierMatch(2, 'total pembayaran');
    if (lower.contains('jumlah bayar')) return const _TierMatch(2, 'jumlah bayar');
    if (lower.contains('jumlah pembayaran')) return const _TierMatch(2, 'jumlah pembayaran');

    // Tier 3: TOTAL TAGIHAN / NET TOTAL
    if (lower.contains('total tagihan')) return const _TierMatch(3, 'total tagihan');
    if (lower.contains('jumlah tagihan')) return const _TierMatch(3, 'jumlah tagihan');
    if (lower.contains('net total')) return const _TierMatch(3, 'net total');
    if (lower.contains('total netto')) return const _TierMatch(3, 'total netto');
    if (lower.contains('jumlah total')) return const _TierMatch(3, 'jumlah total');

    // Tier 4: TOTAL AKHIR / FINAL TOTAL
    if (lower.contains('total akhir')) return const _TierMatch(4, 'total akhir');
    if (lower.contains('final total')) return const _TierMatch(4, 'final total');
    if (lower.contains('tagihan akhir')) return const _TierMatch(4, 'tagihan akhir');

    // Tier 5: TOTAL SETELAH DISKON
    if (lower.contains('total setelah diskon')) return const _TierMatch(5, 'total setelah diskon');
    if (lower.contains('total sesudah diskon')) return const _TierMatch(5, 'total sesudah diskon');
    if (lower.contains('total after discount')) return const _TierMatch(5, 'total after discount');
    if (lower.contains('setelah diskon')) return const _TierMatch(5, 'setelah diskon');
    if (lower.contains('after discount')) return const _TierMatch(5, 'after discount');

    // Tier 6: TOTAL BELANJA
    if (lower.contains('total belanja')) return const _TierMatch(6, 'total belanja');
    if (lower.contains('total belanjaan')) return const _TierMatch(6, 'total belanjaan');
    if (lower.contains('total pembelian')) return const _TierMatch(6, 'total pembelian');

    // Tier 7: TOTAL HARGA / TOTAL BIAYA
    if (lower.contains('total harga')) return const _TierMatch(7, 'total harga');
    if (lower.contains('total biaya')) return const _TierMatch(7, 'total biaya');

    // Tier 8: TOTAL (kata umum/fallback)
    if (lower.contains('total')) return const _TierMatch(8, 'total');

    return null;
  }

  double? _parseAmountForKeyword(String line, String matchedKeyword) {
    final lower = line.toLowerCase();
    final kwIndex = lower.indexOf(matchedKeyword.toLowerCase());
    if (kwIndex == -1) {
      return _parseAmountFromLine(line);
    }

    // Ambil segmen teks setelah keyword
    final afterKw = line.substring(kwIndex + matchedKeyword.length);
    final afterKwLower = afterKw.toLowerCase();

    // Batasi jika pada baris yang sama terdapat keyword lain (misal: "TOTAL BAYAR 100.000 TUNAI 150.000")
    const boundaryKeywords = [
      'tunai',
      'cash',
      'kembalian',
      'kembali',
      'change',
      'subtotal',
      'sub total',
      'sub-total',
      'total bayar',
      'total pembayaran',
      'grand total',
      'total tagihan',
      'total hemat',
      'total poin',
      'total diskon',
    ];

    int boundaryIndex = -1;
    for (final bKw in boundaryKeywords) {
      if (bKw == matchedKeyword.toLowerCase()) continue;
      final idx = afterKwLower.indexOf(bKw);
      if (idx != -1) {
        if (boundaryIndex == -1 || idx < boundaryIndex) {
          boundaryIndex = idx;
        }
      }
    }

    final targetSegment = boundaryIndex != -1
        ? afterKw.substring(0, boundaryIndex)
        : afterKw;

    // Ambil angka pertama dari segmen terasosiasi
    final segmentAmount = _parseFirstAmountFromSegment(targetSegment);
    if (segmentAmount != null) {
      return segmentAmount;
    }

    // Fallback bila pembatasan segmen terlalu ketat
    return _parseFirstAmountFromSegment(afterKw) ?? _parseAmountFromLine(line);
  }

  double? _parseFirstAmountFromSegment(String segment) {
    final numberPattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)',
    );
    final matches = numberPattern.allMatches(segment).toList();
    if (matches.isEmpty) return null;

    // Untuk segmen yang terasosiasi dengan keyword, ambil angka pertama yang valid (>= 100)
    for (final m in matches) {
      final text = m.group(0) ?? '';
      final val = _cleanReceiptAmount(text);
      if (val != null && val >= 100) {
        return val;
      }
    }
    return null;
  }

  static double? _cleanReceiptAmount(String text) {
    String cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    // Deteksi jika angka berakhiran pemisah desimal 1 atau 2 digit (misal: ",00" atau ".00" atau ",50").
    // Catatan: pemisah ribuan selalu 3 digit (misal: ".000" atau ",500").
    final decimalMatch = RegExp(r'[.,](\d{1,2})$').firstMatch(cleaned);
    double decimalPart = 0.0;
    if (decimalMatch != null) {
      final decStr = decimalMatch.group(1)!;
      decimalPart = (double.tryParse(decStr) ?? 0.0) / (decStr.length == 1 ? 10 : 100);
      cleaned = cleaned.substring(0, decimalMatch.start);
    }

    // Hapus seluruh pemisah ribuan (baik titik maupun koma)
    final intStr = cleaned.replaceAll('.', '').replaceAll(',', '').trim();
    final intVal = double.tryParse(intStr);
    if (intVal == null) return null;

    return intVal + decimalPart;
  }

  double? _parseAmountFromLine(String line) {
    final numberPattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)',
    );
    final matches = numberPattern.allMatches(line).toList();
    if (matches.isEmpty) return null;

    // Ambil angka terakhir di baris tersebut (posisi kolom harga)
    for (int i = matches.length - 1; i >= 0; i--) {
      final text = matches[i].group(0) ?? '';
      final val = _cleanReceiptAmount(text);
      if (val != null && val >= 100) {
        return val;
      }
    }

    return null;
  }

  List<ReceiptItem> _extractItems(List<String> lines) {
    final List<ReceiptItem> items = [];
    final itemPattern = RegExp(r'^(.+?)\s+(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)$');

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
        final price = _cleanReceiptAmount(match.group(2) ?? '');
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
  const _TotalResult({
    required this.total,
    this.subtotal,
    this.discount,
    this.tax,
    this.serviceFee,
    this.hasMultipleTotals = false,
  });

  final double total;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? serviceFee;
  final bool hasMultipleTotals;
}

class _ReceiptDateResult {
  const _ReceiptDateResult({this.date, this.time});
  final DateTime? date;
  final String? time;
}

class _CandidateTotal {
  const _CandidateTotal({
    required this.priority,
    required this.amount,
    required this.lineIndex,
  });

  final int priority;
  final double amount;
  final int lineIndex;
}

class _TierMatch {
  const _TierMatch(this.priority, this.keyword);
  final int priority;
  final String keyword;
}
