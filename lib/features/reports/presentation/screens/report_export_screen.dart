import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../goals/presentation/providers/goals_controller.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../export/report_export.dart';
import '../../export/report_export_data.dart';
import '../../export/report_pdf_document.dart';

/// Mampukah perangkat me-raster pratinjau PDF (Printing.info).
/// false (mis. emulator tertentu) -> layar memakai fallback non-pratinjau;
/// ekspor via share sheet tetap tersedia. Error -> anggap mampu agar
/// perilaku lama (coba pratinjau) dipertahankan.
final reportRasterCapableProvider = FutureProvider<bool>((ref) async {
  try {
    final info = await Printing.info();
    return info.canRaster;
  } catch (_) {
    return true;
  }
});

/// Logo asli untuk header PDF; null bila aset tak terbaca (fallback teks).
final _reportLogoProvider = FutureProvider<Uint8List?>((ref) async {
  try {
    final data = await rootBundle.load(AppAssets.logo);
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
});

/// Pratinjau PDF laporan periode aktif + tombol ekspor.
/// Byte PDF dirakit dari provider existing (tanpa sumber kedua).
class ReportExportScreen extends ConsumerStatefulWidget {
  const ReportExportScreen({super.key});

  @override
  ConsumerState<ReportExportScreen> createState() =>
      _ReportExportScreenState();
}

class _ReportExportScreenState extends ConsumerState<ReportExportScreen> {
  bool _exporting = false;
  bool _exportingExcel = false;

  Future<Uint8List> _buildBytes(
    ReportExportData payload,
    Uint8List? logo,
  ) async {
    final bytes = await buildReportPdf(payload, logoBytes: logo);
    return Uint8List.fromList(bytes);
  }

  Future<void> _export(ReportExportData payload, Uint8List? logo) async {
    if (_exporting || _exportingExcel) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _buildBytes(payload, logo);
      final result = await exportReportPdf(
        bytes: bytes,
        filename: payload.filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.ok ? AppStrings.exportSuccess : AppStrings.exportFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel(DateTime month) async {
    if (_exporting || _exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final now = DateTime.now();
      final isCurrent = month.year == now.year && month.month == now.month;
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final startDate =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';
      final endDate =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
      final bytes = await repo.exportFinancialReport(
        period: isCurrent ? 'this_month' : 'custom',
        startDate: isCurrent ? null : startDate,
        endDate: isCurrent ? null : endDate,
      );
      final filename =
          'Laporan_Keuangan_${month.year}_${month.month.toString().padLeft(2, '0')}.xlsx';
      final result = await exportReportExcel(
        bytes: Uint8List.fromList(bytes),
        filename: filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.ok
                ? 'Laporan Excel (.xlsx) berhasil diunduh'
                : 'Gagal mengunduh laporan Excel',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor Excel: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(reportMonthProvider);
    final report = ref.watch(monthlyReportProvider(month));
    final goals = ref.watch(goalsListProvider);
    final logo = ref.watch(_reportLogoProvider);
    final raster = ref.watch(reportRasterCapableProvider);

    return Scaffold(
      extendBodyBehindAppBar: GlassDesignTokens.isDarkGlass(context),
      appBar: const AppAdaptiveAppBar(title: Text(AppStrings.exportPreviewTitle)),
      body: GlassBackdrop(child: SafeArea(
        child: report.when(
          data: (r) => goals.when(
            data: (g) {
              final payload = buildReportExportData(report: r, goals: g);
              final canPreview = raster.value ?? true;
              return Column(
                children: [
                  Expanded(
                    child: canPreview
                        ? PdfPreview(
                            build: (_) => _buildBytes(
                              payload,
                              logo.value,
                            ),
                            allowPrinting: false,
                            useActions: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                            onError: (context, error) => Center(
                              child: Text(AppStrings.exportFailed),
                            ),
                          )
                        : _NoPreview(
                            onExportPdf: () => _export(payload, logo.value),
                            onExportExcel: () => _exportExcel(month),
                            exportingPdf: _exporting,
                            exportingExcel: _exportingExcel,
                          ),
                  ),
                  if (canPreview)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: AppStrings.exportPdf,
                              icon: Icons.picture_as_pdf_outlined,
                              isLoading: _exporting,
                              onPressed: (_exporting || _exportingExcel)
                                  ? null
                                  : () => _export(payload, logo.value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              label: 'Unduh Excel',
                              icon: Icons.table_chart_outlined,
                              backgroundColor: context.palette.primaryContainer,
                              foregroundColor: context.palette.primary,
                              isLoading: _exportingExcel,
                              onPressed: (_exporting || _exportingExcel)
                                  ? null
                                  : () => _exportExcel(month),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const AppLoading(),
            error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(monthlyReportProvider(month))),
          ),
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(monthlyReportProvider(month))),
        ),
      )),
    );
  }
}

/// Fallback bila perangkat tak bisa me-raster pratinjau.
/// Ekspor via share sheet tetap berfungsi (canShare independen).
class _NoPreview extends StatelessWidget {
  const _NoPreview({
    required this.onExportPdf,
    required this.onExportExcel,
    required this.exportingPdf,
    required this.exportingExcel,
  });

  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;
  final bool exportingPdf;
  final bool exportingExcel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 64,
              color: context.palette.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.exportNoPreviewTitle,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.exportNoPreviewBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.exportPdf,
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: exportingPdf,
                    onPressed: (exportingPdf || exportingExcel) ? null : onExportPdf,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Unduh Excel',
                    icon: Icons.table_chart_outlined,
                    backgroundColor: context.palette.primaryContainer,
                    foregroundColor: context.palette.primary,
                    isLoading: exportingExcel,
                    onPressed: (exportingPdf || exportingExcel) ? null : onExportExcel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

