# LAPORAN AKSES — Implementasi Remote Repository & UI Binding Flutter

## Ringkasan

Implementasi sinkronisasi Flutter TahanDulu dengan backend Laravel telah diselesaikan. Semua repository data (Account, Transaction, Goal, Dashboard) sekarang memiliki implementasi remote yang memanggil endpoint Laravel API. Autentikasi menggunakan Sanctum Bearer Token via `flutter_secure_storage`. Penanganan error 401 memaksa navigasi ke halaman login. Error validasi 422 dipetakan ke field-specific error di UI.

`flutter analyze`: **0 issues**
`flutter test`: **461 lulus, 7 gagal** (sama dengan baseline — semua golden/pixel test pre-existing)

---

## 1. File yang Dibuat (New Files)

| Path | Fungsi |
|------|--------|
| `lib/data/datasources/remote/remote_dashboard_repository.dart` | Remote implementation `DashboardRepository`. Memanggil `/api/transactions`, `/api/financial-instrumen`, `/api/goals` secara paralel (`Future.wait`), lalu menghitung ringkasan saldo, pemasukan, pengeluaran, investasi, dan sisa fleksibel di sisi klien. |
| `lib/data/models/api_user_model.dart` | Model respons autentikasi (user, access_token, token_type) dari envelope `{success, message, data}`. |
| `lib/data/models/api_financial_instrument.dart` | Model instrumen keuangan + tipe instrumen dari `FinancialInstrumenResource`. |
| `lib/data/models/api_transaction.dart` | Model transaksi + respons daftar/tunggal + paginasi dari `TransactionResource`. |
| `lib/data/models/api_financial_goal.dart` | Model target keuangan + respons dari `GoalResource`. |
| `lib/data/models/api_goal_transaction.dart` | Model setoran goal + respons dari `GoalTransactionResource`. |
| `lib/data/models/api_investment.dart` | Model investasi + respons dari `InvestmentResource`. |
| `lib/data/models/api_investment_transaction.dart` | Model transaksi investasi + respons dari `InvestmentTransactionResource`. |
| `lib/data/models/api_recurring_transaction.dart` | Model transaksi berulang + respons dari `RecurringTransactionResource`. |

---

## 2. File yang Diubah (Modified Files)

| Path | Perubahan |
|------|-----------|
| `lib/data/datasources/remote/api_client.dart` | Ditambahkan parameter `onUnauthorized` (`void Function()?`). Penanganan status 401: memanggil callback lalu melempar `ApiException`. Ditambahkan method `put()`, `patch()`, `delete()`. |
| `lib/data/datasources/remote/api_config.dart` | Konstanta `useRemoteAuth` dan `useRemoteApi` (default `false`, aktifkan via `--dart-define`). |
| `lib/data/datasources/remote/remote_account_repository.dart` | Implementasi `AccountRepository` di atas `/api/financial-instrumen` dengan `onUnauthorized` callback, `_requireToken()`, dan mapping `AccountType`. |
| `lib/data/datasources/remote/remote_transaction_repository.dart` | Implementasi `TransactionRepository` di atas `/api/transactions` dengan CRUD lengkap, filter, paginasi, dan `onUnauthorized`. |
| `lib/data/datasources/remote/remote_goal_repository.dart` | Implementasi `GoalRepository` di atas `/api/goals` dan `/api/goals/{id}/transactions` dengan `onUnauthorized`. |
| `lib/data/providers/app_providers.dart` | Default repository berpindah ke Remote saat flag aktif. Ditambahkan `goRouterProvider` untuk navigasi 401. Setiap remote repository menginisialisasi `ApiClient` dengan `onUnauthorized: () => router.go('/login')`. |
| `lib/app.dart` | Menggunakan `goRouterProvider` untuk router. |
| `lib/data/repositories/repositories.dart` | Ditambahkan abstract method pada `TransactionRepository` (`getTransactionById`, `getTransactions`, `updateTransaction`, `deleteTransaction`) dan `GoalRepository` (`getGoalById`, `deleteGoal`, `updateDeposit`, `deleteDeposit`). Implementasi ditambahkan di `MockTransactionRepository` dan `MockGoalRepository`. |
| `lib/features/auth/presentation/providers/auth_controller.dart` | `AuthState` sekarang memiliki `fieldErrors` (`Map<String, List<String>>?`). `loginWithEmail` dan `register` menangkap `ApiException` dan menyimpan `fieldErrors`. `restore()` menangani 401 dengan logout otomatis. |
| `lib/features/goals/presentation/providers/goals_controller.dart` | Semua method async (`saveGoal`, `updateGoalFields`, `addDeposit`, `applyPlan`, `saveOrder`) menangkap `on ApiException` dan melempar kembali untuk ditangani UI. |
| `lib/features/transactions/presentation/providers/transactions_controller.dart` | `save()` menangkap `on ApiException` dan melempar kembali agar UI dapat menampilkan field-specific error dari backend. |
| `lib/features/accounts/presentation/providers/accounts_controller.dart` | `addAccount`, `updateAccount`, `deleteAccount` menangkap `on ApiException` dan melempar kembali. |

---

## 3. File yang Dihapus

Tidak ada file yang dihapus.

---

## 4. Arsitektur Alur Data (UI → API → UI)

```
UI Screen (mis. TransactionFormScreen)
    ↓
Riverpod Notifier (mis. TransactionFormController)
    ↓ memanggil
Repository Provider (mis. transactionRepositoryProvider)
    ↓ (jika USE_REMOTE_API=true)
Remote Repository (mis. RemoteTransactionRepository)
    ↓ baca token dari
TokenStorage (flutter_secure_storage, kunci: tahandulu_access_token)
    ↓
ApiClient (HTTP + header Authorization: Bearer <token>)
    ↓
Laravel API (Sanctum, routes/api.php)
    ↓ JSON envelope {success, message, data}
ApiClient _decode() → parsing ke Model API (mis. ApiTransaction)
    ↓
Repository → Model Domain (mis. AppTransaction)
    ↓
Riverpod Provider → UI menampilkan data
```

### Penanganan 401 Unauthorized
Setiap remote repository memiliki `onUnauthorized` callback yang di-set di `app_providers.dart`:
```dart
onUnauthorized: () => router.go('/login')
```
Ketika `ApiClient._decode()` menerima status 401:
1. Memanggil `onUnauthorized()` → navigasi ke `/login` via `go_router`
2. Melempar `ApiException` dengan statusCode 401

### Penanganan Error Validasi 422
`ApiClient._decode()` mem-parsing `body['errors']` menjadi `Map<String, List<String>>` dan menyimpannya di `ApiException.fieldErrors`. Controller (mis. `auth_controller.dart`, `goals_controller.dart`) menangkap `ApiException` dan menyimpan `fieldErrors` di state. UI dapat menampilkan error per field menggunakan `state.fieldErrors['field']`.

---

## 5. Dashboard Composer (RemoteDashboardRepository)

Karena Laravel tidak memiliki endpoint `/api/dashboard`, `RemoteDashboardRepository.getSummary()` memanggil tiga endpoint secara paralel:

```dart
final results = await Future.wait([
  _client.get('/transactions', token: token),
  _client.get('/financial-instrumen', token: token),
  _client.get('/goals', token: token),
]);
```

Lalu menghitung di sisi klien:
- **Total balance**: jumlah saldo semua instrumen keuangan
- **Actual month income/expense**: transaksi bulan berjalan dari `/api/transactions`
- **Saving**: income − expense
- **Investment**: total balance + current_amount dari goal tipe 'investment'
- **Goal contribution**: (target − current) / bulan hingga deadline, dijumlahkan semua goal
- **Remaining flexible**: saving − goalContribution
- **Safe daily spending**: remaining / hari dalam bulan, dibulatkan ke bawah per Rp1.000

---

## 6. Konfigurasi untuk Aktifkan Remote

Untuk menjalankan dengan backend Laravel:

```sh
# Backend Laravel
cd E:\TAHAN_DULU\TahanDulu_Laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve   # http://localhost:8000

# Frontend Flutter
cd E:\TAHAN_DULU\TahanDulu_Flutter
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api \
  --dart-define=USE_REMOTE_AUTH=true \
  --dart-define=USE_REMOTE_API=true
```

Untuk perangkat fisik, ganti `10.0.2.2` dengan IP LAN komputer (mis. `192.168.1.10`).

Untuk mode mock (tanpa backend):
```sh
flutter run
```

---

## 7. Endpoint Laravel yang Diintegrasikan

| Fitur | Endpoint Laravel | Status Flutter |
|-------|-----------------|----------------|
| Authentication | `POST /api/register`, `/login`, `/logout`, `GET /api/me` | Remote siap (opt-in via `USE_REMOTE_AUTH`) |
| Financial Instruments | `GET/POST/PUT/DELETE /api/financial-instrumen` | Remote siap (opt-in via `USE_REMOTE_API`) |
| Transactions | `GET/POST/PUT/DELETE /api/transactions` + filter & paginasi | Remote siap (opt-in via `USE_REMOTE_API`) |
| Goals | `GET/POST/PUT/DELETE /api/goals` + `GET/POST/PUT/DELETE /api/goals/{id}/transactions` | Remote siap (opt-in via `USE_REMOTE_API`) |
| Dashboard | Tidak ada endpoint terpadu (composed dari 3 endpoint) | Remote siap (opt-in via `USE_REMOTE_API`) |
| Investments | `GET/POST/PUT/DELETE /api/investments` + transactions | Belum ada UI Flutter |
| Recurring Incomes | `GET/POST/PUT/DELETE /api/recurring-incomes` | Belum ada UI Flutter |
| Recurring Expenses | `GET/POST/PUT/DELETE /api/recurring-expenses` | Belum ada UI Flutter |

---

## 8. Catatan Quirk Backend yang Ditangani

1. **Tabel `financial_instrumens`** — ejaan tidak standard, digunakan seperti yang ada di migration.
2. **Kolom `reminder date` (dengan spasi)** — migration `goals` menggunakan nama kolom dengan spasi. Model `Goal` cast sebagai datetime. Service Laravel memetakan `reminder_date` → `'reminder date'`. Flutter API model menggunakan `reminder_date` (snake_case standar) di JSON.
3. **Nominal `bigInteger`** — dikirim sebagai integer JSON, diparsing ke `int` di Dart, dikonversi ke `double` untuk model domain.
4. **Tanggal ISO8601** — `created_at`, `updated_at`, `target_date` dalam format ISO8601, di-parse via `DateTime.parse()`.
5. **Envelope respons** — semua endpoint dalam `{success, message, data}`, pagination pada daftar transaksi.

---

## 9. Hasil Pengujian

| Perintah | Hasil |
|----------|-------|
| `flutter analyze` | **No issues found** (0 error, 0 warning) |
| `flutter test` | **461 lulus, 7 gagal** |

### 7 Test yang Gagal (Pre-existing, Golden/Pixel)
Semua 7 kegagalan adalah golden/pixel test yang sudah gagal sebelum perubahan ini:
1. `accounts_golden_test.dart: Accounts golden`
2. `dashboard_golden_test.dart: Dashboard golden`
3. `goals_golden_test.dart: Goals golden`
4. `reports_golden_test.dart: Reports golden`
5. `reports_golden_test.dart: Expenses golden`
6. `tahandulu_golden_test.dart: TahanDulu golden`
7. `transactions_golden_test.dart: Transactions golden`

Semua gagal karena perbedaan rendering piksel (pixel diff 3.9%–8.0%), bukan karena logika atau API.

---

## 9. Pekerjaan yang Masih Tersedia

### Sudah Selesai dan Terverifikasi
- `flutter analyze`: 0 issues
- `flutter test`: 461 lulus (baseline), 7 gagal (pre-existing golden)
- ApiClient mendukung POST/GET/PUT/PATCH/DELETE + 401 handling + fieldErrors
- Model API untuk semua resource Laravel utama
- Remote repository untuk Account, Transaction, Goal, Dashboard
- Provider switching Mock ↔ Remote via `USE_REMOTE_API` / `USE_REMOTE_AUTH`
- 401 → navigasi otomatis ke `/login` via goRouterProvider
- 422 → fieldErrors tersedia di state controller

### Sudah Diimplementasikan Tapi Belum Diverifikasi dengan Backend Nyata
- Semua remote repository (kode kompile berhasil, tapi tidak dapat diverifikasi end-to-end karena backend Laravel tidak tersedia di environment ini)

### Memerlukan Endpoint Backend (Belum Ada UI Flutter)
- Investments (`/api/investments`, `/api/investments/{id}/transactions`)
- Recurring Incomes (`/api/recurring-incomes`)
- Recurring Expenses (`/api/recurring-expenses`)

### Membutuhkan Keputusan dari Anda
1. **Default remote vs mock**: Saat ini default `false` (mock). Aktifkan remote via `--dart-define=USE_REMOTE_API=true --dart-define=USE_REMOTE_AUTH=true`. Apakah Anda ingin default diubah ke `true`?
2. **Fitur Investasi dan Recurring Transaksi**: Backend sudah mendukung, tapi Flutter belum memiliki UI. Perlu dikembangkan jika diperlukan.
3. **Dashboard Repository**: Sudah diimplementasi sebagai komposisi dari 3 endpoint. Belum dapat diverifikasi tanpa backend nyata.
4. **Kode mock**: Masih dipertahankan sebagai fallback dan untuk pengujian. Bisa dihapus setelah backend diverifikasi.