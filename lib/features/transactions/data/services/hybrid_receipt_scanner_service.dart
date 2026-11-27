import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/datasources/remote/api_config.dart';
import '../../../../data/datasources/remote/token_storage.dart';

class HybridReceiptItem {
  const HybridReceiptItem({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.confidence = 0,
    this.evidenceText = '',
  });

  final String name;
  final double? quantity;
  final double? unitPrice;
  final double? lineTotal;
  final double confidence;
  final String evidenceText;

  factory HybridReceiptItem.fromJson(Map<String, dynamic> json) {
    return HybridReceiptItem(
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      evidenceText: (json['evidence_text'] ?? '').toString(),
    );
  }
}

class ReceiptValidationWarning {
  const ReceiptValidationWarning({
    required this.code,
    required this.severity,
    required this.message,
    this.field,
  });

  final String code;
  final String severity;
  final String message;
  final String? field;

  factory ReceiptValidationWarning.fromJson(Map<String, dynamic> json) {
    return ReceiptValidationWarning(
      code: (json['code'] ?? 'WARNING').toString(),
      severity: (json['severity'] ?? 'warning').toString(),
      message: (json['message'] ?? '').toString(),
      field: json['field']?.toString(),
    );
  }
}

class HybridReceiptScanResult {
  const HybridReceiptScanResult({
    required this.rawText,
    this.merchantName,
    this.receiptDate,
    this.receiptTime,
    this.currency,
    this.items = const [],
    this.subtotal,
    this.discount,
    this.tax,
    this.serviceCharge,
    this.rounding,
    this.grandTotal,
    this.cashPaid,
    this.change,
    this.paymentMethod,
    this.suggestedCategory,
    this.validationWarnings = const [],
    this.requiresReview = true,
    this.engine = '',
    this.meanOcrConfidence = 0,
  });

  final String rawText;
  final String? merchantName;
  final DateTime? receiptDate;
  final String? receiptTime;
  final String? currency;
  final List<HybridReceiptItem> items;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? serviceCharge;
  final double? rounding;
  final double? grandTotal;
  final double? cashPaid;
  final double? change;
  final String? paymentMethod;
  final String? suggestedCategory;
  final List<ReceiptValidationWarning> validationWarnings;
  final bool requiresReview;
  final String engine;
  final double meanOcrConfidence;

  factory HybridReceiptScanResult.fromJson(Map<String, dynamic> data) {
    final sourceEvidence = data['source_evidence'];
    final rawText = sourceEvidence is Map<String, dynamic>
        ? (sourceEvidence['raw_text'] ?? '').toString()
        : '';

    DateTime? parsedDate;
    final rawDate = data['receipt_date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(HybridReceiptItem.fromJson)
            .toList(growable: false)
        : const <HybridReceiptItem>[];

    final rawWarnings = data['validation_warnings'];
    final warnings = rawWarnings is List
        ? rawWarnings
            .whereType<Map<String, dynamic>>()
            .map(ReceiptValidationWarning.fromJson)
            .toList(growable: false)
        : const <ReceiptValidationWarning>[];

    return HybridReceiptScanResult(
      rawText: rawText,
      merchantName: data['merchant_name']?.toString(),
      receiptDate: parsedDate,
      receiptTime: data['receipt_time']?.toString(),
      currency: data['currency']?.toString(),
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble(),
      discount: (data['discount'] as num?)?.toDouble(),
      tax: (data['tax'] as num?)?.toDouble(),
      serviceCharge: (data['service_charge'] as num?)?.toDouble(),
      rounding: (data['rounding'] as num?)?.toDouble(),
      grandTotal: (data['grand_total'] as num?)?.toDouble(),
      cashPaid: (data['cash_paid'] as num?)?.toDouble(),
      change: (data['change'] as num?)?.toDouble(),
      paymentMethod: data['payment_method']?.toString(),
      suggestedCategory: data['suggested_category']?.toString(),
      validationWarnings: warnings,
      requiresReview: data['requires_review'] as bool? ?? true,
      engine: (data['engine'] ?? '').toString(),
      meanOcrConfidence: (data['mean_ocr_confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HybridScannerUnavailableException implements Exception {
  const HybridScannerUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class HybridReceiptScannerService {
  bool get isEnabled;

  Future<HybridReceiptScanResult> scanReceiptImage(
    String imagePath, {
    bool allowExternalAi = false,
    bool allowVisionFallback = false,
  });
}

class RemoteHybridReceiptScannerService implements HybridReceiptScannerService {
  RemoteHybridReceiptScannerService({
    required ApiClient client,
    required TokenStore tokens,
    bool? enabledOverride,
  })  : _client = client, // ignore: prefer_initializing_formals
        _tokens = tokens, // ignore: prefer_initializing_formals
        _enabledOverride = enabledOverride; // ignore: prefer_initializing_formals

  final ApiClient _client;
  final TokenStore _tokens;
  final bool? _enabledOverride;

  @override
  bool get isEnabled {
    final override = _enabledOverride;
    if (override != null) return override;
    return ApiConfig.useHybridReceiptScanner && ApiConfig.useRemoteApi;
  }

  @override
  Future<HybridReceiptScanResult> scanReceiptImage(
    String imagePath, {
    bool allowExternalAi = false,
    bool allowVisionFallback = false,
  }) async {
    if (!isEnabled) {
      throw const HybridScannerUnavailableException(
        'Hybrid receipt scanner tidak aktif.',
      );
    }

    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw const HybridScannerUnavailableException(
        'Token autentikasi tidak tersedia untuk hybrid scanner.',
      );
    }

    try {
      final res = await _client.postMultipart(
        '/receipts/scan',
        fileField: 'image',
        filePath: imagePath,
        fields: {
          'allow_external_ai': allowExternalAi ? '1' : '0',
          'allow_vision_fallback': allowVisionFallback ? '1' : '0',
          'preprocess': '1',
        },
        token: token,
      );

      final data = res['data'];
      if (data is! Map<String, dynamic>) {
        throw const HybridScannerUnavailableException(
          'Format respons hybrid scanner tidak valid.',
        );
      }
      return HybridReceiptScanResult.fromJson(data);
    } on ApiException catch (e) {
      throw HybridScannerUnavailableException(e.message);
    }
  }
}
