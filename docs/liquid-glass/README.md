# Redesign Liquid Glass Tahan Dulu

## Audit dan keputusan implementasi

Baseline lokal adalah `8f1e282`. Saat audit, `main`, `release/integrated-8c2` dan referensi remote lokalnya berada di commit tersebut. Implementasi berada di `feature/liquid-glass-ui`. Flutter 3.44.4 stable memakai Dart 3.12.2, Android minSdk 24 dan compileSdk 37.

`main.dart` menyiapkan locale Indonesia, Firebase dan ProviderScope. `app.dart` memasang GoRouter di MaterialApp.router. Aplikasi memakai Riverpod, repositori lokal/remote, formulir Material, aset PNG 3D dan Lottie pada splash. Navbar digunakan melalui alias DashboardBottomNav. Navigasi memakai push/go per halaman. Baseline hanya memasang tema terang. Pengendali preferensi menolak pilihan gelap. Wishlist, notifikasi dan dua pemilih metode memakai warna dan dekorasi lokal yang berbeda.

Migrasi dimulai dari tema Material dan token, lalu navbar, tombol, kartu bersama, layar dan modal. Komponen menggunakan font sistem, skala tipografi, radius dan spasi aplikasi.

## Pemilihan perender

| Kandidat | Evaluasi |
| --- | --- |
| [liquid_glass_toolkit 1.0.0](https://pub.dev/packages/liquid_glass_toolkit) | Dipilih. MIT, Dart ≥3.8 dan Flutter ≥3.32. Paket menyediakan shader pencahayaan, refraksi pada backend yang mendukungnya, tema terang/gelap, semantik dan pengurangan transparansi. Hanya bergantung pada SDK Flutter. Riwayat rilisnya masih singkat sehingga penggunaan API paket dipusatkan dalam satu pembungkus. |
| [liquid_glass_widgets 1.19.0](https://pub.dev/packages/liquid_glass_widgets/example) | MIT. Mendukung Android, Flutter ≥3.41, navigasi, kontrol dan kualitas adaptif. Contoh resmi menginisialisasi shader dan membungkus aplikasi. Toolkit cocok untuk integrasi yang hanya memerlukan perender pada permukaan tertentu. |
| [liquid_glass_renderer 1.0.0-dev.2](https://pub.dev/packages/liquid_glass_renderer) | Apache-2.0. API perender tingkat rendah dan masih prarilis. Efek penuh memerlukan Flutter ≥3.47 dan Flutter GPU. SDK proyek berada di bawah persyaratan tersebut. |

Pub menambahkan satu paket ke lockfile. Versi Flutter, Dart, Gradle dan Android SDK mengikuti baseline. Evaluasi biaya rendering berdasarkan implementasi paket. Belum ada benchmark komparatif ketiga paket pada ponsel fisik.

## Sistem desain

- `lib/core/theme/app_theme.dart` menetapkan ColorScheme, tipografi, tombol, ikon, FAB, chip, input, dialog dan indikator untuk kedua tema.
- `lib/core/theme/glass.dart` memusatkan dekorasi panel statis, latar, pencahayaan, kualitas dan gerak. Baris daftar memakai dekorasi tanpa pengambilan sampel latar per kartu.
- Navbar memakai satu permukaan kaca untuk Beranda, Transaksi, Catat, Tujuan dan Profil. Aset 3D, aksi pusat dan riwayat rute mengikuti aplikasi sebelumnya. Scaffold menyediakan ruang untuk bar, SafeArea memberikan jarak sistem, dan viewInsets mengatur visibilitas saat keyboard terbuka.
- Tombol primer memakai sorotan, tombol sekunder memakai garis dan isian, serta tombol destruktif memakai warna error dan onError. Material menangani fokus, tekan dan keyboard. AppButton menonaktifkan callback selama loading.
- `showGlassSheet<T>` menggunakan modal Material bertipe sehingga pemilih bank, sumber gambar dan konfirmasi mengembalikan hasil ke pemanggil. Field tetap memakai controller, formatter dan validator aslinya.
- Pilihan sistem, terang dan gelap tersedia di Pengaturan Aplikasi serta disimpan oleh pengendali preferensi dengan kunci per pengguna. Pengurangan gerak mengikuti preferensi aplikasi atau sistem.

### Kualitas rendering

`--dart-define=GLASS_QUALITY=balanced` adalah bawaan. `high` mengaktifkan refraksi bila didukung, sedangkan `low` memakai dekorasi statis. Pada mode profil dan rilis, dua kelompok 60 frame berturut-turut dengan sedikitnya 10 frame raster di atas 16,667 ms menurunkan kualitas untuk sesi berjalan. Ambang ini mengatur fallback. Kontras tinggi atau pengurangan gerak memilih panel solid dan durasi nol pada transisi kaca.

## Cakupan layar

| Modul | Perubahan visual |
| --- | --- |
| Dashboard | Anggaran harian, saldo, shortcut, target, transaksi terbaru dan navbar. Ilustrasi memiliki ruang terpisah dari nominal anggaran. |
| Transaksi | Riwayat, filter, pemilih metode, panel suara dan pemindai struk, formulir, review dan hasil. |
| Tahan Dulu | Daftar produk, pemilih manual/link/foto, kamera/galeri, form, analisis, simulasi, keputusan dan konfirmasi pembelian. |
| Goals | Daftar, ringkasan, prioritas, progres, detail, setoran dan riwayat. Pelukis grafik menerima warna dari tema saat build. |
| Rekening | Ringkasan aset, daftar/detail, pemilih bank, tambah/edit rekening, biaya admin dan transfer. |
| Laporan | Ringkasan, pemilih periode, grafik, simpanan, kesehatan dan kontrol ekspor. |
| Profil dan notifikasi | Header, informasi pengguna, pengaturan, keamanan, pengingat, filter dan status baca. |
| Autentikasi dan onboarding | Latar, tombol, input, splash dan panel perencanaan. Investasi dan transaksi berulang juga memakai tema baru. |

## Perbandingan visual

Gambar dirender dengan Flutter pada 393 × 852 dp menggunakan Roboto dan fixture pengujian. Kolom pertama menggunakan sumber commit awal, dua kolom berikutnya menggunakan tema terang dan gelap.

- [Dashboard](dashboard.png)
- [Pemilihan metode transaksi](metode.png)
- [Wishlist](wishlist.png)
## Hasil verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| flutter pub get | Berhasil. Hanya liquid_glass_toolkit ditambahkan ke lockfile. |
| flutter analyze | Lulus pada worktree fitur, tanpa temuan. |
| Suite penuh, konfigurasi bawaan | 525 lulus, 317 gagal. Sejumlah widget test mengharapkan fixture padahal konfigurasi bawaan memakai repositori remote. |
| Suite penuh, fixture proyek | 752 lulus, 90 gagal. Pada baseline dengan opsi yang sama, 743 lulus dan 89 gagal. Seluruh 89 nama tes yang gagal di baseline juga muncul di branch fitur. Penyebab belum tentu sama, khususnya pada golden. |
| Selisih satu tes | Tes transaksi bulan sebelumnya mengalami timeout 30 detik. Saat diulang bersama tes pengendali dashboard dan aksesibilitas, 17/17 lulus. |
| Verifikasi fungsional terarah pada kode akhir | 155/155 lulus untuk parser suara dan struk, input wishlist, idempotensi transaksi, alur transaksi, goals, profil, deep link notifikasi, ekspor dan navbar. |
| Tata letak dan scroll | 35/35 kombinasi lulus dengan Roboto, tujuh modul dan lebar 320, 360, 393, 412 dan 768 dp. Pemilih metode dan navbar juga diperiksa pada skala teks 1,6, tema terang/gelap, kontras tinggi dan keyboard terbuka. |
| APK Android | Build debug berhasil dengan API_BASE_URL yang diberikan. Gradle memberi peringatan terkait penggunaan plugin Kotlin oleh firebase_core. |
| Golden | Perbandingan piksel berubah. Sejumlah tes lama gagal sebelum mencapai layar tujuan. Referensi lama dipertahankan karena kandidat dari harness lama memakai font blok dan beberapa ikon belum terdekode. Gambar perbandingan di atas diambil dengan harness terpisah. |

Verifikasi kode terhadap baseline menunjukkan bahwa kontrak API, model, repositori, parser, perhitungan, konfigurasi Firebase, rute dan pengiriman notifikasi tidak memiliki perubahan. Pengendali preferensi diubah khusus untuk membaca dan menyimpan tema. Pengujian tidak membuktikan transaksi finansial nyata, Google Sign-In produksi, kualitas audio mikrofon atau OCR kamera pada perangkat fisik. Belum ada pengukuran UI/raster frame, jank atau penggunaan memori pada ponsel fisik.

### Riwayat dan berkas

Commit implementasi adalah b4a6025 untuk tema, b5683f3 untuk navbar dan pemilih metode, 94032f5 untuk migrasi layar dan 612a97e untuk tes regresi. Daftar lengkap jalur sumber dan tes yang berubah terhadap baseline tersedia dalam [berkas perubahan](files.txt).

AVD Android 14 terpisah berhenti saat cold boot sebelum instalasi APK dapat diverifikasi. Emulator lain sedang menjalankan aplikasi dari checkout lain. Screenshot di laporan berasal dari renderer widget.
