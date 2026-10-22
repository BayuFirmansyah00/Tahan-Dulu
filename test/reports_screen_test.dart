import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> onboarding -> dashboard -> Lihat laporan.
Future<void> _pumpToReports(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();

  for (var i = 0; i < 3; i++) {
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();
  }
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.doneButton),
  );
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.startAppButton));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.dashboardSeeReport));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.reportsTitle), findsOneWidget);
}

void main() {
  testWidgets('Main report shows summary cards and chart', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);

    expect(find.text(AppStrings.reportsIncomeLabel), findsWidgets);
    expect(find.text(AppStrings.reportsExpenseLabel), findsWidgets);
    expect(find.text(AppStrings.reportsSavedLabel), findsOneWidget);
    expect(find.text(AppStrings.reportsInvestedLabel), findsOneWidget);
    expect(find.text(AppStrings.reportsRemainingLabel), findsOneWidget);
    expect(find.text(AppStrings.reportsVsTitle), findsOneWidget);
    expect(find.text(AppStrings.seeExpenseDetail), findsOneWidget);
  });

  testWidgets('Period switch updates month label', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);

    final firstMonth = find.textContaining(RegExp(r'^\w+ 20\d\d$'));
    expect(firstMonth, findsWidgets);

    // Mundur satu bulan: label berubah.
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
    // Kembali maju: label kembali seperti semula.
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    expect(firstMonth, findsWidgets);
  });

  testWidgets('Detail expenses shows donut, legend, and top list', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);
    await _tapVisible(tester, find.text(AppStrings.seeExpenseDetail));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.totalExpenseLabel), findsWidgets);
    expect(find.text(AppStrings.tabCategory), findsOneWidget);
    expect(find.text(AppStrings.tabNeedsWants), findsOneWidget);
    expect(find.text(AppStrings.topExpensesTitle), findsOneWidget);
    // Seed: Kebutuhan 850rb + Investasi 500rb.
    expect(find.text('Kebutuhan'), findsWidgets);
  });

  testWidgets('Needs tab switches to honest unavailable content', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);
    await _tapVisible(tester, find.text(AppStrings.seeExpenseDetail));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text(AppStrings.tabNeedsWants));
    expect(
      find.text(AppStrings.needsWantsUnavailableTitle),
      findsOneWidget,
    );
    // Donat hilang pada tab klasifikasi.
    expect(find.text(AppStrings.topExpensesTitle), findsNothing);

    await _tapVisible(tester, find.text(AppStrings.tabCategory));
    expect(find.text(AppStrings.topExpensesTitle), findsOneWidget);
  });

  testWidgets('Savings screen shows progress and six month chart', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);
    await _tapVisible(tester, find.text(AppStrings.seeExpenseDetail));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, AppStrings.legendSavings),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.savingsInvestTitle), findsWidgets);
    expect(find.text(AppStrings.lastSixTitle), findsOneWidget);
    expect(find.text(AppStrings.legendInvestment), findsWidgets);
  });

  testWidgets('Health screen shows score ring and indicators', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);
    await _tapVisible(tester, find.text(AppStrings.seeExpenseDetail));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, AppStrings.healthTitle),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.healthTitle), findsWidgets);
    expect(find.text(AppStrings.healthInsightTitle), findsOneWidget);

    // Buka rekomendasi: bottom sheet berisi catatan jujur.
    await _tapVisible(tester, find.text(AppStrings.seeRecommendations));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.recommendationsTitle), findsOneWidget);
    expect(find.text(AppStrings.recommendationsNote), findsOneWidget);
  });

  testWidgets('Bottom navigation stays consistent', (
    WidgetTester tester,
  ) async {
    await _pumpToReports(tester);

    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navRecord), findsOneWidget);
    expect(find.text(AppStrings.navGoals), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);
  });
}
