import 'package:flutter_riverpod/flutter_riverpod.dart';

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

