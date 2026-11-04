import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/utils/currency_formatter.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';

/// Home Dashboard (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> Dashboard (onboarding is now optional via popup).
Future<void> _pumpToDashboard(
  WidgetTester tester, {
  ProviderContainer? container,
}) async {
  if (container != null) {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TahanDuluApp(),
      ),
    );
  } else {
    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  }
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
  expect(find.text('Bayu'), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Dashboard opens with greeting and name', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    expect(find.text('Bayu'), findsOneWidget);
  });

  testWidgets('Hero shows safe daily spending', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.safeTodayTitle), findsOneWidget);
    // 1.250.000 / hari-di-bulan-ini, floor per seribu.
    expect(find.text('Rp40.000'), findsOneWidget);
    expect(find.textContaining('Sisa budget bulan ini'), findsOneWidget);
  });

  testWidgets('Total balance sums instrument initial balances', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.totalBalanceTitle), findsOneWidget);
    expect(find.text('Rp6.500.000'), findsOneWidget);
    expect(find.text(AppStrings.balanceRecordedHint), findsOneWidget);
  });

  testWidgets('Eye toggle obscures balance', (WidgetTester tester) async {
    await _pumpToDashboard(tester);
    expect(find.text('Rp6.500.000'), findsOneWidget);

    await _tapVisible(tester, find.byIcon(Icons.visibility_outlined));
    expect(find.text('Rp••••••'), findsOneWidget);
    expect(find.text('Rp6.500.000'), findsNothing);
  });

  testWidgets('Goals section shows onboarding goal with progress', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.goalsSection), findsOneWidget);
    expect(find.text(AppStrings.dashboardSeeAll), findsOneWidget);
    expect(find.text('Investasi'), findsOneWidget);
    expect(find.text('Rp0 / Rp10.000.000'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('TahanDulu card appears with pending count', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.tahanDuluTitle), findsOneWidget);
    expect(find.text('1 ${AppStrings.pendingSuffix}'), findsOneWidget);
    expect(find.text(AppStrings.tahanDuluSee), findsOneWidget);
  });

  testWidgets('Monthly summary shows actual month income and expense', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    // Nilai aktual bulan berjalan (bukan angka rencana).
    expect(find.text(AppStrings.monthlySummary), findsOneWidget);
    expect(find.text(AppStrings.expense), findsWidgets);
    expect(find.text(AppStrings.income), findsWidgets);
    expect(
      find.textContaining(RegExp(r'^Rp[0-9.]+$')),
      findsWidgets,
    );
  });

  testWidgets('Recording an expense updates dashboard summary', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pumpToDashboard(tester, container: container);

    final before = container.read(dashboardDataProvider).value!;

    // Catat pengeluaran 75rb hari ini lewat UI.
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byType(DashboardBottomNav),
        matching: find.text(AppStrings.navTransactions),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    final formFields = find.byType(TextFormField);
    await tester.ensureVisible(formFields.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(formFields.at(0), '75000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.catFood));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA — Bank').last);
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.reviewAction),
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveTransaction),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.backToHome));
    await tester.pumpAndSettle();

    final after = container.read(dashboardDataProvider).value!;
    expect(
      after.actualMonthExpense,
      before.actualMonthExpense + 75000,
    );
    expect(after.totalBalance, before.totalBalance - 75000);
    expect(
      find.text(
        CurrencyFormatter.formatCompact(after.actualMonthExpense),
      ),
      findsWidgets,
    );
  });

  testWidgets('Bottom navigation with record button appears', (
    WidgetTester tester,
  ) async {
    await _pumpToDashboard(tester);

    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navTransactions), findsOneWidget);
    expect(find.text(AppStrings.navRecord), findsOneWidget);
    expect(find.text(AppStrings.navGoals), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);
    expect(find.byKey(const Key('record_button')), findsOneWidget);
    expect(find.byKey(const Key('record_button_icon')), findsOneWidget);
  });
}
