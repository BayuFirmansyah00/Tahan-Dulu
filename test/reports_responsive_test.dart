import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/goals/presentation/providers/goals_controller.dart';
import 'package:tahan_dulu/data/repositories/report_repository.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/reports_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_expenses_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_export_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_health_screen.dart';
import 'package:tahan_dulu/features/reports/presentation/screens/report_savings_screen.dart';

void main() {
  Widget createSubject(Widget child) {
    return ProviderScope(
      overrides: [
        reportRepositoryProvider.overrideWithValue(MockReportRepository()),
        goalsListProvider.overrideWith((ref) => Future.value(<FinancialGoal>[])),
        reportRasterCapableProvider.overrideWith((ref) => Future.value(false)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  for (final width in [360.0, 393.0, 412.0]) {
    group('Reports screens responsive test on ${width.toInt()}px', () {
      testWidgets('ReportsScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(const ReportsScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.reportsTitle), findsOneWidget);
        expect(find.text(AppStrings.reportsIncomeLabel), findsWidgets);
        expect(find.text(AppStrings.reportsExpenseLabel), findsWidgets);
        expect(find.text(AppStrings.exportPdf), findsOneWidget);
      });

      testWidgets('ReportExpensesScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(const ReportExpensesScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.totalExpenseLabel), findsWidgets);
        expect(find.text(AppStrings.tabCategory), findsOneWidget);
      });

      testWidgets('ReportHealthScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(const ReportHealthScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.healthTitle), findsWidgets);
        expect(find.text(AppStrings.healthInsightTitle), findsOneWidget);
      });

      testWidgets('ReportSavingsScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(const ReportSavingsScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.savingsInvestTitle), findsWidgets);
        expect(find.text(AppStrings.lastSixTitle), findsOneWidget);
      });

      testWidgets('ReportExportScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createSubject(const ReportExportScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.exportPreviewTitle), findsOneWidget);
        expect(find.text(AppStrings.exportPdf), findsOneWidget);
        expect(find.text('Unduh Excel'), findsOneWidget);
      });
    });
  }
}
