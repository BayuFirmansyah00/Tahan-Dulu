import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/datasources/remote/api_config.dart';
import '../../../../data/providers/app_providers.dart';
import '../../data/services/hybrid_receipt_scanner_service.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../data/services/speech_recognition_service.dart';

/// Provider layanan Speech Recognition (default: native).
/// Dapat di-override pada unit/widget test dengan mock.
final speechRecognitionServiceProvider =
    Provider<SpeechRecognitionService>((ref) {
  final service = NativeSpeechRecognitionService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider layanan OCR struk (default: native).
/// Dapat di-override pada unit/widget test dengan mock.
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final service = NativeReceiptOcrService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider hybrid receipt scanner backend (di belakang feature flag
/// [ApiConfig.useHybridReceiptScanner]). Dapat di-override pada unit/widget test.
final hybridReceiptScannerServiceProvider =
    Provider<HybridReceiptScannerService>((ref) {
  final client = ApiClient(baseUrl: ApiConfig.baseUrl);
  final tokens = ref.read(tokenStoreProvider);
  ref.onDispose(client.close);
  return RemoteHybridReceiptScannerService(
    client: client,
    tokens: tokens,
  );
});

