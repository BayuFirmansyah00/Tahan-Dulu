import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Kontrak layanan speech recognition untuk input suara transaksi.
///
/// Mengisolasi integrasi native speech_to_text dan permission_handler
/// agar antarmuka UI mudah diuji dengan mock pada widget test.
abstract class SpeechRecognitionService {
  bool get isListening;
  bool get isAvailable;

  Future<bool> checkMicrophonePermission();
  Future<bool> requestMicrophonePermission();

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  });

  Future<String?> findIndonesianLocale();

  Future<bool> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    String? localeId,
  });

  Future<void> stopListening();
  Future<void> cancelListening();
  void dispose();
}

/// Implementasi produksi speech recognition menggunakan paket native
/// [stt.SpeechToText] dan [Permission.microphone].
class NativeSpeechRecognitionService implements SpeechRecognitionService {
  NativeSpeechRecognitionService({stt.SpeechToText? speechToText})
      : _speech = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _initialized = false;

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] checkPermission error: $e');
      return _speech.hasPermission;
    }
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;
      return false;
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] requestPermission error: $e');
      return false;
    }
  }

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    try {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[NativeSpeechRecognitionService] Status: $status');
          onStatus?.call(status);
        },
        onError: (errorNotification) {
          debugPrint(
            '[NativeSpeechRecognitionService] Error: ${errorNotification.errorMsg} (${errorNotification.permanent})',
          );
          onError?.call(errorNotification.errorMsg);
        },
        debugLogging: kDebugMode,
      );
      return _initialized;
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] initialize exception: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  @override
  Future<String?> findIndonesianLocale() async {
    if (!_speech.isAvailable) return null;
    try {
      final locales = await _speech.locales();
      for (final loc in locales) {
        final id = loc.localeId.toLowerCase();
        final name = loc.name.toLowerCase();
        if (id.startsWith('id') ||
            id.startsWith('in') ||
            name.contains('indonesia')) {
          return loc.localeId;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] findIndonesianLocale error: $e');
      return null;
    }
  }

  @override
  Future<bool> startListening({
    required void Function(String recognizedWords, bool isFinal) onResult,
    String? localeId,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    if (!_speech.isAvailable) return false;

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          localeId: localeId,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] listen exception: $e');
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] stopListening exception: $e');
    }
  }

  @override
  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (e) {
      debugPrint('[NativeSpeechRecognitionService] cancelListening exception: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (_speech.isListening) {
        _speech.cancel();
      }
    } catch (_) {}
  }
}
