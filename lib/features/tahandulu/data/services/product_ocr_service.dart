import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/utils/rupiah_input_formatter.dart';

/// Hasil ekstraksi informasi produk dari gambar atau tangkapan layar.
class ProductOcrResult {
  const ProductOcrResult({
    this.itemName,
    this.price,
    this.marketplace,
    this.rawText = '',
    this.hasDetectedInfo = false,
  });

  final String? itemName;
  final double? price;
  final String? marketplace;
  final String rawText;
  final bool hasDetectedInfo;
}

/// Kontrak layanan pengenalan teks produk pada gambar.
abstract class ProductOcrService {
  Future<ProductOcrResult> scanProductImage(String imagePath);
}

/// Implementasi OCR produk menggunakan on-device Google ML Kit Text Recognition.
class NativeProductOcrService implements ProductOcrService {
  NativeProductOcrService({this.recognizer});

  final TextRecognizer? recognizer;

  @override
  Future<ProductOcrResult> scanProductImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return const ProductOcrResult(hasDetectedInfo: false);
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final activeRecognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await activeRecognizer.processImage(inputImage);
      if (recognizer == null) {
        await activeRecognizer.close();
      }

      return parseProductText(recognizedText.text);
    } catch (e) {
      debugPrint('[NativeProductOcrService] OCR scan error (graceful fallback): $e');
      return const ProductOcrResult(hasDetectedInfo: false);
    }
  }

  /// Parser teks murni dari hasil OCR untuk mengekstrak harga, marketplace, dan nama barang.
  static ProductOcrResult parseProductText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ProductOcrResult(hasDetectedInfo: false);
    }

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? detectedPrice;
    String? detectedMarketplace;
    String? candidateName;

    // 1. Deteksi Marketplace dari teks
    final lower = rawText.toLowerCase();
    if (lower.contains('shopee')) {
      detectedMarketplace = 'Shopee';
    } else if (lower.contains('tokopedia')) {
      detectedMarketplace = 'Tokopedia';
    } else if (lower.contains('tiktok')) {
      detectedMarketplace = 'TikTok Shop';
    } else if (lower.contains('lazada')) {
      detectedMarketplace = 'Lazada';
    } else if (lower.contains('blibli')) {
      detectedMarketplace = 'Blibli';
    }

    // 2. Deteksi Harga
    // Pola: Rp 150.000, Rp. 150.000, IDR 150000, Rp1.500.000, dsb
    final priceRegex = RegExp(r'(?:Rp\.?|IDR)\s*([0-9\.\,]+)', caseSensitive: false);
    for (final line in lines) {
      final match = priceRegex.firstMatch(line);
      if (match != null) {
        final rawVal = match.group(1);
        if (rawVal != null) {
          final p = RupiahInputFormatter.parse(rawVal);
          if (p > 0 && (detectedPrice == null || p > detectedPrice)) {
            detectedPrice = p;
          }
        }
      }
    }

    // 3. Deteksi Nama Produk
    final ignoredPhrases = [
      'shopee',
      'tokopedia',
      'tiktok',
      'lazada',
      'blibli',
      'official',
      'mall',
      'star+',
      'beli sekarang',
      'tambah ke keranjang',
      'masuk keranjang',
      'chat penjual',
      'gratis ongkir',
      'voucher',
      'diskon',
      'ulasan',
      'rating',
      'pengiriman',
      'kategori',
      'spesifikasi',
      'detail produk',
      'garansi',
      'kembali',
      'riwayat',
      'pesanan',
      'keranjang',
      'wishlist',
    ];

    for (final line in lines) {
      final lineLower = line.toLowerCase();
      if (line.length >= 8 && line.length <= 120) {
        if (!priceRegex.hasMatch(line) &&
            !ignoredPhrases.any((phrase) => lineLower.contains(phrase))) {
          candidateName = line;
          break;
        }
      }
    }

    final hasInfo = candidateName != null || (detectedPrice != null && detectedPrice > 0);

    return ProductOcrResult(
      itemName: candidateName,
      price: detectedPrice,
      marketplace: detectedMarketplace,
      rawText: rawText,
      hasDetectedInfo: hasInfo,
    );
  }
}
