import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Kontrak layanan OCR dan pengambilan gambar struk belanja.
///
/// Mengisolasi integrasi native image_picker dan google_mlkit_text_recognition
/// agar mudah diuji dengan mock pada unit dan widget test.
abstract class ReceiptOcrService {
  Future<String?> pickImageFromCamera();
  Future<String?> pickImageFromGallery();
  Future<String> recognizeText(String imagePath);
  void dispose();
}

/// Implementasi produksi OCR dan pengambilan gambar menggunakan paket native
/// [ImagePicker] dan on-device [TextRecognizer] Google ML Kit.
class NativeReceiptOcrService implements ReceiptOcrService {
  NativeReceiptOcrService({ImagePicker? imagePicker})
      : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;
  TextRecognizer? _activeRecognizer;

  @override
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      return photo?.path;
    } catch (e) {
      debugPrint('[NativeReceiptOcrService] pickImageFromCamera error: $e');
      rethrow;
    }
  }

  @override
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      return image?.path;
    } catch (e) {
      debugPrint('[NativeReceiptOcrService] pickImageFromGallery error: $e');
      rethrow;
    }
  }

  @override
  Future<String> recognizeText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const FileSystemException('Berkas gambar struk tidak ditemukan.');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _activeRecognizer = recognizer;

    try {
      final RecognizedText recognizedText =
          await recognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('[NativeReceiptOcrService] recognizeText error: $e');
      rethrow;
    } finally {
      await recognizer.close();
      if (_activeRecognizer == recognizer) {
        _activeRecognizer = null;
      }
    }
  }

  @override
  void dispose() {
    try {
      _activeRecognizer?.close();
      _activeRecognizer = null;
    } catch (_) {}
  }
}

