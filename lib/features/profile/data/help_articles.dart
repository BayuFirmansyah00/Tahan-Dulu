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
    title: 'Transaksi',
    icon: Icons.receipt_long_outlined,
    asset: AppAssets.navTransaction,
  ),
  HelpCategory(
    id: 'accounts',
    title: 'Akun Keuangan',
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
    id: 'tahandulu',
    title: 'TahanDulu',
    icon: Icons.shopping_bag_outlined,
    asset: AppAssets.setBag,
  ),
  HelpCategory(
    id: 'reports',
    title: 'Laporan Keuangan',
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
        'Buka Profil, ketuk Edit Profil, ubah Nama Lengkap, lalu ketuk '
        'Simpan Perubahan. Perubahan tersimpan selama sesi ini dan akan '
        'diatur ulang saat aplikasi dimulai ulang.',
  ),
  HelpArticle(
    id: 'account-2',
    categoryId: 'account',
    question: 'Mengapa email tidak dapat diubah?',
    answer:
        'Email terikat pada akun masuk dan belum didukung untuk diubah '
        'melalui aplikasi pada versi ini. Field email tampil sebagai '
        'read-only.',
  ),
  HelpArticle(
    id: 'account-3',
    categoryId: 'account',
    question: 'Apakah keluar akun menghapus data keuanganku?',
    answer:
        'Tidak. Keluar akun hanya mengakhiri sesi. Data transaksi, target, '
        'dan akun keuangan tetap tersimpan di aplikasi.',
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
    question: 'Bisakah transaksi yang sudah disimpan diubah?',
    answer:
        'Riwayat transaksi menampilkan data yang tercatat. Pengubahan '
        'transaksi tersimpan belum tersedia pada versi ini.',
  ),
  HelpArticle(
    id: 'accounts-1',
    categoryId: 'accounts',
    question: 'Apa itu saldo tercatat?',
    answer:
        'Saldo tercatat adalah saldo awal akun ditambah transaksi yang '
        'tercatat pada akun tersebut. Semua perhitungan memakai sumber '
        'yang sama agar konsisten.',
  ),
  HelpArticle(
    id: 'accounts-2',
    categoryId: 'accounts',
    question: 'Mengapa akun tidak dapat dihapus?',
    answer:
        'Akun yang memiliki transaksi tercatat tidak dapat dihapus agar '
        'riwayat tetap utuh. Transfer antar akun juga belum tersedia.',
  ),
  HelpArticle(
    id: 'goals-1',
    categoryId: 'goals',
    question: 'Bagaimana progres target dihitung?',
    answer:
        'Progres dihitung dari dana terkumpul dibagi target nominal. Dana '
        'terkumpul hanya bertambah melalui setoran yang tercatat pada '
        'halaman target.',
  ),
  HelpArticle(
    id: 'goals-2',
    categoryId: 'goals',
    question: 'Apa fungsi prioritas target?',
    answer:
        'Prioritas menentukan urutan target dari Tinggi hingga Rendah. Atur '
        'melalui halaman Prioritas Target lalu simpan urutannya.',
  ),
  HelpArticle(
    id: 'tahandulu-1',
    categoryId: 'tahandulu',
    question: 'Apa itu TahanDulu?',
    answer:
        'TahanDulu membantumu berpikir sebelum membeli. Masukkan barang, '
        'lihat dampaknya pada budget, lalu tunggu masa tunggu sebelum '
        'memutuskan membeli atau tidak.',
  ),
  HelpArticle(
    id: 'tahandulu-2',
    categoryId: 'tahandulu',
    question: 'Apakah keputusan membeli otomatis mencatat transaksi?',
    answer:
        'Tidak. Keputusan membeli hanya disimpan sebagai keputusan. Catat '
        'transaksinya secara manual agar saldo ikut tercatat.',
  ),
  HelpArticle(
    id: 'reports-1',
    categoryId: 'reports',
    question: 'Dari mana angka laporan berasal?',
    answer:
        'Laporan dihitung dari transaksi yang tercatat pada bulan berjalan '
        'dan setoran target. Tanpa transaksi tercatat, laporan akan kosong.',
  ),
  HelpArticle(
    id: 'reports-2',
    categoryId: 'reports',
    question: 'Apa arti rekomendasi pada kesehatan keuangan?',
    answer:
        'Rekomendasi adalah saran umum berbasis aturan dari datamu, bukan '
        'nasihat finansial profesional.',
  ),
  HelpArticle(
    id: 'notifications-1',
    categoryId: 'notifications',
    question: 'Dari mana notifikasi berasal?',
    answer:
        'Notifikasi dibuat berdasarkan data yang kamu masukkan di aplikasi, '
        'seperti tanggal gajian, target, dan budget. Belum ada push '
        'notification lintas perangkat.',
  ),
  HelpArticle(
    id: 'notifications-2',
    categoryId: 'notifications',
    question: 'Bagaimana cara mengatur pengingat menabung?',
    answer:
        'Buka Pengingat & Notifikasi, ketuk Pengingat Menabung, pilih '
        'target, nominal, frekuensi, dan waktu, lalu simpan pengaturan.',
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
