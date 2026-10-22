import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> onboarding -> dashboard -> tab Tujuan.
Future<void> _pumpToGoals(WidgetTester tester) async {
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
  await _tapVisible(
    tester,
    find.descendant(
      of: find.byType(DashboardBottomNav),
      matching: find.text(AppStrings.navGoals),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.goalsListTitle), findsOneWidget);
}

/// Buat target Lainnya 12jt lewat UI, berhenti di layar setup.
/// Kategori standar memakai nama otomatis; nama kustom perlu Lainnya.
Future<void> _fillCreate(WidgetTester tester) async {
  await _tapVisible(tester, find.text(AppStrings.newGoalButton));
  await tester.pumpAndSettle();

  await _tapVisible(tester, find.text(AppStrings.goalCatOthers));
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Laptop Baru');
  await tester.enterText(fields.at(1), '12000000');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.goalDateHint));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Lanjut dari create yang sudah valid ke setup lalu simpan.
Future<void> _saveFromSetup(WidgetTester tester) async {
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueAction),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.setupGoalTitle), findsOneWidget);

  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.saveGoalAction),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('List shows seed goal and empty-new action', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);

    expect(find.text(AppStrings.goalsListSubtitle), findsOneWidget);
    expect(find.text('Target Investasi'), findsOneWidget);
    // Persen tampil di ringkasan total dan kartu (keduanya 35%).
    expect(find.text('35%'), findsWidgets);
    expect(find.text(AppStrings.newGoalButton), findsOneWidget);
  });

  testWidgets('Bottom navigation stays visible on goals', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);

    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navRecord), findsOneWidget);
    expect(find.text(AppStrings.navGoals), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DashboardBottomNav),
        matching: find.byIcon(Icons.add),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Create validates empty submit', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _tapVisible(tester, find.text(AppStrings.newGoalButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.createGoalQuestion), findsOneWidget);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueAction),
    );

    expect(find.text(AppStrings.goalNameRequired), findsOneWidget);
    expect(find.text(AppStrings.goalAmountRequired), findsOneWidget);
    expect(find.text(AppStrings.setupGoalTitle), findsNothing);
  });

  testWidgets('Create to setup to detail chain', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _fillCreate(tester);
    await _saveFromSetup(tester);

    // Mendarat di detail target baru.
    expect(find.text('Laptop Baru'), findsWidgets);
    expect(find.text(AppStrings.addFundsAction), findsOneWidget);
    expect(find.text(AppStrings.editGoalAction), findsOneWidget);
  });

  testWidgets('Deposit updates detail and history', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _fillCreate(tester);
    await _saveFromSetup(tester);

    await _tapVisible(tester, find.text(AppStrings.addFundsAction));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2000000');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.confirmDepositAction),
    );
    await tester.pumpAndSettle();

    // Kembali ke detail dengan progres baru (pop setelah simpan).
    expect(find.text(AppStrings.goalDetailTitle), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.historyTitle));
    await tester.pumpAndSettle();
    expect(find.text('Rp2.000.000'), findsWidgets);
  });

  testWidgets('Deposit reaching 100 percent opens achieved', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);

    // Buat target kecil 100rb berkategori Lainnya.
    await _tapVisible(tester, find.text(AppStrings.newGoalButton));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.goalCatOthers));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dana Receh');
    await tester.enterText(fields.at(1), '100000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.goalDateHint));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueAction),
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveGoalAction),
    );
    await tester.pumpAndSettle();

    // Setor penuh -> layar tercapai.
    await _tapVisible(tester, find.text(AppStrings.addFundsAction));
    await tester.pumpAndSettle();
    final depositFields = find.byType(TextFormField);
    await tester.enterText(depositFields.at(0), '100000');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.confirmDepositAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.achievedTitle), findsOneWidget);
    expect(find.text(AppStrings.achievedBadge), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.backToHome));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    // Siram timer mock yang mungkin tersisa akibat navigasi terakhir.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Simulate changes estimate without mutating', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _tapVisible(tester, find.text('Target Investasi'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.simulateTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.simulateQuestion), findsOneWidget);
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(60, 0));
    await tester.pumpAndSettle();

    // Masih di layar simulasi (tidak ada mutasi/navigasi).
    expect(find.text(AppStrings.simulateTitle), findsOneWidget);
    expect(find.text(AppStrings.usePlanAction), findsOneWidget);
  });

  testWidgets('Priority save returns to list', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _tapVisible(tester, find.byTooltip(AppStrings.priorityTitle));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.priorityTitle), findsOneWidget);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.savePriorityAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.goalsListTitle), findsOneWidget);
  });

  testWidgets('Edit saves renamed goal', (
    WidgetTester tester,
  ) async {
    await _pumpToGoals(tester);
    await _tapVisible(tester, find.text('Target Investasi'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.editGoalAction));
    await tester.pumpAndSettle();

    // Kategori standar menyembunyikan field nama; pindah ke Lainnya
    // untuk mengganti nama (nama lama dipertahankan di field).
    await _tapVisible(tester, find.text(AppStrings.goalCatOthers));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Investasi Baru');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveChanges),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investasi Baru'), findsOneWidget);
  });
}
