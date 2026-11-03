import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Golden regresi visual laporan pada viewport phone 390x844.
void main() {
  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  Future<void> pumpToReports(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tapVisible(tester, find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();
    // Langsung ke Dashboard; tutup popup onboarding bila muncul.
    if (find.text(AppStrings.onboardingPopupLater).evaluate().isNotEmpty) {
      await tapVisible(tester, find.text(AppStrings.onboardingPopupLater));
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, find.text(AppStrings.navReports));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.dashboardSeeReport));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reportsTitle), findsOneWidget);
  }

  testWidgets('Reports golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await initializeDateFormatting('id_ID');
    await pumpToReports(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/reports_screen.png'),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Expenses golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await initializeDateFormatting('id_ID');
    await pumpToReports(tester);

    await tapVisible(tester, find.text(AppStrings.seeExpenseDetail));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.totalExpenseLabel), findsWidgets);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/report_expenses_screen.png'),
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
