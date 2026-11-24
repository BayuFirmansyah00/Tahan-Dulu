# Laravel–Flutter Feature Gap Audit — Tahan Dulu

Tanggal: **24 November 2026, Asia/Jakarta**. Scope: audit read-only source, Git, pemeriksaan publik dan tes terisolasi. Tidak memperbaiki aplikasi, push, merge, deploy, atau mengubah database persisten.

## A. Executive Summary

Laravel menyediakan kemampuan lebih luas daripada aksi yang dapat digunakan pengguna Flutter. Auth, akun, transfer, pencatatan transaksi baru, wishlist, setoran goal, budget, laporan, dan notifikasi memiliki integrasi nyata. Gap penting berada pada UUID, aksi yang tidak terhubung ke layar, paginasi, persistensi field, dan konsistensi ledger.

**P0 berdasarkan source:** penghapusan akun keuangan dapat melewati guard Flutter dan menghapus paksa riwayat transaksi; operasi investasi memutasi `achieved` di service sekaligus model hook. Ini adalah temuan jalur kode, bukan klaim insiden produksi. Tidak ada operasi destruktif yang dijalankan.

| Klasifikasi | Kapabilitas backend mobile | Tambahan di luar denominator |
| --- | ---: | --- |
| FULLY IMPLEMENTED | 30 | — |
| PARTIALLY IMPLEMENTED | 10 | — |
| NOT IMPLEMENTED | 9 | — |
| API INTEGRATED, UI MISSING | 8 | — |
| IMPLEMENTED BUT INACCESSIBLE | 3 | — |
| IMPLEMENTED WITH CONTRACT MISMATCH | 6 | — |
| PENDING BACKEND RELEASE | 0 | — |
| UI ONLY / NOT CONNECTED | 0 | 1, UI01: simpan rencana goal |
| BACKEND-ONLY / NOT REQUIRED IN MOBILE | 0 | 5 kelompok J01–J05 |
| Total | **66** | **6** |

- **API transport coverage: 76/93 = 81,72%.** Method/path dipanggil implementasi client, termasuk method yang belum memiliki aksi UI.
- **Cakupan kemampuan lengkap dan dapat diakses menurut source: 30/66 = 45,45%.** Tidak memberi kredit parsial. Ini bukan persentase kelulusan Android E2E atau “aplikasi selesai”.
- Source mendefinisikan **104 operasi API**, dengan update PUT/PATCH resource dihitung satu operasi. Sebanyak 11 alias/web/admin dikeluarkan dari denominator mobile.
- **20 kelompok temuan/backlog F01–F20** disusun menurut risiko dan dependensi.
- PR backend #1 dan #2 **MERGED pada pemeriksaan penutup**. PR2 semula OPEN lalu berubah selama audit; detail delta di B. Deployment produksi tetap belum dibuktikan.
- Verifikasi aktual: **27 tes Laravel, 167 assertion lulus; 20 tes Flutter lulus; flutter analyze: No issues found**. Tidak menjalankan full suite atau Android E2E.

**Definisi bukti:** VERIFIED berarti terlihat pada source/hasil command baseline; INFERRED berarti konsekuensi yang diturunkan dari kode, seperti race atau potensi kehilangan saldo; UNVERIFIED berarti belum ada observasi runtime memadai. Klasifikasi bisnis pada D adalah penilaian **source**, bukan sertifikasi produksi. FULLY IMPLEMENTED hanya untuk kemampuan yang dinamai dalam baris, dengan entry UI, handler, repository, payload, persistence backend dan pemakaian hasil/refetch; kemampuan lain dan risiko lintas modul dicatat tersendiri. PENDING BACKEND RELEASE memerlukan bukti dependency rilis yang masih tertahan; ketidakpastian deployment sendiri tidak otomatis masuk kategori itu. C04 berubah R menjadi F setelah PR2 terbukti merged, sehingga jumlah akhir R=0.

Unit hitung adalah 66 baris ledger bisnis pada D, bukan jumlah controller/route. UI01 dan lima kelompok backend-only tidak masuk denominator 66. Native OCR/voice, PDF lokal, dan preferensi perangkat yang sah dicatat terpisah tanpa menaikkan jumlah backend feature.

## B. Git & Environment Baseline

**Tabel berikut merekam baseline awal. Pemeriksaan penutup menemukan perubahan eksternal; delta setelah tabel menentukan status rilis terakhir dan hitungan akhir laporan.**

| Item | Laravel | Flutter |
| --- | --- | --- |
| Root | `E:/TAHAN_DULU/TahanDulu_Laravel` | `E:/TAHAN_DULU/TahanDulu_Flutter` |
| Branch aktif | `fix/financial-instrument-contract-stabilization` | `release/fase8n-final-integration` |
| HEAD | `34aee9222ed973afb8942f1cc560fa78e631c222` | `bde0e6a` |
| origin/main, cocok remote saat diperiksa | `1a7a357e08283706bd2f38c6123876d2cbcb0c38` | `8f1e282200180663d9a9aa43f56bcffb191b6214` |
| Behind / ahead main | 0 / 3 | 0 / 14 |
| Diff terhadap main | 6 file, +806 / -26 | 113 file, +3817 / -2677 |
| Status awal | Clean | Clean |
| Worktree tambahan | Tidak ada | `E:/TAHAN_DULU/Flutter_Liquid_Glass`, `feature/liquid-glass-ui`, `688a5a8` |

Remote: [Laravel](https://github.com/Ranapace565/tahanDulu), [Flutter](https://github.com/BayuFirmansyah00/Tahan-Dulu).

`git status -sb`, `branch -avv`, `log --oneline -20`, `worktree list`, `remote -v`, `rev-list --left-right --count origin/main...HEAD`, dan diff terhadap main diperiksa. Snapshot lengkap ditambahkan pada lampiran. `git ls-remote` mengonfirmasi SHA main remote tanpa fetch.

[PR #1](https://github.com/Ranapace565/tahanDulu/pull/1): GitHub API melalui `gh pr view` mengembalikan **MERGED**, merge commit `6a1f4ebd6c023a42cb677c799b873fa9d14682da`, merged **23 November 2026 22:19 WIB**. Pada pemeriksaan awal, [PR #2](https://github.com/Ranapace565/tahanDulu/pull/2): **OPEN**, mergedAt=null, head `34aee92`, base `1a7a357`. Proses audit tidak melakukan merge/push/deploy. Status PR2 akhir: MERGED, lihat delta di bawah.

Produksi: GET [katalog bank API](https://tahandulu.kreasikan.site/api/banks) menghasilkan **HTTP 200**. Ini hanya bukti public endpoint dapat diakses. Commit deployment, payload authenticated, database, scheduler, queue, SMTP, FCM, dan APK produksi **UNVERIFIED**. Tidak membaca token atau kredensial pengguna.

Environment: Windows PowerShell; PHP **8.4.26**, Composer **2.8.5**, Flutter **3.44.4**, Dart **3.12.2**. `composer.json` meminta PHP ^8.3, Laravel ^13.17, Sanctum ^4.0, Filament ^3.2. Pada HEAD Flutter bde0e6a, default remote flags=true, tetapi default URL emulator `http://10.0.2.2:8000/api`; produksi memerlukan `API_BASE_URL` build define (F: `lib/data/datasources/remote/api_config.dart:14`). APK tidak dibangun/diinspeksi ulang.

AGENTS backend dibaca dan PHP/Composer diverifikasi. Boost tidak diinstal karena tidak ada perubahan aplikasi; instalasi dependencies bertentangan dengan scope audit. Tidak ditemukan instruksi tambahan AGENTS root/Flutter. Tidak menggunakan subagent.


### Delta workspace pada pemeriksaan penutup

Perubahan berikut terjadi **di luar proses audit ini**. Tidak di-revert, di-stage, atau di-commit oleh auditor.

| Surface | Observasi terakhir | Dampak audit |
| --- | --- | --- |
| Laravel | Branch main, HEAD/origin/main/remote main 113ac3f84aed66532dbde3cfae9dcc79a3397bb2, clean | git diff 34aee92..HEAD kosong; tree keduanya **b6e3f106988478b63d20344f3e96a473e4f19667**. Bukti source backend/route tetap berlaku. |
| PR2 | GitHub API terakhir **MERGED**, mergedAt 2026-11-24T03:31:57Z = **24 November 2026 10:31:57 WIB**; mergeCommit113ac3f | C04 kini F, bukan R. Count akhir FULLY30 dan pending0; deployment masih UNVERIFIED. |
| Flutter HEAD | Tetap bde0e6a, release/fase8n-final-integration | Commit baseline tetap; ada perubahan working tree belum committed. |
| Flutter API config | lib/data/datasources/remote/api_config.dart menambah productionBaseUrl/dev URLs, default kini production URL | Default emulator berlaku HEAD committed/baseline awal, bukan working tree terakhir. APK tetap tidak diketahui. |
| Flutter transport | api_client.dart menambah _handleError timeout/socket/SSL dan catch umum | Method/path API tidak berubah; 401 callback tetap opsional; tambahan ini belum ditest ulang oleh audit. |
| Flutter onboarding/assets | app_assets.dart, budget_screen.dart, plan_screen.dart, onboarding_visual_spec_test.dart; sembilan PNG ikon baru dan onboarding_redesign_test.dart | Delta callback saveBudget, updateFinancialInfo dan invalidate mempertahankan jalur utama. Desain/tes baru tidak divalidasi penuh. Repo/model/router akar gap tidak berubah. |

**Batas hasil tes:** 27 Laravel/20 Flutter/analyzer adalah run saat audit sebelum snapshot penutup, bukan sertifikasi seluruh working tree terbaru. Tidak mengatribusikan perubahan atau pekerjaan eksternal kepada audit. Source references backend tetap identik; line refs pada file Flutter yang berubah dibaca terhadap HEAD bde0e6a kecuali lampiran yang dihasilkan dari working tree. Tidak ada production mutation untuk memeriksa perubahan rilis ini.

### Pengujian yang dijalankan

| Pemeriksaan | Hasil dan batas |
| --- | --- |
| `php vendor/bin/phpunit --do-not-cache-result tests/Feature/ComprehensiveApiContractFase8mTest.php tests/Feature/GoalFinancialIntegrityTest.php` | **27 passed, 167 assertions**, tool melaporkan 4420 ms. APP_ENV=testing, DB_CONNECTION=sqlite, DB_DATABASE=:memory:, DB_URL kosong; cache/mail/session array, queue sync. Tidak ada config cache. Test database terisolasi. |
| `flutter test --no-pub test/financial_instrument_contract_fase8m_test.dart test/remote_goal_repository_test.dart test/remote_transaction_repository_test.dart test/remote_purchase_decision_repository_test.dart --reporter expanded` | **20 passed**; mock HTTP/providers dan widget. Tidak membuktikan seluruh screen atau produksi. |
| `flutter analyze --no-pub` | Exit 0, **No issues found**, 110,9 detik. Tidak membuktikan ketepatan kontrak bisnis. |
| Public GET /api/banks | HTTP 200, tanpa mutasi/auth. |
| Full PHPUnit/Flutter suite, PostgreSQL concurrency, Android E2E | **Tidak dijalankan.** Angka tes dari task/branch sebelumnya tidak dipakai. |

Percobaan sandbox awal PHPUnit gagal membuka autoloader yang tersedia; rerun dengan akses environment memadai dan DB in-memory lulus. Percobaan Flutter SDK awal tanpa akses cache tidak menghasilkan output dan dihentikan; rerun berhasil. Tidak mengubah dependencies/source untuk mengatasi ini.

## C. Complete Laravel Feature Inventory

Konvensi: **L:** path relatif terhadap root Laravel di B; **F:** relatif terhadap root Flutter. Baris merujuk HEAD baseline. Matriks E memetakan seluruh route ke controller+method. Lampiran menyediakan field request/resource, metode service/model, tabel migration, dan surface Filament. Daftar struktural tidak dianggap bukti fitur sudah lengkap.

| Modul | Implementasi → model/tabel | Auth/ownership dan perilaku | Kontrak utama → response | Readiness/dependency |
| --- | --- | --- | --- | --- |
| Auth/profil | AuthService, PasswordResetOtpService → User, PasswordResetOtp, personal_access_tokens | Public register/login/google/OTP; protected profile/password/logout/delete memakai user sesi. Google token diverifikasi; OTP throttling | name/email/password_confirmation; id_token; email/otp/reset_token; bio; password lama/baru → user/token atau status | SMTP/Google config; OTP/bio/token migrations. Register catch masih mengembalikan exception/file, AuthController:97 |
| Master bank/type | BankCatalogService, InstrumentTypeService → BankCatalog, InstrumentType | Banks public; types Sanctum; bank toggle wajib administrator | search/category/id/slug → BankCatalogResource/InstrumentTypeResource | Seeder catalog; type UUID stabilisasi di PR2; bank ID integer sah |
| Akun/instrumen | FinancialInstrumenService → FinancialInstrumen, Transaction | Scope user_id; resolve type; bank lookup; model mencatat saldo awal/penyesuaian; delete hook menghapus transaksi | name,type_id,balance,bank_id/slug,admin fee,max_budget,budget_frequency,is_active → FinancialInstrumenResource | UUID/admin-fee schema; PR2 kontrak type; risiko F01 |
| Transfer | TransferService → Transfer, Transaction, FinancialInstrumen | User-owned source/destination; locks, idempotency, paired ledger; reversal cek saldo tujuan | from_id,to_id,amount,notes,idempotency_key → TransferResource | Unique key/transfer_id migration; legacy cash endpoint terpisah |
| Transaksi | TransactionService + TransactionObserver → Transaction, TransactionAttachment | User scope; account ownership/active/non-cash create; observer revert/apply saldo | title,type,category,amount,instrument_id,date,information,idempotency_key,attachments[] → resource + pagination | Relasi resource mismatch F06; lampiran dua representasi F15 |
| Recurring | RecurringTransactionService + ProcessRecurringTransactions → recurring_transactions, transactions, notifications/logs | User+type scope; account ownership; due row lock; next_due_date | title,category,amount,frequency,next_due_date,instrument_id,is_active,make_automatic → RecurringTransactionResource | Every-minute scheduler; UUID %d key defect F05; host execution unknown |
| Goal | GoalService + GoalTransaction hooks → goals, goal_transactions, transactions | User scope; reorder owned IDs; goal lock; balance checks; funded goal delete rejected | title,type,target_amount,current_amount,target_date,frequency,priority,link,note,image,reminder_date,is_active; tx type deposit/withdraw → resources | PR1 merged; legacy column `reminder date`; metadata write risk F07 |
| Investasi | InvestmentService + Investment/InvestmentTransaction hooks → investments, investment_transactions, transactions | User scope; transactional writes; balance/portfolio checks | title,type,target,increase,achieved,allocated_amount,budget_frequency,reminder_date,is_active; tx amount/type/instrument → resources | F02 duplicate achieved mutation; target vs target_amount mismatch F14; write belum layak dibuka tanpa perbaikan |
| Wishlist | WishlistService, ProductMetadataService → wishlists, transactions, accounts, budgets/goals | User scope; metadata/upload throttle; purchase lock + canonical idempotency + balance | item_name/title,price/estimated_price,status,category,product_url/link,image_ref,reason/note,priority,wait timestamps; purchase instrument_id → resource/analysis/transaction_id | Storage/network marketplace, analysis_snapshot dan transaction_id migration; client UUID blocker F03 |
| Dashboard | DashboardService → transactions/accounts/goals/investments | User scope; realCashflow excludes opening/adjustment/internal transfer | Bearer → overview/monthly_cashflow/goals_summary/chart_data | Endpoint tidak dipakai Flutter; agregat mobile berbeda F06 |
| Budget | BudgetController, MonthlyBudget → monthly_budgets, budget_allocations, users | User scope, transaction, total allocation validation, active period | monthly_income, allocations(category/percentage) → current budget/daily figures | Empat kategori tetap; budget transition migration |
| Financial settings | FinancialScheduleService → users pending, budgets/allocations | User session; preview/save/cancel, bridge confirmation, promotion when due | income,salary_day,transition_budget,transition_confirmed,allocations → settings/pending/effective date | Pending/transition columns; timezone/month-end verification |
| Reports | FinancialReportService, FinancialReportExport → transactions/goals/investments/wishlists | User scope; period validation; category/trend/health aggregates | period=this_month,last_month,quarter,custom + start/end → JSON atau XLSX binary | Excel/temp storage; PDF dibuat Flutter, bukan endpoint yang hilang |
| Notifikasi | NotificationService, NotificationTriggerService → notifications/settings/logs | User inbox/count/read; filter+pagination; dedup; triggers | filter,page,per_page; read id; 6 setting boolean → Notification/SettingResource | Queue/FCM; legacy NotificationLog tidak otomatis masuk API F16 |
| Saving reminder | SavingReminderService → saving_reminders, goals | User singleton/upsert; owned goal; time/frequency rules | goal_id,amount,frequency,weekday/day_of_month,hour,minute,enabled → resource/null | Saving reminder migration; trigger/scheduler; berbeda dari goal.reminder_date |
| FCM | FcmTokenController, FcmService, SendFcmNotificationJob → fcm_tokens | Bearer token registration; destroy user token; platform validation | token,platform,device_id/name → id/platform/is_active atau deleted count | Firebase credentials/worker/network/device permission UNVERIFIED |
| Onboarding | AuthController::updateUser + shared services | Completion mensyaratkan income,salary_day,budget aktif | PUT /user is_onboarded + shared resources → fresh user | Tidak ada /onboarding API; optional account/expense/goal sync punya UUID bug |

Inventaris struktural: **22 API controller, 20 service, 22 model, 25 FormRequest, 14 JsonResource, 2 observer, 4 job, 3 command, 43 migration, 3 seeder, 51 file Filament, 15 config, 49 file PHP tests (termasuk TestCase)**. Folder app/Policies, Events, Listeners, Enums tidak ada. Ownership tetap ada di middleware, validation/controller dan query service.

`app/Providers/AppServiceProvider.php:30` mendaftarkan TransactionObserver dan UserObserver, serta OTP rate limiters. Jobs EvaluateBudgetTriggers, EvaluateGoalMilestones, ProcessScheduledNotifications dan SendFcmNotification adalah efek internal. `routes/console.php:13` menjadwalkan notifications:process-triggers, recurring:process dan notifications:process setiap menit dengan overlap protection/background. Keberadaan schedule bukan bukti cron host berjalan.

Filament App panel mempunyai fitur pengguna dan tetap dibandingkan dengan mobile. Filament Admin master bank/type dipisahkan pada J. Model FundInvestment, perhitungan/reconcile Investment, widgets, export classes, dan web notification redirect tidak otomatis berarti ada API mobile terpisah. Config auth/sanctum/database/filesystems/queue/mail/password_reset/services diperiksa sebagai dependency; secret .env/service-account tidak dibaca. `routes/web.php` berisi redirect /app, storage delivery, dan web notification read/mark-all; endpoint read yang mengubah status tidak dieksekusi.

## D. Complete Flutter Feature Inventory

Status singkat: **F** FULLY IMPLEMENTED; **P** PARTIALLY IMPLEMENTED; **N** NOT IMPLEMENTED; **U** API INTEGRATED, UI MISSING; **H** IMPLEMENTED BUT INACCESSIBLE; **C** IMPLEMENTED WITH CONTRACT MISMATCH; **R** PENDING BACKEND RELEASE. Semua 66 unit di bawah membentuk denominator. Field/aksi tambahan dipisahkan agar tidak menyebut seluruh CRUD lengkap hanya karena create bekerja.

| ID | Modul / kemampuan | Status | Endpoint/eksekusi | Entry Flutter dan kesimpulan |
| --- | --- | --- | --- | --- |
| A01 | Registrasi email | F | POST /register | RegisterScreen → auth controller → remote auth → user/token |
| A02 | Login dan pemulihan sesi | F | POST /login; GET /me | LoginScreen, secure TokenStorage, currentUser, router guard |
| A03 | Google sign-in | F | POST /auth/google | LoginScreen → Google ID token → backend validation; device/config live unverified |
| A04 | Logout | F | POST /logout | AuthController.logout; unregister FCM, token/cache cleanup |
| A05 | Reset password OTP | F | POST /auth/forgot-password, verify-reset-otp, reset-password | ForgotPassword/VerifyResetOtp/ResetPassword screens; SMTP live unverified |
| A06 | Nama/bio profil | F | GET /me; PUT /user | EditProfileScreen, updateProfile, update sesi |
| A07 | Ubah password | F | PUT /user/password | SecurityScreen; server revokes other tokens |
| A08 | Hapus akun pengguna | F | POST /delete-account | AccountSecurityDialogs; password/Google reauth; tidak dieksekusi audit |
| C01 | Katalog bank/search | P | GET /banks; /banks/{idOrSlug} | BankPickerSheet; fallback mock pada error/empty; getBank tanpa caller UI |
| C02 | Katalog tipe instrumen | F | GET /instrument-types | AddAccountScreen; String UUID; remote error ditampilkan, defaultTypes tidak dipakai remote |
| C03 | Daftar/detail/saldo akun | F | GET /financial-instruments | AccountsScreen/AccountDetailScreen dari list; endpoint show tidak wajib untuk detail UI |
| C04 | Tambah/edit tipe instrumen stabil | F | POST /financial-instruments; PUT /{id} | AccountsController UUID; PR2 telah merged pada penutup dan tree main sama dengan tree yang diaudit; deployment belum diverifikasi |
| C05 | Hapus akun keuangan | C | DELETE /financial-instruments/{id} | EditAccountScreen:257; guard recent15 vs backend forceDelete history, F01 |
| C06 | Konfigurasi biaya admin | F | POST/PUT /financial-instruments | AdminFeeFormSection; amount/day/enabled round-trip; execution scheduler terpisah |
| C07 | Status aktif/nonaktif akun | C | PUT /financial-instruments/{id} | Domain menghilangkan is_active; repository selalu true, F18 |
| C08 | Limit budget per instrumen | N | POST/PUT /financial-instruments | max_budget/budget_frequency tidak dipetakan atau ditampilkan |
| T01 | Transfer antar akun | F | POST /transfers | TransferScreen → controller/repository; UUID/idempotency; paired ledger/refetch |
| T02 | Riwayat/detail transfer | N | GET /transfers; /{id} | Tidak ada read transfer repository/screen; list transaksi bukan entitas transfer |
| T03 | Reversal transfer | N | DELETE /transfers/{id} | Backend ada; tidak ada method/aksi Flutter |
| T04 | Rekonsiliasi kas legacy | F | POST /transfers/reconcile-legacy-cash | AccountDetailScreen:613, aksi nyata dan refresh |
| X01 | Tambah transaksi manual | F | POST /transactions | Form/review → TransactionFormController → JSON/idempotency → observer → refresh |
| X02 | Daftar/filter/riwayat lengkap | P | GET /transactions | TransactionsScreen; hanya page pertama15, metadata dibuang; relasi account mismatch |
| X03 | Detail transaksi tersimpan | U | GET /transactions/{id} | getTransactionById ada tanpa caller/route detail |
| X04 | Koreksi/hapus transaksi | U | PUT/DELETE /transactions/{id} | update/delete repository ada; tidak ada aksi produk |
| X05 | Lampiran struk persisten | N | POST/PUT /transactions attachments[] | Scan hanya OCR lokal; JSON save tanpa file; backend schema conflict F15 |
| R01 | Kelola pemasukan rutin | H | GET/POST /recurring-incomes | Screens/controller/repo ada, root/add route hilang; ID int blocker tambahan |
| R02 | Pengeluaran rutin/sinkronisasi | C | GET/POST/PUT /recurring-expenses | Onboarding accessible, UUID collapse/int-only update; menu mandiri tidak diroute |
| R03 | Edit/pause/toggle automation recurring | U | PUT /recurring-{incomes,expenses}/{id} | Repository update ada, tanpa caller controller/UI; UUID belum aman |
| R04 | Hapus jadwal rutin | H | DELETE /recurring-{incomes,expenses}/{id} | Aksi pada screen tersembunyi; remove onboarding hanya state sebelum save |
| R05 | Eksekusi jadwal otomatis | P | recurring:process | Command nyata; %d key UUID collision risk; scheduler production unverified |
| W01 | Daftar/detail/tambah wishlist | F | GET/POST /wishlists | List/form/create; detail dari list; String ID |
| W02 | Ekstraksi link produk | F | POST /wishlists/preview-link; /extract-metadata | LinkScreen → metadata service; manual correction/fallback alias |
| W03 | Foto/OCR dan gambar wishlist | F | POST /wishlists/upload-image; POST/PUT item | Controller:304 upload file sebelum save; berbeda dari lampiran transaksi |
| W04 | Analisis kemampuan beli | P | GET /wishlists/{id}/analysis | API terhubung; catch local calculation tidak menjamin paritas |
| W05 | Masa tunggu/countdown | F | PUT /wishlists/{id}; alternatif POST /wait | Timestamp persist via PUT; tidak memanggil /wait bukan fitur absen; snapshot berbeda |
| W06 | Keputusan status tanpa ledger | F | PUT /wishlists/{id}; alternatif PATCH /status | Status considering/wishlist/bought/cancelled persist; opsi bought-only eksplisit |
| W07 | Catat pembelian/potong saldo | C | POST /wishlists/{id}/record-purchase | Picker int.tryParse(UUID) ??0; controller/repo int, F03 |
| W08 | Edit/hapus wishlist tersimpan | U | PUT/DELETE /wishlists/{id} | PUT dipakai draft/status/wait; tidak ada entry edit lama; deleteItem tanpa caller UI |
| G01 | CRUD goal dasar | P | GET/POST /goals; GET/PUT/DELETE /{id} | Screens/actions ada; edit mengirim stale current_amount/active true, F07 |
| G02 | Prioritas goal | F | POST /goals/reorder | GoalPriorityScreen; owned ordered UUIDs persist/refetch |
| G03 | Setoran goal | F | POST /goals/{goalId}/transactions type=deposit | DepositScreen → GoalService lock/hooks PR1 → resource/refetch |
| G04 | Penarikan goal | N | POST /goals/{goalId}/transactions type=withdraw | Remote repo hardcode deposit; tidak ada withdraw action |
| G05 | Riwayat deposit/withdraw | C | GET /goals/{goalId}/transactions | GoalDeposit membuang type; row selalu + dan grafik menjumlah semua amount |
| G06 | Koreksi/hapus setoran | U | PUT/DELETE /goals/{goalId}/transactions/{id} | Repository ada, tidak ada feature caller; delete mencari seluruh goals (N+1) |
| G07 | Gambar/link/catatan goal | N | POST/PUT /goals image/link/note | Backend menerima/merespons; domain/serializer/UI mobile menghilangkan |
| G08 | Status aktif/reminder goal | N | PUT /goals is_active/reminder_date/frequency | Mobile true/null, hanya weekly/monthly; berbeda dari saving-reminders |
| I01 | Daftar/tambah investasi | H | GET/POST /investments | Screens ada tanpa route; UUID collapse dan target hilang |
| I02 | Edit/hapus investasi | U | PUT/DELETE /investments/{id} | Repo/controller ada, list tidak menyediakan aksi |
| I03 | Riwayat transaksi investasi | U | GET /investments/{investmentId}/transactions | Repo tanpa caller; dipetakan FinancialGoal dan ID menjadi0 |
| I04 | Top-up/pencairan/koreksi investasi | N | POST/PUT/DELETE /investments/{investmentId}/transactions[/{id}] | Write methods/UI tidak ada; backend saldo ganda F02 |
| I05 | Nilai pasar/target/alokasi/reminder investasi | N | POST/PUT /investments | Fields backend ada; target form diabaikan, resource target mismatch |
| D01 | Dashboard cashflow/uang aman | P | GET /dashboard/summary; /budget/current | Summary endpoint tidak dipakai; cashflow recent15, budget fallback55% |
| B01 | Budget allocation/current | F | POST /budget; GET /budget/current | BudgetController/UI → server allocations/daily figures |
| B02 | Gaji/siklus/preview/pending/cancel | F | GET/PUT /financial-settings; POST /preview,/cancel-pending | FinancialSettingsScreen/controller → FinancialScheduleService |
| O01 | Gaji/budget/onboarding completion | F | PUT /user; POST /budget | Plan/salary/budget flow; server completion prerequisites |
| O02 | Simpan ulang akun/goal onboarding | C | POST/PUT /financial-instruments,/goals | int-only existing detection mengirim POST ulang pada UUID |
| P01 | Laporan/kategori/tabungan/kesehatan | P | GET /reports/financial | API happy path; catch fallback recent15 bisa tampak sebagai laporan lengkap |
| P02 | Excel backend | F | GET /reports/financial/export | ExportScreen:86 download bytes/share; native device belum diuji |
| P03 | Rentang bebas/quarter laporan | U | GET reports/export period custom/quarter | Repository parameter ada, UI terbatas pilihan bulan |
| N01 | Inbox/filter/riwayat lengkap | P | GET /notifications | Filter ada; pagination default15 diabaikan |
| N02 | Unread/baca satu/semua | F | GET /unread-count; PATCH /{id}/read; POST /mark-all-read | Providers/actions persist dan refresh count/inbox |
| N03 | Enam preferensi reminder | F | GET/PUT /notification-settings | NotificationSettingsScreen semua boolean terpetakan |
| N04 | Saving reminder/deactivate | F | GET/POST /saving-reminders; POST /deactivate | Goal UUID, nominal, time/frequency persist; execution live belum diuji |
| N05 | Token/penerimaan FCM | F | POST/DELETE /fcm-tokens | Lifecycle login/logout/foreground/background/tap tersedia; delivery device unverified |
| N06 | Deep link semua tipe | P | notification target_route/FCM data | Allowlist recurring root tanpa GoRoute; bill link dapat gagal |
| N07 | Reminder legacy goal/investasi ke mobile | P | notifications:process; GET /notifications | Command menulis NotificationLog, API membaca Notification; bridge tidak ditemukan |

Layer: `lib/features/<module>/presentation/screens` → providers/controllers → `lib/data/providers/app_providers.dart`/auth/onboarding providers → `lib/data/datasources/remote/remote_*_repository.dart` → `api_client.dart` dan `lib/data/models/api_*.dart`. Route: `lib/core/routing/app_router.dart`. Field domain tanpa api_ prefix sering menjadi titik kehilangan data. Bukti file:line backend/client per endpoint tersedia pada E; temuan penting memiliki kedua sisi source di N.

Loading/error/empty, busy guard dan invalidate/refetch ada pada banyak layar. Namun catch false/null/fallback dan hasil list parsial membuat keberadaan loading/error widget tidak cukup untuk membuktikan kegagalan ditampilkan benar.

### Tambahan Flutter yang tidak dihitung sebagai backend feature

| ID | Kemampuan | Status/persistensi |
| --- | --- | --- |
| UI01 | Simpan rencana nominal/sumber akun goal | UI ONLY / NOT CONNECTED: applyPlan memanggil update, serializer menghilangkan recurringAmount/sourceAccountId; F09 |
| AUX01 | OCR struk | ReceiptOcrService/receipt_parser → draft/review → POST transaction; gambar belum menjadi attachment; native kamera/ML Kit unverified |
| AUX02 | Input suara | SpeechRecognitionService/voice_transaction_parser → draft/review → POST; audio tidak perlu upload server; permission/native engine unverified |
| AUX03 | PDF laporan | report_pdf_document/exportReportPdf lokal; bukan endpoint backend yang hilang; data fallback tetap berisiko |
| AUX04 | Theme/reduce-motion/tips/in-app preference | SharedPreferences per user; local-only by design; berbeda dari enam reminder setting server |
| AUX05 | Help/privacy/about/simulasi murni | Konten/kalkulasi lokal sah; bantuan usang F19; simpan plan UI01 harus dibedakan |

## E. API Coverage Matrix

Penghitungan: `routes/api.php` diekspansi; apiResource update PUT/PATCH digabung; automatic HEAD tidak dihitung. **104 operasi** dikurangi **11**: GET /user (1), GET+PUT /user/profile (2), /financial-instrumens alias (5), token-broker POST /forgot-password dan /reset-password (2), admin toggle bank (1). Denominator **93**. Preview-link/extract-metadata tetap dua operasi karena keduanya dipanggil fallback.

**76/93=81,72%** menghitung transport implementasi, termasuk UI-missing/hidden/mismatch. **17 operasi canonical tidak dipanggil.** Endpoint show tidak dipakai bukan otomatis gap jika detail berasal dari list. Wishlist wait/status berjalan melalui PUT alternatif; POST wait mempunyai tambahan refresh snapshot. Kemampuan pengguna lengkap dihitung terpisah **30/66=45,45%**, tanpa partial credit.

Semua endpoint kecuali register/login/google/OTP/broker/banks memakai Sanctum. Admin bank menambah role check. Ownership dan persistence per modul dijelaskan C; request/resource lengkap ada di lampiran. Matriks berikut berasal HEAD lokal, bukan daftar route produksi.

| ID | Method + /api path | Laravel handler/route | Client transport evidence | UI/feature IDs | Status integrasi source |
| --- | --- | --- | --- | --- | --- |
| E001 | GET /user | `routes/api.php:28` closure; `routes/api.php:28` | Excluded | J | B: alias/web/admin, excluded |
| E002 | POST /register | `app/Http/Controllers/Api/AuthController.php:71` AuthController::register; `routes/api.php:33` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:98` | A01-A08/O01 | F dasar; batas lihat D |
| E003 | POST /login | `app/Http/Controllers/Api/AuthController.php:142` AuthController::login; `routes/api.php:34` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:85` | A01-A08/O01 | F dasar; batas lihat D |
| E004 | POST /auth/google | `app/Http/Controllers/Api/AuthController.php:193` AuthController::googleLogin; `routes/api.php:35` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:131` | A01-A08/O01 | F dasar; batas lihat D |
| E005 | POST /auth/forgot-password | `app/Http/Controllers/Api/PasswordResetController.php:14` PasswordResetController::requestOtp; `routes/api.php:36` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:165` | A05 | F dasar; batas lihat D |
| E006 | POST /auth/verify-reset-otp | `app/Http/Controllers/Api/PasswordResetController.php:48` PasswordResetController::verifyOtp; `routes/api.php:39` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:184` | A05 | F dasar; batas lihat D |
| E007 | POST /auth/reset-password | `app/Http/Controllers/Api/PasswordResetController.php:83` PasswordResetController::resetPassword; `routes/api.php:42` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:201` | A05 | F dasar; batas lihat D |
| E008 | POST /forgot-password | `app/Http/Controllers/Api/AuthController.php:549` AuthController::forgotPassword; `routes/api.php:47` | Excluded | A01-A08/O01 | B: alias/web/admin, excluded |
| E009 | POST /reset-password | `app/Http/Controllers/Api/AuthController.php:593` AuthController::resetPassword; `routes/api.php:48` | Excluded | A01-A08/O01 | B: alias/web/admin, excluded |
| E010 | GET /banks | `app/Http/Controllers/Api/BankCatalogController.php:33` BankCatalogController::index; `routes/api.php:51` | ADA `lib/data/datasources/remote/remote_bank_repository.dart:44` | C01 | P: mock fallback |
| E011 | GET /banks/{idOrSlug} | `app/Http/Controllers/Api/BankCatalogController.php:65` BankCatalogController::show; `routes/api.php:52` | ADA `lib/data/datasources/remote/remote_bank_repository.dart:58` | C01 | U transport (detail dari list) |
| E012 | GET /me | `app/Http/Controllers/Api/AuthController.php:244` AuthController::me; `routes/api.php:56` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:295` | A01-A08/O01 | F dasar; batas lihat D |
| E013 | GET /user/profile | `app/Http/Controllers/Api/AuthController.php:244` AuthController::me; `routes/api.php:57` | Excluded | A01-A08/O01 | B: alias/web/admin, excluded |
| E014 | PUT /user | `app/Http/Controllers/Api/AuthController.php:272` AuthController::updateUser; `routes/api.php:58` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:221` | A01-A08/O01 | F dasar; batas lihat D |
| E015 | PUT /user/profile | `app/Http/Controllers/Api/AuthController.php:272` AuthController::updateUser; `routes/api.php:59` | Excluded | A01-A08/O01 | B: alias/web/admin, excluded |
| E016 | PUT /user/password | `app/Http/Controllers/Api/AuthController.php:359` AuthController::updatePassword; `routes/api.php:60` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:242` | A01-A08/O01 | F dasar; batas lihat D |
| E017 | POST /logout | `app/Http/Controllers/Api/AuthController.php:226` AuthController::logout; `routes/api.php:63` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:315` | A01-A08/O01 | F dasar; batas lihat D |
| E018 | POST /delete-account | `app/Http/Controllers/Api/AuthController.php:462` AuthController::deleteAccount; `routes/api.php:64` | ADA `lib/data/datasources/remote/remote_auth_repository.dart:340` | A01-A08/O01 | F dasar; batas lihat D |
| E019 | GET /dashboard/summary | `app/Http/Controllers/Api/DashboardController.php:24` DashboardController::index; `routes/api.php:69` | TIDAK | D01 | N transport; UI dashboard P |
| E020 | GET /instrument-types | `app/Http/Controllers/Api/InstrumentTypeController.php:26` InstrumentTypeController::index; `routes/api.php:72` | ADA `lib/data/datasources/remote/remote_instrument_type_repository.dart:43` | C02 | F dasar; batas lihat D |
| E021 | GET /instrument-types/{id} | `app/Http/Controllers/Api/InstrumentTypeController.php:46` InstrumentTypeController::show; `routes/api.php:73` | TIDAK | C02 | N transport; detail dapat dari list, lihat D |
| E022 | GET /financial-instruments | `app/Http/Controllers/Api/FinancialInstrumenController.php:36` FinancialInstrumenController::index; `routes/api.php:76` | ADA `lib/data/datasources/remote/remote_account_repository.dart:80` | C03-C08/O02 | F dasar; batas lihat D |
| E023 | POST /financial-instruments | `app/Http/Controllers/Api/FinancialInstrumenController.php:69` FinancialInstrumenController::store; `routes/api.php:76` | ADA `lib/data/datasources/remote/remote_account_repository.dart:110` | C03-C08/O02 | F: PR2 merged; deploy unverified |
| E024 | GET /financial-instruments/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:92` FinancialInstrumenController::show; `routes/api.php:76` | TIDAK | C03-C08/O02 | N transport; detail dapat dari list, lihat D |
| E025 | PUT/PATCH /financial-instruments/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:124` FinancialInstrumenController::update; `routes/api.php:76` | ADA `lib/data/datasources/remote/remote_account_repository.dart:150` | C03-C08/O02 | F: PR2 merged; deploy unverified |
| E026 | DELETE /financial-instruments/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:147` FinancialInstrumenController::destroy; `routes/api.php:76` | ADA `lib/data/datasources/remote/remote_account_repository.dart:190` | C03-C08/O02 | C: delete policy F01 |
| E027 | GET /financial-instrumens | `app/Http/Controllers/Api/FinancialInstrumenController.php:36` FinancialInstrumenController::index; `routes/api.php:77` | Excluded | C03-C08/O02 | B: alias/web/admin, excluded |
| E028 | POST /financial-instrumens | `app/Http/Controllers/Api/FinancialInstrumenController.php:69` FinancialInstrumenController::store; `routes/api.php:77` | Excluded | C03-C08/O02 | B: alias/web/admin, excluded |
| E029 | GET /financial-instrumens/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:92` FinancialInstrumenController::show; `routes/api.php:77` | Excluded | C03-C08/O02 | B: alias/web/admin, excluded |
| E030 | PUT/PATCH /financial-instrumens/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:124` FinancialInstrumenController::update; `routes/api.php:77` | Excluded | C03-C08/O02 | B: alias/web/admin, excluded |
| E031 | DELETE /financial-instrumens/{id} | `app/Http/Controllers/Api/FinancialInstrumenController.php:147` FinancialInstrumenController::destroy; `routes/api.php:77` | Excluded | C03-C08/O02 | B: alias/web/admin, excluded |
| E032 | GET /budget/current | `app/Http/Controllers/Api/BudgetController.php:20` BudgetController::current; `routes/api.php:80` | ADA `lib/data/datasources/remote/remote_budget_repository.dart:23` | B01 | F dasar; batas lihat D |
| E033 | POST /budget | `app/Http/Controllers/Api/BudgetController.php:84` BudgetController::store; `routes/api.php:81` | ADA `lib/data/datasources/remote/remote_budget_repository.dart:37` | B01 | F dasar; batas lihat D |
| E034 | GET /financial-settings | `app/Http/Controllers/Api/FinancialSettingsController.php:22` FinancialSettingsController::index; `routes/api.php:84` | ADA `lib/data/datasources/remote/remote_financial_settings_repository.dart:29` | B02 | F dasar; batas lihat D |
| E035 | PUT /financial-settings | `app/Http/Controllers/Api/FinancialSettingsController.php:59` FinancialSettingsController::update; `routes/api.php:85` | ADA `lib/data/datasources/remote/remote_financial_settings_repository.dart:78` | B02 | F dasar; batas lihat D |
| E036 | POST /financial-settings/preview | `app/Http/Controllers/Api/FinancialSettingsController.php:38` FinancialSettingsController::preview; `routes/api.php:86` | ADA `lib/data/datasources/remote/remote_financial_settings_repository.dart:43` | B02 | F dasar; batas lihat D |
| E037 | POST /financial-settings/cancel-pending | `app/Http/Controllers/Api/FinancialSettingsController.php:88` FinancialSettingsController::cancelPending; `routes/api.php:87` | ADA `lib/data/datasources/remote/remote_financial_settings_repository.dart:93` | B02 | F dasar; batas lihat D |
| E038 | GET /transactions | `app/Http/Controllers/Api/TransactionController.php:30` TransactionController::index; `routes/api.php:90` | ADA `lib/data/datasources/remote/remote_transaction_repository.dart:58` | X01-X05 | P/C: pagination/relasi |
| E039 | POST /transactions | `app/Http/Controllers/Api/TransactionController.php:72` TransactionController::store; `routes/api.php:90` | ADA `lib/data/datasources/remote/remote_transaction_repository.dart:66` | X01-X05 | F dasar; batas lihat D |
| E040 | GET /transactions/{id} | `app/Http/Controllers/Api/TransactionController.php:101` TransactionController::show; `routes/api.php:90` | ADA `lib/data/datasources/remote/remote_transaction_repository.dart:89` | X01-X05 | U |
| E041 | PUT/PATCH /transactions/{id} | `app/Http/Controllers/Api/TransactionController.php:133` TransactionController::update; `routes/api.php:90` | ADA `lib/data/datasources/remote/remote_transaction_repository.dart:119` | X01-X05 | U |
| E042 | DELETE /transactions/{id} | `app/Http/Controllers/Api/TransactionController.php:158` TransactionController::destroy; `routes/api.php:90` | ADA `lib/data/datasources/remote/remote_transaction_repository.dart:139` | X01-X05 | U |
| E043 | GET /recurring-incomes | `app/Http/Controllers/Api/RecurringIncomeController.php:27` RecurringIncomeController::index; `routes/api.php:93` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:32` | R01/R03-R05 | H + UUID C |
| E044 | POST /recurring-incomes | `app/Http/Controllers/Api/RecurringIncomeController.php:62` RecurringIncomeController::store; `routes/api.php:93` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:57` | R01/R03-R05 | H + UUID C |
| E045 | GET /recurring-incomes/{id} | `app/Http/Controllers/Api/RecurringIncomeController.php:86` RecurringIncomeController::show; `routes/api.php:93` | TIDAK | R01/R03-R05 | N transport; detail dapat dari list, lihat D |
| E046 | PUT/PATCH /recurring-incomes/{id} | `app/Http/Controllers/Api/RecurringIncomeController.php:120` RecurringIncomeController::update; `routes/api.php:93` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:118` | R01/R03-R05 | U + UUID C |
| E047 | DELETE /recurring-incomes/{id} | `app/Http/Controllers/Api/RecurringIncomeController.php:144` RecurringIncomeController::destroy; `routes/api.php:93` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:170` | R01/R03-R05 | H + UUID C |
| E048 | GET /recurring-expenses | `app/Http/Controllers/Api/RecurringExpenseController.php:27` RecurringExpenseController::index; `routes/api.php:96` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:40` | R02-R05 | C: onboarding; menu mandiri H |
| E049 | POST /recurring-expenses | `app/Http/Controllers/Api/RecurringExpenseController.php:62` RecurringExpenseController::store; `routes/api.php:96` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:87` | R02-R05 | C: onboarding; menu mandiri H |
| E050 | GET /recurring-expenses/{id} | `app/Http/Controllers/Api/RecurringExpenseController.php:86` RecurringExpenseController::show; `routes/api.php:96` | TIDAK | R02-R05 | N transport; detail dapat dari list, lihat D |
| E051 | PUT/PATCH /recurring-expenses/{id} | `app/Http/Controllers/Api/RecurringExpenseController.php:120` RecurringExpenseController::update; `routes/api.php:96` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:149` | R02-R05 | C: onboarding; menu mandiri H |
| E052 | DELETE /recurring-expenses/{id} | `app/Http/Controllers/Api/RecurringExpenseController.php:144` RecurringExpenseController::destroy; `routes/api.php:96` | ADA `lib/data/datasources/remote/remote_recurring_repository.dart:176` | R02-R05 | H + UUID C |
| E053 | POST /goals/reorder | `app/Http/Controllers/Api/GoalController.php:39` GoalController::reorder; `routes/api.php:99` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:258` | G01/G02/G07/G08/O02 | F dasar; batas lihat D |
| E054 | GET /goals | `app/Http/Controllers/Api/GoalController.php:28` GoalController::index; `routes/api.php:100` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:108` | G01/G02/G07/G08/O02 | F dasar; batas lihat D |
| E055 | POST /goals | `app/Http/Controllers/Api/GoalController.php:97` GoalController::store; `routes/api.php:100` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:116` | G01/G02/G07/G08/O02 | F dasar; batas lihat D |
| E056 | GET /goals/{id} | `app/Http/Controllers/Api/GoalController.php:121` GoalController::show; `routes/api.php:100` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:162` | G01/G02/G07/G08/O02 | F dasar; batas lihat D |
| E057 | PUT/PATCH /goals/{id} | `app/Http/Controllers/Api/GoalController.php:158` GoalController::update; `routes/api.php:100` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:139` | G01/G02/G07/G08/O02 | P: metadata/fields |
| E058 | DELETE /goals/{id} | `app/Http/Controllers/Api/GoalController.php:182` GoalController::destroy; `routes/api.php:100` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:170` | G01/G02/G07/G08/O02 | F dasar; batas lihat D |
| E059 | GET /goals/{goalId}/transactions | `app/Http/Controllers/Api/GoalTransactionController.php:28` GoalTransactionController::index; `routes/api.php:103` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:176` | G03-G06 | C: history type |
| E060 | POST /goals/{goalId}/transactions | `app/Http/Controllers/Api/GoalTransactionController.php:60` GoalTransactionController::store; `routes/api.php:104` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:184` | G03-G06 | P: deposit F, withdraw N |
| E061 | GET /goals/{goalId}/transactions/{id} | `app/Http/Controllers/Api/GoalTransactionController.php:84` GoalTransactionController::show; `routes/api.php:105` | TIDAK | G03-G06 | N transport; detail dapat dari list, lihat D |
| E062 | PUT /goals/{goalId}/transactions/{id} | `app/Http/Controllers/Api/GoalTransactionController.php:115` GoalTransactionController::update; `routes/api.php:106` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:212` | G03-G06 | U |
| E063 | DELETE /goals/{goalId}/transactions/{id} | `app/Http/Controllers/Api/GoalTransactionController.php:140` GoalTransactionController::destroy; `routes/api.php:107` | ADA `lib/data/datasources/remote/remote_goal_repository.dart:244` | G03-G06 | U |
| E064 | GET /investments | `app/Http/Controllers/Api/InvestmentController.php:27` InvestmentController::index; `routes/api.php:110` | ADA `lib/data/datasources/remote/remote_investment_repository.dart:34` | I01/I02/I05 | H + kontrak C |
| E065 | POST /investments | `app/Http/Controllers/Api/InvestmentController.php:63` InvestmentController::store; `routes/api.php:110` | ADA `lib/data/datasources/remote/remote_investment_repository.dart:50` | I01/I02/I05 | H + kontrak C |
| E066 | GET /investments/{id} | `app/Http/Controllers/Api/InvestmentController.php:86` InvestmentController::show; `routes/api.php:110` | TIDAK | I01/I02/I05 | N transport; detail dapat dari list, lihat D |
| E067 | PUT/PATCH /investments/{id} | `app/Http/Controllers/Api/InvestmentController.php:121` InvestmentController::update; `routes/api.php:110` | ADA `lib/data/datasources/remote/remote_investment_repository.dart:75` | I01/I02/I05 | U + kontrak C |
| E068 | DELETE /investments/{id} | `app/Http/Controllers/Api/InvestmentController.php:144` InvestmentController::destroy; `routes/api.php:110` | ADA `lib/data/datasources/remote/remote_investment_repository.dart:100` | I01/I02/I05 | U + kontrak C |
| E069 | GET /investments/{investmentId}/transactions | `app/Http/Controllers/Api/InvestmentTransactionController.php:28` InvestmentTransactionController::index; `routes/api.php:113` | ADA `lib/data/datasources/remote/remote_investment_repository.dart:108` | I03/I04 | U + kontrak C |
| E070 | POST /investments/{investmentId}/transactions | `app/Http/Controllers/Api/InvestmentTransactionController.php:60` InvestmentTransactionController::store; `routes/api.php:114` | TIDAK | I03/I04 | N transport/business gap |
| E071 | GET /investments/{investmentId}/transactions/{id} | `app/Http/Controllers/Api/InvestmentTransactionController.php:84` InvestmentTransactionController::show; `routes/api.php:115` | TIDAK | I03/I04 | N transport; detail dapat dari list, lihat D |
| E072 | PUT /investments/{investmentId}/transactions/{id} | `app/Http/Controllers/Api/InvestmentTransactionController.php:115` InvestmentTransactionController::update; `routes/api.php:116` | TIDAK | I03/I04 | N transport/business gap |
| E073 | DELETE /investments/{investmentId}/transactions/{id} | `app/Http/Controllers/Api/InvestmentTransactionController.php:140` InvestmentTransactionController::destroy; `routes/api.php:117` | TIDAK | I03/I04 | N transport/business gap |
| E074 | POST /transfers/reconcile-legacy-cash | `app/Http/Controllers/Api/TransferController.php:79` TransferController::reconcileLegacyCash; `routes/api.php:120` | ADA `lib/data/datasources/remote/remote_account_repository.dart:225` | T01-T04 | F dasar; batas lihat D |
| E075 | GET /transfers | `app/Http/Controllers/Api/TransferController.php:27` TransferController::index; `routes/api.php:121` | TIDAK | T01-T04 | N transport/business gap |
| E076 | POST /transfers | `app/Http/Controllers/Api/TransferController.php:57` TransferController::store; `routes/api.php:121` | ADA `lib/data/datasources/remote/remote_account_repository.dart:202` | T01-T04 | F dasar; batas lihat D |
| E077 | GET /transfers/{id} | `app/Http/Controllers/Api/TransferController.php:110` TransferController::show; `routes/api.php:121` | TIDAK | T01-T04 | N transport; detail dapat dari list, lihat D |
| E078 | DELETE /transfers/{id} | `app/Http/Controllers/Api/TransferController.php:129` TransferController::destroy; `routes/api.php:121` | TIDAK | T01-T04 | N transport/business gap |
| E079 | GET /notification-settings | `app/Http/Controllers/Api/NotificationSettingController.php:26` NotificationSettingController::show; `routes/api.php:124` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:99` | N03 | F dasar; batas lihat D |
| E080 | PUT /notification-settings | `app/Http/Controllers/Api/NotificationSettingController.php:56` NotificationSettingController::update; `routes/api.php:125` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:149` | N03 | F dasar; batas lihat D |
| E081 | GET /notifications | `app/Http/Controllers/Api/NotificationController.php:33` NotificationController::index; `routes/api.php:128` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:53` | N01/N02/N06/N07 | P: pagination |
| E082 | GET /notifications/unread-count | `app/Http/Controllers/Api/NotificationController.php:67` NotificationController::unreadCount; `routes/api.php:129` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:76` | N01/N02/N06/N07 | F dasar; batas lihat D |
| E083 | PATCH /notifications/{id}/read | `app/Http/Controllers/Api/NotificationController.php:98` NotificationController::markAsRead; `routes/api.php:130` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:87` | N01/N02/N06/N07 | F dasar; batas lihat D |
| E084 | POST /notifications/mark-all-read | `app/Http/Controllers/Api/NotificationController.php:123` NotificationController::markAllAsRead; `routes/api.php:131` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:93` | N01/N02/N06/N07 | F dasar; batas lihat D |
| E085 | GET /saving-reminders | `app/Http/Controllers/Api/SavingReminderController.php:34` SavingReminderController::show; `routes/api.php:134` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:155` | N04 | F dasar; batas lihat D |
| E086 | POST /saving-reminders | `app/Http/Controllers/Api/SavingReminderController.php:71` SavingReminderController::store; `routes/api.php:135` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:188` | N04 | F dasar; batas lihat D |
| E087 | POST /saving-reminders/deactivate | `app/Http/Controllers/Api/SavingReminderController.php:99` SavingReminderController::deactivate; `routes/api.php:136` | ADA `lib/data/datasources/remote/remote_notification_repository.dart:201` | N04 | F dasar; batas lihat D |
| E088 | POST /fcm-tokens | `app/Http/Controllers/Api/FcmTokenController.php:17` FcmTokenController::store; `routes/api.php:139` | ADA `lib/data/repositories/fcm_token_repository.dart:46` | N05 | F dasar; batas lihat D |
| E089 | DELETE /fcm-tokens | `app/Http/Controllers/Api/FcmTokenController.php:52` FcmTokenController::destroy; `routes/api.php:140` | ADA `lib/data/repositories/fcm_token_repository.dart:64` | N05 | F dasar; batas lihat D |
| E090 | POST /wishlists/extract-metadata | `app/Http/Controllers/Api/WishlistController.php:33` WishlistController::extractMetadata; `routes/api.php:143` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:112` | W01-W08 | F dasar; batas lihat D |
| E091 | POST /wishlists/preview-link | `app/Http/Controllers/Api/WishlistController.php:60` WishlistController::previewLink; `routes/api.php:144` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:103` | W01-W08 | F dasar; batas lihat D |
| E092 | POST /wishlists/upload-image | `app/Http/Controllers/Api/WishlistController.php:71` WishlistController::uploadImage; `routes/api.php:145` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:127` | W01-W08 | F dasar; batas lihat D |
| E093 | GET /wishlists/{id}/analysis | `app/Http/Controllers/Api/WishlistController.php:340` WishlistController::analysis; `routes/api.php:146` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:143` | W01-W08 | P: fallback |
| E094 | PATCH /wishlists/{id}/status | `app/Http/Controllers/Api/WishlistController.php:264` WishlistController::updateStatus; `routes/api.php:147` | TIDAK | W01-W08 | N transport; via PUT, W05/W06 |
| E095 | POST /wishlists/{id}/record-purchase | `app/Http/Controllers/Api/WishlistController.php:359` WishlistController::recordPurchase; `routes/api.php:148` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:165` | W01-W08 | C: UUID picker |
| E096 | POST /wishlists/{id}/wait | `app/Http/Controllers/Api/WishlistController.php:301` WishlistController::startWait; `routes/api.php:149` | TIDAK | W01-W08 | N transport; via PUT, W05/W06 |
| E097 | GET /wishlists | `app/Http/Controllers/Api/WishlistController.php:116` WishlistController::index; `routes/api.php:150` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:34` | W01-W08 | F dasar; batas lihat D |
| E098 | POST /wishlists | `app/Http/Controllers/Api/WishlistController.php:146` WishlistController::store; `routes/api.php:150` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:64` | W01-W08 | F dasar; batas lihat D |
| E099 | GET /wishlists/{id} | `app/Http/Controllers/Api/WishlistController.php:178` WishlistController::show; `routes/api.php:150` | TIDAK | W01-W08 | N transport; detail dapat dari list, lihat D |
| E100 | PUT/PATCH /wishlists/{id} | `app/Http/Controllers/Api/WishlistController.php:207` WishlistController::update; `routes/api.php:150` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:88` | W01-W08 | F dasar; batas lihat D |
| E101 | DELETE /wishlists/{id} | `app/Http/Controllers/Api/WishlistController.php:236` WishlistController::destroy; `routes/api.php:150` | ADA `lib/data/datasources/remote/remote_purchase_decision_repository.dart:96` | W01-W08 | U |
| E102 | PATCH /admin/banks/{id}/toggle-active | `app/Http/Controllers/Api/BankCatalogController.php:94` BankCatalogController::toggleActive; `routes/api.php:153` | Excluded | C01 | B: alias/web/admin, excluded |
| E103 | GET /reports/financial | `app/Http/Controllers/Api/FinancialReportController.php:54` FinancialReportController::index; `routes/api.php:156` | ADA `lib/data/datasources/remote/remote_report_repository.dart:50` | P01-P03 | P: fallback; date range U |
| E104 | GET /reports/financial/export | `app/Http/Controllers/Api/FinancialReportController.php:116` FinancialReportController::export; `routes/api.php:157` | ADA `lib/data/datasources/remote/remote_report_repository.dart:73` | P01-P03 | F dasar; batas lihat D |

PUT/PATCH resource yang digabung: 8. Jumlah verba mentah tanpa HEAD: 112.

Canonical tidak dipanggil (17): `GET /dashboard/summary`; `GET /instrument-types/{id}`; `GET /financial-instruments/{id}`; `GET /recurring-incomes/{id}`; `GET /recurring-expenses/{id}`; `GET /goals/{goalId}/transactions/{id}`; `GET /investments/{id}`; `POST /investments/{investmentId}/transactions`; `GET /investments/{investmentId}/transactions/{id}`; `PUT /investments/{investmentId}/transactions/{id}`; `DELETE /investments/{investmentId}/transactions/{id}`; `GET /transfers`; `GET /transfers/{id}`; `DELETE /transfers/{id}`; `PATCH /wishlists/{id}/status`; `POST /wishlists/{id}/wait`; `GET /wishlists/{id}`.


## F. Missing Flutter Features

Sembilan unit N: **C08** limit budget instrumen, **T02** riwayat/detail transfer, **T03** reversal transfer, **X05** lampiran struk, **G04** withdrawal goal, **G07** gambar/link/catatan goal, **G08** active/reminder goal, **I04** write transaksi investasi, **I05** konfigurasi/nilai pasar investasi.

Metode pembuktian negatif: inventaris `rg --files`, pencarian endpoint/symbol di seluruh `lib`, repository/interface/model, screen/controller, `app_router.dart`, AppRoutes dan `context.go/push`. Backend positif ditautkan pada E/N. Tidak menyatakan “belum ada” hanya dari tidak ditemukannya file screen bernama tertentu. Write investasi menunggu F02; upload struk menunggu F15. Native OCR/voice/PDF bukan gap hanya karena tidak punya endpoint khusus. Tidak mengarang fitur restore, CRUD kategori, atau email verification yang tidak ditemukan surface source-nya.

## G. Partially Implemented Features

Sepuluh unit P: **C01** bank fallback, **X02** history pagination, **R05** scheduler UUID key, **W04** analysis fallback, **G01** CRUD metadata goal, **D01** dashboard, **P01** reports fallback, **N01** inbox pages, **N06** deep links, **N07** legacy reminder bridge. Batas per unit pada D; detail F01–F20.

Delapan unit U, dihitung terpisah: **X03** transaction detail, **X04** transaction correction/delete, **R03** recurring update/pause, **W08** edit/delete persisted wishlist, **G06** correction/delete deposit, **I02** investment edit/delete, **I03** investment history, **P03** date range bebas/quarter. Method repository tidak membuktikan aksi dapat diakses. Invalidate provider juga tidak memperbaiki field/pagination yang hilang saat parsing.

## H. UI-Only & Mock Features

**UI01:** `GoalsController.applyPlan` (F: `lib/features/goals/presentation/providers/goals_controller.dart:339`) memperbarui recurringAmount/frequency, tetapi serializer `remote_goal_repository.dart:137` tidak mengirim nominal/sumber akun dan mapper :74 tidak memulihkannya. Schema/request Goal tidak mempunyai padanan eksplisit. Frekuensi bisa tersimpan, rencana nominal tidak. Lihat F09.

- Default USE_REMOTE_API/AUTH=true. Mock provider hanya dipilih flag false (`app_providers.dart:62`, auth controller :29); bukan seluruh aplikasi masih dummy.
- **RemoteBankRepository:45/47 fallback ke MockBankRepository pada remote error/empty** tanpa provenance. Katalog mock tidak membuktikan seed production.
- RemoteInstrumentTypeRepository:41 rethrows remote error/empty; defaultTypes bukan fallback remote aktif. Jangan membawa temuan branch lama bahwa UUID tipe selalu menjadi enum string.
- Investment/recurring provider (`app_providers.dart:204,221`) tetap memakai RemoteRepository saat flag API=false; mode mock bukan offline penuh.
- Dashboard/report/purchase analysis fallback adalah kalkulasi lokal, bukan fixture; risiko data parsial tetap ada F17.
- Preferensi tampilan tersimpan SharedPreferences user-scoped; token secure storage; cache/draft onboarding in-memory. Durable offline writes tidak ditemukan; bukan klaim backend punya offline-sync yang belum dihubungkan.
- Fee transaksi dipersist sebagai net amount; domain response fee=0 (`remote_transaction_repository.dart:42`). Backend tidak punya breakdown fee terpisah. Nilai bersih bisa benar sementara breakdown tidak round-trip.
- Kamera/speech/OCR native tidak otomatis mock karena parser lokal. Perangkat nyata belum diuji.

## I. Contract Mismatches

Enam unit C utama: **C05** delete policy, **C07** active account, **R02** recurring UUID, **W07** purchase UUID, **G05** signed goal history, **O02** onboarding identity. Mismatch lain tetap dicatat pada status utama H/P/U/N tanpa double counting:

1. DTO recurring/investment masih integer, scheduler memakai `%d` untuk UUID (F05).
2. Investment model/request `target` vs response `target_amount`; increase/portfolio metrics tidak diekspor; target form tidak dikirim (F14).
3. Transaction service eager-load `financialInstrumen`, resource memakai `whenLoaded('instrument')`, raw instrument_id tidak dikirim. Alias relation tidak otomatis dianggap loaded. Create fallback accountId tidak memperbaiki GET berikutnya (F06).
4. Attachment JSON/array service/resource vs relation/table model/schema (F15).
5. Goal metadata update menerima ledger current_amount; active selalu true dan reminder/frequency tidak round-trip (F07/F18).
6. SavingReminder backend min amount0 sedangkan mobile save menolak <=0; deactivate tersedia. Ini pembatasan UX, bukan blocker utama.
7. PUT wishlist wait menerima clock client; dedicated POST wait juga refresh analysis_snapshot. Countdown persist, kesetaraan snapshot tidak terbukti.
8. Register catch mengembalikan exception/file (L: AuthController.php:97); ApiClient menyamarkan 5xx/SQL (F: api_client.dart:79). Sanitasi Flutter tidak menghilangkan kebocoran respons backend.
9. ApiClient punya timeout15s, 401/422/5xx handling, tetapi unauthorized callback opsional; budget/onboarding client tanpa callback dan catch dapat menelan kegagalan (F20).
10. Anotasi Swagger integer yang lama tidak mengalahkan runtime UUID. ID bank master bisa integer sah; jangan mengonversi semua integer secara membabi-buta.

Payload authenticated produksi belum dibandingkan. Jangan menambah adapter spekulatif berdasarkan dokumentasi lama tanpa contract fixture aktual.

## J. Backend-Only Features

| ID | Kelompok | Evidence/batas |
| --- | --- | --- |
| J01 | Administrasi master bank | L: app/Filament/Resources/BankCatalogResource.php; BankCatalogController.php:94, role check :96. Read catalog tetap C01 |
| J02 | Administrasi tipe instrumen | L: app/Filament/Resources/InstrumentTypeResource.php; InstrumentTypeSeeder. Read tetap C02 |
| J03 | Panel administrator/access panel | L: app/Providers/Filament/AdminPanelProvider.php; app/Models/User.php. Bukan menu konsumen |
| J04 | Schema/seed/queue/scheduler/credential operations | L: database/migrations, seeders, routes/console.php, config/services.php. Efek bisnis recurring/reminder tetap diaudit |
| J05 | Navigasi web/Filament dan broker reset alternatif | L: routes/web.php; NotificationActionController; AuthController.php:549,593. Mobile sudah OTP; alias bukan fitur baru |

Filament **App panel** adalah antarmuka pengguna, tidak otomatis backend-only. Reconcile investasi pada model/Filament belum berarti ada endpoint reconcile investasi. Public storage adalah delivery infrastructure yang dapat dipakai mobile, bukan tombol admin yang perlu dibuat.

## K. Hidden Features

Tiga unit H: **R01** pemasukan rutin, **R04** hapus recurring, **I01** list/add investasi. Screens/controller/repository ada, tetapi tidak ada root/add GoRoute. `app_router.dart:151` hanya menyebut investasi/recurring dalam protectedPrefixes. Konstanta AppRoutes bukan route registration. Tidak ditemukan import/register screen tersebut atau alternatif entry produk.

`/onboarding/recurring-expenses` **ada**, tetapi tidak sama dengan `/recurring-expenses` dan tidak memberi management lengkap. `notification_deep_link.dart:26` membolehkan recurring root sehingga notifikasi bisa diarahkan ke route kosong. Cari constructor screen, literal path, AppRoutes, seluruh context.go/push untuk mereproduksi temuan.

## L. Dead Code / Duplicate Code

| Fakta/kandidat | Evidence dan penilaian |
| --- | --- |
| Method tanpa caller produk | getBank, getTransactionById/getTransactions/updateTransaction/deleteTransaction, updateDeposit/deleteDeposit, getInvestmentTransactions, updateRecurringIncome/Expense: pencarian seluruh lib tidak menemukan consumer aksi produk. Test call bukan UI |
| Screen investasi/recurring tak terdaftar | Kandidat fitur belum selesai, jangan hapus otomatis; F10 |
| Empty investment CTA | F: investments_screen.dart:177, onPressed:(){} |
| Dua pemilik saldo investasi | Service+model hooks, F02; duplikasi berbahaya |
| NotificationLog vs Notification | Dua pipeline tidak sepenuhnya terhubung; perlu bridge/dedup, bukan drop tabel |
| Dashboard berlapis | RemoteDashboardRepository, dashboardDataProvider dan Laravel DashboardService menghitung dengan data/scope berbeda |
| Onboarding write terpisah | Integer identity lama berbeda dari account/goal repository utama yang sudah String |
| Mock repositories | Dipakai tests/flag false, bukan dead otomatis; recurring/investment false branch tetap remote |
| Placeholder/DTO/route constants/comments lama | Kandidat unreachable, perlu reference analysis sebelum menghapus |
| Help usang | F: lib/features/profile/data/help_articles.dart:129,146; transfer sudah ada tetapi bantuan menyebut belum tersedia |
| API aliases | financial-instrumens/user-profile compatibility; bukan fitur duplikat untuk denominator |

## M. Release Dependency Analysis

| Dependency | Local/main/PR | Produksi | Langkah lanjutan, tidak dieksekusi audit |
| --- | --- | --- | --- |
| Goals PR1 | Merged 6a1f4eb, ancestor main | Deploy SHA unknown | DB UUID + Android ledger tests |
| Instruments PR2 | Awal OPEN; akhir MERGED ke main113ac3f, tree identik34aee92 | Deployment UNVERIFIED | Verifikasi deployment/manifest dan UUID seed; merge tidak lagi tertunda |
| Flutter integration | bde0e6a, ahead14 dari main8f1e282; tanpa tracking branch remote | Build SHA/defines unknown | Pin SHA/flavor/API_BASE_URL/remote flags |
| Type/bank master | Seeder ada, type changes di PR2 | Banks200; authenticated types unknown | Read existing IDs sebelum rencana seeding |
| UUID/token morph/schema | 43 migrations; tokenable_id varchar patch | Migration history/schema unknown | Compare instance schema; source migration historis bukan bukti applied |
| Wishlist storage/transaction bridge | Upload dan transaction_id migration ada main | Storage delivery/write unknown | Staging upload/reload/purchase |
| Pending financial schedule | Pending/transition columns dan service ada | Due promotion/clock unknown | Month-end/payday/bridge fixtures |
| Recurring/reminder | Commands every-minute; UUID key bug F05 | Cron/queue/locks unknown | Fix key, verify heartbeat/due/worker |
| FCM/Google/SMTP | Config/lifecycle source ada | Credentials/consent/delivery unknown | Authorized device/user test, tanpa expose secret |
| Investment/attachment/transaction resource | Source defects F02/F06/F15 | Tidak diuji | Backend stabilization sebelum write UI |

Diff PR2: Store/UpdateFinancialInstrumenRequest, FinancialInstrumenService, InstrumentTypeService, InstrumentTypeSeeder, ComprehensiveApiContractFase8mTest. **Tidak ada migration baru pada diff PR2.** Jangan reseed/deploy hanya untuk menutup dropdown error tanpa memeriksa existing UUID.

Dedup data existing atau rekonsiliasi saldo adalah pekerjaan mutasi terpisah yang memerlukan rencana/otorisasi; tidak dilakukan atas nama audit. Tidak mengubah .env, dependencies, menjalankan seed manual atau migration terhadap DB persisten.

## N. Prioritized Development Backlog

S=terfokus, M=beberapa layer/regresi, L=alur/domain besar; bukan estimasi hari. P0 berarti potensi kerusakan data pada source, bukan insiden produksi terukur. File pada evidence adalah area perubahan berikutnya; audit tidak mengeditnya.

### F01 — P0 — Penghapusan akun dapat menghapus riwayat

**C05/X02; M.** L: `app/Models/FinancialInstrumen.php:146`, `app/Services/FinancialInstrumenService.php:176`. F: `lib/features/accounts/presentation/providers/accounts_controller.dart:195`, `lib/data/datasources/remote/remote_transaction_repository.dart:56`.

Guard hanya getRecentTransactions default15; accountId juga bisa hilang F06. Backend deleting hook mengambil withTrashed dan forceDelete seluruh transaksi akun. Contoh INFERRED: transaksi akun A berada halaman2 → guard tidak melihat → DELETE menghapus ledger A. Jalur source VERIFIED; tidak dieksekusi. **Backend prerequisite:** invariant server-side untuk arsip/delete. **Acceptance:** akun dengan history lama/baru/opening/goal/transfer tidak kehilangan ledger; delete ditolak atau arsip sesuai kebijakan eksplisit; UI tidak menjanjikan proteksi yang tidak ditegakkan server.

### F02 — P0 — Mutasi saldo investasi ganda

**I04; M.** L: `app/Services/InvestmentService.php:110,117,190`, `app/Models/InvestmentTransaction.php:124,142`. F: `lib/data/datasources/remote/remote_investment_repository.dart:104`.

Service mengubah achieved sebelum create InvestmentTransaction; creating hook mengubah lagi tanpa guard transaction_id pada mutasi achieved. Delete juga revert service+hook. Deposit D berpotensi +2D sementara ledger bank satu; numerical effect INFERRED dari jalur VERIFIED, belum test investasi runtime. **Backend blocker:** satu pemilik mutasi. **Acceptance:** deposit/withdraw/update/delete/profit/loss/inactive/race tepat sekali pada DB UUID; baru kemudian aktifkan UI write.

### F03 — P1 — Wishlist purchase UUID menjadi nol

**W07; S.** L: `app/Http/Controllers/Api/WishlistController.php:359`. F: `lib/features/tahandulu/presentation/screens/tahandulu_decide_screen.dart:339`, `lib/data/datasources/remote/remote_purchase_decision_repository.dart:151`.

int.tryParse(acc.id) ??0 kehilangan UUID; controller/interface/repo int. Backend menerima instrument_id owned. **Readiness:** purchase backend ada main; bukan menunggu endpoint baru/PR2. **Acceptance:** UUID tetap String picker→JSON; sekali potong saldo/transaction_id, reload bought, retry idempoten, ownership/insufficient balance error terlihat.

### F04 — P1 — Onboarding menduplikasi entitas UUID

**O02/R02; M.** L: `app/Services/FinancialInstrumenService.php:76`, `app/Services/GoalService.php:50`. F: `lib/data/datasources/remote/remote_onboarding_repository.dart:311,376,427`, `lib/features/onboarding/presentation/providers/instruments_controller.dart:104,136`.

addInstrument sudah POST lalu tombol lanjut saveInstruments memakai int-only existing check; UUID dianggap baru dan POST lagi. Goal juga demikian; expense punya tambahan id=0 parsing. Source VERIFIED, existing duplicates produksi UNVERIFIED. **Dependency:** explicit server identity/upsert delta; cleanup data dipisahkan. **Acceptance:** tambah→lanjut→kembali→save→restart tetap satu akun/goal; edit PUT UUID; remove persisted dan retry partial failure benar.

### F05 — P1 — UUID recurring/investment dan scheduler key

**R01–R05/I01–I05; M.** L: `app/Models/RecurringTransaction.php:15`, `app/Models/Investment.php:15`, `app/Console/Commands/ProcessRecurringTransactions.php:53,114`. F: `lib/data/models/api_recurring_transaction.dart:42`, `lib/data/models/api_investment.dart:37`, `lib/data/models/api_investment_transaction.dart:35`, `lib/data/datasources/remote/remote_recurring_repository.dart:52`.

DTO UUID→int/0, recurring instrumentId int. Scheduler sprintf recurring:%d mengubah UUID sehingga ID berbeda dapat berbagi key due-time sama; collision/dedup impact INFERRED. **Dependency:** backend key+Flutter DTO/interface serempak. **Acceptance:** UUID tidak berubah; dua jadwal prefix nonnumeric due sama menghasilkan dua transaksi/notifikasi, masing-masing tepat sekali.

### F06 — P1 — Relasi transaksi hilang dan agregat recent15

**X02/D01/C05; M.** L: `app/Services/TransactionService.php:15,30`, `app/Http/Resources/TransactionResource.php:25`, `app/Models/Transaction.php:22,54`. F: `lib/data/datasources/remote/remote_transaction_repository.dart:34,56,95`, `lib/data/providers/dashboard_providers.dart:64,191`.

Eager-load financialInstrumen tidak sama dengan whenLoaded('instrument'); raw instrument_id tidak dikirim. Repository membuang pagination; dashboard menghitung dari15. Mobile mengecualikan transfer tetapi backend juga Saldo Awal/Penyesuaian Saldo. **Dependency:** backend resource contract + server aggregate/pagination. **Acceptance:** list/detail preserve account UUID; >30 transaksi lintas bulan dapat ditelusuri; totals sesuai backend termasuk transfer/opening/adjustment; account filter tidak kosong palsu.

### F07 — P1 — Edit metadata goal dapat menimpa ledger

**G01/G08; M.** L: `app/Http/Requests/Api/Goal/UpdateGoalRequest.php:23`, `app/Services/GoalService.php:82`. F: `lib/data/datasources/remote/remote_goal_repository.dart:137`, `lib/features/goals/presentation/providers/goals_controller.dart:230`.

Update mengirim current_amount snapshot; jika list gagal fallback object currentAmount=0. Backend menerima update; concurrent deposit dapat tertimpa (INFERRED). Active selalu true, reminder null/frequency lossy. **Dependency:** pisahkan metadata dari ledger. **Acceptance:** concurrent deposit+edit nama tidak kehilangan dana; fetch gagal tidak reset; field tak diedit tetap utuh.

### F08 — P1 — Withdrawal goal dan history bertanda

**G04/G05/G06; M.** L: `app/Http/Requests/Api/Goal/StoreGoalTransactionRequest.php:18`, `app/Models/GoalTransaction.php:74`. F: `lib/data/datasources/remote/remote_goal_repository.dart:84,182,207`, `lib/features/goals/presentation/screens/goal_history_screen.dart:194,323`.

Repo hardcode deposit; mapper membuang type; withdrawal dari web terlihat + dan menaikkan grafik. Edit/delete hanya repo. Funded goal delete ditolak tetapi mobile tidak punya withdraw normal. **Readiness:** PR1 merged, perlu UUID E2E. **Acceptance:** +100/−40 →60 dan signed history; edit/delete/overdraw/ownership konsisten. Menghapus deposit bukan pengganti withdrawal.

### F09 — P1 — Simpan plan tidak menyimpan nominal/sumber akun

**UI01; M.** L: `app/Http/Requests/Api/Goal/UpdateGoalRequest.php:17`. F: `lib/features/goals/presentation/providers/goals_controller.dart:339`, `lib/data/datasources/remote/remote_goal_repository.dart:74,137`.

applyPlan mengubah domain namun serializer menghilangkan recurringAmount/sourceAccountId, mapper tidak mengembalikan. **Dependency:** putuskan kontrak rencana; saving-reminders tidak otomatis padanan. **Acceptance:** nominal/frekuensi/sumber sama setelah reload/login; bila simulasi saja, tidak memberi pesan seolah tersimpan.

### F10 — P1 — Routes tersembunyi/deep link buntu

**R01/R04/I01/N06; M.** L: `app/Console/Commands/ProcessRecurringTransactions.php:109`. F: `lib/core/routing/app_router.dart:151,214`, `lib/core/routing/app_routes.dart:29`, `lib/core/routing/notification_deep_link.dart:26`.

Konstanta/protectedPrefixes bukan route; screen investasi/recurring tidak didaftarkan; allowlist membolehkan root kosong. **Dependency:** F02/F05 sebelum write investasi; read navigation bisa bertahap. **Acceptance:** menu list/add/edit nyata; cold/warm notification tap setelah auth valid; tes route discovery.

### F11 — P1 — Verifikasi rilis instrument contract setelah PR2 merged

**C04; S.** L: `app/Services/FinancialInstrumenService.php:19`, `app/Services/InstrumentTypeService.php:11`, `database/seeders/InstrumentTypeSeeder.php:1`. F: `lib/data/datasources/remote/remote_instrument_type_repository.dart:41`, `test/financial_instrument_contract_fase8m_test.dart:1`.

PR2 semula OPEN, tetapi pemeriksaan penutup mengonfirmasi MERGED 113ac3f (24 November 2026 10:31:57 WIB). Flutter mengharapkan UUID stabil. **Dependency tersisa:** verifikasi deployment/manifest; jangan meminta merge ulang. Tidak ada bukti bahwa produksi belum atau sudah memuatnya. **Acceptance:** manifest SHA kedua sisi; seeder idempotent mempertahankan UUID; invalid/missing/cash cases memberi 422 aman; partial update type preserved; auth staging contract tests.

### F12 — P2 — Aksi koreksi transaksi/wishlist belum ada

**X03/X04/W08; M.** L: `app/Http/Controllers/Api/TransactionController.php:101,133,158`, `app/Http/Controllers/Api/WishlistController.php:207,236`. F: `lib/data/datasources/remote/remote_transaction_repository.dart:87,117,137`, `lib/features/tahandulu/presentation/providers/tahandulu_controller.dart:415`.

Pencarian seluruh lib tidak menemukan caller detail/update/delete transaction; wishlist deleteItem tak dipanggil dan tak ada entry edit item lama. **Dependency:** F01/F06/F15 dan linked-ledger rules. **Acceptance:** buka/edit/delete confirm/cancel/retry, errors jelas, reload persist; transaction linked goal/transfer/wishlist tidak merusak invariant.

### F13 — P2 — History/reversal transfer

**T02/T03; M.** L: `app/Services/TransferService.php:15,348,357`. F: `lib/data/datasources/remote/remote_account_repository.dart:194`, `lib/features/accounts/presentation/screens/transfer_screen.dart:1`.

Mobile create/reconcile saja; backend read/reversal ada. **Dependency:** transfer lifecycle tests. **Acceptance:** history source/destination/notes; reverse sekali, saldo tujuan kurang ditolak; saldo dan cashflow benar setelah reload/retry.

### F14 — P2 — Domain investasi/field/response belum utuh

**I01–I05; L.** L: `app/Models/Investment.php:17,74`, `app/Http/Resources/InvestmentResource.php:18`, `app/Http/Requests/Api/Investment/StoreInvestmentRequest.php:19`. F: `lib/features/investment/presentation/screens/add_investment_screen.dart:60`, `lib/features/investment/presentation/providers/investment_controller.dart:27`, `lib/data/datasources/remote/remote_investment_repository.dart:50`.

Target input diabaikan controller, repo target/increase=null; resource target_amount bukan model target, increase/portfolio metrics hilang. History dipaksa FinancialGoal. **Dependency:** F02/F05/F10. **Acceptance:** domain investasi tersendiri; UUID, target, return, allocation, reminder, active round-trip; signed tx history dan portfolio sesuai ledger.

### F15 — P2 — Attachment struk belum siap ujung-ke-ujung

**X05/G07; M.** L: `app/Http/Requests/Api/Transaction/StoreTransactionRequest.php:34`, `app/Services/TransactionService.php:62,169`, `app/Models/Transaction.php:37`, `app/Http/Resources/TransactionResource.php:14`, `database/migrations/2026_10_14_063531_create_transaction_attachments_table.php:14`. F: `lib/features/transactions/presentation/screens/transaction_scan_screen.dart:71`, `lib/data/datasources/remote/remote_transaction_repository.dart:64`.

Service menyimpan attachments array, model relation/table; base transaction migration tanpa column/cast array. Mobile file OCR tidak diteruskan JSON. **Dependency:** stabilisasi satu representation backend/storage, bukan sekadar tombol upload. **Acceptance:** upload/view/replace/delete/reload, MIME/size/owner, rollback cleanup; gambar goal menggunakan endpointnya sendiri.

### F16 — P2 — Inbox pages dan reminder legacy bridge

**N01/N07; M.** L: `app/Services/NotificationService.php:16`, `app/Console/Commands/ProcessScheduledNotifications.php:39,85`, `app/Models/NotificationLog.php:11`. F: `lib/data/datasources/remote/remote_notification_repository.dart:43`.

API paginate15; client mengabaikan meta. Legacy command hanya NotificationLog, API Notification; tidak ditemukan observer bridge. Milestone/saving-reminder baru tetap punya jalur lain. **Dependency:** bridge/dedup + paging + scheduler verification. **Acceptance:** >30 notifications reachable; reminder muncul sekali sesuai preferensi di web/mobile/push; unread count konsisten.

### F17 — P2 — Fallback menyamarkan error/data parsial

**C01/D01/P01/W04; M.** L: `app/Services/DashboardService.php:14`, `app/Services/FinancialReportService.php:36`. F: `lib/data/providers/dashboard_providers.dart:242`, `lib/data/providers/reports_providers.dart:74`, `lib/data/datasources/remote/remote_bank_repository.dart:45`, `lib/features/tahandulu/presentation/providers/tahandulu_controller.dart:446`.

Budget/report/analysis error menjadi angka lokal; report recent15; bank empty/error jadi mock catalog tanpa provenance. **Dependency:** error/stale policy, bukan menghapus semua kalkulasi lokal sah. **Acceptance:** offline/401/422/500 terlabel; rekomendasi parsial bukan angka server; bank fallback slug tervalidasi.

### F18 — P2 — Field lanjutan akun/goal hilang

**C07/C08/G07/G08; M.** L: `app/Http/Requests/Api/FinancialInstrumen/UpdateFinancialInstrumenRequest.php:28`, `app/Http/Resources/GoalResource.php:20`. F: `lib/data/datasources/remote/remote_account_repository.dart:13,162`, `lib/data/datasources/remote/remote_goal_repository.dart:137`.

is_active tidak dipetakan dan true dikirim selalu; limit akun, link/note/image/reminder/frequency goal tidak lengkap. **Dependency:** F07/F15; scope field UX. **Acceptance:** edit nama tidak mengubah status/field lain; advanced values round-trip web/mobile; active/inactive selectable bila scope disetujui.

### F19 — P3 — Rentang laporan/help/legacy CTA

**P03/L; S.** L: `app/Http/Controllers/Api/FinancialReportController.php:57`. F: `lib/features/reports/presentation/screens/reports_screen.dart:39`, `lib/data/datasources/remote/remote_report_repository.dart:35`, `lib/features/profile/data/help_articles.dart:129,146`, `lib/features/investment/presentation/screens/investments_screen.dart:177`.

Repository quarter/custom, UI bulan; help transfer usang; empty CTA investasi no-op. **Dependency:** alur inti stabil. **Acceptance:** free-range validation, help sesuai kemampuan, CTA bekerja; reference analysis sebelum cleanup tanpa menghapus mock/test yang sah.

### F20 — P1 — Evidence release/E2E dan expired session

**Lintas modul; M.** L: `tests/Feature/LiveHttpEndToEndTest.php:14`, `tests/Feature/GoalPostgresConcurrencyTest.php:33`, `config/services.php:38`. F: `lib/data/datasources/remote/api_config.dart:14`, `lib/data/providers/onboarding_providers.dart:23`, `lib/data/providers/app_providers.dart:127`.

Default API pada HEAD Flutter bde0e6a adalah emulator; perubahan working tree di akhir audit menggantinya ke productionBaseUrl. Build define APK terpasang tetap unknown. LiveHttp test memakai TestCase/RefreshDatabase lokal; concurrency test memanggil service berurutan. Budget/onboarding client tanpa callback401 dapat berakhir fallback. **Dependency:** staging UUID DB, authorized accounts/device, release manifest, SMTP/FCM/scheduler. **Acceptance:** Android create/reload/relogin,401 redirect,slow/offline retry,ownership,camera/mic/export,due scheduler/push. Laporkan unit/widget/API/device secara terpisah.

## O. Final Recommendations

1. **Lindungi ledger:** F01 account deletion, F02 investasi, F07 metadata goal, F06 relation/aggregates. Jangan membuka write investasi sebelum invariants backend lulus.
2. **Stabilkan UUID dan rilis:** F03 wishlist, F04 onboarding, F05 DTO/scheduler, F11 PR2. Pin SHA dan build defines; bank ID integer tetap diperlakukan sesuai schema.
3. **Lengkapi alur pengguna:** F08 withdrawal/history, F09 plan persistence, F10 routes/deep links, F12 correction, F13 transfer lifecycle.
4. **Lengkapi field/data:** F14 domain investasi, F15 attachment, F16 notifications, F17 provenance, F18 advanced fields.
5. **Tutup release acceptance:** F20 Android/staging/scheduler/FCM/401; F19 report range/help/cleanup setelah inti stabil.

### Trace lintas layer yang diuji melalui source

- **Transfer:** TransferScreen → AccountsController.transfer → RemoteAccountRepository POST → StoreTransferRequest ownership → TransferService locks → paired Transactions → TransactionObserver saldo → TransferResource → invalidate/refetch. Read/delete lifecycle belum dipakai mobile.
- **Deposit goal:** GoalDepositScreen → GoalsController.addDeposit → remote hardcode deposit → GoalService lock → GoalTransaction creating + ledger/observer → resource/refetch. PR1 satu pemilik current_amount; withdraw/UI history masih gap.
- **Wishlist purchase:** picker UUID→int0 (**putus**) → controller/repo → backend ownership→WishlistService lock/idempotency→Transaction/observer→wishlist transaction_id/status→refetch. Backend purchase test lulus tidak menutup picker mobile.
- **Onboarding akun:** add langsung POST→UUID response→state→lanjut saveInstruments→integer-only identity check gagal→POST lagi. Ini bukan masalah rendering glass atau Firebase.
- **Laporan:** Screen/month provider→RemoteReportRepository→period validation→FinancialReportService aggregate→DTO→chart. Catch beralih recent15; Excel binary dan PDF lokal berbeda jalur.
- **Notifikasi:** trigger→NotificationService/dedup→Notification+FCM job→device→allowlist/router. Legacy scheduled command hanya NotificationLog, melewati pipeline mobile baru.

### Audit Limitations

- Produksi hanya public GET banks; authenticated HTTP/database/Android E2E tidak dijalankan. Tidak membuat klaim screenshot, performa, atau delivery native.
- “Complete inventory” berarti seluruh surface source yang ditemukan pada baseline terinventarisasi, bukan semua branch/edge case diuji. Indeks struktural dibedakan dari penelusuran semantik/action dan runtime tests.
- Hanya dua file tes Laravel dan empat file tes Flutter dijalankan. SQLite tidak menutup perbedaan PostgreSQL locking/type/cast. Nama tes live/concurrency bukan bukti external network/parallel execution.
- APK/deploy SHA/migration status/master seed/cron/queue/timezone host/SMTP/Google/FCM/storage/native export belum diverifikasi.
- Risiko numerik/race F01/F02/F04/F05/F07 diturunkan dari source, bukan bukti insiden data existing. Production mutation tidak dicoba.
- Local-only preferences, OCR/voice/simulasi murni/PDF lokal dan compatibility aliases bukan gap tanpa alasan bisnis.
- Denominator ada pada D/E agar hitungan bisa diaudit ulang; angka bukan persentase aplikasi selesai.
- Proses audit ini hanya menambahkan dokumen. Proses eksternal mengubah branch backend dan working tree Flutter selama audit; perubahan itu tidak disentuh/dibatalkan. Baseline awal, delta penutup dan hasil tes dipisahkan pada B.

### Lampiran evidence terstruktur

#### Backend service/model/observer/job/command/provider index

Metode:baris adalah lokasi deklarasi source, bukan bukti tiap metode dieksekusi atau lulus tes.


**app/Services**

| File | Method:baris |
| --- | --- |
| app/Services/AuthService.php | setGoogleClient:18, getGoogleClient:23, register:33, login:50, loginWithGoogle:69, logout:162, verifyGoogleReauthentication:180 |
| app/Services/BankCatalogService.php | normalizeCategory:14, getActiveBanks:31, findByIdOrSlug:60, getBanksFromFile:103, toggleActive:180 |
| app/Services/DashboardService.php | getSummary:14, getMonthlyCashflowChart:100 |
| app/Services/FcmService.php | sendForNotification:24, resolveSafeRoute:158, isCategoryEnabledForUser:178, resolveCredentialsPath:196, fetchAccessToken:217, extractFcmErrorCode:240, isPermanentTokenError:256 |
| app/Services/FinancialInstrumenService.php | getUserInstruments:11, resolveAndValidateTypeId:19, createInstrument:76, getInstrumentById:119, updateInstrument:126, deleteInstrument:176, getTotalMonthlyAdminFee:186 |
| app/Services/FinancialReportService.php | resolveDateRange:14, generateReport:36 |
| app/Services/FinancialScheduleService.php | clampSalaryDay:18, calculateEffectiveDate:29, analyzeTransition:48, savePendingFinancialSettings:156, cancelPendingFinancialSettings:222, getFinancialSettings:239, promotePendingIfDue:331, getActiveBudget:585, hasPendingColumns:597, hasTransitionColumn:607 |
| app/Services/GoalService.php | getUserGoals:17, reorderGoals:37, createGoal:50, getGoalById:76, updateGoal:82, deleteGoal:109, getGoalTransactions:136, getGoalTransactionById:146, addGoalTransaction:156, updateGoalTransaction:199, deleteGoalTransaction:231 |
| app/Services/InstrumentTypeService.php | getAllInstrumentTypes:10, getInstrumentTypeById:45 |
| app/Services/InvestmentService.php | getUserInvestments:15, createInvestment:22, getInvestmentById:31, updateInvestment:37, deleteInvestment:45, getInvestmentTransactions:56, getInvestmentTransactionById:66, addInvestmentTransaction:76, updateInvestmentTransaction:131, deleteInvestmentTransaction:184 |
| app/Services/NotificationService.php | getUserNotifications:16, getUnreadCount:37, markAsRead:49, markAllAsRead:63, createNotification:77 |
| app/Services/NotificationSettingService.php | getUserSettings:9, updateUserSettings:24 |
| app/Services/NotificationTriggerService.php | __construct:17, getUserTimezone:24, triggerSalaryReminders:36, triggerWishlistCoolingOff:88, triggerGoalMilestones:141, triggerScheduledSavingReminders:215, triggerBudgetWarningsAndOverspending:310, triggerAll:549, getCategoryLabel:572 |
| app/Services/PasswordResetOtpService.php | requestOtp:22, issueOtp:35, verifyOtp:148, resetPassword:219, digest:260 |
| app/Services/ProductMetadataService.php | getMaxBytes:25, extractMetadata:57, detectMarketplace:205, validateUrlForSsrf:243, isPublicIp:288, safeFetchHtml:301, resolveRedirectUrl:412, extractJsonLd:446, extractOpenGraph:605, extractHtmlTitle:709, extractCanonicalUrl:722, cleanTitle:735, normalizePrice:764, isValidImageUrl:812 |
| app/Services/RecurringTransactionService.php | getUserRecurringTransactions:12, createRecurringTransaction:21, getRecurringTransactionById:43, updateRecurringTransaction:51, deleteRecurringTransaction:70 |
| app/Services/SavingReminderService.php | getUserReminder:14, upsertUserReminder:24, deactivateUserReminder:75 |
| app/Services/TransactionService.php | getUserTransactions:13, createTransaction:33, isSameTransactionPayload:101, getTransactionById:151, updateTransaction:158, deleteTransaction:188 |
| app/Services/TransferService.php | getUserTransfers:15, createTransfer:25, reconcileLegacyCash:190, getTransferById:348, deleteTransfer:357 |
| app/Services/WishlistService.php | getUserWishlists:23, getWishlistById:41, createWishlist:50, updateWishlist:74, updateStatus:108, startWait:125, deleteWishlist:146, getPurchaseAnalysis:155, recordPurchase:175, calculateFinancialMetrics:297 |


**app/Models**

| File | Method:baris |
| --- | --- |
| app/Models/BankCatalog.php | instruments:33, scopeActive:41, scopeSearch:49, getLogoUrlAttribute:67, getRawSvgAttribute:77, getDropdownHtmlAttribute:99 |
| app/Models/BudgetAllocation.php | monthlyBudget:26 |
| app/Models/FcmToken.php | casts:21, user:29, scopeActive:34 |
| app/Models/FinancialInstrumen.php | getNextAdminFeeDate:51, booted:84, isLegacyCash:161, scopeSpendable:186, user:202, instrumentType:207, bank:212, transactions:217, transfersFrom:222, transfersTo:227, recurringTransactions:232 |
| app/Models/FundInvestment.php | investment:17 |
| app/Models/Goal.php | booted:43, reconcile:63, user:91, transactions:96, savingReminders:101 |
| app/Models/GoalTransaction.php | booted:35, goal:210, transaction:215 |
| app/Models/InstrumentType.php | instrument:18 |
| app/Models/Investment.php | booted:40, getCurrentPortfolioValueAttribute:68, getReturnPercentageAttribute:73, reconcile:86, user:116, transactions:121 |
| app/Models/InvestmentTransaction.php | booted:36, investment:206, transaction:211 |
| app/Models/MonthlyBudget.php | user:36, allocations:41, calculatePeriod:50, calculateDailySpending:86 |
| app/Models/Notification.php | user:38, getIsReadAttribute:46, markAsRead:54, markAsUnread:65, scopeUnread:76, scopeRead:84, scopeReminder:92 |
| app/Models/NotificationLog.php | getFilamentUrl:28 |
| app/Models/NotificationSetting.php | user:34 |
| app/Models/PasswordResetOtp.php | casts:26 |
| app/Models/RecurringTransaction.php | user:39, financialInstrumen:44 |
| app/Models/SavingReminder.php | user:41, goal:49, getTimeLabelAttribute:57, effectiveDayFor:65 |
| app/Models/Transaction.php | financialInstrumen:22, instrument:27, transfer:32, attachments:37, booted:42, scopeRealCashflow:54 |
| app/Models/TransactionAttachment.php | transaction:19 |
| app/Models/Transfer.php | fromInstrument:28, toInstrument:33, transactions:38 |
| app/Models/User.php | createRegularUser:64, isVerifiedAdministrator:73, casts:86, sendPasswordResetNotification:101, getIsOnboardedAttribute:106, canAccessPanel:126, recurringTransactions:139, investments:144, goals:149, wishlists:154, instrument:159, notificationSetting:164, notifications:169, savingReminder:174, monthlyBudgets:179, activeMonthlyBudget:184, fcmTokens:189 |
| app/Models/Wishlist.php | booted:48, user:89, isWaiting:94, remainingWaitSeconds:100, transaction:109 |


**app/Observers**

| File | Method:baris |
| --- | --- |
| app/Observers/TransactionObserver.php | created:16, updating:82, updated:124, deleting:156, deleted:190, restored:208, forceDeleted:226 |
| app/Observers/UserObserver.php | created:9 |


**app/Jobs**

| File | Method:baris |
| --- | --- |
| app/Jobs/EvaluateBudgetTriggersJob.php | __construct:20, handle:25 |
| app/Jobs/EvaluateGoalMilestonesJob.php | __construct:19, handle:23 |
| app/Jobs/ProcessScheduledNotificationsJob.php | __construct:20, handle:25 |
| app/Jobs/SendFcmNotificationJob.php | __construct:25, handle:29 |


**app/Console/Commands**

| File | Method:baris |
| --- | --- |
| app/Console/Commands/ProcessNotificationTriggersCommand.php | handle:31 |
| app/Console/Commands/ProcessRecurringTransactions.php | handle:22 |
| app/Console/Commands/ProcessScheduledNotifications.php | handle:19 |


**app/Providers**

| File | Method:baris |
| --- | --- |
| app/Providers/AppServiceProvider.php | register:20, boot:28 |
| app/Providers/Filament/AdminPanelProvider.php | panel:23 |
| app/Providers/Filament/AppPanelProvider.php | panel:32 |


#### Request/resource contract fields

Field:baris dari file aktual; rules lengkap berada pada file. Controller Request inline (auth/report/FCM/purchase/reorder) dijelaskan C dan handler E. Untuk array rules, lihat Rule::exists/where dan validasi lanjutan pada source; daftar field ini tidak meratakan aturan ownership.


**app/Http/Requests**

| File | Field:baris |
| --- | --- |
| app/Http/Requests/Api/Auth/GoogleLoginRequest.php | id_token:25 |
| app/Http/Requests/Api/Budget/StoreBudgetRequest.php | monthly_income:18, allocations:19, allocations.*.category:20, allocations.*.percentage:21 |
| app/Http/Requests/Api/FinancialInstrumen/StoreFinancialInstrumenRequest.php | type_id:20, name:21, bank_id:22, bank_slug:23, balance:24, monthly_admin_fee:25, admin_fee_day:26, admin_fee_enabled:27, max_budget:28, budget_frequency:29, is_active:30 |
| app/Http/Requests/Api/FinancialInstrumen/UpdateFinancialInstrumenRequest.php | type_id:20, name:21, bank_id:22, bank_slug:23, balance:24, monthly_admin_fee:25, admin_fee_day:26, admin_fee_enabled:27, max_budget:28, budget_frequency:29, is_active:30 |
| app/Http/Requests/Api/FinancialSettings/PreviewFinancialSettingsRequest.php | monthly_income:17, salary_day:18 |
| app/Http/Requests/Api/FinancialSettings/UpdateFinancialSettingsRequest.php | monthly_income:18, salary_day:19, transition_budget:20, transition_confirmed:21, allocations:22, allocations.*.category:23, allocations.*.percentage:28 |
| app/Http/Requests/Api/Goal/StoreGoalRequest.php | title:17, type:18, link:19, priority:20, note:21, target_amount:22, current_amount:23, target_date:24, reminder_date:25, frequency:26, is_active:27, image:28 |
| app/Http/Requests/Api/Goal/StoreGoalTransactionRequest.php | type:18, amount:19, notes:20, instrument_id:21 |
| app/Http/Requests/Api/Goal/UpdateGoalRequest.php | title:17, type:18, link:19, priority:20, note:21, target_amount:22, current_amount:23, target_date:24, reminder_date:25, frequency:26, is_active:27, image:28 |
| app/Http/Requests/Api/Goal/UpdateGoalTransactionRequest.php | type:18, amount:19, notes:20, instrument_id:21 |
| app/Http/Requests/Api/Investment/StoreInvestmentRequest.php | title:17, type:18, target:19, increase:20, achieved:21, allocated_amount:22, budget_frequency:23, reminder_date:24, is_active:25 |
| app/Http/Requests/Api/Investment/StoreInvestmentTransactionRequest.php | type:18, amount:19, notes:20, instrument_id:21 |
| app/Http/Requests/Api/Investment/UpdateInvestmentRequest.php | title:17, type:18, target:19, increase:20, achieved:21, allocated_amount:22, budget_frequency:23, reminder_date:24, is_active:25 |
| app/Http/Requests/Api/Investment/UpdateInvestmentTransactionRequest.php | type:18, amount:19, notes:20, instrument_id:21 |
| app/Http/Requests/Api/RecurringTransaction/StoreRecurringExpenseRequest.php | title:18, category:19, amount:20, frequency:21, next_due_date:22, instrument_id:23, is_active:29, make_automatic:30 |
| app/Http/Requests/Api/RecurringTransaction/StoreRecurringIncomeRequest.php | title:18, category:19, amount:20, frequency:21, next_due_date:22, instrument_id:23, is_active:29, make_automatic:30 |
| app/Http/Requests/Api/RecurringTransaction/UpdateRecurringExpenseRequest.php | title:18, category:19, amount:20, frequency:21, next_due_date:22, instrument_id:23, is_active:29, make_automatic:30 |
| app/Http/Requests/Api/RecurringTransaction/UpdateRecurringIncomeRequest.php | title:18, category:19, amount:20, frequency:21, next_due_date:22, instrument_id:23, is_active:30, make_automatic:31 |
| app/Http/Requests/Api/SavingReminder/StoreSavingReminderRequest.php | goal_id:20, amount:27, frequency:28, weekday:29, day_of_month:35, hour:41, minute:42, enabled:43 |
| app/Http/Requests/Api/Transaction/StoreTransactionRequest.php | title:20, type:21, category:22, amount:23, instrument_id:24, date:30, created_at:31, information:32, idempotency_key:33, attachments.*:34 |
| app/Http/Requests/Api/Transaction/UpdateTransactionRequest.php | title:19, type:20, category:21, amount:22, instrument_id:23, date:30, created_at:31, information:32, attachments.*:33 |
| app/Http/Requests/Api/Transfer/StoreTransferRequest.php | amount:18, from_id:19, to_id:25, notes:32, idempotency_key:33 |
| app/Http/Requests/Api/UpdateNotificationSettingRequest.php | salary_reminder:17, saving_reminder:18, bill_reminder:19, budget_reminder:20, wishlist_reminder:21, overspending_reminder:22 |
| app/Http/Requests/Api/Wishlist/StoreWishlistRequest.php | item_name:17, title:18, price:19, estimated_price:20, status:21, category:22, product_url:23, link:24, image_ref:25, reason:26, note:27, priority:28, wait_hours:29, wait_started_at:30, wait_ends_at:31 |
| app/Http/Requests/Api/Wishlist/UpdateWishlistRequest.php | item_name:17, title:18, price:19, estimated_price:20, status:21, category:22, product_url:23, link:24, image_ref:25, reason:26, note:27, priority:28, wait_hours:29, wait_started_at:30, wait_ends_at:31 |


**app/Http/Resources**

| File | Field:baris |
| --- | --- |
| app/Http/Resources/BankCatalogResource.php | id:13, name:14, slug:15, legal_name:16, aliases:17, category:18, institution_type:19, code:20, logo_ref:21, logo_url:22, is_active:23, verification_status:24, verified_at:25, sources:26, created_at:27, updated_at:28 |
| app/Http/Resources/FinancialInstrumenResource.php | id:21, name:22, balance:23, balance_formatted:24, monthly_admin_fee:25, monthly_admin_fee_formatted:26, admin_fee_day:27, admin_fee_enabled:28, next_admin_fee_date:29, max_budget:30, max_budget_formatted:31, budget_frequency:32, is_active:33, is_legacy_cash:34, is_spendable:35, bank_id:36, bank_slug:37, type:38, id:40, name:41, type:42, logo_url:43, bank:46, id:48, name:49, slug:50, category:51, logo_url:52, id:59, name:60, slug:61, category:62, logo_url:63, id:67, name:68, slug:69, category:70, logo_url:71, created_at:76, updated_at:77 |
| app/Http/Resources/GoalResource.php | id:17, title:18, type:19, link:20, priority:21, note:22, target_amount:23, target_amount_formatted:24, current_amount:25, current_amount_formatted:26, progress_percentage:27, is_reached:28, remaining_amount:29, image_url:30, target_date:31, reminder_date:32, frequency:33, is_active:34, created_at:35, updated_at:36 |
| app/Http/Resources/GoalTransactionResource.php | id:15, goal_id:16, type:17, amount:18, amount_formatted:19, notes:20, instrument:21, transaction:24, created_at:25 |
| app/Http/Resources/InstrumentTypeResource.php | id:13, name:14, type:15, type_label:16, bank:17, ewallet:18, investment:19, cash:20, logo_url:23, created_at:24, updated_at:25 |
| app/Http/Resources/InvestmentResource.php | id:15, title:16, type:17, target_amount:18, target_amount_formatted:19, achieved:20, achieved_formatted:21, allocated_amount:22, allocated_amount_formatted:23, budget_frequency:24, reminder_date:25, is_active:26, created_at:27, updated_at:28 |
| app/Http/Resources/InvestmentTransactionResource.php | id:15, investment_id:16, type:17, amount:18, amount_formatted:19, notes:20, instrument:21, transaction:24, created_at:25 |
| app/Http/Resources/NotificationResource.php | id:18, user_id:19, title:20, message:21, category:22, is_reminder:23, target_route:24, is_read:25, read_at:26, reference_type:27, reference_id:28, created_at:29, updated_at:30 |
| app/Http/Resources/NotificationSettingResource.php | salary_reminder:13, saving_reminder:14, bill_reminder:15, budget_reminder:16, wishlist_reminder:17, overspending_reminder:18, updated_at:19 |
| app/Http/Resources/RecurringTransactionResource.php | id:13, title:14, type:15, category:16, amount:17, amount_formatted:18, frequency:19, next_due_date:20, is_active:21, make_automatic:22, instrument:23, created_at:24, updated_at:25 |
| app/Http/Resources/SavingReminderResource.php | id:18, user_id:19, goal_id:20, amount:21, frequency:22, weekday:23, day_of_month:24, hour:25, minute:26, time_label:27, enabled:28, last_triggered_at:29, goal:30, created_at:31, updated_at:32 |
| app/Http/Resources/TransactionResource.php | id:18, title:19, type:20, category:21, amount:22, amount_formatted:23, information:24, instrument:25, attachments:26, created_at:29, updated_at:30 |
| app/Http/Resources/TransferResource.php | id:15, amount:16, amount_formatted:17, notes:18, from_instrument:19, to_instrument:20, created_at:21, updated_at:22 |
| app/Http/Resources/WishlistResource.php | id:21, item_name:22, title:23, price:24, estimated_price:25, estimated_price_formatted:26, status:27, category:28, product_url:29, link:30, image_ref:31, raw_image_ref:32, reason:33, note:34, priority:35, wait_hours:36, wait_started_at:37, wait_ends_at:38, is_waiting:39, remaining_wait_seconds:40, analysis_snapshot:41, transaction_id:42, created_at:43, updated_at:44 |


#### Migration/seed dependencies

Tidak dijalankan pada database persisten. Schema source bukan status migration produksi. Historical migration yang berubah tidak membuktikan instance lama sudah sesuai.


| Migration | Tabel |
| --- | --- |
| database/migrations/0001_01_01_000000_create_users_table.php | users, password_reset_tokens, sessions |
| database/migrations/0001_01_01_000001_create_cache_table.php | cache, cache_locks |
| database/migrations/0001_01_01_000002_create_jobs_table.php | jobs, job_batches, failed_jobs |
| database/migrations/2026_10_14_000034_create_instrument_types_table.php | instrument_types |
| database/migrations/2026_10_14_055048_create_financial_instrumens_table.php | financial_instrumens |
| database/migrations/2026_10_14_062720_create_transactions_table.php | transactions |
| database/migrations/2026_10_14_063531_create_transaction_attachments_table.php | transaction_attachments |
| database/migrations/2026_10_14_063958_create_transfers_table.php | transfers |
| database/migrations/2026_10_14_070300_create_investments_table.php | investments |
| database/migrations/2026_10_14_071203_create_goals_table.php | goals |
| database/migrations/2026_10_15_152906_create_recurring_transactions_table.php | recurring_transactions |
| database/migrations/2026_10_16_063442_create_personal_access_tokens_table.php | personal_access_tokens |
| database/migrations/2026_10_24_163524_create_goal_transactions_table.php | goal_transactions |
| database/migrations/2026_10_25_070110_create_investment_transactions_table.php | investment_transactions |
| database/migrations/2026_10_26_042439_create_notification_settings_table.php | notification_settings |
| database/migrations/2026_10_27_065120_add_monthly_income_and_salary_day_to_users_table.php | users |
| database/migrations/2026_10_27_171117_create_notification_logs_table.php | notification_logs |
| database/migrations/2026_10_28_070000_add_is_onboarded_to_users_table.php | users |
| database/migrations/2026_10_28_080000_create_monthly_budgets_table.php | monthly_budgets, budget_allocations |
| database/migrations/2026_10_28_140416_add_is_read_to_notification_logs_table.php | notification_logs |
| database/migrations/2026_10_29_090000_add_link_priority_note_to_goals_table.php | goals |
| database/migrations/2026_10_29_100000_create_or_update_wishlists_table.php | wishlists |
| database/migrations/2026_10_29_110000_add_analysis_snapshot_to_wishlists_table.php | wishlists |
| database/migrations/2026_10_29_120000_create_bank_catalogs_table.php | bank_catalogs, financial_instrumens |
| database/migrations/2026_10_29_130000_add_notes_and_transfer_id_to_transfers_and_transactions_table.php | transfers, transactions |
| database/migrations/2026_10_30_030000_add_unique_index_to_transfers_idempotency_key.php | transfers |
| database/migrations/2026_10_30_040000_add_overspending_reminder_to_notification_settings_table.php | notification_settings |
| database/migrations/2026_10_30_050000_create_notifications_table.php | notifications |
| database/migrations/2026_10_30_060000_create_saving_reminders_table.php | saving_reminders |
| database/migrations/2026_10_30_070000_patch_missing_remote_columns_safely.php | financial_instrumens, investments, goal_transactions, investment_transactions |
| database/migrations/2026_11_04_210000_add_google_id_to_users_table.php | users |
| database/migrations/2026_11_08_130000_add_idempotency_key_to_transactions_table.php | transactions |
| database/migrations/2026_11_12_000001_create_fcm_tokens_table.php | fcm_tokens |
| database/migrations/2026_11_13_000001_change_users_role_default_to_pengguna.php | users |
| database/migrations/2026_11_13_000002_create_password_reset_otps_table.php | password_reset_otps |
| database/migrations/2026_11_16_210000_add_admin_fee_columns_to_financial_instrumens_table.php | financial_instrumens |
| database/migrations/2026_11_16_220000_add_pending_financial_columns_to_users_table.php | users |
| database/migrations/2026_11_16_230000_add_is_transition_to_monthly_budgets_table.php | monthly_budgets |
| database/migrations/2026_11_20_235144_add_description_to_recurring_transactions_table.php | recurring_transactions |
| database/migrations/2026_11_21_000001_add_bio_to_users_table.php | users |
| database/migrations/2026_11_21_235900_alter_personal_access_tokens_tokenable_id_to_varchar.php | personal_access_tokens |
| database/migrations/2026_11_22_010305_add_transaction_id_to_wishlists_table.php | wishlists |
| database/migrations/2026_11_22_041829_update_transaction_attachments_fk_cascade.php | transaction_attachments |


Seeders: `database/seeders/BankCatalogSeeder.php:1`, `database/seeders/DatabaseSeeder.php:1`, `database/seeders/InstrumentTypeSeeder.php:1`.


#### Filament dan config inventory

App panel adalah surface pengguna; admin master/internal dipisahkan pada J. Daftar ini adalah inventaris file/class, bukan klaim semua aksi web sudah diuji.


| File | Class:baris |
| --- | --- |
| app/Filament/App/Pages/Auth/Register.php | Register:9 |
| app/Filament/App/Pages/Dashboard.php | Dashboard:12 |
| app/Filament/App/Pages/EditProfile.php | EditProfile:14 |
| app/Filament/App/Pages/FinancialReportPage.php | FinancialReportPage:17 |
| app/Filament/App/Pages/Notifications.php | Notifications:12 |
| app/Filament/App/Pages/NotificationSettings.php | NotificationSettings:13 |
| app/Filament/App/Resources/AlokasiSaldoResource/Widgets/InstrumentAllocationChart.php | InstrumentAllocationChart:9 |
| app/Filament/App/Resources/FinancialInstrumenResource/Pages/CreateFinancialInstrumen.php | CreateFinancialInstrumen:12 |
| app/Filament/App/Resources/FinancialInstrumenResource/Pages/EditFinancialInstrumen.php | EditFinancialInstrumen:15 |
| app/Filament/App/Resources/FinancialInstrumenResource/Pages/ListFinancialInstrumens.php | ListFinancialInstrumens:15 |
| app/Filament/App/Resources/FinancialInstrumenResource.php | FinancialInstrumenResource:25 |
| app/Filament/App/Resources/GoalResource/Pages/CreateGoal.php | CreateGoal:13 |
| app/Filament/App/Resources/GoalResource/Pages/EditGoal.php | EditGoal:13 |
| app/Filament/App/Resources/GoalResource/Pages/ListGoals.php | ListGoals:16 |
| app/Filament/App/Resources/GoalResource/RelationManagers/GoalTransactionsRelationManager.php | GoalTransactionsRelationManager:14 |
| app/Filament/App/Resources/GoalResource.php | GoalResource:16 |
| app/Filament/App/Resources/IncomeExpenseChartResource/Widgets/IncomeExpenseChart.php | IncomeExpenseChart:10 |
| app/Filament/App/Resources/InvestmentResource/Pages/CreateInvestment.php | CreateInvestment:15 |
| app/Filament/App/Resources/InvestmentResource/Pages/EditInvestment.php | EditInvestment:13 |
| app/Filament/App/Resources/InvestmentResource/Pages/ListInvestments.php | ListInvestments:15 |
| app/Filament/App/Resources/InvestmentResource/RelationManagers/InvestmentTransactionsRelationManager.php | InvestmentTransactionsRelationManager:14 |
| app/Filament/App/Resources/InvestmentResource.php | InvestmentResource:17 |
| app/Filament/App/Resources/RecurringExpenseResource/Pages/CreateRecurringExpense.php | CreateRecurringExpense:14 |
| app/Filament/App/Resources/RecurringExpenseResource/Pages/EditRecurringExpense.php | EditRecurringExpense:14 |
| app/Filament/App/Resources/RecurringExpenseResource/Pages/ListRecurringExpenses.php | ListRecurringExpenses:14 |
| app/Filament/App/Resources/RecurringExpenseResource.php | RecurringExpenseResource:18 |
| app/Filament/App/Resources/RecurringTransactionResource/Pages/CreateRecurringTransaction.php | CreateRecurringTransaction:9 |
| app/Filament/App/Resources/RecurringTransactionResource/Pages/EditRecurringTransaction.php | EditRecurringTransaction:9 |
| app/Filament/App/Resources/RecurringTransactionResource/Pages/ListRecurringTransactions.php | ListRecurringTransactions:9 |
| app/Filament/App/Resources/SalaryResource/Pages/CreateSalary.php | CreateSalary:14 |
| app/Filament/App/Resources/SalaryResource/Pages/EditSalary.php | EditSalary:14 |
| app/Filament/App/Resources/SalaryResource/Pages/ListSalaries.php | ListSalaries:14 |
| app/Filament/App/Resources/SalaryResource.php | SalaryResource:18 |
| app/Filament/App/Resources/TransactionResource/Pages/CreateTransaction.php | CreateTransaction:14 |
| app/Filament/App/Resources/TransactionResource/Pages/EditTransaction.php | EditTransaction:14 |
| app/Filament/App/Resources/TransactionResource/Pages/ListTransactions.php | ListTransactions:16 |
| app/Filament/App/Resources/TransactionResource.php | TransactionResource:20 |
| app/Filament/App/Resources/TransaksiCepatResource/Widgets/StatsOverviewWidget.php | StatsOverviewWidget:11 |
| app/Filament/App/Resources/WishlistResource/Pages/CreateWishlist.php | CreateWishlist:12 |
| app/Filament/App/Resources/WishlistResource/Pages/EditWishlist.php | EditWishlist:12 |
| app/Filament/App/Resources/WishlistResource/Pages/ListWishlists.php | ListWishlists:16 |
| app/Filament/App/Resources/WishlistResource.php | WishlistResource:15 |
| app/Filament/App/Widgets/OverviewStatsWidget.php | OverviewStatsWidget:13 |
| app/Filament/Resources/BankCatalogResource/Pages/CreateBankCatalog.php | CreateBankCatalog:8 |
| app/Filament/Resources/BankCatalogResource/Pages/EditBankCatalog.php | EditBankCatalog:9 |
| app/Filament/Resources/BankCatalogResource/Pages/ListBankCatalogs.php | ListBankCatalogs:11 |
| app/Filament/Resources/BankCatalogResource.php | BankCatalogResource:16 |
| app/Filament/Resources/InstrumentTypeResource/Pages/CreateInstrumentType.php | CreateInstrumentType:9 |
| app/Filament/Resources/InstrumentTypeResource/Pages/EditInstrumentType.php | EditInstrumentType:9 |
| app/Filament/Resources/InstrumentTypeResource/Pages/ListInstrumentTypes.php | ListInstrumentTypes:9 |
| app/Filament/Resources/InstrumentTypeResource.php | InstrumentTypeResource:16 |


Config: `config/admin.php:1`, `config/app.php:1`, `config/auth.php:1`, `config/cache.php:1`, `config/database.php:1`, `config/filesystems.php:1`, `config/l5-swagger.php:1`, `config/logging.php:1`, `config/mail.php:1`, `config/onboarding.php:1`, `config/password_reset.php:1`, `config/queue.php:1`, `config/sanctum.php:1`, `config/services.php:1`, `config/session.php:1`. Nilai secret tidak dibaca.


#### Flutter feature-file inventory dan entry evidence

Indeks meliputi seluruh file features (screens/providers/domain/services/widgets/utils). Lokasi class pertama membantu penelusuran; class/widget internal bukan fitur baru. Untuk screen, import router eksplisit hanya indikator entry langsung; absence saja bukan bukti unreachable, sebab screen dapat dipasang melalui Navigator atau widget lain. Negative claims telah diperiksa caller-nya pada K/N.


| File | Class:baris | Screen di-import router |
| --- | --- | --- |
| lib/features/accounts/presentation/providers/accounts_controller.dart | AccountsController:14 | — |
| lib/features/accounts/presentation/screens/account_detail_screen.dart | AccountDetailScreen:26 | ya |
| lib/features/accounts/presentation/screens/accounts_screen.dart | AccountsScreen:21 | ya |
| lib/features/accounts/presentation/screens/add_account_screen.dart | AddAccountScreen:23 | ya |
| lib/features/accounts/presentation/screens/edit_account_screen.dart | EditAccountScreen:31 | ya |
| lib/features/accounts/presentation/screens/transfer_screen.dart | TransferScreen:29 | ya |
| lib/features/accounts/presentation/utils/account_ui.dart | top-level functions/providers | — |
| lib/features/accounts/presentation/widgets/admin_fee_form_section.dart | AdminFeeFormSection:10 | — |
| lib/features/accounts/presentation/widgets/bank_logo_badge.dart | BankLogoBadge:21 | — |
| lib/features/accounts/presentation/widgets/bank_picker_sheet.dart | BankPickerSheet:13 | — |
| lib/features/auth/presentation/models/password_reset_flow.dart | PasswordResetOtpArgs:1 | — |
| lib/features/auth/presentation/providers/auth_controller.dart | AuthState:42 | — |
| lib/features/auth/presentation/screens/forgot_password_screen.dart | ForgotPasswordScreen:14 | ya |
| lib/features/auth/presentation/screens/login_screen.dart | LoginScreen:19 | ya |
| lib/features/auth/presentation/screens/register_screen.dart | RegisterScreen:16 | ya |
| lib/features/auth/presentation/screens/reset_password_screen.dart | ResetPasswordScreen:16 | ya |
| lib/features/auth/presentation/screens/verify_reset_otp_screen.dart | VerifyResetOtpScreen:17 | ya |
| lib/features/auth/presentation/widgets/auth_scaffold.dart | AuthScaffold:7 | — |
| lib/features/common/presentation/screens/feature_placeholder_screen.dart | FeaturePlaceholderScreen:5 | tidak |
| lib/features/dashboard/presentation/screens/dashboard_screen.dart | DashboardScreen:26 | ya |
| lib/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart | top-level functions/providers | — |
| lib/features/goals/presentation/providers/goals_controller.dart | GoalDraft:61 | — |
| lib/features/goals/presentation/screens/goal_achieved_screen.dart | GoalAchievedScreen:22 | ya |
| lib/features/goals/presentation/screens/goal_create_screen.dart | GoalCreateScreen:22 | ya |
| lib/features/goals/presentation/screens/goal_deposit_screen.dart | GoalDepositScreen:28 | ya |
| lib/features/goals/presentation/screens/goal_detail_screen.dart | GoalDetailScreen:24 | ya |
| lib/features/goals/presentation/screens/goal_edit_screen.dart | GoalEditScreen:24 | ya |
| lib/features/goals/presentation/screens/goal_history_screen.dart | GoalHistoryScreen:20 | ya |
| lib/features/goals/presentation/screens/goal_priority_screen.dart | GoalPriorityScreen:21 | ya |
| lib/features/goals/presentation/screens/goal_setup_screen.dart | GoalSetupScreen:26 | ya |
| lib/features/goals/presentation/screens/goal_simulate_screen.dart | GoalSimulateScreen:24 | ya |
| lib/features/goals/presentation/screens/goals_list_screen.dart | GoalsListScreen:21 | ya |
| lib/features/goals/presentation/utils/goal_category_ui.dart | top-level functions/providers | — |
| lib/features/goals/presentation/widgets/goal_widgets.dart | GoalLinearProgress:34 | — |
| lib/features/investment/presentation/providers/investment_controller.dart | InvestmentController:9 | — |
| lib/features/investment/presentation/screens/add_investment_screen.dart | AddInvestmentScreen:13 | tidak |
| lib/features/investment/presentation/screens/investments_screen.dart | InvestmentsScreen:17 | tidak |
| lib/features/notifications/presentation/providers/notifications_providers.dart | NotificationFilterController:14 | — |
| lib/features/notifications/presentation/screens/notification_settings_screen.dart | NotificationSettingsScreen:20 | ya |
| lib/features/notifications/presentation/screens/notifications_screen.dart | NotificationsScreen:25 | ya |
| lib/features/notifications/presentation/screens/saving_reminder_screen.dart | SavingReminderScreen:21 | ya |
| lib/features/notifications/presentation/utils/notification_ui.dart | NotifCategoryIcon:70 | — |
| lib/features/onboarding/presentation/providers/budget_controller.dart | BudgetState:9 | — |
| lib/features/onboarding/presentation/providers/expenses_controller.dart | ExpensesState:8 | — |
| lib/features/onboarding/presentation/providers/goal_controller.dart | GoalState:10 | — |
| lib/features/onboarding/presentation/providers/instruments_controller.dart | InstrumentsState:8 | — |
| lib/features/onboarding/presentation/providers/onboarding_status_provider.dart | OnboardingStatus:16 | — |
| lib/features/onboarding/presentation/providers/salary_controller.dart | SalaryState:9 | — |
| lib/features/onboarding/presentation/screens/budget_screen.dart | BudgetScreen:16 | ya |
| lib/features/onboarding/presentation/screens/expenses_screen.dart | ExpensesScreen:95 | ya |
| lib/features/onboarding/presentation/screens/goals_screen.dart | GoalsScreen:25 | ya |
| lib/features/onboarding/presentation/screens/instruments_screen.dart | InstrumentsScreen:79 | ya |
| lib/features/onboarding/presentation/screens/plan_screen.dart | PlanScreen:24 | ya |
| lib/features/onboarding/presentation/screens/salary_screen.dart | SalaryScreen:20 | ya |
| lib/features/onboarding/presentation/widgets/onboarding_invitation_popup.dart | OnboardingInvitationPopup:23 | — |
| lib/features/profile/data/help_articles.dart | HelpCategory:7 | — |
| lib/features/profile/presentation/providers/financial_settings_controller.dart | FinancialSettingsController:7 | — |
| lib/features/profile/presentation/providers/profile_providers.dart | ProfileStats:28 | — |
| lib/features/profile/presentation/screens/about_screen.dart | AboutScreen:13 | ya |
| lib/features/profile/presentation/screens/app_settings_screen.dart | AppSettingsScreen:15 | ya |
| lib/features/profile/presentation/screens/edit_profile_screen.dart | EditProfileScreen:21 | ya |
| lib/features/profile/presentation/screens/financial_settings_screen.dart | _TransitionConfirmationResult:15 | ya |
| lib/features/profile/presentation/screens/help_screen.dart | HelpScreen:14 | ya |
| lib/features/profile/presentation/screens/privacy_screen.dart | PrivacyScreen:13 | ya |
| lib/features/profile/presentation/screens/profile_screen.dart | ProfileScreen:20 | ya |
| lib/features/profile/presentation/screens/security_screen.dart | SecurityScreen:17 | ya |
| lib/features/profile/presentation/utils/account_security_dialogs.dart | _ChangePasswordSheet:27 | — |
| lib/features/profile/presentation/utils/profile_ui.dart | ProfileIconContainer:30 | — |
| lib/features/recurring/presentation/providers/recurring_controller.dart | RecurringController:10 | — |
| lib/features/recurring/presentation/screens/add_recurring_expense_screen.dart | AddRecurringExpenseScreen:15 | tidak |
| lib/features/recurring/presentation/screens/add_recurring_income_screen.dart | AddRecurringIncomeScreen:15 | tidak |
| lib/features/recurring/presentation/screens/recurring_expenses_screen.dart | RecurringExpensesScreen:17 | tidak |
| lib/features/recurring/presentation/screens/recurring_incomes_screen.dart | RecurringIncomesScreen:17 | tidak |
| lib/features/reports/export/report_export.dart | ReportExportResult:6 | — |
| lib/features/reports/export/report_export_data.dart | ReportCategoryExport:10 | — |
| lib/features/reports/export/report_pdf_document.dart | top-level functions/providers | — |
| lib/features/reports/presentation/screens/report_expenses_screen.dart | ReportExpensesScreen:22 | ya |
| lib/features/reports/presentation/screens/report_export_screen.dart | ReportExportScreen:44 | ya |
| lib/features/reports/presentation/screens/report_health_screen.dart | ReportHealthScreen:21 | ya |
| lib/features/reports/presentation/screens/report_savings_screen.dart | ReportSavingsScreen:19 | ya |
| lib/features/reports/presentation/screens/reports_screen.dart | ReportsScreen:19 | ya |
| lib/features/reports/presentation/widgets/report_charts.dart | IncomeExpenseBars:21 | — |
| lib/features/reports/presentation/widgets/report_widgets.dart | PeriodSelector:8 | — |
| lib/features/splash/presentation/screens/splash_screen.dart | SplashScreen:28 | ya |
| lib/features/tahandulu/data/services/product_ocr_service.dart | ProductOcrResult:8 | — |
| lib/features/tahandulu/presentation/providers/tahandulu_controller.dart | ConsiderationDraft:23 | — |
| lib/features/tahandulu/presentation/screens/tahandulu_add_screen.dart | TahanDuluAddScreen:23 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_analysis_screen.dart | TahanDuluAnalysisScreen:24 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_decide_screen.dart | TahanDuluDecideScreen:25 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_form_screen.dart | TahanDuluFormScreen:23 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_link_screen.dart | TahanDuluLinkScreen:21 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_list_screen.dart | TahanDuluListScreen:28 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_simulate_screen.dart | TahanDuluSimulateScreen:24 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_success_screen.dart | TahanDuluSuccessScreen:24 | ya |
| lib/features/tahandulu/presentation/screens/tahandulu_wait_screen.dart | TahanDuluWaitScreen:25 | ya |
| lib/features/tahandulu/presentation/utils/tahandulu_ui.dart | top-level functions/providers | — |
| lib/features/tahandulu/presentation/widgets/tahandulu_widgets.dart | TahanDuluScaffold:36 | — |
| lib/features/transactions/data/services/receipt_ocr_service.dart | ReceiptOcrService:10 | — |
| lib/features/transactions/data/services/speech_recognition_service.dart | SpeechRecognitionService:9 | — |
| lib/features/transactions/domain/receipt_parser.dart | ReceiptItem:2 | — |
| lib/features/transactions/domain/voice_transaction_parser.dart | ParsedVoiceTransaction:5 | — |
| lib/features/transactions/presentation/providers/native_input_providers.dart | top-level functions/providers | — |
| lib/features/transactions/presentation/providers/transactions_controller.dart | TransactionDraft:20 | — |
| lib/features/transactions/presentation/screens/transaction_form_screen.dart | TransactionFormScreen:63 | ya |
| lib/features/transactions/presentation/screens/transaction_record_method_screen.dart | TransactionRecordMethodScreen:20 | ya |
| lib/features/transactions/presentation/screens/transaction_review_screen.dart | TransactionReviewScreen:23 | ya |
| lib/features/transactions/presentation/screens/transaction_scan_screen.dart | TransactionScanScreen:31 | ya |
| lib/features/transactions/presentation/screens/transaction_success_screen.dart | TransactionSuccessScreen:21 | ya |
| lib/features/transactions/presentation/screens/transaction_voice_screen.dart | TransactionVoiceScreen:48 | ya |
| lib/features/transactions/presentation/screens/transactions_screen.dart | TransactionsScreen:25 | ya |
| lib/features/transactions/presentation/utils/transaction_categories.dart | top-level functions/providers | — |


#### Flutter transport/model/routing index


| File | Class:baris |
| --- | --- |
| lib/data/datasources/remote/api_client.dart | ApiException:7, ApiClient:28 |
| lib/data/datasources/remote/api_config.dart | ApiConfig:14 |
| lib/data/datasources/remote/remote_account_repository.dart | RemoteAccountRepository:14 |
| lib/data/datasources/remote/remote_auth_repository.dart | RemoteAuthRepository:14 |
| lib/data/datasources/remote/remote_bank_repository.dart | RemoteBankRepository:7 |
| lib/data/datasources/remote/remote_budget_repository.dart | RemoteBudgetRepository:5 |
| lib/data/datasources/remote/remote_dashboard_repository.dart | RemoteDashboardRepository:22 |
| lib/data/datasources/remote/remote_financial_settings_repository.dart | RemoteFinancialSettingsRepository:5 |
| lib/data/datasources/remote/remote_goal_repository.dart | RemoteGoalRepository:11 |
| lib/data/datasources/remote/remote_instrument_type_repository.dart | RemoteInstrumentTypeRepository:11 |
| lib/data/datasources/remote/remote_investment_repository.dart | RemoteInvestmentRepository:10 |
| lib/data/datasources/remote/remote_notification_repository.dart | RemoteNotificationRepository:9 |
| lib/data/datasources/remote/remote_onboarding_repository.dart | RemoteOnboardingRepository:19 |
| lib/data/datasources/remote/remote_purchase_decision_repository.dart | RemotePurchaseDecisionRepository:8 |
| lib/data/datasources/remote/remote_recurring_repository.dart | RemoteRecurringRepository:8 |
| lib/data/datasources/remote/remote_report_repository.dart | RemoteReportRepository:11 |
| lib/data/datasources/remote/remote_transaction_repository.dart | RemoteTransactionRepository:9 |
| lib/data/datasources/remote/token_storage.dart | TokenStore:4, TokenStorage:11, MemoryTokenStore:31 |
| lib/data/models/api_bank.dart | ApiBank:4, ApiBanksResponse:84, ApiBankResponse:110 |
| lib/data/models/api_financial_goal.dart | ApiFinancialGoal:4, ApiFinancialGoalsResponse:185, ApiFinancialGoalResponse:212 |
| lib/data/models/api_financial_instrument.dart | ApiFinancialInstrument:5, ApiInstrumentType:140, ApiFinancialInstrumentsResponse:176 |
| lib/data/models/api_financial_report.dart | ApiFinancialReport:6, FinancialReportSummary:144, FinancialReportScores:211, FinancialReportComposition:258, FinancialReportTopCategory:303, FinancialReportMonthlyPoint:338, FinancialReportSavedWishlist:385 |
| lib/data/models/api_goal_transaction.dart | ApiGoalTransaction:7, ApiGoalTransactionsResponse:112, ApiGoalTransactionResponse:139 |
| lib/data/models/api_investment.dart | ApiInvestment:4, ApiInvestmentsResponse:132, ApiInvestmentResponse:159 |
| lib/data/models/api_investment_transaction.dart | ApiInvestmentTransaction:7, ApiInvestmentTransactionsResponse:114, ApiInvestmentTransactionResponse:141 |
| lib/data/models/api_monthly_budget.dart | ApiBudgetAllocation:2, ApiMonthlyBudget:58 |
| lib/data/models/api_recurring_transaction.dart | ApiRecurringTransaction:6, ApiRecurringTransactionsResponse:137, ApiRecurringTransactionResponse:164 |
| lib/data/models/api_transaction.dart | ApiTransaction:6, ApiTransactionsResponse:140, ApiTransactionResponse:172, ApiPagination:196 |
| lib/data/models/api_user_model.dart | ApiUserModel:7, ApiAuthResponse:98 |
| lib/data/models/api_wishlist.dart | ApiWishlist:5, ApiWishlistResponse:222, ApiWishlistsResponse:246 |
| lib/data/models/app_notification.dart | AppNotification:17 |
| lib/data/models/app_preferences.dart | AppPreferences:11 |
| lib/data/models/dashboard_data.dart | DashboardData:7 |
| lib/data/models/financial_account.dart | FinancialAccount:10 |
| lib/data/models/financial_goal.dart | FinancialGoal:29 |
| lib/data/models/financial_health.dart | HealthIndicator:9, HealthScore:25 |
| lib/data/models/financial_instrument.dart | FinancialInstrument:8 |
| lib/data/models/financial_plan.dart | FinancialPlan:11 |
| lib/data/models/financial_settings.dart | FinancialTransitionInfo:4, ActivePeriodInfo:108, PendingFinancialChange:184, FinancialSettings:255 |
| lib/data/models/financial_summary.dart | FinancialSummary:4 |
| lib/data/models/goal_deposit.dart | GoalDeposit:10 |
| lib/data/models/monthly_report.dart | CategoryTotal:4, MonthPoint:22, MonthlyReport:50 |
| lib/data/models/onboarding_data.dart | OnboardingData:8 |
| lib/data/models/purchase_consideration.dart | PurchaseConsideration:26 |
| lib/data/models/recurring_expense.dart | RecurringExpense:7 |
| lib/data/models/reminder_settings.dart | ReminderPreference:7, SavingReminderConfig:33 |
| lib/data/models/transaction_model.dart | AppTransaction:25 |
| lib/data/models/user_model.dart | UserModel:4 |
| lib/core/routing/app_router.dart | AuthRouteNotifier:72 |
| lib/core/routing/app_routes.dart | AppRoutes:4 |
| lib/core/routing/notification_deep_link.dart | NotificationDeepLink:7 |


#### Test inventory, dipisahkan dari execution evidence



**TahanDulu_Laravel**

| File | Level bukti audit |
| --- | --- |
| tests/Feature/AccountingIntegrityAndUuidAuthorizationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/AccountTransferApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/AccountTransferHardeningTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/AccountTransferIntegratedScenarioTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/BankCatalogApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/BatasBelanjaHarianFase1Test.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/BioMigrationSafetyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/BudgetApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/ComprehensiveApiContractFase8mTest.php | DIJALANKAN pada audit |
| tests/Feature/CrossModuleFinancialIntegrityEndToEndTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/ExampleTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/FcmIntegrationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/FinancialReportApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/FinancialScheduleChangeTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/FlutterLaravelContractTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/GoalFinancialConsistencyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/GoalFinancialIntegrityTest.php | DIJALANKAN pada audit |
| tests/Feature/GoalPostgresConcurrencyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/GoogleAuthApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/InstrumentCatalogRefactorTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/InstrumentTypeApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/LegacyCashReconciliationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/LiveHttpEndToEndTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/MultiAccountAdminFeeTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/NotificationApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/NotificationDatabaseModelTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/NotificationTriggersTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/OnboardingCompletionTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/OnboardingDataSyncFase2Test.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/OnboardingOptionalFase3Test.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/PasswordResetOtpMailTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/PasswordResetOtpTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/ProductionBigintIncidentRecoveryTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/SafeDailyBudgetCombinedModelTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/SafeMigrationPatchRollbackTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/SanctumLogoutSecurityTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/SavingReminderApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/SevenMigrationsSafetyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/TransactionBalanceConsistencyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/TransactionDataIsolationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/TransactionIdempotencyTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/UpdateUserApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/UserPasswordApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/WishlistApiTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/WishlistFinancialIntegrationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/WishlistLiveIntegrationTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Feature/WishlistMetadataAndUploadTest.php | SOURCE INVENTORY; tidak dijalankan |
| tests/TestCase.php | SOURCE INVENTORY; tidak dijalankan |
| tests/Unit/ExampleTest.php | SOURCE INVENTORY; tidak dijalankan |


**TahanDulu_Flutter**

| File | Level bukti audit |
| --- | --- |
| test/account_settings_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/account_transfer_integrated_scenario_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/account_transfer_widget_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/account_types_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/accounts_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/accounts_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/accounts_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/app_back_button_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/app_bottom_navigation_bar_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/app_icons_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/auth_flow_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/auth_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/bank_catalog_widget_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/dashboard_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/dashboard_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/dashboard_reference_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/dashboard_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/expenses_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/expenses_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/expenses_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/fcm_notification_deep_link_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/finance_math_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/financial_health_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/financial_instrument_contract_fase8m_test.dart | DIJALANKAN pada audit |
| test/financial_integration_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/financial_plan_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/financial_settings_fase4b_flutter_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/full_application_integration_fase8c2_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goal_flows_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goal_headers_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goal_math_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goal_priority_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_crud_fase8f_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_financial_integrity_fase8i_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_full_integration_fase8c_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_remote_live_e2e_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/goals_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/instruments_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/instruments_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/instruments_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/integration_audit_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/legacy_cash_fase4d_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/liquid_glass_accessibility_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/login_google_icon_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/multi_account_admin_fee_flutter_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/notification_remote_live_e2e_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/notifications_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_assets_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_data_sync_fase2_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_invitation_popup_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_optional_fase3_flutter_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_redesign_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_three_steps_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/onboarding_visual_spec_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/password_reset_email_display_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/plan_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/plan_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/profile_features_fase7b_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/profile_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/receipt_parser_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/remote_bank_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/remote_goal_repository_test.dart | DIJALANKAN pada audit |
| test/remote_google_auth_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/remote_notification_repository_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/remote_purchase_decision_repository_test.dart | DIJALANKAN pada audit |
| test/remote_transaction_repository_test.dart | DIJALANKAN pada audit |
| test/report_export_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/report_integration_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/reports_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/reports_provider_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/reports_redesign_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/reports_responsive_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/reports_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/safe_daily_combined_model_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/salary_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/salary_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_add_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_link_and_photo_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_remote_live_e2e_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/tahandulu_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transaction_fee_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transaction_idempotency_flutter_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transaction_methods_flow_fase8b_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transaction_record_method_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transactions_controller_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transactions_golden_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/transactions_screen_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/ui_modernization_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/validators_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/voice_transaction_parser_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/widget_test.dart | SOURCE INVENTORY; tidak dijalankan |
| test/wishlist_fase4c_test.dart | SOURCE INVENTORY; tidak dijalankan |


#### Snapshot Git command audit

Command berurutan: status -sb; branch -avv; log --oneline -20; worktree list; remote -v; rev-list --left-right --count origin/main...HEAD; diff --shortstat origin/main...HEAD. Snapshot penutup mencakup perubahan eksternal dan dokumen audit untracked. Backend main sudah113ac3f; source tree identik34aee92. Working tree Flutter berubah dari baseline awal; lihat delta B.


<details><summary>TahanDulu_Laravel</summary>

```text
$ git status -sb
## main...origin/main
$ git branch -avv
  backup/local-work-20261030                                     c15ece6 backup: save all local financial and notification features before remote sync
  feature/fase-1-4d-completed                                    d05c0ed feat(fase-1-4d): complete implementation of budget, onboarding, multi-account admin fee, bridge mode, wishlist purchases, and cash legacy reconciliation
  feature/financial-reports-integration                          1c8bfe9 [origin/feature/financial-reports-integration] fix(deploy): add pre-migration config cache, explicit storage symlink check, and clean app restart
  feature/goals-integration-8c                                   c848ebf feat(wishlist): enhance product link metadata preview with discounts, price ranges, marketplace detection, and SSRF hardening
  feature/profile-fase7b                                         6ea5a74 fix(security): rate limiting, session revocation, token freshness, and postgres migration tests in Fase 7C
  feature/sync-github-merge                                      5bff047 [origin/main: ahead 5, behind 56] chore: format patch migration
  feature/tahandulu-backend-integration                          48095d7 [origin/feature/tahandulu-backend-integration] security(fase-5d): harden docker compose secrets, implement server-side google reauth for account deletion, and add cross-platform contract and migration tests
  feature/transaction-input-8b                                   c848ebf feat(wishlist): enhance product link metadata preview with discounts, price ranges, marketplace detection, and SSRF hardening
  feature/wishlist-input-8a                                      c848ebf feat(wishlist): enhance product link metadata preview with discounts, price ranges, marketplace detection, and SSRF hardening
  fix/financial-instrument-contract-stabilization                34aee92 [origin/fix/financial-instrument-contract-stabilization] fix(instruments): strictly forbid cash UUID on create and update instruments
  fix/goals-current-amount-integrity                             104e8cf test(goals): add PostgreSQL UUID concurrency suite and align notification cascade test
  hotfix/goals-production-id-mismatch                            6b33490 fix(goals): deduplicate current_amount mutations with GoalTransaction hooks and guard Filament deletion rule
  hotfix/production-bigint-recovery                              a46fcb2 [origin/main: behind 24] fix(hotfix): restore BIGINT database compatibility, recover user registration, and fix dashboard cashflow
  integration/financial-reports                                  5152d69 test(budget): set deterministic test timestamp in test_zero_remaining_budget_safe_daily_zero
  integration/profile-uuid-sync                                  38190d1 fix(accounting): ensure opening balance and internal transfers do not inflate cashflow, harden UUID cross-user authorization
  integration/safe-sync                                          48095d7 [origin/main: behind 37] security(fase-5d): harden docker compose secrets, implement server-side google reauth for account deletion, and add cross-platform contract and migration tests
* main                                                           113ac3f [origin/main] Merge branch 'fix/financial-instrument-contract-stabilization' into main
  publish/clean-main                                             0b04198 [origin/main: behind 55] feat: integrate financial accounts, transfers, bank catalog, and notifications
  release/integrated-8c2                                         a869964 fix(api): add route aliases for user profile and financial-instrumens backward compatibility
  release/profile-uuid-production                                ee0b41b feat(profile): integrate bio field, password update, and robust profile api into production UUID branch
  remotes/origin/HEAD                                            -> origin/main
  remotes/origin/feature/financial-reports-integration           1c8bfe9 fix(deploy): add pre-migration config cache, explicit storage symlink check, and clean app restart
  remotes/origin/feature/tahandulu-backend-integration           48095d7 security(fase-5d): harden docker compose secrets, implement server-side google reauth for account deletion, and add cross-platform contract and migration tests
  remotes/origin/fix/financial-instrument-contract-stabilization 34aee92 fix(instruments): strictly forbid cash UUID on create and update instruments
  remotes/origin/fix/goals-current-amount-integrity              104e8cf test(goals): add PostgreSQL UUID concurrency suite and align notification cascade test
  remotes/origin/main                                            113ac3f Merge branch 'fix/financial-instrument-contract-stabilization' into main
$ git log --oneline -20
113ac3f Merge branch 'fix/financial-instrument-contract-stabilization' into main
34aee92 fix(instruments): strictly forbid cash UUID on create and update instruments
6396078 fix(instruments): enforce 422 on invalid type_id, avoid silent nulls, and preserve type_id on partial update
eb98a0d fix(instruments): safe UUID lookup and contract compatibility for financial instruments
1a7a357 fix: tampilan teks meleber & update saldo instrumen
e7a222d Merge branch 'main' of github.com:Ranapace565/tahanDulu
111d08f fix: auto schedule
6a1f4eb Merge pull request #1 from Ranapace565/fix/goals-current-amount-integrity
104e8cf test(goals): add PostgreSQL UUID concurrency suite and align notification cascade test
3208c07 fix(goals): implement single source of truth for current_amount mutations and prevent double increment
50e405f fix: kalkulasi tampilan dan fitur goal investment
a869964 fix(api): add route aliases for user profile and financial-instrumens backward compatibility
6fde554 feat(release): bridge wishlist transaction_id with financial record purchase and add cross-module E2E test
7dc8932 chore(release): merge origin/main into release/integrated-8c2 with new wishlist transaction_id migration
61dfa22 Merge branch 'main' of github.com:Ranapace565/tahanDulu
d1b0f51 fix: tahan dulu tampilan & struktur
c848ebf feat(wishlist): enhance product link metadata preview with discounts, price ranges, marketplace detection, and SSRF hardening
ee0b41b feat(profile): integrate bio field, password update, and robust profile api into production UUID branch
91a7158 fix(hotfix): align models and migrations with production UUID schema, alter personal_access_tokens tokenable_id to varchar, and fix cashflow scope
9132d39 fix(debug): query sample user and counts
$ git worktree list
E:/TAHAN_DULU/TahanDulu_Laravel  113ac3f [main]
$ git remote -v
origin	https://github.com/Ranapace565/tahanDulu (fetch)
origin	https://github.com/Ranapace565/tahanDulu (push)
$ git rev-list --left-right --count origin/main...HEAD
0	0
$ git diff --shortstat origin/main...HEAD
```

</details>


<details><summary>TahanDulu_Flutter</summary>

```text
$ git status -sb
## release/fase8n-final-integration
 M lib/core/constants/app_assets.dart
 M lib/data/datasources/remote/api_client.dart
 M lib/data/datasources/remote/api_config.dart
 M lib/features/onboarding/presentation/screens/budget_screen.dart
 M lib/features/onboarding/presentation/screens/plan_screen.dart
 M test/onboarding_visual_spec_test.dart
?? assets/icons/batas_belanja_harian.png
?? assets/icons/dana_darurat.png
?? assets/icons/investasi_tabungan.png
?? assets/icons/kebutuhan_pokok.png
?? assets/icons/pengeluaran_fleksibel.png
?? assets/icons/pengeluaran_rutin.png
?? assets/icons/penghasilan_bulanan.png
?? assets/icons/target_dana_darurat.png
?? assets/icons/total_alokasi.png
?? docs/audits/
?? test/onboarding_redesign_test.dart
$ git branch -avv
  feature/financial-reports-mobile                9a24f57 [origin/feature/financial-reports-mobile] fix(build): add proguard rules to suppress optional ML Kit language pack warnings for release build
  feature/goals-integration-8c                    a511f37 fix(goals): resolve UUID truncation, multi-goal deposit deletion, and notification deep link routing
+ feature/liquid-glass-ui                         688a5a8 (E:/TAHAN_DULU/Flutter_Liquid_Glass) docs(ui): include changed source file inventory
  feature/profile-fase7b                          6879ff6 fix(uuid): ensure remote repositories support UUID identifiers for goals, accounts, and transactions
  feature/transaction-input-8b                    ae23862 feat(transactions): complete three-method transaction input flow with voice recognition and receipt OCR scanning
  feature/wishlist-input-8a                       ab1817c feat(wishlist): complete three-method add item flow with automatic link product extraction and on-device OCR
  fix/flutter-laravel-contract-stabilization      db47735 fix(accounts): stabilize financial instrument contract and support UUID instrument types
  fix/goals-crud-priority                         6c98432 test(goals): add financial integrity and delete validation widget tests
  main                                            8f1e282 [origin/main] fix(test): disambiguate bottom sheet and dialog finders in profile_test
* release/fase8n-final-integration                bde0e6a test(accounts): update test fixtures to use string typeId and clean unused imports
  release/integrated-8c2                          8f1e282 [origin/release/integrated-8c2] fix(test): disambiguate bottom sheet and dialog finders in profile_test
  remotes/origin/feature/financial-reports-mobile 9a24f57 fix(build): add proguard rules to suppress optional ML Kit language pack warnings for release build
  remotes/origin/main                             8f1e282 fix(test): disambiguate bottom sheet and dialog finders in profile_test
  remotes/origin/release/integrated-8c2           8f1e282 fix(test): disambiguate bottom sheet and dialog finders in profile_test
$ git log --oneline -20
bde0e6a test(accounts): update test fixtures to use string typeId and clean unused imports
7f81165 fix(accounts): enforce strict UUID instrument types and handle loading errors
f4bf24f Merge branch 'feature/liquid-glass-ui' into release/fase8n-final-integration
db47735 fix(accounts): stabilize financial instrument contract and support UUID instrument types
688a5a8 docs(ui): include changed source file inventory
d088afe docs(ui): record verification results and before-after Flutter renders
6c98432 test(goals): add financial integrity and delete validation widget tests
640d062 fix(security): sanitize raw SQL and database stack traces from user-facing error messages
974941d test(goals): remove unused imports in goals_crud_fase8f_test.dart
0a4f8e8 fix(goals): resolve save button unresponsive bug, CRUD operations, priority reorder, and detail screen layout
612a97e test(ui): verify responsive glass navigation and dark theme selection
94032f5 feat(ui): migrate financial screens, overlays and controls to adaptive glass surfaces
b5683f3 feat(ui): unify floating navigation, buttons and method selection
b4a6025 feat(theme): add liquid glass rendering and persisted dark appearance
8f1e282 fix(test): disambiguate bottom sheet and dialog finders in profile_test
bc9a032 feat(release): end-to-end integration of profile, wishlist, transactions, and goals with full UUID safety
a511f37 fix(goals): resolve UUID truncation, multi-goal deposit deletion, and notification deep link routing
ae23862 feat(transactions): complete three-method transaction input flow with voice recognition and receipt OCR scanning
ab1817c feat(wishlist): complete three-method add item flow with automatic link product extraction and on-device OCR
6879ff6 fix(uuid): ensure remote repositories support UUID identifiers for goals, accounts, and transactions
$ git worktree list
E:/TAHAN_DULU/TahanDulu_Flutter     bde0e6a [release/fase8n-final-integration]
E:/TAHAN_DULU/Flutter_Liquid_Glass  688a5a8 [feature/liquid-glass-ui]
$ git remote -v
origin	https://github.com/BayuFirmansyah00/Tahan-Dulu.git (fetch)
origin	https://github.com/BayuFirmansyah00/Tahan-Dulu.git (push)
$ git rev-list --left-right --count origin/main...HEAD
0	14
$ git diff --shortstat origin/main...HEAD
 113 files changed, 3817 insertions(+), 2677 deletions(-)
```

</details>

