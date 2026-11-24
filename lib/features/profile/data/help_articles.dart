import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

/// Kategori bantuan (sesuai fitur aktual aplikasi).
class HelpCategory extends Equatable {
  const HelpCategory({
    required this.id,
    required this.title,
    this.icon = Icons.help_outline,
    this.asset,
  });

  final String id;
  final String title;
  final IconData icon;
  final String? asset;

  @override
  List<Object?> get props => [id, title, asset];
}

/// Satu entri FAQ. Konten merujuk fitur yang benar-benar ada.
class HelpArticle extends Equatable {
  const HelpArticle({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.answer,
  });

  final String id;
  final String categoryId;
  final String question;
  final String answer;

  @override
  List<Object?> get props => [id, categoryId, question, answer];
}

const List<HelpCategory> helpCategories = [
  HelpCategory(
    id: 'account',
    title: 'Akun dan Profil',
    icon: Icons.person_outline,
    asset: AppAssets.setProfile,
  ),
  HelpCategory(
    id: 'transactions',
    title: 'Transaksi & Lampiran',
    icon: Icons.receipt_long_outlined,
    asset: AppAssets.navTransaction,
  ),
  HelpCategory(
    id: 'accounts',
    title: 'Akun Keuangan & Transfer',
    icon: Icons.account_balance_wallet_outlined,
    asset: AppAssets.txWallet,
  ),
  HelpCategory(
    id: 'goals',
    title: 'Target Keuangan',
    icon: Icons.flag_outlined,
    asset: AppAssets.navTarget,
  ),
  HelpCategory(
    id: 'investments',
    title: 'Portofolio Investasi',
    icon: Icons.trending_up_outlined,
    asset: AppAssets.dashChart,
  ),
  HelpCategory(
    id: 'tahandulu',
    title: 'TahanDulu',
    icon: Icons.shopping_bag_outlined,
    asset: AppAssets.setBag,
  ),
  HelpCategory(
    id: 'reports',
    title: 'Laporan Keuangan & Ekspor',
    icon: Icons.bar_chart_outlined,
    asset: AppAssets.dashChart,
  ),
  HelpCategory(
    id: 'notifications',
    title: 'Pengingat & Notifikasi',
    icon: Icons.notifications_outlined,
    asset: AppAssets.setNotif,
  ),
];

const List<HelpArticle> helpArticles = [
  HelpArticle(
    id: 'account-1',
    categoryId: 'account',
    question: 'Bagaimana cara mengubah nama profil?',
    answer:
        'Buka Pengaturan, ketuk Edit Profil, ubah Nama Lengkap, lalu ketuk '
        'Simpan Perubahan. Nama akan langsung diperbarui di sesi aktif '
        'dan disinkronkan ke server.',
  ),
  HelpArticle(
    id: 'account-2',
    categoryId: 'account',
    question: 'Mengapa email tidak dapat diubah?',
    answer:
        'Email terikat pada akun masuk dan identitas autentikasi Sanctum '
        'demi keamanan data keuangan. Field email ditampilkan secara read-only.',
  ),
  HelpArticle(
    id: 'account-3',
    categoryId: 'account',
    question: 'Apakah keluar akun menghapus data keuanganku?',
    answer:
        'Tidak. Keluar akun hanya mengakhiri sesi autentikasi dan '
        'membersihkan cache lokal pada perangkat. Seluruh saldo, transaksi, '
        'dan target tetap aman tersimpan di cloud database.',
  ),
  HelpArticle(
    id: 'transactions-1',
    categoryId: 'transactions',
    question: 'Bagaimana cara mencatat transaksi?',
    answer:
        'Ketuk tombol Catat pada navigasi bawah atau buka halaman '
        'Transaksi. Isi jenis, nominal, kategori, akun, dan tanggal, lalu '
        'periksa kembali sebelum disimpan.',
  ),
  HelpArticle(
    id: 'transactions-2',
    categoryId: 'transactions',
    question: 'Bisakah transaksi yang sudah disimpan diubah atau dilampirkan struk?',
    answer:
        'Ya. Anda dapat membuka rincian transaksi untuk memperbarui nominal, '
        'kategori, atau catatan, serta mengunggah foto struk sebagai bukti '
        'pembayaran yang tersimpan privat dan aman.',
  ),
  HelpArticle(
    id: 'accounts-1',
    categoryId: 'accounts',
    question: 'Apa itu saldo tercatat?',
    answer:
        'Saldo tercatat adalah akumulasi saldo riil pada instrumen keuangan '
        '(Bank, Bank Digital, E-Wallet, atau Tunai) yang diperbarui secara '
        'otomatis oleh ledger transaksi backend.',
  ),
  HelpArticle(
    id: 'accounts-2',
    categoryId: 'accounts',
    question: 'Bagaimana cara melakukan transfer antar rekening?',
    answer:
        'Pilih jenis transaksi Transfer pada formulir pencatatan transaksi, '
        'lalu tentukan Akun Asal dan Akun Tujuan. Ledger akan secara atomik '
        'memotong saldo akun asal dan menambah saldo akun tujuan.',
  ),
  HelpArticle(
    id: 'goals-1',
    categoryId: 'goals',
    question: 'Bagaimana progres target dihitung?',
    answer:
        'Progres dihitung dari akumulasi setoran riil dibagi target nominal. '
        'Setiap setoran target terhubung dengan mutasi pengeluaran pada akun '
        'keuangan Anda.',
  ),
  HelpArticle(
    id: 'goals-2',
    categoryId: 'goals',
    question: 'Apa fungsi prioritas target?',
    answer:
        'Prioritas menentukan urutan alokasi dana dan target yang paling utama. '
        'Anda dapat mengatur urutan prioritas melalui halaman Target Keuangan.',
  ),
  HelpArticle(
    id: 'investments-1',
    categoryId: 'investments',
    question: 'Mengapa transaksi investasi saya tidak dapat disimpan?',
    answer:
        'Demi menjaga integritas dan keamanan portofolio, penulisan transaksi '
        'investasi dapat dilindungi oleh fail-closed safety gate di server. '
        'Jika fitur sedang digembok, Anda tetap dapat memantau portofolio '
        'secara read-only.',
  ),
  HelpArticle(
    id: 'investments-2',
    categoryId: 'investments',
    question: 'Bagaimana mutasi investasi mempengaruhi saldo akun?',
    answer:
        'Setoran investasi akan mengurangi saldo akun pembayaran dan menambah '
        'nilai pokok investasi. Sebaliknya, penarikan investasi akan menambah '
        'saldo akun tujuan dan mengurangi pokok investasi.',
  ),
  HelpArticle(
    id: 'tahandulu-1',
    categoryId: 'tahandulu',
    question: 'Apa itu TahanDulu?',
    answer:
        'TahanDulu membantumu berpikir sebelum membeli keinginan impulsif. '
        'Masukkan barang yang ingin dibeli, lihat dampaknya pada batas '
        'belanja harian dan tabungan, lalu tahan selama masa tunggu.',
  ),
  HelpArticle(
    id: 'tahandulu-2',
    categoryId: 'tahandulu',
    question: 'Apakah keputusan membeli otomatis mencatat transaksi?',
    answer:
        'Ketika Anda memutuskan untuk membeli setelah masa tunggu berakhir, '
        'aplikasi akan mengarahkan Anda ke formulir pencatatan transaksi '
        'dengan data barang yang sudah terisi otomatis.',
  ),
  HelpArticle(
    id: 'reports-1',
    categoryId: 'reports',
    question: 'Bagaimana cara melihat laporan periode selain bulan ini?',
    answer:
        'Pada halaman Laporan Keuangan, Anda dapat berpindah periode antara '
        'Bulan Ini, Bulan Lalu, Kuartal Ini, atau memilih Rentang Tanggal '
        'Kustom melalui pemilih periode di bagian atas.',
  ),
  HelpArticle(
    id: 'reports-2',
    categoryId: 'reports',
    question: 'Format berkas apa saja yang didukung untuk ekspor laporan?',
    answer:
        'Anda dapat mengunduh laporan keuangan dalam format PDF berstandar '
        'cetak atau berkas spreadsheet Excel (.xlsx) lengkap dengan rincian '
        'analisis alokasi kebutuhan dan tabungan.',
  ),
  HelpArticle(
    id: 'notifications-1',
    categoryId: 'notifications',
    question: 'Bagaimana sistem notifikasi dan pengingat bekerja?',
    answer:
        'Notifikasi pengingat menabung, jadwal tagihan berulang, dan evaluasi '
        'budget dikirim secara tepat waktu melalui integrasi Firebase Cloud '
        'Messaging dan kotak masuk yang mendukung sinkronisasi status baca.',
  ),
  HelpArticle(
    id: 'notifications-2',
    categoryId: 'notifications',
    question: 'Bagaimana cara mengatur pengingat menabung?',
    answer:
        'Buka Pengaturan Notifikasi, ketuk Pengingat Menabung, pilih target '
        'yang ingin dicapai, tentukan nominal, frekuensi (mingguan/bulanan), '
        'serta jam pengingat.',
  ),
];

/// Cari artikel berdasarkan kata kunci (judul, pertanyaan, jawaban).
List<HelpArticle> searchHelpArticles(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return helpArticles;
  return helpArticles.where((a) {
    final category = helpCategories.firstWhere(
      (c) => c.id == a.categoryId,
      orElse: () => const HelpCategory(id: '', title: '', icon: Icons.help),
    );
    final haystack =
        '${category.title} ${a.question} ${a.answer}'.toLowerCase();
    return haystack.contains(q);
  }).toList();
}
