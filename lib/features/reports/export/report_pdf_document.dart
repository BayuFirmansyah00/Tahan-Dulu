import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_export_data.dart';

/// Palet PDF mengikuti design system TahanDulu (flat, ramah cetak).
PdfColor _hex(int value) => PdfColor(
      ((value >> 16) & 0xFF) / 255,
      ((value >> 8) & 0xFF) / 255,
      (value & 0xFF) / 255,
    );

final PdfColor _navy = _hex(0x0F2440);
final PdfColor _emerald = _hex(0x0E9F6E);
final PdfColor _mint = _hex(0xE1F5EC);
final PdfColor _blue = _hex(0x3B82F6);
final PdfColor _red = _hex(0xEF4444);
final PdfColor _grey = _hex(0x64748B);
final PdfColor _line = _hex(0xE2E8F0);
final PdfColor _white = PdfColors.white;

/// Warna irisan donat + legenda (disiklus bila kategori > 8).
final List<PdfColor> _sliceColors = [
  _hex(0xF59E0B),
  _hex(0x3B82F6),
  _hex(0xF87171),
  _hex(0x8B5CF6),
  _hex(0x14B8A6),
  _hex(0x9CA3AF),
  _hex(0x0E9F6E),
  _hex(0xF472B6),
];

pw.TextStyle _s(double size, {bool bold = false, PdfColor? color}) =>
    pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? _navy,
    );

/// Membangun dokumen PDF A4 portrait dari payload yang sudah dirakit.
/// [logoBytes] PNG logo asli; null -> wordmark teks (tetap branding).
/// Murni layout dari data — tanpa sumber kedua, tanpa klaim verifikasi.
Future<List<int>> buildReportPdf(
  ReportExportData data, {
  List<int>? logoBytes,
}) async {
  final doc = pw.Document(
    title: 'Laporan Keuangan ${data.periodLabel}',
    author: 'TahanDulu',
  );

  pw.Widget brandMark() {
    if (logoBytes != null && logoBytes.isNotEmpty) {
      return pw.Image(
        pw.MemoryImage(Uint8List.fromList(logoBytes)),
        width: 44,
        height: 44,
      );
    }
    return pw.Container(
      width: 44,
      height: 44,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _emerald,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text('T', style: _s(24, bold: true, color: _white)),
    );
  }

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Text(text, style: _s(13, bold: true)),
      );

  pw.Widget summaryCell({
    required String amount,
    required String label,
    required PdfColor color,
  }) =>
      pw.Expanded(
        child: pw.Column(
          children: [
            pw.Container(
              width: 26,
              height: 26,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(amount, style: _s(12, bold: true, color: color)),
            pw.Text(label, style: _s(9, color: _grey)),
          ],
        ),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      header: (context) => pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              brandMark(),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TahanDulu', style: _s(16, bold: true)),
                    pw.Text(
                      'Atur uang. Capai tujuan. Pikir sebelum beli.',
                      style: _s(8, color: _grey),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ID Laporan', style: _s(8, color: _grey)),
                  pw.Text(data.reportId, style: _s(10, bold: true)),
                  pw.SizedBox(height: 4),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data.qrPayload,
                    width: 72,
                    height: 72,
                  ),
                  pw.SizedBox(height: 2),
                  pw.SizedBox(
                    width: 84,
                    child: pw.Text(
                      'Scan untuk melihat informasi laporan',
                      textAlign: pw.TextAlign.center,
                      style: _s(7, color: _grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 10),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.SizedBox(height: 8),
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TahanDulu - ${data.periodLabel}',
                style: _s(8, color: _grey),
              ),
              pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: _s(8, color: _grey),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.Text('Laporan Keuangan', style: _s(22, bold: true)),
        pw.Text(data.periodLabel, style: _s(13, bold: true)),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Periode', style: _s(8, color: _grey)),
                    pw.Text(data.dateRangeLabel, style: _s(10, bold: true)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Dibuat pada', style: _s(8, color: _grey)),
                    pw.Text(data.generatedLabel, style: _s(10, bold: true)),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: pw.BoxDecoration(
            color: _mint,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              summaryCell(
                amount: data.incomeLabel,
                label: 'Pemasukan',
                color: _emerald,
              ),
              summaryCell(
                amount: data.expenseLabel,
                label: 'Pengeluaran',
                color: _red,
              ),
              summaryCell(
                amount: data.netLabel,
                label: 'Selisih',
                color: _blue,
              ),
            ],
          ),
        ),
        sectionTitle('Pengeluaran per Kategori'),
        if (!data.hasExpenseData)
          pw.Text(
            'Belum ada data pada periode ini.',
            style: _s(10, color: _grey),
          )
        else
          _categoryChart(data.categories, data.expenseLabel),
        sectionTitle('Rincian Kategori Pengeluaran'),
        if (!data.hasExpenseData)
          pw.Text(
            'Belum ada data pada periode ini.',
            style: _s(10, color: _grey),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: _line),
            columnWidths: const {
              0: pw.FixedColumnWidth(36),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.4),
            },
            defaultVerticalAlignment:
                pw.TableCellVerticalAlignment.middle,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: [
                  _cell('No.', bold: true, align: pw.TextAlign.center),
                  _cell('Kategori', bold: true),
                  _cell('Jumlah', bold: true, align: pw.TextAlign.right),
                  _cell('Persentase',
                      bold: true, align: pw.TextAlign.right),
                ],
              ),
              for (var i = 0; i < data.categories.length; i++)
                pw.TableRow(
                  children: [
                    _cell('${i + 1}', align: pw.TextAlign.center),
                    _cell(data.categories[i].label),
                    _cell(data.categories[i].amountLabel,
                        align: pw.TextAlign.right),
                    _cell(data.categories[i].percentLabel,
                        align: pw.TextAlign.right),
                  ],
                ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _mint),
                children: [
                  _cell(''),
                  _cell('Total Pengeluaran', bold: true),
                  _cell(data.expenseLabel,
                      bold: true, align: pw.TextAlign.right),
                  _cell('100%', bold: true, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
        if (data.goalSummary != null) ...[
          sectionTitle('Ringkasan Target Keuangan'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _kv('Total Setoran',
                    data.goalSummary!.monthDepositsLabel),
                _kv('Jumlah Target Aktif',
                    '${data.goalSummary!.activeCount}'),
                _kv('Target Tercapai',
                    '${data.goalSummary!.reachedCount}'),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _hex(0xE8EFFE),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Laporan ini dibuat secara otomatis oleh aplikasi TahanDulu. '
            'QR Code berisi ID laporan dan informasi periode. '
            'Verifikasi daring belum tersedia.',
            style: _s(9, color: _navy),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

/// Irisan donat: 8 kategori teratas + agregat "Lainnya".
/// Baris Row donat+legenda tidak dapat dipenggal halaman oleh MultiPage,
/// tabel penuh di bawah tetap memuat semua kategori.
List<ReportCategoryExport> chartSlices(List<ReportCategoryExport> all) {
  if (all.length <= 8) return all;
  final top = all.take(7).toList();
  final rest = all.skip(7).toList();
  final restAmount = rest.fold<double>(0, (s, e) => s + e.amount);
  final total = all.fold<double>(0, (s, e) => s + e.amount);
  return [
    ...top,
    ReportCategoryExport(
      label: 'Lainnya',
      amount: restAmount,
      share: total > 0 ? restAmount / total : 0,
    ),
  ];
}

pw.Widget legendDot(PdfColor color) => pw.Container(
      width: 9,
      height: 9,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
    );

/// Donat + legenda untuk maksimal 8 irisan (lihat [chartSlices]).
pw.Widget _categoryChart(
  List<ReportCategoryExport> categories,
  String totalLabel,
) {
  final slices = chartSlices(categories);
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 170,
        height: 170,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            pw.Chart(
              grid: pw.PieGrid(),
              datasets: [
                for (var i = 0; i < slices.length; i++)
                  pw.PieDataSet(
                    value: slices[i].amount,
                    color: _sliceColors[i % _sliceColors.length],
                    legendPosition: pw.PieLegendPosition.none,
                  ),
              ],
            ),
            pw.Container(
              width: 92,
              height: 92,
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(totalLabel, style: _s(11, bold: true)),
                  pw.Text(
                    'Total Pengeluaran',
                    style: _s(7, color: _grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Expanded(
        child: pw.Column(
          children: [
            for (var i = 0; i < slices.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    legendDot(_sliceColors[i % _sliceColors.length]),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Text(slices[i].label, style: _s(9)),
                    ),
                    pw.Text(
                      slices[i].percentLabel,
                      style: _s(9, color: _grey),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      slices[i].amountLabel,
                      style: _s(9, bold: true),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, textAlign: align, style: _s(9, bold: bold)),
    );

pw.Widget _kv(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _s(10, color: _grey)),
          pw.Text(value, style: _s(10, bold: true)),
        ],
      ),
    );
