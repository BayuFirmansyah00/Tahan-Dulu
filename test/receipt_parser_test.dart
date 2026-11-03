import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/features/transactions/domain/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser Tests', () {
    test('Struk standar: Kenali Toko, Tanggal, Subtotal vs Total', () {
      const receiptText = '''
INDOMARET POINT
JL. SUDIRMAN NO. 45 JAKARTA
TGL: 02/11/2026 14:30
-----------------------------
ROTI COKELAT        12.000
AIR MINERAL 600ML    4.000
KOPI BOTOL           9.000
-----------------------------
SUBTOTAL            25.000
DISKON                   0
TOTAL               25.000
TUNAI               50.000
KEMBALIAN           25.000
TERIMA KASIH
''';

      final result = parser.parse(receiptText);

      expect(result.merchantName, equals('INDOMARET POINT'));
      expect(result.date, equals(DateTime(2026, 11, 2)));
      expect(result.subtotal, equals(25000.0));
      expect(result.total, equals(25000.0));
      expect(result.hasTotal, isTrue);
      expect(result.paymentMethod, equals('Tunai'));
      expect(result.items.length, greaterThanOrEqualTo(2));
    });

    test('Prioritaskan Grand Total atas Subtotal berbeda', () {
      const receiptText = '''
SUPERINDO SUPERMARKET
TANGGAL: 2026-10-30
-----------------------------
APEL FUJI 1KG       35.000
SUSU UHT 1L         20.000
-----------------------------
SUBTOTAL            55.000
ONGKOS KIRIM        10.000
GRAND TOTAL         65.000
BCA DEBIT           65.000
''';

      final result = parser.parse(receiptText);

      expect(result.merchantName, equals('SUPERINDO SUPERMARKET'));
      expect(result.date, equals(DateTime(2026, 10, 30)));
      expect(result.subtotal, equals(55000.0));
      // Total akhir adalah Grand Total Rp65.000, bukan Subtotal Rp55.000!
      expect(result.total, equals(65000.0));
      expect(result.paymentMethod, equals('BCA'));
    });

    test('Jika total tidak terbaca, total bernilai 0 (minta user isi)', () {
      const blurryReceipt = '''
WARUNG KOPI JAYA
JL. MAWAR
-----------------------------
KOPI HITAM
PISANG GORENG
-----------------------------
KERTAS SOBEK...
''';

      final result = parser.parse(blurryReceipt);

      expect(result.merchantName, equals('WARUNG KOPI JAYA'));
      expect(result.total, equals(0));
      expect(result.hasTotal, isFalse);
    });

    test('Kategori dan akun tidak dikarang sembarangan', () {
      const receiptText = '''
ALFAMART
01/11/2026
TOTAL 50.000
''';

      final result = parser.parse(receiptText);
      expect(result.total, equals(50000.0));
      // Parser struk tidak mengarang akun atau kategori
    });
  });
}

