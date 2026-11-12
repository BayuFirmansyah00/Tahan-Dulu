import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/features/transactions/domain/voice_transaction_parser.dart';

void main() {
  const parser = VoiceTransactionParser();

  final userAccounts = [
    const FinancialAccount(
      id: 'acc-1',
      name: 'BCA',
      type: AccountType.bank,
      balance: 5000000,
      institutionName: 'Bank Central Asia',
    ),
    const FinancialAccount(
      id: 'acc-2',
      name: 'Mandiri',
      type: AccountType.bank,
      balance: 2000000,
      institutionName: 'Bank Mandiri',
    ),
    const FinancialAccount(
      id: 'acc-3',
      name: 'GoPay',
      type: AccountType.ewallet,
      balance: 350000,
      institutionName: 'GoPay',
    ),
  ];

  group('VoiceTransactionParser Tests', () {
    test('Contoh prompt: Makan siang dua puluh lima ribu menggunakan BCA', () {
      final result = parser.parse(
        'Makan siang dua puluh lima ribu menggunakan BCA',
        userAccounts: userAccounts,
      );

      expect(result.type, equals(TransactionType.expense));
      expect(result.amount, equals(25000.0));
      expect(result.category, equals(TransactionCategory.food));
      expect(result.accountId, equals('acc-1'));
      expect(result.accountName, equals('BCA'));
      expect(result.description, contains('Makan siang'));
    });

    test('Beli bensin lima puluh ribu pakai Mandiri', () {
      final result = parser.parse(
        'Beli bensin lima puluh ribu pakai Mandiri',
        userAccounts: userAccounts,
      );

      expect(result.type, equals(TransactionType.expense));
      expect(result.amount, equals(50000.0));
      expect(result.category, equals(TransactionCategory.transport));
      expect(result.accountId, equals('acc-2'));
      expect(result.accountName, equals('Mandiri'));
      expect(result.description, contains('Beli bensin'));
    });

    test('Gaji bulanan lima juta masuk BCA', () {
      final result = parser.parse(
        'Gaji bulanan lima juta masuk BCA',
        userAccounts: userAccounts,
      );

      expect(result.type, equals(TransactionType.income));
      expect(result.amount, equals(5000000.0));
      expect(result.category, equals(TransactionCategory.salary));
      expect(result.accountId, equals('acc-1'));
    });

    test('Bayar listrik seratus ribu tanpa sebut akun', () {
      final result = parser.parse(
        'Bayar listrik seratus ribu',
        userAccounts: userAccounts,
      );

      expect(result.type, equals(TransactionType.expense));
      expect(result.amount, equals(100000.0));
      expect(result.category, equals(TransactionCategory.bills));
      expect(result.accountId, isNull);
      expect(result.hasAccount, isFalse);
    });

    test('Angka langsung dengan k atau rb: Kopi 25k pakai GoPay', () {
      final result = parser.parse(
        'Kopi 25k pakai GoPay',
        userAccounts: userAccounts,
      );

      expect(result.amount, equals(25000.0));
      expect(result.category, equals(TransactionCategory.food));
      expect(result.accountId, equals('acc-3'));
    });

    test('Kopi dua puluh ribu pakai GoPay', () {
      final result = parser.parse(
        'Kopi dua puluh ribu pakai GoPay',
        userAccounts: userAccounts,
      );

      expect(result.type, equals(TransactionType.expense));
      expect(result.amount, equals(20000.0));
      expect(result.category, equals(TransactionCategory.food));
      expect(result.accountId, equals('acc-3'));
      expect(result.accountName, equals('GoPay'));
      expect(result.description, contains('Kopi'));
    });

    test('Akun tidak dikenal tidak dikarang', () {
      final result = parser.parse(
        'Beli buku tiga puluh ribu pakai ShopeePay',
        userAccounts: userAccounts,
      );

      expect(result.amount, equals(30000.0));
      expect(result.category, equals(TransactionCategory.education));
      expect(result.accountId, isNull); // ShopeePay tidak ada di akun user
    });

    group('P0-02 Indonesian Word Number Variations', () {
      test('Lima ribu -> 5.000', () {
        final result = parser.parse('Beli kopi lima ribu');
        expect(result.amount, equals(5000.0));
      });

      test('Dua puluh ribu -> 20.000', () {
        final result = parser.parse('Dua puluh ribu');
        expect(result.amount, equals(20000.0));
      });

      test('Seratus lima puluh ribu -> 150.000 (tidak menjadi 1.050.000)', () {
        final result = parser.parse('Makan siang seratus lima puluh ribu');
        expect(result.amount, equals(150000.0));
      });

      test('Dua ratus lima puluh ribu -> 250.000 (tidak menjadi 2.050.000)', () {
        final result = parser.parse('Beli sepatu dua ratus lima puluh ribu');
        expect(result.amount, equals(250000.0));
      });

      test('Tiga ratus empat puluh lima ribu -> 345.000', () {
        final result = parser.parse('Belanja tiga ratus empat puluh lima ribu');
        expect(result.amount, equals(345000.0));
      });

      test('Satu juta dua ratus ribu -> 1.200.000', () {
        final result = parser.parse('Satu juta dua ratus ribu');
        expect(result.amount, equals(1200000.0));
      });

      test('Dua juta lima ratus ribu -> 2.500.000', () {
        final result = parser.parse('Dua juta lima ratus ribu');
        expect(result.amount, equals(2500000.0));
      });

      test('Lima ribu lima ratus -> 5.500', () {
        final result = parser.parse('Bayar parkir lima ribu lima ratus');
        expect(result.amount, equals(5500.0));
      });

      test('Seratus ribu -> 100.000', () {
        final result = parser.parse('Bayar listrik seratus ribu');
        expect(result.amount, equals(100000.0));
      });

      test('Satu juta -> 1.000.000', () {
        final result = parser.parse('Bonus satu juta');
        expect(result.amount, equals(1000000.0));
      });

      test('Dua puluh lima ribu -> 25.000', () {
        final result = parser.parse('Beli makan dua puluh lima ribu');
        expect(result.amount, equals(25000.0));
      });

      test('Lima belas ribu -> 15.000', () {
        final result = parser.parse('Kopi lima belas ribu');
        expect(result.amount, equals(15000.0));
      });

      test('Sebelas ribu -> 11.000', () {
        final result = parser.parse('Sebelas ribu');
        expect(result.amount, equals(11000.0));
      });

      test('Sepuluh ribu -> 10.000', () {
        final result = parser.parse('Sepuluh ribu');
        expect(result.amount, equals(10000.0));
      });

      test('Seribu -> 1.000', () {
        final result = parser.parse('Seribu');
        expect(result.amount, equals(1000.0));
      });

      test('Sejuta -> 1.000.000', () {
        final result = parser.parse('Dapat sejuta');
        expect(result.amount, equals(1000000.0));
      });

      test('Setengah juta -> 500.000', () {
        final result = parser.parse('Uang masuk setengah juta');
        expect(result.amount, equals(500000.0));
      });

      test('Dua setengah juta -> 2.500.000', () {
        final result = parser.parse('Gaji dua setengah juta');
        expect(result.amount, equals(2500000.0));
      });

      test('Verifikasi variasi: Dua puluh lima ribu -> 25.000', () {
        final result = parser.parse('Dua puluh lima ribu');
        expect(result.amount, equals(25000.0));
      });

      test('Verifikasi variasi: Dua ratus lima puluh ribu -> 250.000', () {
        final result = parser.parse('Dua ratus lima puluh ribu');
        expect(result.amount, equals(250000.0));
      });

      test('Verifikasi variasi: Dua puluh lima juta -> 25.000.000', () {
        final result = parser.parse('Dua puluh lima juta');
        expect(result.amount, equals(25000000.0));
      });

      test('Verifikasi variasi: Seratus dua puluh lima ribu -> 125.000', () {
        final result = parser.parse('Seratus dua puluh lima ribu');
        expect(result.amount, equals(125000.0));
      });

      test('Verifikasi variasi: Dua ratus dua puluh lima ribu -> 225.000', () {
        final result = parser.parse('Dua ratus dua puluh lima ribu');
        expect(result.amount, equals(225000.0));
      });

      test('Verifikasi variasi: Dua ribu lima ratus -> 2.500', () {
        final result = parser.parse('Dua ribu lima ratus');
        expect(result.amount, equals(2500.0));
      });

      test('Input non-angka menghasilkan amount 0', () {
        final result = parser.parse('Halo selamat pagi apa kabar');
        expect(result.amount, equals(0.0));
        expect(result.hasAmount, isFalse);
      });
    });

    group('B3-02 Voice Input Date Recognition Tests', () {
      final refDate = DateTime(2026, 11, 8, 14, 30);
      final testParser = VoiceTransactionParser(clock: () => refDate);

      test('"Kemarin beli makan dua puluh ribu" -> tanggal kemarin, amount 20000, desc "Beli makan"', () {
        final result = testParser.parse(
          'Kemarin beli makan dua puluh ribu',
          referenceDate: refDate,
        );
        expect(result.hasDate, isTrue);
        expect(result.date, equals(DateTime(2026, 11, 7)));
        expect(result.amount, equals(20000.0));
        expect(result.description, equals('Beli makan'));
      });

      test('"Hari ini beli kopi lima belas ribu" -> tanggal hari ini, amount 15000, desc "Beli kopi"', () {
        final result = testParser.parse(
          'Hari ini beli kopi lima belas ribu',
          referenceDate: refDate,
        );
        expect(result.hasDate, isTrue);
        expect(result.date, equals(DateTime(2026, 11, 8)));
        expect(result.amount, equals(15000.0));
        expect(result.description, equals('Beli kopi'));
      });

      test('"Tadi pagi bayar parkir lima ribu" -> tanggal hari ini, amount 5000, desc "Bayar parkir"', () {
        final result = testParser.parse(
          'Tadi pagi bayar parkir lima ribu',
          referenceDate: refDate,
        );
        expect(result.hasDate, isTrue);
        expect(result.date, equals(DateTime(2026, 11, 8)));
        expect(result.amount, equals(5000.0));
        expect(result.description, equals('Bayar parkir'));
      });

      test('"Tanggal 5 November beli bensin lima puluh ribu" -> tanggal 5 Nov 2026, amount 50000', () {
        final result = testParser.parse(
          'Tanggal 5 November beli bensin lima puluh ribu',
          referenceDate: refDate,
        );
        expect(result.hasDate, isTrue);
        expect(result.date, equals(DateTime(2026, 11, 5)));
        expect(result.amount, equals(50000.0));
        expect(result.description, equals('Beli bensin'));
      });

      test('"Kemarin dapat transfer seratus ribu" -> tanggal kemarin, amount 100000, type income', () {
        final result = testParser.parse(
          'Kemarin dapat transfer seratus ribu',
          referenceDate: refDate,
        );
        expect(result.hasDate, isTrue);
        expect(result.date, equals(DateTime(2026, 11, 7)));
        expect(result.amount, equals(100000.0));
        expect(result.type, equals(TransactionType.income));
      });

      test('Tanpa sebutan tanggal -> hasDate bernilai false (form bebas tentukan tanggal)', () {
        final result = testParser.parse('Beli makan siang dua puluh ribu');
        expect(result.hasDate, isFalse);
        expect(result.date, isNull);
      });
    });
  });
}

