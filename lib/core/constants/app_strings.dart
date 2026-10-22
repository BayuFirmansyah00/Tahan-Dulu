/// Semua copy Bahasa Indonesia terpusat di sini.
abstract final class AppStrings {
  static const String appTagline =
      'Atur uang. Capai tujuan. Pikir sebelum beli.';

  // Splash.
  static const String splashTagline =
      'Atur uang. Capai tujuan.\nPikir sebelum beli.';
  static const String splashLoading =
      'Menyiapkan pengalaman terbaik untuk kamu...';

  // Login.
  static const String loginHeadline = 'Kelola uangmu\ndengan lebih sadar.';
  static const String loginSubtitle =
      'Mulai dengan membuat rencana keuangan yang sesuai dengan kondisi kamu.';
  static const String continueWithGoogle = 'Continue with Google';
  static const String loginWithEmail = 'Masuk dengan Email';
  static const String noAccount = 'Belum punya akun? ';
  static const String registerLink = 'Daftar';

  // Register.
  static const String registerTitle = 'Daftar';
  static const String registerSubtitle =
      'Buat akun untuk mulai mengatur keuanganmu.';
  static const String fullName = 'Nama Lengkap';
  static const String fullNameHint = 'Bayu Firmansyah';
  static const String email = 'Email';
  static const String emailHint = 'nama@email.com';
  static const String password = 'Password';
  static const String confirmPassword = 'Konfirmasi Password';
  static const String registerButton = 'Daftar';
  static const String haveAccount = 'Sudah punya akun? ';
  static const String loginLink = 'Masuk';

  // Error autentikasi (server + lokal).
  static const String authLoginFailed = 'Gagal masuk. Silakan coba lagi.';
  static const String authRegisterFailed =
      'Gagal mendaftar. Silakan coba lagi.';
  static const String authGoogleFailed =
      'Gagal masuk dengan Google. Silakan coba lagi.';
  static const String authEmailTaken = 'Email sudah terdaftar. Silakan masuk.';
  static const String authPasswordShort = 'Password minimal 8 karakter.';

  // Validation.
  static const String nameRequired = 'Nama wajib diisi.';
  static const String emailRequired = 'Email wajib diisi.';
  static const String emailInvalid = 'Masukkan email yang valid.';
  static const String passwordRequired = 'Password tidak boleh kosong.';
  static const String confirmRequired = 'Konfirmasi password wajib diisi.';
  static const String confirmMismatch = 'Konfirmasi password harus sama.';

  // Onboarding.
  static const String onboardingStep = '1 dari 4';
  static const String onboardingStep2 = '2 dari 4';
  static const String onboardingStep3 = '3 dari 4';
  static const String onboardingStep4 = '4 dari 4';

  // Salary (No.3 — Input Gaji Bulanan).
  static const String salaryTitle = 'Mulai dari kondisi\nkeuanganmu';
  static const String salarySubtitle =
      'Data ini membantu kami membuat\nrencana yang sesuai.';
  static const String salaryIncomeQuestion = 'Berapa pemasukanmu setiap bulan?';
  static const String salaryDayQuestion = 'Biasanya kamu menerima gaji kapan?';
  static const String salaryCustomDay = 'Lainnya';
  static const String salaryCustomDayTitle = 'Pilih tanggal gajian';
  static const String salaryCustomDayHint = '1–31';
  static const String salaryHelper = 'Kamu bisa mengubahnya kapan saja.';
  static const String continueButton = 'Lanjut →';
  static const String incomeRequired = 'Masukkan pemasukan bulananmu.';
  static const String customDayInvalid = 'Masukkan tanggal 1–31.';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';

  // Instruments (No.4 — Pilih Instrumen Keuangan).
  static const String instrumentsTitle = 'Uangmu biasanya\ndisimpan di mana?';
  static const String instrumentsSubtitle =
      'Pilih rekening atau instrumen yang kamu gunakan.';
  static const String initialBalance = 'Saldo awal';
  static const String addInstrument = '+ Tambah instrumen';
  static const String instrumentDetail = 'Detail instrumen';
  static const String adminFee = 'Biaya administrasi bulanan';
  static const String feeDay = 'Tanggal pemotongan';
  static const String feeDaySuffix = 'setiap bulan';
  static const String feeHelper =
      'Biaya ini akan diperhitungkan dalam saldo tercatat dan rencana keuangan.';
  static const String addInstrumentTitle = 'Tambah instrumen';
  static const String instrumentName = 'Nama instrumen';
  static const String instrumentNameHint = 'cth. BCA';
  static const String instrumentType = 'Tipe instrumen';
  static const String typeBank = 'Bank';
  static const String typeDigitalBank = 'Bank Digital';
  static const String typeEWallet = 'E-Wallet';
  static const String noInstrumentError =
      'Tambahkan setidaknya satu instrumen keuangan.';
  static const String instrumentNameRequired = 'Nama instrumen wajib diisi.';
  static const String balanceRequired = 'Masukkan saldo awal.';

  // Recurring expenses (No.5 — Pengeluaran Rutin).
  static const String expensesTitle = 'Apa saja pengeluaran\nrutinmu?';
  static const String expensesSubtitle =
      'Perkirakan kebutuhan bulanan agar budgetmu lebih realistis.';
  static const String addExpense = '+ Tambah pengeluaran';
  static const String addExpenseTitle = 'Tambah pengeluaran';
  static const String expenseTotal = 'Total pengeluaran rutin';
  static const String perMonth = '/ bulan';
  static const String expenseSummaryInfo =
      'Pengeluaran ini akan digunakan untuk membuat rencana keuanganmu.';
  static const String expenseName = 'Nama pengeluaran';
  static const String expenseNameHint = 'cth. Kebutuhan sehari-hari';
  static const String expenseCategory = 'Kategori';
  static const String expenseAmount = 'Nominal bulanan';
  static const String expenseNameRequired = 'Nama pengeluaran wajib diisi.';
  static const String expenseAmountRequired = 'Masukkan nominal bulanan.';
  static const String noExpenseError =
      'Tambahkan setidaknya satu pengeluaran rutin.';
  static const String editExpenseTitle = 'Ubah pengeluaran';
  static const String deleteExpense = 'Hapus';
  static const String deleteExpenseTitle = 'Hapus pengeluaran?';
  static const String deleteExpenseConfirm = 'Hapus';
  static const String catNeeds = 'Kebutuhan';
  static const String catTransport = 'Transportasi';
  static const String catBills = 'Tagihan';
  static const String catShopping = 'Belanja';
  static const String catOthers = 'Lainnya';
  static const String catFood = 'Makanan';
  static const String catEntertainment = 'Hiburan';
  static const String catEducation = 'Pendidikan';
  static const String catSalary = 'Gaji';
  static const String catBonus = 'Bonus';

  // Transactions (Tahap 7 — Riwayat & input manual).
  static const String transactionsTitle = 'Transaksi';
  static const String filterAll = 'Semua';
  static const String filterIncome = 'Pemasukan';
  static const String filterExpense = 'Pengeluaran';
  static const String todayLabel = 'Hari ini';
  static const String emptyTransactions = 'Belum ada transaksi';
  static const String emptyTransactionsHint = 'Yuk catat transaksi pertamamu.';
  static const String emptyFilterIncome = 'Belum ada pemasukan.';
  static const String emptyFilterExpense = 'Belum ada pengeluaran.';
  static const String searchHint = 'Cari transaksi...';
  static const String searchClear = 'Hapus pencarian';
  static const String searchEmptyTitle = 'Tidak ada hasil';
  static const String searchEmptySubtitle = 'Coba kata kunci atau filter lain.';
  static const String addTransaction = 'Catat Transaksi';
  static const String formType = 'Jenis transaksi';
  static const String typeExpense = 'Pengeluaran';
  static const String typeIncome = 'Pemasukan';
  static const String amountLabel = 'Nominal';
  static const String amountHint = '0';
  static const String amountRequired = 'Masukkan nominal yang valid.';
  static const String feeLabel = 'Biaya Tambahan (Opsional)';
  static const String feeHint = '0';
  static const String txFeeHelper =
      'Biaya admin atau layanan. Kosongkan bila tidak ada.';
  static const String feeTotalOut = 'Total pengeluaran';
  static const String feeTotalIn = 'Total diterima';
  static const String feeExceedsIncome =
      'Biaya tidak boleh melebihi nominal pemasukan.';
  static const String categoryLabel = 'Kategori';
  static const String categoryRequired = 'Pilih kategori.';
  static const String accountLabel = 'Akun';
  static const String accountHint = 'Pilih akun';
  static const String accountRequired = 'Pilih akun terlebih dahulu.';
  static const String noAccountTitle = 'Belum ada akun tersedia.';
  static const String noAccountHint =
      'Tambahkan instrumen keuangan terlebih dahulu.';
  static const String dateLabel = 'Tanggal';
  static const String noteLabel = 'Catatan (opsional)';
  static const String noteHint = 'cth. Makan siang';
  static const String reviewTitle = 'Periksa Transaksi';
  static const String reviewSubtitle =
      'Pastikan datanya sudah benar sebelum disimpan.';
  static const String reviewName = 'Nama';
  static const String reviewCategory = 'Kategori';
  static const String reviewPayFrom = 'Bayar dari';
  static const String reviewReceiveIn = 'Terima di';
  static const String reviewDate = 'Tanggal';
  static const String reviewSource = 'Sumber';
  static const String reviewSourceManual = 'Manual';
  static const String reviewFee = 'Biaya Tambahan';
  static const String reviewNote = 'Catatan';
  static const String reviewAction = 'Periksa Transaksi';
  static const String saveTransaction = 'Simpan Transaksi';
  static const String saveFailed = 'Gagal menyimpan. Coba lagi.';
  static const String editAction = 'Edit';
  static const String successTitle = 'Transaksi berhasil disimpan';
  static const String seeTransactions = 'Lihat Transaksi';
  static const String backToHome = 'Kembali ke Home';

  // Goals (No.7 — Target Keuangan).
  static const String goalsTitle = 'Rencanakan tujuan\nkeuanganmu';
  static const String goalsSubtitle =
      'Tujuan kecil hari ini bisa membantu kamu mencapai rencana yang lebih besar.';
  static const String goalCategoryLabel = 'Pilih kategori target';
  static const String goalName = 'Nama Target';
  static const String goalNameHint = 'cth. Dana Darurat';
  static const String goalAmount = 'Target Nominal';
  static const String goalDate = 'Target Waktu';
  static const String goalDateHint = 'Pilih bulan';
  static const String contributionTitle = 'Perkiraan setoran per bulan';
  static const String goalHelper = 'Kamu bisa mengubah target ini nanti.';
  static const String doneButton = 'Selesai';
  static const String goalNameRequired = 'Masukkan nama target.';
  static const String goalAmountRequired = 'Masukkan nominal target.';
  static const String goalDateRequired = 'Pilih target waktu.';
  static const String goalCatEmergency = 'Dana Darurat';
  static const String goalCatSavings = 'Tabungan';
  static const String goalCatInvestment = 'Investasi';
  static const String goalCatOthers = 'Lainnya';
  static const String goalCatHouse = 'Rumah';
  static const String goalCatVehicle = 'Kendaraan';
  static const String goalCatGadget = 'Gadget';
  static const String goalCatHoliday = 'Liburan';
  static const String goalCatEducation = 'Pendidikan';

  // Goals feature (Tahap 10 — Target Keuangan).
  static const String goalsListTitle = 'Target Keuangan';
  static const String goalsListSubtitle = 'Wujudkan tujuanmu satu per satu.';
  static const String goalsTotalTarget = 'Total Target';
  static const String goalsTotalSaved = 'Terkumpul';
  static const String goalsActiveTitle = 'Target Aktif';
  static const String newGoalButton = 'Target Baru';
  static const String createGoalTitle = 'Buat Target Baru';
  static const String createGoalQuestion = 'Untuk apa kamu menabung?';
  static const String createGoalHint =
      'Pilih kategori yang sesuai dengan tujuanmu.';
  static const String continueAction = 'Lanjutkan';
  static const String setupGoalTitle = 'Atur Target';
  static const String goalDetailTitle = 'Detail Target';
  static const String goalSavedAmount = 'Dana yang sudah terkumpul';
  static const String goalRemaining = 'Sisa dana';
  static const String periodicSaving = 'Nominal tabungan berkala';
  static const String depositFrequency = 'Frekuensi setoran';
  static const String frequencyMonthly = 'Per bulan';
  static const String frequencyWeekly = 'Per minggu';
  static const String perWeekSuffix = '/ minggu';
  static const String savingSource = 'Pilih sumber dana';
  static const String saveGoalAction = 'Simpan Target';
  static const String estimateUnreachable =
      'Rencana ini belum bisa mencapai target. Naikkan nominal setoran.';
  static const String goalDetailCollected = 'Sudah terkumpul';
  static const String goalDetailRemaining = 'Masih dibutuhkan';
  static const String goalDetailDeadline = 'Target tanggal';
  static const String goalDetailPeriodic = 'Setoran bulanan';
  static const String goalDetailEta = 'Estimasi selesai';
  static const String addFundsAction = 'Tambah Dana';
  static const String editGoalAction = 'Edit Target';
  static const String depositTitle = 'Tambah Dana';
  static const String depositTo = 'Tambahkan dana ke';
  static const String depositHelp =
      'Setiap setoran membawamu lebih dekat ke tujuanmu.';
  static const String quickAmounts = 'Nominal cepat';
  static const String fundingSource = 'Sumber dana';
  static const String recordedBalanceShort = 'Saldo tercatat';
  static const String depositPreview = 'Preview setoran';
  static const String depositBeforeAfter = 'sebelum → sesudah';
  static const String depositImpactNote =
      'Setoran dicatat sebagai alokasi target dan tidak mengurangi saldo akun.';
  static const String confirmDepositAction = 'Konfirmasi Setoran';
  static const String historyTitle = 'Riwayat Setoran';
  static const String historyProgressTitle = 'Progress dari waktu ke waktu';
  static const String historyEmpty =
      'Belum ada setoran tercatat untuk target ini.';
  static const String historyTotal = 'Total setoran';
  static const String historyAverage = 'Rata-rata per bulan';
  static const String simulateTitle = 'Simulasi Target';
  static const String simulateQuestion =
      'Bagaimana kalau kamu menabung lebih banyak?';
  static const String simulateHint =
      'Lihat bagaimana perubahan setoran mempengaruhi waktu pencapaian.';
  static const String simulateAmount = 'Setoran bulanan';
  static const String simulateEta = 'Estimasi waktu tercapai';
  static const String simulateUnreachable =
      'Target tidak dapat dicapai melalui rencana tersebut.';
  static const String simulateReached = 'Target sudah tercapai.';
  static const String usePlanAction = 'Gunakan Rencana Ini';
  static const String confirmUsePlanTitle = 'Gunakan rencana ini?';
  static const String confirmUsePlanBody =
      'Nominal tabungan berkala target akan diperbarui.';
  static const String priorityTitle = 'Prioritas Target';
  static const String priorityQuestion =
      'Target mana yang ingin kamu prioritaskan?';
  static const String priorityHint =
      'Atur urutan prioritas sesuai dengan kebutuhan dan kondisi kamu.';
  static const String priorityHigh = 'Tinggi';
  static const String priorityMedium = 'Sedang';
  static const String priorityLow = 'Rendah';
  static const String savePriorityAction = 'Simpan Prioritas';
  static const String achievedTitle = 'Target Tercapai!';
  static const String achievedSubtitle = 'Selamat! Kamu berhasil mencapai';
  static const String achievedBadge = 'Target tercapai';
  static const String achievedDuration = 'Durasi';
  static const String achievedTotalDeposits = 'Total setoran';
  static const String achievedNextTitle = 'Apa selanjutnya?';
  static const String newGoalAction = 'Buat Target Baru';
  static const String monthSuffix = 'bulan';

  // Goals (Tahap 31 — rekomendasi, estimasi, status).
  static const String goalNameAutoNote = 'Nama otomatis mengikuti kategori.';
  static const String goalRecommendLabel = 'Rekomendasi setoran';
  static const String goalReachedNoDeposit =
      'Target sudah tercapai. Tidak perlu setoran lagi.';
  static const String goalRescheduleNote =
      'Tanggal target sudah lewat. Perbarui tanggal target untuk menghitung ulang rencana.';
  static const String goalShortfallNote =
      'Estimasi selesai melewati tenggat. Naikkan nominal setoran.';
  static const String goalEtaLabel = 'Estimasi tercapai';
  static const String goalDeadlineLabel = 'Tenggat';
  static const String goalStatusReached = 'Tercapai';
  static const String goalStatusOverdue = 'Tenggat lewat';
  static const String goalStatusActive = 'Aktif';
  static const String weekSuffix = 'minggu';

  // Goals (Tahap 32 — tab, empty state).
  static const String goalTabOverdue = 'Lewat';
  static const String goalTabEmpty = 'Belum ada target pada kategori ini.';
  static const String goalEmptyTitle = 'Belum ada target keuangan';
  static const String goalEmptySubtitle =
      'Mulai buat target untuk mewujudkan impianmu. '
      'Atur tujuan, pantau progres, dan capai satu per satu.';

  // Goals (Tahap 37 — Prioritas Target sesuai referensi).
  static const String priorityQuestionLead = 'Target mana yang ingin kamu ';
  static const String priorityQuestionAccent = 'prioritaskan?';
  static const String priorityFirst = 'Prioritas Utama';
  static const String prioritySecond = 'Prioritas Kedua';
  static const String priorityThird = 'Prioritas Ketiga';
  static const String priorityOthers = 'Prioritas Lainnya';
  static const String priorityInfoTitle =
      'Target dengan prioritas lebih tinggi akan lebih ditonjolkan';
  static const String priorityInfoBody =
      'Kamu tetap bisa mengubah urutan kapan saja.';
  static const String priorityMoveUp = 'Naikkan prioritas';
  static const String priorityMoveDown = 'Turunkan prioritas';

  // Plan summary (penyelesaian onboarding No.7).
  static const String planTitle = 'Rencana keuanganmu siap!';
  static const String planSubtitle =
      'Berdasarkan pemasukan dan kebutuhanmu, berikut pembagian yang disarankan.';
  static const String monthlyIncomeLabel = 'Pemasukan bulanan';
  static const String monthlyAllocation = 'Alokasi bulanan';
  static const String flexibleExpense = 'Pengeluaran fleksibel';
  static const String safeToday = 'UANG AMAN HARI INI';
  static const String safeTodayDesc =
      'Perkiraan budget yang aman digunakan hari ini.';
  static const String planAdjustable =
      'Rencana ini dapat disesuaikan kapan saja.';
  static const String startAppButton = 'Mulai gunakan aplikasi';

  // Dashboard.
  static const String hi = 'Halo';
  static const String dashboardGreeting = 'Selamat pagi 👋';
  static const String dashboardSubtitle =
      'Tetap konsisten dengan rencana keuanganmu';
  static const String safeTodayTitle = 'UANG AMAN HARI INI';
  static const String safeEstimateHint =
      'Estimasi berdasarkan rencana keuanganmu';
  static const String remainingBudgetLabel = 'Sisa budget bulan ini';
  static const String totalBalanceTitle = 'TOTAL SALDO';
  static const String showBalance = 'Tampilkan saldo';
  static const String hideBalance = 'Sembunyikan saldo';
  static const String balanceRecordedHint =
      'Saldo berdasarkan transaksi yang tercatat';
  static const String goalsSection = 'Tujuan keuangan';
  static const String dashboardSeeAll = 'Lihat semua >';
  static const String monthlySummary = 'Ringkasan bulan ini';
  static const String dashboardSeeReport = 'Lihat laporan >';
  static const String shortcutReport = 'Lihat Laporan';
  static const String recentToday = 'Hari ini';
  static const String recentYesterday = 'Kemarin';
  static const String tahanDuluTitle = 'TahanDulu';
  static const String tahanDuluEmpty = 'Jeda sebelum membeli sesuatu.';
  static const String pendingSuffix = 'barang menunggu keputusan';
  static const String tahanDuluSee = 'Lihat';
  static const String tahanDuluBannerHint =
      'Pikir dulu, keputusan yang lebih baik untuk keuanganmu';

  // TahanDulu (Tahap 11 — Purchase Decision Assistant).
  static const String tahanDuluPageTitle = 'TahanDulu';
  static const String tahanDuluPageSubtitle =
      'Sebelum checkout, cek dulu dampaknya.';
  static const String tabWaiting = 'Menunggu';
  static const String tabWishlist = 'Wishlist';
  static const String tabDone = 'Selesai';
  static const String addItemAction = 'Tambah Barang';
  static const String tahanDuluEduTitle =
      'TahanDulu membantumu berpikir sebelum membeli.';
  static const String tahanDuluEduBody =
      'Lihat dampak pada budget, tabungan, dan target keuanganmu.';
  static const String emptyTahanDulu = 'Belum ada barang di sini';
  static const String emptyTahanDuluHint =
      'Tambahkan barang yang sedang kamu pertimbangkan.';
  static const String addItemTitle = 'Tambah Barang';
  static const String addItemQuestion = 'Apa yang ingin kamu beli?';
  static const String addItemHint =
      'Masukkan barang yang sedang kamu pertimbangkan.';
  static const String methodManual = 'Masukkan manual';
  static const String methodManualDesc =
      'Isi nama, harga, dan kategori sendiri.';
  static const String methodLink = 'Masukkan link produk';
  static const String methodLinkDesc =
      'Tempel link dari Tokopedia, Shopee, atau lainnya.';
  static const String methodPhoto = 'Upload foto';
  static const String methodPhotoDesc = 'Ambil foto atau pilih dari galeri.';
  static const String comingSoonBadge = 'Segera hadir';
  static const String photoComingSoon =
      'Upload foto segera hadir. Gunakan metode lain untuk lanjut.';
  static const String productNameLabel = 'Nama barang';
  static const String productNameHint = 'cth. Adidas Samba';
  static const String productNameRequired = 'Nama barang wajib diisi.';
  static const String productPriceLabel = 'Harga';
  static const String productPriceRequired = 'Masukkan harga yang valid.';
  static const String productCategoryLabel = 'Kategori';
  static const String productUrlLabel = 'Link produk';
  static const String productUrlHint = 'https://tokopedia.com/...';
  static const String productUrlInvalid = 'Masukkan URL yang valid.';
  static const String productNoteLabel = 'Catatan atau alasan membeli';
  static const String productNoteHint = 'cth. Sepatu lama sudah rusak';
  static const String analyzeAction = 'Analisis Pembelian';
  static const String reviewFirstTitle = 'Pertimbangkan dulu';
  static const String reviewFirstSubtitle =
      'Berikut gambaran dampaknya terhadap keuanganmu.';
  static const String flexibleBudgetLabel = 'Budget fleksibel bulan ini';
  static const String usesBudgetPrefix = 'Pembelian ini menggunakan';
  static const String budgetSuffixNote = 'dari budget fleksibel bulan ini.';
  static const String safeTodayShort = 'Uang aman hari ini';
  static const String afterBuyTitle = 'Jika membeli sekarang:';
  static const String remainingBudgetAfter = 'Sisa budget fleksibel';
  static const String tahanDuluSimulateTitle = 'Kalau saya beli?';
  static const String simulateImpactAction = 'Simulasi Dampak';

  // Reports (Tahap 12 — Laporan Keuangan).
  static const String reportsTitle = 'Laporan Keuangan';
  static const String reportsIncomeLabel = 'Pemasukan';
  static const String reportsExpenseLabel = 'Pengeluaran';
  static const String reportsSavedLabel = 'Ditabung';
  static const String reportsInvestedLabel = 'Investasi';
  static const String reportsRemainingLabel = 'Sisa Dana';
  static const String reportsVsTitle = 'Pemasukan vs Pengeluaran';
  static const String reportsIncomeShort = 'Pemasukan';
  static const String reportsExpenseShort = 'Pengeluaran';
  static const String reportsMonthSummary = 'Ringkasan Bulan Ini';
  static const String reportsWithinBudget =
      'Pengeluaranmu masih berada dalam batas yang direncanakan.';
  static const String reportsOverBudget =
      'Pengeluaranmu melebihi pemasukan bulan ini.';
  static const String seeExpenseDetail = 'Lihat Detail Pengeluaran';
  static const String exportPdf = 'Ekspor PDF';
  static const String exportPreviewTitle = 'Pratinjau PDF';
  static const String exportSuccess = 'PDF berhasil dibagikan.';
  static const String exportFailed = 'Gagal mengekspor PDF. Coba lagi.';
  static const String exportNoPreviewTitle = 'Pratinjau tidak tersedia';
  static const String exportNoPreviewBody =
      'Perangkat ini tidak dapat menampilkan pratinjau PDF, '
      'tetapi dokumen tetap bisa diekspor dan dibagikan.';
  static const String fromLastMonth = 'dari bulan lalu';
  static const String totalExpenseLabel = 'Total Pengeluaran';
  static const String tabCategory = 'Kategori';
  static const String tabNeedsWants = 'Kebutuhan vs Keinginan';
  static const String topExpensesTitle = 'Pengeluaran Terbesar';
  static const String needsWantsUnavailableTitle = 'Klasifikasi belum tersedia';
  static const String needsWantsUnavailableBody =
      'Transaksi belum memiliki label kebutuhan vs keinginan, sehingga tab ini hanya menampilkan kategori yang tercatat.';
  static const String savingsInvestTitle = 'Tabungan & Investasi';
  static const String savedThisMonth = 'Ditabung bulan ini';
  static const String investedThisMonth = 'Investasi bulan ini';
  static const String lastSixTitle = 'Perkembangan 6 Bulan Terakhir';
  static const String legendSavings = 'Tabungan';
  static const String legendInvestment = 'Investasi';
  static const String allocationInsightPrefix =
      'Bulan ini kamu berhasil mengalokasikan';
  static const String allocationInsightSuffix = 'untuk tabungan dan investasi.';
  static const String noAllocationYet =
      'Belum ada alokasi tabungan atau investasi pada periode ini.';
  static const String healthTitle = 'Kesehatan Keuangan';
  static const String healthInsufficientHint =
      'Data belum cukup untuk menilai kondisi keuanganmu.';
  static const String healthGoodBody =
      'Kondisi keuanganmu bulan ini cukup baik. Pertahankan konsistensimu!';
  static const String healthIndicatorSpending = 'Pengeluaran terkendali';
  static const String healthIndicatorSavings = 'Tabungan berjalan';
  static const String healthIndicatorBudget = 'Sisa anggaran tersedia';
  static const String healthIndicatorGoals = 'Progres target';
  static const String healthInsightTitle = 'Insight untukmu';
  static const String seeRecommendations = 'Lihat Rekomendasi';
  static const String recommendationsTitle = 'Rekomendasi';
  static const String recommendationsNote =
      'Saran umum berbasis aturan dari datamu, bukan nasihat finansial profesional.';
  static const String emptyChartData = 'Belum ada data pada periode ini.';
  static const String simulateSubtitle =
      'Simulasikan dampaknya sebelum memutuskan.';
  static const String currentStateTitle = 'Kondisi saat ini';
  static const String afterBuyStateTitle = 'Setelah membeli';
  static const String goalImpactLabel = 'Target investasi';
  static const String dailyBudgetLabel = 'Budget harian';
  static const String nextBudgetLabel = 'Budget harian berikutnya';
  static const String delayEstimatePrefix = 'Mundur ±';
  static const String daySuffix = 'hari';
  static const String safeEstimateDisclaimer =
      'Gambaran estimasi, bukan nasihat finansial.';
  static const String waitTitle = 'Tahan dulu.';
  static const String waitSubtitle = 'Kamu tidak harus memutuskan sekarang.';
  static const String waitDurationLabel = 'Masa tunggu';
  static const String wait24 = '24 Jam';
  static const String wait48 = '48 Jam';
  static const String wait7d = '7 Hari';
  static const String waitCountdownTitle = 'Masih dalam masa tunggu';
  static const String waitReflectTitle = 'Pertanyaan untuk direnungkan';
  static const String waitReflectQ1 = 'Apakah kamu benar-benar membutuhkannya?';
  static const String waitReflectQ2 =
      'Apakah kamu sudah punya barang yang serupa?';
  static const String waitFrequencyLabel = 'Seberapa sering akan digunakan?';
  static const String waitFrequencyDaily = 'Setiap hari';
  static const String waitNotifyNote =
      'Setelah masa tunggu selesai, kami akan mengingatkanmu.';
  static const String saveAndWaitAction = 'Simpan & Tunggu';
  static const String expiredTitle = 'Masa tunggu sudah selesai.';
  static const String decideTitle = 'Masih ingin membelinya?';
  static const String decideSubtitle = 'Masa tunggu sudah selesai.';
  static const String decideBuy = 'Beli Sekarang';
  static const String decideBuyDesc =
      'Lanjutkan pembelian dan catat sebagai transaksi.';
  static const String decideSnooze = 'Tunda Lagi';
  static const String decideSnoozeDesc = 'Pilih waktu tunggu lain.';
  static const String decideWishlist = 'Simpan Wishlist';
  static const String decideWishlistDesc = 'Simpan untuk nanti.';
  static const String decideCancel = 'Tidak Jadi';
  static const String decideCancelDesc = 'Hapus dari daftar.';
  static const String decideImpactTitle = 'Dampak jika beli sekarang';
  static const String boughtBadge = 'Sudah dibeli';
  static const String cancelledBadge = 'Dibatalkan';
  static const String finalDecisionNote =
      'Keputusan sudah final untuk barang ini.';
  static const String confirmBuyTitle = 'Beli barang ini?';
  static const String confirmBuyBody =
      'Keputusan membeli akan disimpan. Transaksi tidak tercatat otomatis.';
  static const String confirmCancelTitle = 'Batalkan barang ini?';
  static const String confirmCancelBody =
      'Barang akan ditandai selesai dan keluar dari daftar tunggu.';
  static const String successBuyTitle = 'Pembelian dikonfirmasi';
  static const String successBuySubtitle =
      'Keputusan membeli telah disimpan. Catat transaksinya agar saldo ikut tercatat.';
  static const String seeTransactionsAction = 'Lihat Transaksi';
  static const String waitRemainingHours = 'jam lagi';
  static const String waitRemainingDays = 'hari lagi';
  static const String waitExpired = 'Selesai';
  static const String productCatFashion = 'Fashion';
  static const String productCatElectronics = 'Elektronik';
  static const String productCatFood = 'Makanan';
  static const String productCatTransport = 'Transportasi';
  static const String productCatEntertainment = 'Hiburan';
  static const String productCatHousehold = 'Rumah tangga';
  static const String productCatEducation = 'Pendidikan';
  static const String productCatOthers = 'Lainnya';
  static const String navHome = 'Home';
  static const String navTransactions = 'Transaksi';
  static const String navRecord = 'Catat';
  static const String navGoals = 'Tujuan';
  static const String navProfile = 'Profil';

  // Accounts (Tahap 9 — Akun Keuangan).
  static const String accountsTitle = 'Akun Keuangan';
  static const String accountsSubtitle =
      'Kelola semua sumber uangmu dalam satu tempat.';
  static const String totalBalanceLabel = 'Total Saldo';
  static const String accountsListTitle = 'Daftar Akun';
  static const String addAccount = '+ Tambah Akun';
  static const String addAccountTitle = 'Tambah Akun';
  static const String chooseAccountType = 'Pilih jenis akun';
  static const String accountName = 'Nama Akun';
  static const String accountNameHint = 'cth. BCA';
  static const String accountTypeLabel = 'Jenis Akun';
  static const String institutionName = 'Nama Institusi';
  static const String institutionHint = 'cth. Bank Central Asia';
  static const String accountNameRequired = 'Nama akun wajib diisi.';
  static const String saveAccount = 'Simpan Akun';
  static const String accountSavedHint =
      'Saldo akan digunakan untuk perhitungan transaksi, budget, dan laporan keuangan.';
  static const String accountDetailTitle = 'Detail Akun';
  static const String currentBalanceLabel = 'Saldo saat ini';
  static const String recordedBalanceHint =
      'Saldo berdasarkan transaksi yang tercatat.';
  static const String transferAction = 'Transfer';
  static const String transferComingSoon =
      'Fitur transfer antar akun akan tersedia pada tahap berikutnya.';
  static const String editAccountTitle = 'Edit Akun';
  static const String saveChanges = 'Simpan Perubahan';
  static const String deleteAccount = 'Hapus Akun';
  static const String deleteAccountTitle = 'Hapus akun ini?';
  static const String deleteAccountBlocked =
      'Akun memiliki transaksi tercatat dan tidak dapat dihapus agar riwayat tetap utuh.';
  static const String recentTransactionsTitle = 'Transaksi Terbaru';
  static const String seeAllAction = 'Lihat Semua >';
  static const String emptyAccounts = 'Belum ada akun';
  static const String emptyAccountsHint =
      'Tambahkan akun pertamamu untuk mulai mencatat.';
  static const String emptyAccountTransactions =
      'Belum ada transaksi untuk akun ini.';
  static const String accountNotFound = 'Akun tidak ditemukan.';
  static const String accountFilterPrefix = 'Akun:';
  static const String promoTitle = 'Kelola akun dengan lebih mudah';
  static const String promoSubtitle =
      'Semua transaksi akun otomatis memperbarui saldo akun kamu.';
  static const String recordedBalance = 'Saldo Tercatat';
  static const String income = 'Pemasukan';
  static const String expense = 'Pengeluaran';
  static const String saving = 'Tabungan';
  static const String investment = 'Investasi';
  static const String remaining = 'Sisa';
  static const String safeSpendingToday = 'Batas Aman Hari Ini';
  static const String seeAll = 'Lihat Semua';

  // Generic.
  static const String retry = 'Coba Lagi';
  static const String loadFailed = 'Gagal memuat data.';
  static const String emptyTitle = 'Belum ada data';
  static const String emptySubtitle = 'Data akan muncul di sini.';

  // Notifications (Tahap 13 — Reminder & Notification).
  static const String notificationsTitle = 'Notifikasi';
  static const String notifTabAll = 'Semua';
  static const String notifTabUnread = 'Belum Dibaca';
  static const String notifTabReminder = 'Pengingat';
  static const String notifMarkAllRead = 'Tandai semua sudah dibaca';
  static const String notifToday = 'Hari ini';
  static const String notifYesterday = 'Kemarin';
  static const String notifEmpty = 'Belum ada notifikasi';
  static const String notifEmptyHint =
      'Semua pengingat keuanganmu akan muncul di sini.';
  static const String notifEmptyUnread = 'Semua sudah dibaca';
  static const String notifEmptyUnreadHint =
      'Tidak ada notifikasi yang belum dibaca.';
  static const String notifEmptyReminder = 'Belum ada pengingat';
  static const String notifEmptyReminderHint =
      'Pengingat keuanganmu akan muncul di sini.';
  static const String notifMenuSettings = 'Pengaturan notifikasi';
  static const String notifMenuMarkAll = 'Tandai semua sudah dibaca';
  static const String notifMarkedRead = 'Notifikasi ditandai sudah dibaca.';
  static const String notifAllMarkedRead =
      'Semua notifikasi ditandai sudah dibaca.';

  // Notification settings.
  static const String notifSettingsTitle = 'Pengaturan Notifikasi';
  static const String notifHeroTitle = 'Tetap update';
  static const String notifHeroSubtitle =
      'Pengingat dan info keuanganmu, dalam satu tempat.';
  static const String notifActiveTitle = 'Notifikasi Aktif';
  static const String notifActiveDesc =
      'Kamu akan menerima pengingat sesuai pengaturan yang dipilih.';
  static const String notifFinanceSection = 'Pengingat Keuangan';
  static const String notifInfo =
      'Notifikasi akan dikirim berdasarkan data yang kamu masukkan di aplikasi.';
  static const String reminderSalaryTitle = 'Pengingat Gaji';
  static const String reminderSalaryDesc =
      'Pengingat saat tanggal gajian tiba.';
  static const String reminderSavingsTitle = 'Pengingat Menabung';
  static const String reminderSavingsDesc =
      'Pengingat untuk menyisihkan uang sesuai target.';
  static const String reminderBillsTitle = 'Pengingat Tagihan';
  static const String reminderBillsDesc =
      'Pengingat sebelum pembayaran jatuh tempo.';
  static const String reminderBudgetTitle = 'Pengingat Budget';
  static const String reminderBudgetDesc =
      'Beritahu jika pengeluaran mendekati batas.';
  static const String reminderTahanDuluTitle = 'TahanDulu';
  static const String reminderTahanDuluDesc =
      'Pengingat saat waktu tunggu pembelian selesai.';
  static const String reminderOverspendTitle = 'Pengeluaran Berlebih';
  static const String reminderOverspendDesc =
      'Beritahu jika pengeluaran mulai melebihi rencana.';
  static const String reminderDetailComingSoon =
      'Konfigurasi khusus jenis ini segera hadir. Toggle tetap tersimpan.';

  // Saving reminder detail.
  static const String savingReminderTitle = 'Pengingat Menabung';
  static const String savingReminderIntro =
      'Atur jadwal pengingat untuk menyisihkan uang sesuai target.';
  static const String savingStatusLabel = 'Status';
  static const String savingStatusActive = 'Aktif';
  static const String savingStatusInactive = 'Nonaktif';
  static const String savingStatusHint =
      'Pengingat ini akan dikirim sesuai jadwal.';
  static const String savingTargetLabel = 'Target Tabungan';
  static const String savingTargetHint = 'Pilih target';
  static const String savingTargetEmpty =
      'Belum ada target. Buat target terlebih dahulu.';
  static const String savingTargetAction = 'Buka Target Keuangan';
  static const String savingAmountLabel = 'Jumlah Pengingat';
  static const String savingAmountHint = 'Jumlah yang ingin kamu sisihkan.';
  static const String savingAmountRequired = 'Masukkan nominal yang valid.';
  static const String savingFrequencyLabel = 'Frekuensi';
  static const String savingFrequencyDaily = 'Harian';
  static const String savingFrequencyWeekly = 'Mingguan';
  static const String savingFrequencyMonthly = 'Bulanan';
  static const String savingDateLabel = 'Tanggal';
  static const String savingWeekdayLabel = 'Hari';
  static const String savingShortMonthHint =
      'Pada bulan pendek, pengingat dikirim di hari terakhir.';
  static const String savingDailyHint = 'Pengingat dikirim setiap hari.';
  static const String savingTimeLabel = 'Waktu';
  static const String savingSaveAction = 'Simpan Pengaturan';
  static const String savingDeactivateAction = 'Nonaktifkan Pengingat';
  static const String savingSaved = 'Pengaturan pengingat disimpan.';
  static const String savingSaveFailed = 'Gagal menyimpan. Coba lagi.';
  static const String savingDeactivated = 'Pengingat dinonaktifkan.';
  static const String savingEveryMonthSuffix = 'setiap bulan';

  // Profile (Tahap 14 — Profil & Pengaturan).
  static const String profileTitle = 'Profil';
  static const String profileSubtitle = 'Kelola akun dan preferensi kamu';
  static const String profileBadge = 'Pengguna TahanDulu';
  static const String profileEditAction = 'Edit Profil';
  static const String profileEmailUnavailable = 'Email belum tersedia';
  static const String profileJourneyTitle = 'Perjalanan Keuanganmu';
  static const String profileJourneySubtitle =
      'Ringkasan aktivitas keuangan di TahanDulu';
  static const String profileStatGoals = 'Target\nAktif';
  static const String profileStatAccounts = 'Akun\nKeuangan';
  static const String profileStatTransactions = 'Transaksi\nTercatat';
  static const String profileAccountSection = 'Pengaturan Akun';
  static const String profileMenuInfo = 'Informasi Profil';
  static const String profileMenuInfoDesc = 'Nama, email, dan informasi akun';
  static const String profileMenuApp = 'Pengaturan Aplikasi';
  static const String profileMenuAppDesc = 'Preferensi dan tampilan aplikasi';
  static const String profileMenuNotif = 'Pengingat & Notifikasi';
  static const String profileMenuNotifDesc = 'Kelola pengingat keuangan';
  static const String profileMenuSecurity = 'Keamanan Akun';
  static const String profileMenuSecurityDesc =
      'Pengaturan keamanan dan metode login';
  static const String profileMenuPrivacy = 'Privasi';
  static const String profileMenuPrivacyDesc = 'Data, privasi, dan akun';
  static const String profileMenuHelp = 'Bantuan & Dukungan';
  static const String profileMenuHelpDesc = 'Jawaban atas pertanyaan umum';
  static const String profileMenuAbout = 'Tentang TahanDulu';
  static const String profileMenuAboutDesc = 'Versi dan informasi aplikasi';
  static const String profileLogoutAction = 'Keluar Akun';
  static const String profileTipsTitle = 'Tips Keuangan';
  static const String profileTipsBody =
      'Catat setiap transaksi agar laporan dan rencanamu selalu akurat.';

  // Edit profil.
  static const String editProfileTitle = 'Edit Profil';
  static const String editProfilePhoto = 'Ubah Foto';
  static const String editProfilePhotoSoon =
      'Ubah foto profil segera hadir. Gunakan versi ini tanpa foto.';
  static const String editProfileName = 'Nama Lengkap';
  static const String editProfileNameHint = 'cth. Bayu Firmansyah';
  static const String editProfileNameRequired = 'Nama wajib diisi.';
  static const String editProfileEmailFrozen =
      'Email tidak dapat diubah saat ini.';
  static const String editProfileBio = 'Tentang Saya (Opsional)';
  static const String editProfileBioHint =
      'Ceritakan sedikit tentang tujuan keuanganmu.';
  static const String editProfileBioTooLong = 'Maksimal 120 karakter.';
  static const String editProfileSave = 'Simpan Perubahan';
  static const String editProfileCancel = 'Batal';
  static const String editProfileSaved = 'Profil berhasil diperbarui.';
  static const String editProfileFailed = 'Gagal menyimpan. Coba lagi.';

  // Pengaturan aplikasi.
  static const String appSettingsTitle = 'Pengaturan Aplikasi';
  static const String appSettingsDisplay = 'Tampilan';
  static const String appSettingsThemeSystem = 'Ikuti Sistem';
  static const String appSettingsThemeLight = 'Terang';
  static const String appSettingsThemeDark = 'Gelap';
  static const String appSettingsSoonBadge = 'Segera';
  static const String appSettingsDarkSoon =
      'Mode gelap segera hadir dan belum dapat dipilih.';
  static const String appSettingsPrefs = 'Preferensi';
  static const String appSettingsLanguage = 'Bahasa Aplikasi';
  static const String appSettingsLanguageValue = 'Bahasa Indonesia';
  static const String appSettingsLanguageInfo =
      'Saat ini hanya Bahasa Indonesia yang didukung.';
  static const String appSettingsCurrency = 'Mata Uang';
  static const String appSettingsCurrencyValue = 'Rupiah (IDR)';
  static const String appSettingsCurrencyInfo =
      'Rupiah adalah satu-satunya mata uang yang didukung.';
  static const String appSettingsExperience = 'Pengalaman Pengguna';
  static const String appSettingsMotion = 'Animasi Ringan';
  static const String appSettingsMotionDesc =
      'Kurangi animasi untuk pengalaman yang lebih ringan.';
  static const String appSettingsInAppNotif = 'Notifikasi dalam Aplikasi';
  static const String appSettingsInAppNotifDesc =
      'Tampilkan notifikasi penting di aplikasi.';
  static const String appSettingsTips = 'Tips Keuangan';
  static const String appSettingsTipsDesc =
      'Tampilkan tips dan edukasi keuangan.';
  static const String appSettingsSessionNote =
      'Preferensi tersimpan sementara di aplikasi dan akan diatur ulang '
      'saat aplikasi dimulai ulang.';

  // Keamanan akun.
  static const String securityTitle = 'Keamanan Akun';
  static const String securitySummaryTitle = 'Akun Kamu Aman';
  static const String securitySummaryDesc =
      'Pastikan informasi akun tetap aman dengan pengaturan keamanan '
      'yang tepat.';
  static const String securityLoginSection = 'Metode Login';
  static const String securityLoginEmail = 'Login dengan Email';
  static const String securityLoginGoogle = 'Login dengan Google';
  static const String securityActiveBadge = 'Aktif';
  static const String securityNoSessionTitle = 'Belum ada sesi masuk';
  static const String securityNoSessionDesc =
      'Informasi login akan muncul setelah kamu masuk ke akunmu.';
  static const String securityLoginAction = 'Masuk';
  static const String securityChangePassword = 'Ubah Kata Sandi';
  static const String securityChangePasswordDesc =
      'Perbarui kata sandi akun kamu';
  static const String securityPasswordUnavailableTitle =
      'Ubah kata sandi belum tersedia';
  static const String securityPasswordUnavailableBody =
      'Perubahan kata sandi belum didukung pada versi ini karena belum ada '
      'layanan backend. Fitur ini akan hadir setelah autentikasi server '
      'tersedia.';
  static const String securityGooglePasswordNote =
      'Tidak tersedia untuk login Google.';
  static const String securitySessions = 'Kelola Sesi';
  static const String securitySessionsDesc = 'Lihat dan kelola perangkat aktif';
  static const String securitySessionsSoon =
      'Manajemen sesi membutuhkan backend dan segera hadir.';
  static const String securityAccountSection = 'Aksi Akun';
  static const String securityLogout = 'Keluar dari Akun';
  static const String securityLogoutDesc = 'Keluar dari aplikasi ini';
  static const String securityTipsTitle = 'Tips Keamanan';
  static const String securityTipsBody =
      'Gunakan kata sandi yang kuat dan jangan bagikan informasi akun '
      'kamu kepada orang lain.';

  // Privasi.
  static const String privacyTitle = 'Privasi';
  static const String privacyIntroTitle = 'Privasi Kamu Penting';
  static const String privacyIntroDesc =
      'Kami berkomitmen untuk menjaga keamanan dan privasi data kamu.';
  static const String privacyDataSection = 'Data dan Privasi';
  static const String privacyPolicy = 'Kebijakan Privasi';
  static const String privacyPolicyDesc =
      'Pelajari bagaimana kami melindungi data kamu';
  static const String privacyPolicyBody =
      'TahanDulu menyimpan data keuanganmu di aplikasi ini. Pada versi ini '
      'belum ada server atau sinkronisasi cloud, sehingga datamu tidak '
      'dikirim ke mana pun. Kami tidak menjual data dan tidak menjalankan '
      'pelacakan iklan. Kebijakan lengkap akan diterbitkan bersama layanan '
      'backend.';
  static const String privacyDataUsage = 'Penggunaan Data';
  static const String privacyDataUsageDesc =
      'Informasi tentang data yang kami kumpulkan';
  static const String privacyDataUsageBody =
      'Data yang dipakai aplikasi: profil (nama, email, bio), transaksi '
      'yang kamu catat, akun keuangan, target, barang TahanDulu, serta '
      'preferensi tampilan dan pengingat. Seluruhnya tersimpan lokal '
      'sementara di perangkat dan dipakai hanya untuk fitur aplikasi.';
  static const String privacyDelete = 'Hapus Akun';
  static const String privacyDeleteDesc = 'Hapus akun dan semua data kamu';
  static const String privacyDeleteUnavailable =
      'Hapus akun belum tersedia pada versi ini. Tidak ada data yang '
      'dihapus.';

  // Bantuan.
  static const String helpTitle = 'Bantuan & Dukungan';
  static const String helpHeadline = 'Ada yang bisa kami bantu?';
  static const String helpSubtitle =
      'Temukan jawaban untuk pertanyaan umum atau hubungi kami jika masih '
      'perlu bantuan.';
  static const String helpSearchHint = 'Cari bantuan...';
  static const String helpCategoryTitle = 'Kategori Bantuan';
  static const String helpEmptyTitle = 'Tidak ditemukan';
  static const String helpEmptySubtitle =
      'Coba kata kunci lain yang berkaitan dengan fitur TahanDulu.';
  static const String helpStillNeed = 'Masih butuh bantuan?';
  static const String helpStillNeedDesc =
      'Tim dukungan masih dalam persiapan. Kamu akan segera dapat '
      'menghubungi kami dari sini.';
  static const String helpContactAction = 'Hubungi Dukungan';
  static const String helpContactSoon =
      'Dukungan langsung segera hadir. Sementara ini jelajahi FAQ di atas.';

  // Tentang.
  static const String aboutTitle = 'Tentang TahanDulu';
  static const String aboutTagline =
      'Atur uang. Capai tujuan. Pikir sebelum beli.';
  static const String aboutVersionPrefix = 'Versi';
  static const String aboutDescription =
      'TahanDulu adalah aplikasi personal finance yang membantumu mengelola '
      'keuangan, mencapai tujuan finansial, dan membuat keputusan pembelian '
      'yang lebih bijak.';
  static const String aboutTerms = 'Syarat dan Ketentuan';
  static const String aboutTermsBody =
      'Dengan memakai TahanDulu versi ini, kamu memahami bahwa aplikasi '
      'berjalan dengan data lokal sementara tanpa backend. Angka yang '
      'ditampilkan adalah hasil perhitungan dari data yang kamu masukkan. '
      'Syarat lengkap akan diterbitkan bersama layanan resmi.';
  static const String aboutLicenses = 'Lisensi Open Source';
  static const String aboutLicensesDesc = 'Pustaka open source yang digunakan';
  static const String aboutLicensesBody =
      'Dibangun dengan Flutter dan paket open source: flutter_riverpod, '
      'go_router, intl, equatable, dan cupertino_icons.';
  static const String aboutCopyright = '© 2026 TahanDulu';

  // Dialog keluar & hapus.
  static const String logoutDialogTitle = 'Keluar dari akun?';
  static const String logoutDialogBody =
      'Kamu akan keluar dari akun ini dan harus login kembali untuk '
      'mengakses data keuangan kamu.';
  static const String logoutCancel = 'Batal';
  static const String logoutConfirm = 'Keluar';
  static const String deleteDialogTitle = 'Hapus akun?';
  static const String deleteDialogBody =
      'Tindakan ini tidak dapat dibatalkan. Semua data kamu, termasuk '
      'transaksi, target, dan pengaturan, akan dihapus secara permanen.';
  static const String deleteConfirm = 'Ya, Hapus Akun';

  // Target tak dikenal (mis. goal onboarding dari Dashboard).
  static const String goalNotFound = 'Target tidak ditemukan.';
  static const String goalNotFoundAction = 'Lihat Target';

  // Keamanan: info metode login sesi.
  static const String securityMethodInfoBody =
      'Sesi ini memakai metode login di atas. Keluar lalu masuk kembali '
      'untuk mengganti metode login.';
}
