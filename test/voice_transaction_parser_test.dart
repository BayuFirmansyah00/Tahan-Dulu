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
  });
}

