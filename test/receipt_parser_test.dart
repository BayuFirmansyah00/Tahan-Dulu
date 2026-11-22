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

    group('P0-03 Decimal Cents and Thousand Formatting Scenarios', () {
      test('Rp 35.500 -> 35500', () {
        const text = 'TOTAL Rp 35.500';
        final result = parser.parse(text);
        expect(result.total, equals(35500.0));
      });

      test('Rp 35.500,00 -> 35500 (tidak menjadi 3.550.000)', () {
        const text = 'TOTAL BAYAR Rp 35.500,00';
        final result = parser.parse(text);
        expect(result.total, equals(35500.0));
      });

      test('Rp 121.000,00 -> 121000 (tidak menjadi 12.100.000)', () {
        const text = 'GRAND TOTAL: Rp 121.000,00';
        final result = parser.parse(text);
        expect(result.total, equals(121000.0));
      });

      test('Rp 1.250.000 -> 1250000', () {
        const text = 'TOTAL: Rp 1.250.000';
        final result = parser.parse(text);
        expect(result.total, equals(1250000.0));
      });

      test('Rp 1.250.000,00 -> 1250000', () {
        const text = 'TOTAL Rp 1.250.000,00';
        final result = parser.parse(text);
        expect(result.total, equals(1250000.0));
      });

      test('121000 -> 121000 (angka bulat tanpa pemisah)', () {
        const text = 'TOTAL 121000';
        final result = parser.parse(text);
        expect(result.total, equals(121000.0));
      });

      test('50,000.00 -> 50000 (format US/internasional)', () {
        const text = 'TOTAL 50,000.00';
        final result = parser.parse(text);
        expect(result.total, equals(50000.0));
      });

      test('50.000,00 -> 50000', () {
        const text = 'TOTAL 50.000,00';
        final result = parser.parse(text);
        expect(result.total, equals(50000.0));
      });

      test('Item belanja dengan format desimal sen diekstrak benar', () {
        const text = '''TOKO KITA
ROTI COKELAT  15.000,00
TOTAL         15.000,00''';
        final result = parser.parse(text);
        expect(result.total, equals(15000.0));
        expect(result.items.first.price, equals(15000.0));
      });
    });

    group('INT-06 Promo and Total Priority Tests', () {
      test('Baris TOTAL HEMAT dan TOTAL POIN tidak menimpa TOTAL BAYAR', () {
        const receiptText = '''
INDOMARET
TGL: 05/11/2026
-----------------------------
MINYAK GORENG 2L       38.000
BERAS 5KG              72.000
GULA PASIR 1KG         15.000
-----------------------------
SUBTOTAL              125.000
DISKON                 15.000
PPN                    11.000
TOTAL BAYAR           121.000
TUNAI                 150.000
KEMBALIAN              29.000
TOTAL HEMAT             5.000
TOTAL POIN                150
TERIMA KASIH
''';
        final result = parser.parse(receiptText);
        expect(result.subtotal, equals(125000.0));
        // Harus bernilai 121.000 (TOTAL BAYAR), BUKAN 5.000 (TOTAL HEMAT) atau 150 (TOTAL POIN)!
        expect(result.total, equals(121000.0));
      });

      test('GRAND TOTAL tidak tertimpa baris TOTAL POIN di bagian bawah', () {
        const receiptText = '''
ALFAMART
-----------------------------
SABUN MANDI            25.000
SHAMPOO                40.000
-----------------------------
GRAND TOTAL            65.000
TUNAI                  70.000
KEMBALI                 5.000
-----------------------------
TOTAL POIN ANDA: 350
ANDA HEMAT: 4.500
''';
        final result = parser.parse(receiptText);
        expect(result.total, equals(65000.0));
      });

      test('Tier 1 keyword (TOTAL BAYAR) memprioritaskan nilai akhir di atas Tier 2 (TOTAL HARGA)', () {
        const receiptText = '''
SUPERMARKET MAKMUR
TOTAL HARGA           100.000
POTONGAN               10.000
TOTAL BAYAR            90.000
''';
        final result = parser.parse(receiptText);
        expect(result.total, equals(90000.0));
      });

      test('Negative keywords seperti kupon, voucher, cashback, dan item diabaikan', () {
        const receiptText = '''
MINIMARKET JAYA
TOTAL BELANJA          50.000
TOTAL KUPON             5.000
TOTAL VOUCHER          10.000
TOTAL CASHBACK          2.500
TOTAL ITEM                  3
TOTAL BAYAR CASH       50.000
''';
        final result = parser.parse(receiptText);
        expect(result.total, equals(50000.0));
      });
    });

    group('HOTFIX Regression & Deterministic Total Priority Tests', () {
      test('TOTAL BAYAR 121.000 -> 121000', () {
        const receipt = '''
TOKO SUKSES
TOTAL BAYAR 121.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
        expect(result.hasTotal, isTrue);
      });

      test('TOTAL BAYAR TERMASUK PPN 121.000 -> 121000 (tidak diabaikan karena PPN)', () {
        const receipt = '''
CAFE KOPI SENJA
TOTAL BAYAR TERMASUK PPN 121.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
        expect(result.hasTotal, isTrue);
      });

      test('GRAND TOTAL INCL TAX 121.000 -> 121000 (tidak diabaikan karena TAX)', () {
        const receipt = '''
BISTRO MODERN
GRAND TOTAL INCL TAX 121.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
        expect(result.hasTotal, isTrue);
      });

      test('TOTAL SETELAH DISKON 90.000 -> 90000 (tidak diabaikan karena DISKON)', () {
        const receipt = '''
FASHION STORE
TOTAL HARGA 100.000
DISKON 10.000
TOTAL SETELAH DISKON 90.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(90000.0));
      });

      test('TOTAL TAGIHAN TERMASUK ONGKIR 75.000 -> 75000 (tidak diabaikan karena ONGKIR)', () {
        const receipt = '''
PESAN ANTAR ONLINE
TOTAL TAGIHAN TERMASUK ONGKIR 75.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(75000.0));
      });

      test('GRAND TOTAL 65.000 diikuti TOTAL HEMAT 5.000 -> 65000', () {
        const receipt = '''
ALFAMART
GRAND TOTAL 65.000
TOTAL HEMAT 5.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(65000.0));
      });

      test('TOTAL BAYAR 90.000 diikuti TOTAL POIN 150 -> 90000', () {
        const receipt = '''
SUPERMARKET
TOTAL BAYAR 90.000
TOTAL POIN 150
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(90000.0));
      });

      test('SUBTOTAL 100.000 diikuti TOTAL BAYAR 90.000 -> subtotal 100000, total 90000', () {
        const receipt = '''
RESTORAN NUSANTARA
SUBTOTAL 100.000
DISKON 10.000
TOTAL BAYAR 90.000
''';
        final result = parser.parse(receipt);
        expect(result.subtotal, equals(100000.0));
        expect(result.total, equals(90000.0));
      });

      test('TOTAL PPN 11.000 saja -> Tidak dianggap total bayar (total: 0, hasTotal: false)', () {
        const receipt = '''
FAKTUR PAJAK
TOTAL PPN 11.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(0.0));
        expect(result.hasTotal, isFalse);
      });

      test('TOTAL DISKON 5.000 saja -> Tidak dianggap total bayar (total: 0, hasTotal: false)', () {
        const receipt = '''
VOUCHER PROMO
TOTAL DISKON 5.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(0.0));
        expect(result.hasTotal, isFalse);
      });

      test('Struk Restoran Lengkap (Subtotal, Service, PB1, Grand Total, Tunai, Kembali)', () {
        const receipt = '''
WARUNG MAKAN PADANG SEDAP
NASI AYAM POP      35.000
RENDANG SAPI       40.000
ES TEH MANIS        8.000
-----------------------------
SUBTOTAL           83.000
SERVICE 5%          4.150
PB1 RESTORAN 10%    8.715
-----------------------------
GRAND TOTAL        95.865
TUNAI             100.000
KEMBALI             4.135
TERIMA KASIH ATAS KUNJUNGANNYA
''';
        final result = parser.parse(receipt);
        expect(result.subtotal, equals(83000.0));
        expect(result.total, equals(95865.0));
        expect(result.paymentMethod, equals('Tunai'));
      });

      test('Format nominal desimal sen Rp121.000,00 pada TOTAL BAYAR TERMASUK PPN', () {
        const receipt = '''
TOKO SERBA ADA
TOTAL BAYAR TERMASUK PPN Rp121.000,00
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
      });

      test('Format nominal US 50,000.00 pada GRAND TOTAL INCL TAX', () {
        const receipt = '''
HOTEL INTERNATIONAL
GRAND TOTAL INCL TAX 50,000.00
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(50000.0));
      });

      test('Beberapa kandidat total dalam satu struk: Grand Total (Tier 1) mengalahkan Total Belanja (Tier 6)', () {
        const receipt = '''
MINIMARKET KITA
TOTAL BELANJA      125.000
POTONGAN            10.000
PPN 11%              6.000
GRAND TOTAL        121.000
TUNAI              150.000
KEMBALIAN           29.000
TOTAL HEMAT         10.000
TOTAL POIN             120
''';
        final result = parser.parse(receipt);
        // Memilih GRAND TOTAL 121.000 secara deterministik di atas TOTAL BELANJA 125.000 dan promo 10.000/120
        expect(result.total, equals(121000.0));
      });
    });

    group('B3-01 Multi-Nominal in Single Line & B3-03 Indonesian Receipt Dates', () {
      test('TOTAL BAYAR 100.000 TUNAI 150.000 -> 100000 (tidak mengambil angka tunai)', () {
        const receipt = '''
TOKO MAJU JAYA
TOTAL BAYAR 100.000 TUNAI 150.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(100000.0));
      });

      test('GRAND TOTAL 121.000 KEMBALIAN 29.000 -> 121000 (tidak mengambil kembalian)', () {
        const receipt = '''
ALFAMART POINT
GRAND TOTAL 121.000 KEMBALIAN 29.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
      });

      test('SUBTOTAL 125.000 TOTAL BAYAR 121.000 -> subtotal 125000, total 121000', () {
        const receipt = '''
SUPERINDO
SUBTOTAL 125.000 TOTAL BAYAR 121.000
''';
        final result = parser.parse(receipt);
        expect(result.subtotal, equals(125000.0));
        expect(result.total, equals(121000.0));
      });

      test('TOTAL HEMAT 5.000 setelah GRAND TOTAL 121.000 -> 121000', () {
        const receipt = '''
HYPERMART
GRAND TOTAL 121.000
TOTAL HEMAT 5.000
''';
        final result = parser.parse(receipt);
        expect(result.total, equals(121000.0));
      });

      test('Format tanggal struk: 05/11/2026', () {
        const receipt = '''
INDOMARET
TGL: 05/11/2026 14:30
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 11, 5)));
      });

      test('Format tanggal struk: 05-11-2026', () {
        const receipt = '''
INDOMARET
TGL: 05-11-2026
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 11, 5)));
      });

      test('Format tanggal struk: 2026-11-05 (ISO)', () {
        const receipt = '''
SUPERMARKET
DATE: 2026-11-05
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 11, 5)));
      });

      test('Format tanggal struk teks bulan: 05 Nov 2026', () {
        const receipt = '''
CAFE KOPI
TANGGAL 05 Nov 2026
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 11, 5)));
      });

      test('Format tanggal struk teks bulan panjang: 05 November 2026', () {
        const receipt = '''
RESTORAN ENAK
05 November 2026
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 11, 5)));
      });

      test('Format tanggal struk teks bulan: 05 Okt 2026', () {
        const receipt = '''
APOTEK KELUARGA
05 Okt 2026
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 10, 5)));
      });

      test('Format tanggal struk teks bulan panjang: 05 Oktober 2026', () {
        const receipt = '''
BENGKEL MOTOR
05 Oktober 2026
TOTAL 50.000
''';
        final result = parser.parse(receipt);
        expect(result.date, equals(DateTime(2026, 10, 5)));
      });
    });

    group('Fase 8B Section 6.3 & 6.4 Receipt Scenarios', () {
      test('Contoh Struk 6.3: Subtotal, Diskon, PPN -> Total Bayar adalah nominal final', () {
        const text = '''
SUPERMARKET NUSANTARA
02/11/2026 14:30
-----------------------------
BERAS PREMIUM 5KG    75.000
MINYAK GORENG 2L     25.000
-----------------------------
Subtotal: Rp100.000
Diskon: Rp10.000
PPN: Rp9.900
Total Bayar: Rp99.900
TUNAI: Rp100.000
KEMBALIAN: Rp100
TERIMA KASIH
''';

        final result = parser.parse(text);

        expect(result.merchantName, equals('SUPERMARKET NUSANTARA'));
        expect(result.date, equals(DateTime(2026, 11, 2)));
        expect(result.time, equals('14:30'));
        expect(result.subtotal, equals(100000.0));
        expect(result.discount, equals(10000.0));
        expect(result.tax, equals(9900.0));
        // Prioritas utama: Total akhir yang benar-benar dibayar adalah Rp99.900
        expect(result.total, equals(99900.0));
        expect(result.hasTotal, isTrue);
      });

      test('Struk Restoran dengan Biaya Layanan, PB1, dan Kembalian', () {
        const text = '''
KAFE KENANGAN
JL. SENOPATI NO. 12
22/11/2026 15:45
-----------------------------
KOPI KENANGAN MANTAN   22.000
ROTI COKLAT KLASIK     15.000
-----------------------------
SUBTOTAL               37.000
BIAYA LAYANAN           2.000
PB1 10%                 3.900
PEMBULATAN               -100
TOTAL AKHIR            42.800
BAYAR TUNAI            50.000
KEMBALIAN               7.200
''';

        final result = parser.parse(text);

        expect(result.merchantName, equals('KAFE KENANGAN'));
        expect(result.date, equals(DateTime(2026, 11, 22)));
        expect(result.time, equals('15:45'));
        expect(result.subtotal, equals(37000.0));
        expect(result.serviceFee, equals(2000.0));
        expect(result.tax, equals(3900.0));
        // Total akhir harus Rp42.800 (bukan Rp50.000 tunai dan bukan Rp7.200 kembalian)
        expect(result.total, equals(42800.0));
      });

      test('Struk QRIS digital: Payment method terdeteksi QRIS', () {
        const text = '''
WARUNG KOPI LESTARI
20/11/2026 09:15
-----------------------------
AMERICANO DINGIN       20.000
CROISSANT              25.000
-----------------------------
TOTAL PEMBAYARAN       45.000
PEMBAYARAN: QRIS BCA   45.000
STATUS: BERHASIL
''';

        final result = parser.parse(text);

        expect(result.merchantName, equals('WARUNG KOPI LESTARI'));
        expect(result.total, equals(45000.0));
        expect(result.paymentMethod, equals('QRIS'));
      });

      test('Struk buram tanpa angka valid menghasilkan total 0 (minta isi manual)', () {
        const text = '''
TOKO MAKMUR
KERTAS BASAH
TIDAK DAPAT DIBACA
TERIMA KASIH
''';

        final result = parser.parse(text);

        expect(result.total, equals(0.0));
        expect(result.hasTotal, isFalse);
      });

      test('Multiple conflicting totals terdeteksi dan set hasMultipleTotals', () {
        const text = '''
TOKO SERBA ADA
10/11/2026
-----------------------------
GRAND TOTAL            100.000
GRAND TOTAL            120.000
''';

        final result = parser.parse(text);

        expect(result.hasMultipleTotals, isTrue);
        expect(result.total, greaterThan(0));
      });
    });
  });
}

