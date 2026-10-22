import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Hasil ekspor: dibagikan/dicetak atau gagal beserta alasannya.
class ReportExportResult {
  const ReportExportResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// Bagikan PDF laporan (Android: sheet berbagi, Web: unduh).
/// Bila berbagi gagal/ditolak (mis. emulator tanpa aplikasi share),
/// otomatis fallback ke dialog cetak sistem (Android: "Save as PDF").
/// [shareWith]/[printWith] injeksi untuk test; default memakai Printing.
/// Tidak pernah melempar — kegagalan dikembalikan sebagai result.
Future<ReportExportResult> exportReportPdf({
  required Uint8List bytes,
  required String filename,
  Future<bool> Function(Uint8List bytes, String filename)? shareWith,
  Future<void> Function(Uint8List bytes, String filename)? printWith,
}) async {
  if (bytes.isEmpty) {
    return const ReportExportResult(ok: false, message: 'empty');
  }
  try {
    final share = shareWith ??
        ((b, name) => Printing.sharePdf(bytes: b, filename: name));
    if (await share(bytes, filename)) {
      return const ReportExportResult(ok: true);
    }
  } catch (e) {
    return _tryPrint(bytes, filename, printWith, 'share: $e');
  }
  return _tryPrint(bytes, filename, printWith, 'share unavailable');
}

Future<ReportExportResult> _tryPrint(
  Uint8List bytes,
  String filename,
  Future<void> Function(Uint8List bytes, String filename)? printWith,
  String reason,
) async {
  try {
    final printDoc = printWith ??
        ((b, name) => Printing.layoutPdf(
              onLayout: (_) async => b,
              name: name,
            ));
    await printDoc(bytes, filename);
    return const ReportExportResult(ok: true);
  } catch (e) {
    return ReportExportResult(ok: false, message: '$reason; print: $e');
  }
}
