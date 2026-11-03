import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/models/monthly_report.dart';
import 'package:tahan_dulu/features/reports/export/report_export.dart';
import 'package:tahan_dulu/features/reports/export/report_export_data.dart';
import 'package:tahan_dulu/features/reports/export/report_pdf_document.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_export_screen.dart';

MonthlyReport _sampleReport() {
  const cats = [
    ('Makan & Minum', 1750000.0),
    ('Transportasi', 1100000.0),
    ('Belanja', 950000.0),
    ('Tagihan', 660000.0),
    ('Hiburan', 430000.0),
    ('Lainnya', 540000.0),
  ];
  const total = 5430000.0;
  return MonthlyReport(
    month: DateTime(2026, 10),
    income: 8250000,
    expense: total,
    prevIncome: 8000000,
    prevExpense: 5000000,
    categories: [
      for (final c in cats)
        CategoryTotal(label: c.$1, amount: c.$2, share: c.$2 / total),
    ],
    savingsMonth: 1200000,
    investmentMonth: 600000,
    savingsTarget: 10000000,
    savingsSaved: 6500000,
    investmentTarget: 10000000,
    investmentSaved: 3500000,
    lastSix: const [],
  );
}

List<FinancialGoal> _sampleGoals() => const [
      FinancialGoal(
        id: 'g1',
        name: 'Dana Darurat',
        targetAmount: 10000000,
        currentAmount: 6500000,
      ),
      FinancialGoal(
        id: 'g2',
        name: 'Liburan',
        targetAmount: 5000000,
        currentAmount: 5000000,
      ),
      FinancialGoal(
        id: 'g3',
        name: 'Investasi',
        targetAmount: 10000000,
        currentAmount: 3500000,
        category: GoalCategory.investment,
      ),
    ];

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Tahap 18: payload export', () {
    test('ID laporan unik dan berformat', () {
      final id = buildReportId(
        DateTime(2026, 10),
        now: DateTime(2026, 10, 28, 14, 30),
      );
      expect(id, matches(RegExp(r'^TD-2026-10-\d{4}$')));
      final id2 = buildReportId(
        DateTime(2026, 10),
        now: DateTime(2026, 10, 28, 14, 30, 1),
      );
      expect(id2, isNot(equals(id)));
    });

    test('nama file informatif', () {
      expect(exportFilename(DateTime(2026, 10)), 'laporan_keuangan_2026-10.pdf');
    });

    test('QR hanya ID + periode, tanpa nominal/PII', () {
      const payload = 'TAHANDULU|TD-2026-10-0018|2026-10';
      expect(qrPayloadFor('TD-2026-10-0018', DateTime(2026, 10)), payload);
      expect(payload.contains('Rp'), isFalse);
      expect(payload.contains('http'), isFalse);
    });

    test('payload konsisten dengan provider (tanpa double-count fee)',
        () {
      // amount transaksi sudah net (Tahap 17): dipakai apa adanya.
      final data = buildReportExportData(
        report: _sampleReport(),
        goals: _sampleGoals(),
        now: DateTime(2026, 10, 28, 14, 30),
      );
      expect(data.income, 8250000);
      expect(data.expense, 5430000);
      expect(data.net, 8250000 - 5430000);
      expect(
        data.categories.fold<double>(0, (s, e) => s + e.amount),
        data.expense,
      );
      expect(data.goalSummary!.monthDeposits, 1200000 + 600000);
      expect(data.goalSummary!.activeCount, 2);
      expect(data.goalSummary!.reachedCount, 1);
      expect(data.filename, 'laporan_keuangan_2026-10.pdf');
      expect(data.qrPayload, startsWith('TAHANDULU|${data.reportId}|'));
      expect(data.periodLabel, 'Oktober 2026');
      expect(data.dateRangeLabel, '1 - 31 Oktober 2026');
    });

    test('tanpa goal menyembunyikan ringkasan target', () {
      final data = buildReportExportData(
        report: _sampleReport(),
        goals: const [],
        now: DateTime(2026, 10, 28),
      );
      expect(data.goalSummary, isNull);
    });
  });

  group('Tahap 18: dokumen PDF', () {
    test('terbentuk dan beraudit %PDF', () async {
      final data = buildReportExportData(
        report: _sampleReport(),
        goals: _sampleGoals(),
        now: DateTime(2026, 10, 28, 14, 30),
      );
      final bytes = await buildReportPdf(data);
      expect(bytes, isNotEmpty);
      final head = String.fromCharCodes(bytes.take(5));
      expect(head, '%PDF-');
    });

    test('logo asli terpasang; fallback tanpa logo tetap jadi', () async {
      final data = buildReportExportData(
        report: _sampleReport(),
        goals: _sampleGoals(),
        now: DateTime(2026, 10, 28, 14, 30),
      );
      final logoFile = File('assets/branding/tahan_dulu_logo.png');
      expect(logoFile.existsSync(), isTrue);
      final withLogo =
          await buildReportPdf(data, logoBytes: logoFile.readAsBytesSync());
      final withoutLogo = await buildReportPdf(data);
      expect(withLogo.length, greaterThan(withoutLogo.length));
    });

    test('kosong dan nol tidak crash', () async {
      final empty = MonthlyReport(
        month: DateTime(2026, 10),
        income: 0,
        expense: 0,
        prevIncome: null,
        prevExpense: null,
        categories: const [],
        savingsMonth: 0,
        investmentMonth: 0,
        savingsTarget: 0,
        savingsSaved: 0,
        investmentTarget: 0,
        investmentSaved: 0,
        lastSix: const [],
      );
      final data = buildReportExportData(
        report: empty,
        goals: const [],
        now: DateTime(2026, 10, 28),
      );
      expect(data.hasExpenseData, isFalse);
      final bytes = await buildReportPdf(data);
      expect(bytes, isNotEmpty);
    });

    test('banyak kategori tetap jadi satu dokumen', () async {
      final base = _sampleReport();
      final many = MonthlyReport(
        month: base.month,
        income: base.income,
        expense: 40 * 100000,
        prevIncome: null,
        prevExpense: null,
        categories: [
          for (var i = 0; i < 40; i++)
            CategoryTotal(
              label: 'Kategori ${i + 1}',
              amount: 100000,
              share: 1 / 40,
            ),
        ],
        savingsMonth: 0,
        investmentMonth: 0,
        savingsTarget: 0,
        savingsSaved: 0,
        investmentTarget: 0,
        investmentSaved: 0,
        lastSix: const [],
      );
      final data = buildReportExportData(
        report: many,
        goals: const [],
        now: DateTime(2026, 10, 28),
      );
      final bytes = await buildReportPdf(data);
      final few = await buildReportPdf(
        buildReportExportData(
          report: base,
          goals: const [],
          now: DateTime(2026, 10, 28),
        ),
      );
      expect(bytes.length, greaterThan(few.length));
    });

    test('dump contoh untuk inspeksi visual', () async {
      final dir = Directory('build/pdf_preview');
      dir.createSync(recursive: true);
      final logo = File('assets/branding/tahan_dulu_logo.png').readAsBytesSync();
      final rich = buildReportExportData(
        report: _sampleReport(),
        goals: _sampleGoals(),
        now: DateTime(2026, 10, 28, 14, 30),
      );
      File('${dir.path}/rich.pdf')
          .writeAsBytesSync(await buildReportPdf(rich, logoBytes: logo));
      final empty = buildReportExportData(
        report: MonthlyReport(
          month: DateTime(2026, 11),
          income: 0,
          expense: 0,
          prevIncome: null,
          prevExpense: null,
          categories: const [],
          savingsMonth: 0,
          investmentMonth: 0,
          savingsTarget: 0,
          savingsSaved: 0,
          investmentTarget: 0,
          investmentSaved: 0,
          lastSix: const [],
        ),
        goals: const [],
        now: DateTime(2026, 11, 2, 9, 5),
      );
      File('${dir.path}/empty.pdf')
          .writeAsBytesSync(await buildReportPdf(empty, logoBytes: logo));
    });
  });

  group('Tahap 18: share', () {
    test('byte kosong ditolak', () async {
      final result = await exportReportPdf(
        bytes: Uint8List(0),
        filename: 'x.pdf',
      );
      expect(result.ok, isFalse);
    });

    test('sukses dan gagal share', () async {
      final sample = Uint8List.fromList(const [1, 2, 3]);
      final ok = await exportReportPdf(
        bytes: sample,
        filename: 'x.pdf',
        shareWith: (b, name) async => b.isNotEmpty && name.isNotEmpty,
      );
      expect(ok.ok, isTrue);
      final printFallback = await exportReportPdf(
        bytes: sample,
        filename: 'x.pdf',
        shareWith: (b, name) async => false,
        printWith: (b, name) async {},
      );
      expect(printFallback.ok, isTrue);
      final error = await exportReportPdf(
        bytes: sample,
        filename: 'x.pdf',
        shareWith: (b, name) => throw Exception('platform'),
        printWith: (b, name) => throw Exception('no-print'),
      );
      expect(error.ok, isFalse);
    });
  });

  group('Tahap 18: tombol ekspor di Reports', () {
    testWidgets('membuka pratinjau', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), 'bayu@email.com');
      await tester.enterText(loginFields.at(1), 'rahasia123');
      await tester.pump();
      await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
      await tester.pumpAndSettle();
      // Langsung ke Dashboard; tutup popup onboarding bila muncul.
      if (find.text(AppStrings.onboardingPopupLater).evaluate().isNotEmpty) {
        await _tapVisible(tester, find.text(AppStrings.onboardingPopupLater));
        await tester.pumpAndSettle();
      }
      await _tapVisible(tester, find.text(AppStrings.dashboardSeeReport));
      expect(find.text(AppStrings.reportsTitle), findsOneWidget);

      // PdfPreview tak pernah settle (render internal) -> pump manual.
      await tester.ensureVisible(find.text(AppStrings.exportPdf));
      await tester.pump();
      await tester.tap(find.text(AppStrings.exportPdf));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(AppStrings.exportPreviewTitle), findsOneWidget);
      expect(find.text(AppStrings.exportPdf), findsWidgets);
    });
    testWidgets('fallback saat perangkat tak bisa raster', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRasterCapableProvider.overrideWith((ref) async => false),
          ],
          child: const MaterialApp(home: ReportExportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.exportNoPreviewTitle), findsOneWidget);
      expect(find.byType(PdfPreview), findsNothing);
      expect(find.text(AppStrings.exportPdf), findsWidgets);
    });
  });
}
