import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/widgets/app_button.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:tahan_dulu/features/goals/presentation/screens/goals_list_screen.dart';

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

/// Buka layar buat target dan pilih kategori.
Future<void> _newGoalWithCategory(
  WidgetTester tester,
  String categoryLabel,
) async {
  await _tapVisible(tester, find.text(AppStrings.newGoalButton));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(categoryLabel));
  await tester.pumpAndSettle();
}

/// Isi nominal + tanggal pada layar buat target.
Future<void> _fillAmountAndDate(
  WidgetTester tester,
  String amount,
) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.last, amount);
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.goalDateHint));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Tahap 31: nama otomatis kategori', () {
    testWidgets('kategori standar menyembunyikan field nama', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatSavings);

      // Hanya field nominal yang tersisa; field nama disembunyikan.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text(AppStrings.goalName), findsNothing);
      expect(find.text(AppStrings.goalNameAutoNote), findsOneWidget);
    });

    testWidgets('Lainnya menampilkan field nama dan wajib diisi', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);

      expect(find.byType(TextFormField), findsNWidgets(2));
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.continueAction),
      );
      await tester.pump();
      expect(find.text(AppStrings.goalNameRequired), findsOneWidget);
      expect(find.text(AppStrings.setupGoalTitle), findsNothing);
    });

    testWidgets('nama otomatis dipakai saat simpan kategori standar', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatSavings);
      await _fillAmountAndDate(tester, '5000000');
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.continueAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.setupGoalTitle), findsOneWidget);
      // Ringkasan menampilkan nama otomatis = label kategori.
      expect(find.text(AppStrings.goalCatSavings), findsWidgets);
    });

    testWidgets('kembali ke Lainnya mempertahankan nama kustom', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Kado Ultah',
      );
      await tester.pump();
      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text(AppStrings.goalCatOthers));
      await tester.pumpAndSettle();
      expect(find.text('Kado Ultah'), findsOneWidget);
    });

    testWidgets('pindah ke standar mengikuti kategori baru', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).first, 'Kado');
      await tester.pump();
      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      await tester.pumpAndSettle();
      await _fillAmountAndDate(tester, '12000000');
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.continueAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.goalCatHouse), findsWidgets);
      expect(find.text('Kado'), findsNothing);
    });

    testWidgets('ganti kategori tidak menghapus nominal dan tanggal', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).last, '5000000');
      await tester.pump();
      await _tapVisible(tester, find.text(AppStrings.goalDateHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.goalCatHouse));
      await tester.pumpAndSettle();

      expect(find.text('5.000.000'), findsOneWidget);
      expect(find.text(AppStrings.goalDateHint), findsNothing);
    });

    testWidgets('edit memuat kategori dan nama kustom tersimpan', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _tapVisible(tester, find.text('Target Investasi'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text(AppStrings.editGoalAction));
      await tester.pumpAndSettle();

      // Kategori standar: field nama disembunyikan, nominal dimuat.
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('10.000.000'), findsOneWidget);
      // Kembali ke Lainnya: nama kustom tersimpan muncul kembali.
      await _tapVisible(tester, find.text(AppStrings.goalCatOthers));
      await tester.pumpAndSettle();
      expect(find.text('Target Investasi'), findsWidgets);
    });
  });

  group('Tahap 31: rekomendasi dan estimasi di Atur Target', () {
    testWidgets('rekomendasi terisi otomatis dan ETA muncul', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).first, 'Kado');
      await tester.pump();
      await _fillAmountAndDate(tester, '12000000');
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.continueAction),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.setupGoalTitle), findsOneWidget);

      final planField = find.byType(TextFormField);
      expect(planField, findsOneWidget);
      final text =
          tester.widget<TextFormField>(planField).controller!.text;
      expect(text.isNotEmpty, isTrue);
      expect(find.text(AppStrings.goalEtaLabel), findsNothing);
      // Label ETA memakai format "Estimasi tercapai: ...".
      expect(find.textContaining('Estimasi tercapai'), findsOneWidget);
    });

    testWidgets('nominal kecil memicu peringatan melewati tenggat', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).first, 'Kado');
      await tester.pump();
      await _fillAmountAndDate(tester, '12000000');
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.continueAction),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '100000');
      await tester.pump();
      expect(find.text(AppStrings.goalShortfallNote), findsOneWidget);
      final warned = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                AppAssets.goalActionWarning,
      );
      expect(warned, findsOneWidget);
    });
  });

  group('Tahap 31: detail, setoran, riwayat', () {    testWidgets('detail menampilkan rekomendasi dan estimasi', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _tapVisible(tester, find.text('Target Investasi'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.goalRecommendLabel), findsOneWidget);
      // Seed tanpa tenggat: minta jadwal ulang, bukan estimasi palsu.
      expect(find.text(AppStrings.goalRescheduleNote), findsOneWidget);
      expect(find.text(AppStrings.goalDetailEta), findsOneWidget);
      expect(find.text(AppStrings.simulateUnreachable), findsOneWidget);
    });

    testWidgets('konfirmasi setoran aktif hanya bila input valid', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).first, 'Kado');
      await tester.pump();
      await _fillAmountAndDate(tester, '100000');
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

      await _tapVisible(tester, find.text(AppStrings.addFundsAction));
      await tester.pumpAndSettle();

      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, AppStrings.confirmDepositAction),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '50000');
      await tester.pump();
      final enabled = tester.widget<AppButton>(
        find.widgetWithText(AppButton, AppStrings.confirmDepositAction),
      );
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('setoran konsisten di detail dan riwayat', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _newGoalWithCategory(tester, AppStrings.goalCatOthers);
      await tester.enterText(find.byType(TextFormField).first, 'Kado');
      await tester.pump();
      await _fillAmountAndDate(tester, '12000000');
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

      await _tapVisible(tester, find.text(AppStrings.addFundsAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '2000000');
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.confirmDepositAction),
      );
      await tester.pumpAndSettle();

      // Detail: dana terkumpul bertambah.
      expect(find.text(AppStrings.goalDetailTitle), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.historyTitle));
      await tester.pumpAndSettle();
      // Riwayat: nominal tercatat + total konsisten.
      expect(find.text('Rp2.000.000'), findsWidgets);
      expect(find.text(AppStrings.historyTotal), findsOneWidget);
    });
  });

  group('Tahap 31: simulasi memakai mesin bersama', () {
    testWidgets('toggle mingguan lalu terapkan tanpa membuat setoran', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      await _tapVisible(tester, find.text('Target Investasi'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text(AppStrings.simulateTitle));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text(AppStrings.frequencyWeekly));
      await tester.pumpAndSettle();
      expect(find.textContaining('/ minggu'), findsWidgets);

      await _tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.usePlanAction),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, AppStrings.usePlanAction),
      );
      // Beri waktu mock repository (mockDelay) lalu settle.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Kembali ke detail: rencana mingguan tersimpan.
      expect(find.text(AppStrings.goalDetailTitle), findsOneWidget);
      expect(find.textContaining('/ minggu'), findsWidgets);

      // Simulasi tidak membuat setoran: riwayat tetap kosong
      // (kosong tampil di seksi grafik dan daftar).
      await _tapVisible(tester, find.text(AppStrings.historyTitle));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.historyEmpty), findsWidgets);
    });
  });

  group('Tahap 31: daftar dan responsivitas', () {
    testWidgets('kartu menampilkan tenggat dan badge status', (
      tester,
    ) async {
      await _pumpToGoals(tester);
      // Seed tanpa tenggat dan belum tercapai -> badge Aktif.
      expect(find.text(AppStrings.goalStatusActive), findsOneWidget);
      expect(find.text('Tenggat: -'), findsOneWidget);
    });

    testWidgets('tanpa overflow pada lebar 360, 393, 412', (
      tester,
    ) async {
      for (final width in [360.0, 393.0, 412.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: GoalsListScreen())),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: GoalDetailScreen(goalId: 'goal-investment'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
