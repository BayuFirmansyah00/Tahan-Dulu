import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/currency_formatter.dart';
import 'package:tahan_dulu/data/models/api_financial_instrument.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/widgets/admin_fee_form_section.dart';

void main() {
  group('Fase 4A: Multi-Rekening Admin Fee Model & Perhitungan Bisnis', () {
    test('1. Skenario Multi-Rekening: BCA (15k tgl 5), Mandiri (12.5k tgl 20), BRI (6.5k tgl 27) = Rp34.000', () {
      final bca = FinancialAccount(
        id: 'acc-bca',
        name: 'BCA Utama',
        type: AccountType.bank,
        balance: 5000000,
        monthlyAdminFee: 15000,
        adminFeeDay: 5,
        adminFeeEnabled: true,
      );

      final mandiri = FinancialAccount(
        id: 'acc-mandiri',
        name: 'Mandiri Payroll',
        type: AccountType.bank,
        balance: 3500000,
        monthlyAdminFee: 12500,
        adminFeeDay: 20,
        adminFeeEnabled: true,
      );

      final bri = FinancialAccount(
        id: 'acc-bri',
        name: 'BRI Simpedes',
        type: AccountType.bank,
        balance: 1500000,
        monthlyAdminFee: 6500,
        adminFeeDay: 27,
        adminFeeEnabled: true,
      );

      final accounts = [bca, mandiri, bri];

      // Verifikasi total saldo tetap utuh (biaya admin tidak memotong saldo)
      final totalBalance = accounts.fold<double>(0.0, (sum, a) => sum + a.balance);
      expect(totalBalance, 10000000);

      // Verifikasi total estimasi biaya admin bulanan
      final totalMonthlyAdminFee = accounts
          .where((a) => a.adminFeeEnabled)
          .fold<double>(0.0, (sum, a) => sum + a.monthlyAdminFee);

      expect(totalMonthlyAdminFee, 34000);
      expect(CurrencyFormatter.formatCompact(totalMonthlyAdminFee), 'Rp34.000');
    });

    test('2. Dua rekening dari bank yang sama dengan konfigurasi biaya berbeda', () {
      final bcaBisnis = FinancialAccount(
        id: 'acc-bca-bisnis',
        name: 'BCA Bisnis Giro',
        type: AccountType.bank,
        balance: 20000000,
        monthlyAdminFee: 25000,
        adminFeeDay: 10,
        adminFeeEnabled: true,
      );

      final bcaTabungan = FinancialAccount(
        id: 'acc-bca-tabungan',
        name: 'BCA Tahapan Pribadi',
        type: AccountType.bank,
        balance: 5000000,
        monthlyAdminFee: 15000,
        adminFeeDay: 5,
        adminFeeEnabled: true,
      );

      expect(bcaBisnis.monthlyAdminFee, 25000);
      expect(bcaBisnis.adminFeeDay, 10);
      expect(bcaTabungan.monthlyAdminFee, 15000);
      expect(bcaTabungan.adminFeeDay, 5);

      final total = [bcaBisnis, bcaTabungan]
          .where((a) => a.adminFeeEnabled)
          .fold<double>(0.0, (sum, a) => sum + a.monthlyAdminFee);
      expect(total, 40000);
    });

    test('3. Independensi Akun: edit akun satu tidak mengubah akun lain & toggle nonaktif', () {
      final bca = FinancialAccount(
        id: 'acc-bca',
        name: 'BCA Utama',
        type: AccountType.bank,
        balance: 5000000,
        monthlyAdminFee: 15000,
        adminFeeDay: 5,
        adminFeeEnabled: true,
      );

      final mandiri = FinancialAccount(
        id: 'acc-mandiri',
        name: 'Mandiri Payroll',
        type: AccountType.bank,
        balance: 3500000,
        monthlyAdminFee: 12500,
        adminFeeDay: 20,
        adminFeeEnabled: true,
      );

      // Edit Mandiri: ubah biaya jadi 10.000 tgl 25
      final mandiriUpdated = mandiri.copyWith(
        monthlyAdminFee: 10000,
        adminFeeDay: 25,
      );

      // BCA tidak boleh terpengaruh
      expect(bca.monthlyAdminFee, 15000);
      expect(bca.adminFeeDay, 5);
      expect(mandiriUpdated.monthlyAdminFee, 10000);
      expect(mandiriUpdated.adminFeeDay, 25);

      // Total baru
      var total = [bca, mandiriUpdated]
          .where((a) => a.adminFeeEnabled)
          .fold<double>(0.0, (sum, a) => sum + a.monthlyAdminFee);
      expect(total, 25000);

      // Toggle nonaktifkan biaya admin pada BCA (bebas biaya)
      final bcaDisabled = bca.copyWith(adminFeeEnabled: false);
      total = [bcaDisabled, mandiriUpdated]
          .where((a) => a.adminFeeEnabled)
          .fold<double>(0.0, (sum, a) => sum + a.monthlyAdminFee);
      expect(total, 10000);
    });

    test('4. E-Wallet dan Cash tidak dikenakan biaya admin bulanan', () {
      final gopay = FinancialAccount(
        id: 'acc-gopay',
        name: 'GoPay',
        type: AccountType.ewallet,
        balance: 250000,
        monthlyAdminFee: 0,
        adminFeeDay: null,
        adminFeeEnabled: false,
      );

      final cash = FinancialAccount(
        id: 'acc-cash',
        name: 'Dompet Tunai',
        type: AccountType.legacyCash,
        balance: 500000,
        monthlyAdminFee: 0,
        adminFeeDay: null,
        adminFeeEnabled: false,
      );

      expect(gopay.adminFeeEnabled, false);
      expect(gopay.monthlyAdminFee, 0);
      expect(gopay.adminFeeDay, isNull);
      expect(gopay.getNextAdminFeeDate(), isNull);

      expect(cash.adminFeeEnabled, false);
      expect(cash.monthlyAdminFee, 0);
      expect(cash.adminFeeDay, isNull);
      expect(cash.getNextAdminFeeDate(), isNull);
    });

    test('5. Penyesuaian tanggal pemotongan (getNextAdminFeeDate) untuk bulan pendek & kabisat', () {
      final accountTgl31 = FinancialAccount(
        id: 'acc-31',
        name: 'Rekening Akhir Bulan',
        type: AccountType.bank,
        balance: 1000000,
        monthlyAdminFee: 10000,
        adminFeeDay: 31,
        adminFeeEnabled: true,
      );

      // Februari kabisat (2024-02-05) -> tgl 31 disesuaikan ke tgl 29 Februari 2024
      final nextFebLeap = accountTgl31.getNextAdminFeeDate(DateTime(2024, 2, 5));
      expect(nextFebLeap, DateTime(2024, 2, 29));

      // Februari non-kabisat (2025-02-05) -> tgl 31 disesuaikan ke tgl 28 Februari 2025
      final nextFebNonLeap = accountTgl31.getNextAdminFeeDate(DateTime(2025, 2, 5));
      expect(nextFebNonLeap, DateTime(2025, 2, 28));

      // April (30 hari, diuji pada 2025-04-01) -> tgl 31 disesuaikan ke tgl 30 April 2025
      final nextApril = accountTgl31.getNextAdminFeeDate(DateTime(2025, 4, 1));
      expect(nextApril, DateTime(2025, 4, 30));

      // Tanggal normal: tgl 15 diuji pada 10 Maret 2025 -> tgl 15 Maret 2025
      final accountTgl15 = accountTgl31.copyWith(adminFeeDay: 15);
      final nextMar = accountTgl15.getNextAdminFeeDate(DateTime(2025, 3, 10));
      expect(nextMar, DateTime(2025, 3, 15));

      // Tanggal sudah lewat: tgl 15 diuji pada 20 Maret 2025 -> tgl 15 April 2025
      final nextApr = accountTgl15.getNextAdminFeeDate(DateTime(2025, 3, 20));
      expect(nextApr, DateTime(2025, 4, 15));
    });

    test('6. Parsing API Financial Instrument JSON serialization', () {
      final json = {
        'id': 101,
        'name': 'BCA Prioritas',
        'type': 'bank',
        'balance': '7500000.00',
        'monthly_admin_fee': 20000,
        'monthly_admin_fee_formatted': 'Rp 20.000',
        'admin_fee_day': 8,
        'admin_fee_enabled': true,
        'next_admin_fee_date': '2026-12-08',
      };

      final apiModel = ApiFinancialInstrument.fromJson(json);
      expect(apiModel.name, 'BCA Prioritas');
      expect(apiModel.monthlyAdminFee, 20000.0);
      expect(apiModel.monthlyAdminFeeFormatted, 'Rp 20.000');
      expect(apiModel.adminFeeDay, 8);
      expect(apiModel.adminFeeEnabled, true);
      expect(apiModel.nextAdminFeeDate, '2026-12-08');

      // Mapping ke FinancialInstrument (onboarding)
      final fi = FinancialInstrument(
        id: apiModel.id.toString(),
        name: apiModel.name,
        type: InstrumentType.bank,
        initialBalance: apiModel.balance.toDouble(),
        monthlyAdminFee: apiModel.monthlyAdminFee.toDouble(),
        adminFeeDay: apiModel.adminFeeDay ?? 15,
        adminFeeEnabled: apiModel.adminFeeEnabled,
      );

      expect(fi.monthlyAdminFee, 20000.0);
      expect(fi.adminFeeDay, 8);
      expect(fi.adminFeeEnabled, true);
    });
  });

  group('Fase 4A: Widget AdminFeeFormSection', () {
    testWidgets('Tampil dengan opsi Bebas Biaya vs Ada Biaya dan interaksi toggle', (tester) async {
      bool enabled = false;
      int feeDay = 15;
      final feeController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AdminFeeFormSection(
                  enabled: enabled,
                  onEnabledChanged: (val) => setState(() => enabled = val),
                  feeController: feeController,
                  feeDay: feeDay,
                  onDayChanged: (d) => setState(() => feeDay = d),
                );
              },
            ),
          ),
        ),
      );

      // Judul section
      expect(find.text('Biaya Administrasi Bulanan'), findsOneWidget);
      expect(find.text('Tidak Ada'), findsOneWidget);
      expect(find.text('Bebas biaya'), findsOneWidget);
      expect(find.text('Ada Biaya'), findsOneWidget);
      expect(find.text('Rutin bulanan'), findsOneWidget);

      // Dalam kondisi awal (enabled = false), input nominal belum tampil
      expect(find.text('Nominal Biaya Admin'), findsNothing);
      expect(find.text('Tanggal Pemotongan'), findsNothing);

      // Tap opsi "Ada Biaya"
      await tester.tap(find.text('Ada Biaya'));
      await tester.pumpAndSettle();

      // Sekarang input nominal dan tanggal pemotongan harus tampil
      expect(enabled, true);
      expect(find.text('Nominal Biaya Admin'), findsOneWidget);
      expect(find.text('Tanggal Pemotongan'), findsOneWidget);
      expect(find.text('Setiap tanggal 15'), findsOneWidget);

      // Teks penjelasan penyesuaian tanggal akhir bulan
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Tap kembali ke "Tidak Ada"
      await tester.tap(find.text('Tidak Ada'));
      await tester.pumpAndSettle();

      expect(enabled, false);
      expect(find.text('Nominal Biaya Admin'), findsNothing);
    });
  });

  group('Fase 4A: Widget AccountsScreen & AccountDetailScreen UI', () {
    testWidgets('AccountsScreen menampilkan banner total biaya admin dan badge rekening', (tester) async {
      final bca = FinancialAccount(
        id: 'acc-1',
        name: 'BCA Utama',
        type: AccountType.bank,
        balance: 5000000,
        monthlyAdminFee: 15000,
        adminFeeDay: 5,
        adminFeeEnabled: true,
      );
      final mandiri = FinancialAccount(
        id: 'acc-2',
        name: 'Mandiri Bebas',
        type: AccountType.bank,
        balance: 3000000,
        monthlyAdminFee: 0,
        adminFeeDay: 15,
        adminFeeEnabled: false,
      );

      final overviews = [
        AccountOverview(
          account: bca,
          currentBalance: 5000000,
          transactionCount: 0,
        ),
        AccountOverview(
          account: mandiri,
          currentBalance: 3000000,
          transactionCount: 0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsOverviewProvider
                .overrideWith((ref) async => overviews),
            accountsTotalProvider.overrideWith((ref) => 8000000.0),
          ],
          child: const MaterialApp(
            home: AccountsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner total estimasi
      expect(find.text('Estimasi Biaya Admin: Rp15.000 / bln'), findsOneWidget);
      expect(
        find.text(
          'Perkiraan total biaya administrasi dari rekening aktif. Nilai ini tidak otomatis memotong saldo.',
        ),
        findsOneWidget,
      );

      // Badge pada kartu akun
      expect(find.text('Biaya admin: Rp15.000/bln (tgl 5)'), findsOneWidget);
      expect(find.text('Bebas biaya admin'), findsOneWidget);
    });

    testWidgets('AccountDetailScreen menampilkan detail kartu biaya admin dan jadwal pemotongan', (tester) async {
      final bca = FinancialAccount(
        id: 'acc-1',
        name: 'BCA Utama',
        type: AccountType.bank,
        balance: 5000000,
        monthlyAdminFee: 15000,
        adminFeeDay: 5,
        adminFeeEnabled: true,
      );

      final overviews = [
        AccountOverview(
          account: bca,
          currentBalance: 5000000,
          transactionCount: 0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsOverviewProvider
                .overrideWith((ref) async => overviews),
            transactionsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: AccountDetailScreen(accountId: 'acc-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biaya Administrasi Bulanan'), findsOneWidget);
      expect(find.text('Rp15.000 / bulan'), findsOneWidget);
      expect(find.text('Jadwal Pemotongan'), findsOneWidget);
      expect(find.text('Setiap tanggal 5'), findsOneWidget);
      expect(find.text('Estimasi Berikutnya'), findsOneWidget);
      expect(
        find.text(
          'Biaya ini adalah rencana terjadwal dan tidak memotong saldo secara otomatis.',
        ),
        findsOneWidget,
      );
    });
  });
}
