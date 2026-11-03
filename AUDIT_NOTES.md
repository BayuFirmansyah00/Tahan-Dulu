# Audit Notes — Flutter vs Laravel (TahanDulu)

## BACKEND LARAVEL (Source of Truth)

### Base URL / Mount
- `routes/api.php` — routes di-definiskan tanpa prefix "/api" di dalam file, tapi dipanggil via route service provider dengan prefix `/api`.
- Contoh full path: `http://localhost:8000/api/login`

### Authentication
- Laravel Sanctum (stateful tokens, `personal_access_tokens` table).
- Endpoint auth:
  - `POST /api/register` — body: name, email, password, password_confirmation. Response 201: `{success, message, data: {user, access_token, token_type}}`
  - `POST /api/login` — body: email, password. Response 200: `{success, message, data: {user, access_token, token_type}}`; 401: `{success, message}`
  - `GET /api/me` — auth:sanctum. Response: `{success, data: user}`
  - `POST /api/logout` — auth:sanctum. Response: `{success, message}`
  - `GET /api/user` — auth:sanctum, returns `$request->user()` (raw, no envelope)

### Response Envelope
- Semua endpoint terproteksi: `{success: bool, message: string, data: ..., pagination?: {...}}`
- Error 422: `{success: false, message: 'Validasi gagal', errors: {...}}`
- Error 401: `{success: false, message: 'Kredensial email atau password salah'}`

### Financial Instruments (`/api/financial-instruments`)
- Model: `financial_instrumens` (note spelling). Columns: id, name, balance (bigInt, default 0), is_active (bool), user_id, type_id (nullable FK instrument_types), timestamps, softDeletes.
- Resource fields: id, name, balance (int), balance_formatted, is_active (bool), type (object when loaded: id, name, type, logo_url), created_at, updated_at (ISO8601).
- Store validation: name required, type_id nullable exists, balance nullable numeric min:0, is_active nullable boolean.

### Transactions (`/api/transactions`)
- Model: `transactions`. Columns: id, title, type (income/expense), category, amount (bigInt), information (nullable), user_id, instrument_id (FK financial_instrumens), timestamps, softDeletes.
- Resource fields: id, title, type, category, amount (int), amount_formatted ('Rp ...'), information, instrument (FinancialInstrumenResource when loaded), attachments (array of asset URLs), created_at, updated_at (ISO8601).
- Store validation: title required, type in:income,expense, category required, amount numeric min:1, instrument_id required exists, attachments.* image max 2MB.
- Query filters: type, category, instrument_id, per_page. Paginated (default 15).

### Goals (`/api/goals`)
- Model: `goals`. Columns: id, image, title, type, target_amount (bigInt), current_amount (bigInt), target_date (timestamp), `reminder date` (timestamp, WITH SPACE), frequency enum, is_active bool, user_id, timestamps, softDeletes.
- Casts: `reminder date` → datetime (note: key has space).
- Resource fields: id, title, type, target_amount (int), target_amount_formatted, current_amount (int), current_amount_formatted, progress_percentage, image_url, target_date, reminder_date, frequency, is_active, created_at, updated_at.
- Store validation: title, type, target_amount required; current_amount nullable; target_date, reminder_date nullable date; frequency in daily/weekly/monthly/yearly; is_active nullable boolean; image nullable image.
- Store service: maps `reminder_date` → `reminder date` before create. Image stored to `goals` public disk.

### Goal Transactions (`/api/goals/{goalId}/transactions`)
- Model: `goal_transactions`. Columns: id, goal_id, user_id, transaction_id (nullable), type enum(deposit,withdraw), amount (bigInt), notes, timestamps.
- Service business logic: deposit validates instrument balance sufficient; withdraw validates goal current_amount sufficient. Creates main Transaction (type expense for deposit, income for withdraw), updates goal current_amount.
- Resource fields: id, goal_id, type, amount (int), amount_formatted, notes, instrument (null or FinancialInstrumenResource), transaction (TransactionResource), created_at.

### Investments (`/api/investments`)
- Model: `investments`. Columns: id, title, type, target (nullable bigInt), increase (nullable bigInt), achieved (bigInt), is_active bool, user_id, timestamps, softDeletes.
- Resource fields: id, title, type, target (int), target_formatted, increase (int), increase_formatted, achieved (int), achieved_formatted, progress_percentage, is_active, created_at, updated_at.

### Investment Transactions (`/api/investments/{investmentId}/transactions`)
- Model: `investment_transactions`. Columns: id, investment_id, user_id, transaction_id (nullable), type enum(deposit,withdraw), amount (bigInt), notes, timestamps.
- Business logic similar to goal transactions but updates investment.achieved.

### Recurring Incomes/Expenses (`/api/recurring-incomes`, `/api/recurring-expenses`)
- Model: `recurring_transactions`. Columns: id, title, type enum(income,expense), category (nullable), amount (bigInt), next_due_date (timestamp), frequency enum, is_active bool, make_automatic bool, user_id, instrument_id (nullable FK), timestamps, softDeletes.
- Resource fields: id, title, type, category, amount (int), amount_formatted, frequency, next_due_date ('Y-m-d'), is_active (bool), make_automatic (bool), instrument (FinancialInstrumenResource), created_at, updated_at.
- Income validation: instrument_id required (scoped to user). Expense validation: instrument_id nullable.

### Important quirks
1. Goal model column `reminder date` (with space) — migration `2026_10_14_071203` defines `reminder date`, Goal model casts `'reminder date'` → datetime, service maps `reminder_date` → `'reminder date'`.
2. `financial_instrumens` table spelling (not "instruments").
3. User model has `role` column default 'admin'.
4. Amount fields are `bigInteger` → JSON int.
5. Dates returned as ISO8601 strings.

## FRONTEND FLUTTER (Current State)

### Architecture
- Riverpod (NotifierProvider, FutureProvider, Provider).
- go_router for navigation.
- `http` package for API client.
- `flutter_secure_storage` for token.
- Data layer: repositories (abstract) + mock implementations. Remote auth repository exists but default = mock.

### api_client.dart
- Only `post()` and `get()`. No `put`, `patch`, `delete`.
- Decodes envelope `{success, message, data}`; throws ApiException on status >= 400.
- fieldErrors parsed from `body['errors']`.

### Models (MISMATCH vs Laravel)
- `AppTransaction`: id(String), title, amount(double), type(income/expense), date(DateTime), category(String?), accountId(String?), note, fee. — Laravel uses instrument_id not accountId, amount is int, no fee field, created_at/updated_at ISO strings.
- `FinancialGoal`: id, name, targetAmount(double), currentAmount(double), deadline, category (enum GoalCategory), recurringAmount, frequency (DepositFrequency monthly/weekly only), sourceAccountId, priority. — Laravel: title, type, target_amount, current_amount, target_date, reminder_date, frequency (daily/weekly/monthly/yearly), image_url, is_active. No category enum mapping.
- `FinancialInstrument`: id, name, type (bank/digitalBank/ewallet), initialBalance(double), institutionName, monthlyAdminFee, adminFeeDay, isSelected. — Laravel: id, name, balance(int), is_active(bool), type (object with id/name/type/logo_url), type_id. Flutter type enum doesn't match instrument_type table.
- `UserModel`: id, name, email, bio. — Laravel: id, name, email, role, email_verified_at.

### Providers (all mock)
- `authRepositoryProvider` → MockAuthRepository (default), RemoteAuthRepository only if `USE_REMOTE_AUTH=true`.
- `dashboardRepositoryProvider` → MockDashboardRepository
- `accountRepositoryProvider` → MockAccountRepository (backed by onboarding mock)
- `transactionRepositoryProvider` → MockTransactionRepository
- `goalRepositoryProvider` → MockGoalRepository
- etc.

### Test Baseline
- `flutter analyze`: No issues.
- `flutter test`: 461 pass, 7 fail (all golden/pixel tests, pre-existing, unrelated to API integration).

## MATRIX (Feature | Laravel | Flutter | Status | Rec)
| Authentication | POST /register, /login, /logout, /me (Sanctum) | MockAuthRepository default; RemoteAuthRepository exists but opt-in | Perlu penyesuaian Flutter | Aktifkan remote repo, update providers |
| Financial Instruments | /api/financial-instruments (full CRUD) | Mock (onboarding in-memory) | Perlu penyesuaian Flutter | Buat remote impl, map model |
| Transactions | /api/transactions (full CRUD + pagination + filters) | Mock | Perlu penyesuaian Flutter | Buat remote impl, add put/delete to ApiClient |
| Goals | /api/goals + /api/goals/{id}/transactions | Mock | Perlu penyesuaian Flutter | Buat remote impl, map reminder_date quirk |
| Goal Transactions | /api/goals/{goalId}/transactions | Mock (GoalDeposit) | Perlu penyesuaian Flutter | Buat remote impl |
| Investments | /api/investments + transactions | Not present in Flutter | Belum tersedia di frontend | (Optional) Catat sebagai blocker |
| Recurring Incomes | /api/recurring-incomes | Not present | Belum tersedia | Catat blocker |
| Recurring Expenses | /api/recurring-expenses | Not present | Belum tersedia | Catat blocker |
| Dashboard summary | No dedicated endpoint (composed from transactions/instruments) | MockDashboardRepository | Perlu penyesuaian | Compose from remote data |
