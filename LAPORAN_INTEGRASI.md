# LAPORAN INTEGRASI & PERBAIKAN MENYELURUH ONBOARDING, INSTRUMEN KEUANGAN, DAN PERHITUNGAN FINANSIAL TAHANDULU

## 1. Ringkasan Masalah dan Solusi

### Akar Masalah:
1. **Error Tambah Instrumen Saat Onboarding**:
   - URL mismatch: Frontend memanggil endpoint yang salah (`/financial-instrumen` vs `/financial-instruments`).
   - Missing required field: Backend membutuhkan `type_id` (foreign key ke `instrument_types`), namun form onboarding frontend sebelumnya hanya mengirim payload tanpa `type_id` valid atau gagal memetakan tipe enum lokal ke master data admin.
2. **Dropdown Master Data Instrumen**:
   - Tambah instrumen di mobile sebelumnya mengandalkan button chip statis lokal, bukan dropdown dinamis yang mengambil daftar tipe instrumen master (`GET /api/instrument-types`) yang dikelola admin di backend.
3. **Inkonsistensi Alur Popup & Status Onboarding**:
   - Tidak ada field persisten di tabel `users` backend untuk menandai apakah user sudah menyelesaikan onboarding (`is_onboarded`). Akibatnya, routing hanya mengandalkan heuristik lokal atau popup acak di dashboard yang membuat user lama terjebak atau terlempar ulang ke onboarding.
4. **Perhitungan Finansial & Sumber Data**:
   - `monthlyIncome` dan `salaryDay` di Dashboard sebelumnya terpisah antara memory onboarding dan profil backend.
   - Terjadi risiko double-counting saldo akun di mode remote bila transaksi ditambahkan ke saldo awal, padahal backend Laravel secara otomatis telah memutasi kolom `balance` tabel `financial_instrumens`.
5. **Navigasi Terputus / Tidak Berakhir di Dashboard**:
   - Langkah terakhir onboarding (`PlanScreen`) tidak memicu penyimpanan status onboarding terpusat ke backend dan tidak melakukan refresh state dashboard secara menyeluruh, sehingga data yang tampil di dashboard menjadi kosong atau stale.

### Solusi yang Diimplementasikan:
1. **Sinkronisasi Endpoint & Skema**:
   - Memperbaiki path endpoint menjadi konsisten (`/financial-instruments`).
   - Menyediakan `GET /api/instrument-types` dan mengintegrasikannya ke Flutter melalui `instrumentTypesProvider` & `RemoteInstrumentTypeRepository`.
   - Mengirim `type_id` valid ke backend saat menyimpan instrumen baik di onboarding maupun di menu Akun.
2. **Implementasi Dropdown Master Data**:
   - `_AddInstrumentDialog` di onboarding (`instruments_screen.dart`) dan `AddAccountScreen` diubah menggunakan `DropdownButtonFormField<int>` dinamis berbasis data dari `instrumentTypesProvider`.
3. **Field `is_onboarded` & Route Guard Konsisten**:
   - Migrasi backend `add_is_onboarded_to_users_table.php` menambahkan boolean `is_onboarded` (default: false).
   - `AuthController@updateUser` menerima dan memvalidasi `is_onboarded`.
   - `AppRouter` dilengkapi `AuthRouteNotifier` dan redirect guard global:
     - User belum login (`!isAuth`) dialihkan ke Login bila mengakses protected route / onboarding.
     - User terautentikasi dan `isOnboarded == false` diarahkan ke Onboarding Step 1 (`/onboarding/salary`).
     - User terautentikasi dan `isOnboarded == true` langsung diarahkan ke Dashboard dan dilarang kembali ke onboarding/auth page.
4. **Sinkronisasi Finansial Bersih**:
   - Dashboard memprioritaskan profil pengguna dari backend (`authUser.monthlyIncome`), lalu in-memory fallback.
   - Di mode remote (`ApiConfig.useRemoteApi == true`), `totalBalance` langsung dihitung dari `accounts.fold(0.0, sum + a.balance)` tanpa penambahan ganda transaksi. Di mode mock tetap menghitung riwayat transaksi secara terisolasi.
5. **Finalisasi Onboarding ke Dashboard**:
   - CTA "Mulai Aplikasi" di `PlanScreen` menyimpan gaji dan `is_onboarded: true` ke backend via `PUT /api/user`, lalu menginvalidasi seluruh provider terkait (`dashboardDataProvider`, `accountsProvider`, `profileUserProvider`, `onboardingStatusProvider`), kemudian bernavigasi ke `AppRoutes.dashboard`.

---

## 2. Perubahan Backend (Laravel)

### File yang Diubah & Dibuat:
1. **Migrasi Baru**:
   - `database/migrations/2026_10_28_070000_add_is_onboarded_to_users_table.php`
   - Menambahkan kolom `is_onboarded` (`boolean`, default: `false`) ke tabel `users`.
2. **Model `User.php`**:
   - Menambahkan `is_onboarded` ke `$fillable` dan `$casts` (`'is_onboarded' => 'boolean'`).
   - Backward-compatibility accessor: `getIsOnboardedAttribute()` mengembalikan `true` bila nilai kolom bernilai true ATAU user sudah memiliki relasi `financialInstrumens`.
3. **Controller `AuthController.php`**:
   - Method `updateUser`: menambahkan validasi `'is_onboarded' => 'sometimes|boolean'` dan menyimpannya ke model `$user`.
4. **Endpoint API**:
   - `GET /api/instrument-types` -> Mengembalikan daftar master tipe instrumen aktif (`InstrumentTypeResource`).
   - `PUT /api/user` -> Memperbarui profil finansial (`monthly_income`, `salary_day`, `is_onboarded`).
   - `POST /api/financial-instruments` -> Menyimpan instrumen keuangan dengan `type_id` wajib dan valid.

---

## 3. Perubahan Frontend (Flutter)

### File yang Diubah & Dibuat:
1. **Domain & Data Models**:
   - `lib/data/models/user_model.dart`: Menambahkan field `isOnboarded: bool` (default: `false`), `copyWith`, serialization, dan `props`.
   - `lib/data/models/financial_instrument.dart`: Menambahkan field `typeId: int?` agar instrumen onboarding dapat memuat foreign key master data backend.
   - `lib/data/datasources/mock/mock_data.dart`: Menetapkan `isOnboarded: true` pada `MockData.user` untuk akun demo kanonis.
2. **Repositories & Datasources**:
   - `lib/data/repositories/auth_repository.dart` & `lib/data/datasources/remote/remote_auth_repository.dart`: Menambahkan parameter `bool? isOnboarded` pada method `updateFinancialInfo()`.
   - `lib/data/datasources/remote/remote_dashboard_repository.dart`: Memperbaiki path URL ke `/financial-instruments`.
   - `lib/data/datasources/remote/remote_onboarding_repository.dart`: Mengirimkan payload `type_id` valid, menyimpan gaji langsung ke `PUT /api/user`, dan menyediakan method `fetchExistingInstruments()`.
3. **State Management & Routing**:
   - `lib/features/auth/presentation/providers/auth_controller.dart`: Menambahkan parameter `bool? isOnboarded` di `updateFinancialInfo()`.
   - `lib/features/onboarding/presentation/providers/salary_controller.dart`: Prefill nilai gaji dan tanggal gajian dari profil user backend yang sudah ada.
   - `lib/features/onboarding/presentation/providers/instruments_controller.dart`: Menambahkan method `loadExisting()` untuk memuat instrumen yang sudah tersimpan di backend.
   - `lib/core/routing/app_router.dart`: Mengimplementasikan `AuthRouteNotifier extends ChangeNotifier` dan redirect guard berbasis `isAuth` & `isOnboarded`.
   - `lib/data/providers/app_providers.dart`: Mengikat `AuthRouteNotifier` dengan `authControllerProvider` untuk sinkronisasi otomatis router saat state auth berubah.
   - `lib/data/providers/dashboard_providers.dart`: Membaca `monthlyIncome` dari `authControllerProvider` backend, mencegah double-counting saldo instrumen di mode remote.
4. **Presentation Screens**:
   - `lib/features/onboarding/presentation/screens/instruments_screen.dart`: Mengubah form tambah instrumen menjadi dropdown dinamis dari `instrumentTypesProvider`, menangani status loading/error/empty, serta memanggil `loadExisting()` saat mount.
   - `lib/features/onboarding/presentation/screens/plan_screen.dart`: Menyimpan `monthlyIncome`, `salaryDay`, dan `isOnboarded: true` ke backend via `updateFinancialInfo`, menginvalidasi provider dashboard, dan mengarahkan ke `AppRoutes.dashboard`.
   - `lib/features/auth/presentation/screens/register_screen.dart` & `login_screen.dart`: Mengarahkan user baru/belum selesai ke onboarding step 1 (`/onboarding/salary`) dan user yang sudah selesai ke Dashboard.
   - `lib/features/splash/presentation/screens/splash_screen.dart`: Mengecek `user.isOnboarded` setelah token sesi dipulihkan (`restore()`).

---

## 4. Alur Onboarding Lengkap (Step-by-Step)

```
[Register / Login Baru]
         │ (is_onboarded = false)
         ▼
[Step 1: Onboarding Salary Screen] (/onboarding/salary)
  - Input: Pendapatan bulanan (Rp) & Tanggal gajian (1-31).
  - Prefill otomatis jika sebelumnya sudah pernah mengisi.
  - Tombol: "Lanjut"
         ▼
[Step 2: Onboarding Instruments Screen] (/onboarding/instruments)
  - Memuat tipe instrumen master dari backend (GET /api/instrument-types).
  - Tambah instrumen via dialog: Dropdown tipe instrumen master + Saldo awal (+ biaya admin jika Bank).
  - Otomatis tersimpan ke database backend via POST /api/financial-instruments (type_id terisi).
  - Tampilan kartu instrumen terpilih dapat di-toggle.
  - Tombol: "Lanjut"
         ▼
[Step 3: Onboarding Expenses Screen] (/onboarding/expenses)
  - Input: Pengeluaran rutin bulanan.
  - Tombol: "Lanjut"
         ▼
[Step 4: Onboarding Goal Screen] (/onboarding/goal)
  - Input: Target finansial utama.
  - Tombol: "Lanjut"
         ▼
[Step 5: Onboarding Plan Screen] (/onboarding/plan)
  - Menampilkan ringkasan alokasi keuangan yang telah dihitung.
  - User menekan tombol "Mulai Aplikasi".
  - Frontend mengirim PUT /api/user dengan { monthly_income, salary_day, is_onboarded: true }.
  - Semua cache data (dashboard, accounts, profile, onboarding status) di-refresh.
         ▼
[Dashboard Utama] (/dashboard)
  - Langsung menampilkan data riil: Saldo gabungan instrumen, penghasilan bulanan, dan anggaran terkini.
```

---

## 5. Alur Instrumen Keuangan

1. **Pengambilan Master Data**:
   - `instrumentTypesProvider` memanggil `InstrumentTypeRepository.getInstrumentTypes()`.
   - Pada mode remote, request dikirim ke `GET /api/instrument-types` (Bearer Token Sanctum).
   - Data diparsing menjadi objek `List<ApiInstrumentType>` yang berisi `id`, `name`, `type`, `logoUrl`.
2. **Formulir Tambah Instrumen (Dropdown)**:
   - Pengguna membuka dialog "Tambah Instrumen".
   - Jika master data sedang memuat -> indikator loading `Memuat instrumen master...`.
   - Dropdown menampilkan nama-nama tipe instrumen (contoh: "Bank", "Bank Digital", "E-Wallet").
   - Pengguna memilih instrumen, menginput saldo awal, dan tanggal biaya admin (bila bertipe Bank).
3. **Penyimpanan ke Backend**:
   - `RemoteOnboardingRepository.addInstrument()` mengirim payload JSON ke `POST /api/financial-instruments`:
     ```json
     {
       "name": "BCA",
       "type_id": 1,
       "balance": 5000000,
       "is_active": true
     }
     ```
   - Backend memvalidasi `type_id` pada tabel `instrument_types`, membuat record di tabel `financial_instrumens`, dan mengembalikan data tersimpan.
4. **Sinkronisasi Tampilan**:
   - Setelah sukses disimpan, instrumen baru otomatis ditambahkan ke daftar instrumen terpilih di `instrumentsControllerProvider`.

---

## 6. Alur Profil dan Popup

1. **Eliminasi Popup Menggantung**:
   - Konsep lama menggunakan popup di dashboard ("Lengkapi Profil Keuanganmu") yang tumpang tindih dengan status onboarding pengguna baru.
   - Kini, alur dibuat tegas: **Pengguna baru wajib menyelesaikan onboarding sebelum dapat membuka Dashboard**. Route guard memblokir akses ke route protected dan mengarahkannya langsung ke `/onboarding/salary`.
2. **Peran OnboardingInvitationPopup**:
   - `OnboardingInvitationPopup` dipertahankan di dashboard secara non-intrusif khusus untuk backward-compatibility (misal bila ada akun lama tanpa profile lengkap yang mengakses dashboard secara direct).
   - Tombol "Lengkapi Sekarang": Membuka `/onboarding/salary`.
   - Tombol "Nanti Saja": Menutup dialog dan mencatat state `markShown` pada sesi aktif agar dialog tidak muncul berulang kali.

---

## 7. Perhitungan Finansial

1. **Pendapatan Bulanan (Monthly Income)**:
   - Sumber utama: `authUser.monthlyIncome` yang disimpan di database backend melalui `PUT /api/user`.
   - Fallback: Data in-memory `onboarding?.monthlyIncome` (mode mock atau sebelum submit final).
2. **Total Saldo (Total Balance)**:
   - **Mode Remote**: Laravel backend secara otomatis memutasi kolom `balance` di tabel `financial_instrumens` setiap kali ada transaksi pengeluaran/pemasukan. Oleh karena itu, di Flutter:
     $$\text{Total Balance} = \sum_{a \in \text{accounts}} a.\text{balance}$$
     *(Tidak menambahkan lagi agregasi transaksi lokal untuk menghindari double-counting)*.
   - **Mode Mock**: Total saldo dihitung dari saldo instrumen canonical ditambah agregasi transaksi sesi berjalan.
3. **Safe Spending Today (Uang Dingin Harian Aman)**:
   - Dihitung dari sisa budget fleksibel bulanan dibagi sisa hari menuju tanggal gajian berikutnya (`salaryDay`).

---

## 8. Hasil Pengujian

### A. Pengujian Backend Laravel (PHPUnit)
- **Perintah**: `php ./vendor/bin/phpunit tests/Feature`
- **Hasil**: **24 passed, 0 failed** (79 assertions)
- Mencakup pengujian:
  - `InstrumentTypeApiTest`: Pengambilan data master tipe instrumen.
  - `UpdateUserApiTest`: Pembaruan profil `monthly_income`, `salary_day`, dan flag `is_onboarded`.
  - `TransactionBalanceConsistencyTest`: Konsistensi saldo akun saat transaksi dibuat/diubah.
  - `TransactionDataIsolationTest`: Isolasi data antar user.

### B. Pengujian Frontend Flutter (Static Analysis & Unit Tests)
- **Perintah Analisis**: `flutter analyze`
- **Hasil Analisis**: **No issues found!** (0 error, 0 warning, 0 info).
- **Pengujian Unit & Widget**:
  - `test/auth_flow_test.dart`: 8/8 passed (Login, Register -> Onboarding Step 1, Google Sign-in).
  - `test/account_types_test.dart`: 12/12 passed (Dropdown master data instrumen, tipe akun).
  - `test/accounts_screen_test.dart`: 8/8 passed (Tambah akun via dropdown master, validasi, dan simpan).
  - `test/transactions_screen_test.dart`: 10/10 passed (Riwayat transaksi, navigasi dashboard).
  - `test/tahandulu_screen_test.dart`: 11/11 passed (Navigasi fitur pertimbangan beli).

---

## 9. Cara Menjalankan dan Menguji

### 1. Menjalankan Backend Laravel:
```bash
cd E:\TAHAN_DULU\TahanDulu_Laravel
php artisan migrate
php artisan db:seed --class=InstrumentTypeSeeder
php artisan serve --port=8000
```
Backend berjalan di `http://127.0.0.1:8000/api`.

### 2. Menjalankan Frontend Flutter (Remote Mode):
```bash
cd E:\TAHAN_DULU\TahanDulu_Flutter
# Untuk Android Emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api \
            --dart-define=USE_REMOTE_AUTH=true \
            --dart-define=USE_REMOTE_API=true

# Untuk Windows Desktop / Web / Host Lokal:
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api \
                       --dart-define=USE_REMOTE_AUTH=true \
                       --dart-define=USE_REMOTE_API=true
```

### 3. Menjalankan Frontend Flutter (Mock Mode):
```bash
cd E:\TAHAN_DULU\TahanDulu_Flutter
flutter run --dart-define=USE_REMOTE_AUTH=false --dart-define=USE_REMOTE_API=false
```

---

## 10. Catatan Tambahan

1. **Konsistensi Penamaan Tabel Backend**:
   - Backend menggunakan penamaan tabel `financial_instrumens` (ejaan bahasa Indonesia/campuran). Model Laravel memetakan ke tabel ini dengan benar.
2. **Backward Compatibility**:
   - Model `User` Laravel memiliki accessor `is_onboarded` yang secara otomatis mengembalikan nilai `true` jika user lama telah memiliki instrumen keuangan terkait, mencegah pengguna lama dipaksa mengulang onboarding.
3. **Integritas Git**:
   - Seluruh file existing dan untracked yang relevan pada kedua repositori tetap dipertahankan dengan aman tanpa adanya file yang terhapus secara tidak sengaja.