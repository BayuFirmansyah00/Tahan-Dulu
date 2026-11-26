/// Path asset terpusat. Satu lokasi: assets/.
/// Ilustrasi dipakai untuk: Login, Onboarding, TahanDulu, Success/Confirmation.
abstract final class AppAssets {
  static const String _illustrations = 'assets/illustrations';
  static const String _icons = 'assets/icons';
  static const String _branding = 'assets/branding';
  static const String _animations = 'assets/animations';

  /// Logo TahanDulu — dipakai di Splash, Login, Register.
  static const String logo = '$_branding/tahan_dulu_logo.webp';

  /// Animasi Lottie splash screen resmi TahanDulu (512x512, 2.5s, 30fps).
  static const String splashAnimation = '$_animations/tahan_dulu_splash.json';

  // TODO: ganti ke '$_illustrations/login_illustration.webp' saat file
  // tersedia. Sementara memakai income_setup.webp yang artwork-nya sama
  // dengan ilustrasi Login pada desain (orang + HP + grafik + target + Rp).
  static const String loginIllustration = '$_illustrations/income_setup.webp';
  static const String incomeSetupIllustration =
      '$_illustrations/income_setup1.webp';
  static const String successIllustration =
      '$_illustrations/financial_plan_success.webp';

  /// Hero dashboard: pria duduk santai (latar gelap menyatu di kartu).
  static const String safeBudgetHero = '$_illustrations/safe_budget_hero.webp';

  /// Banner TahanDulu: keranjang + bubble teks Indonesia.
  static const String tahanDuluBanner =
      '$_illustrations/tahan_dulu_illustration.webp';

  /// Header ilustrasi Reports (terverifikasi transparan di disk).
  /// Dipakai sebagai aksen proporsional, bukan background penuh.
  static const String headerLaporanKeuangan =
      '$_illustrations/header_laporan_keuangan.webp';
  static const String headerPengeluaran =
      '$_illustrations/header_pengeluaran.webp';
  static const String headerKesehatanKeuangan =
      '$_illustrations/header_kesehatan_keuangan.webp';
  static const String headerTabunganInvestasi =
      '$_illustrations/header_tabungan_investasi.webp';

  /// Celengan biru untuk baris target kategori investasi.
  static const String goalsPiggy =
      '$_illustrations/financial_goals_illustration.webp';

  /// Ikon 3D dashboard (set HD transparan, assets/icons).
  /// Dipakai untuk baris transaksi, ringkasan, shortcut, saldo, target.
  static const String navTransaction = '$_icons/icon_transaction.webp';
  static const String navTarget = '$_icons/icon_goal_target.webp';
  static const String navBack = '$_icons/icon_navigate_back.webp';
  static const String navForward = '$_icons/icon_navigate_forward.webp';
  static const String navDown = '$_icons/icon_navigate_down.webp';
  static const String navMore = '$_icons/icon_more_vertical.webp';
  static const String actionAddMoney = '$_icons/icon_add_money.webp';
  static const String actionEdit = '$_icons/icon_edit.webp';
  static const String actionDelete = '$_icons/icon_delete.webp';
  static const String actionRefresh = '$_icons/icon_refresh.webp';
  static const String actionCalendar = '$_icons/icon_calendar.webp';
  static const String actionHistory = '$_icons/icon_history.webp';
  static const String actionSimulation = '$_icons/icon_simulation.webp';
  static const String statusSuccess = '$_icons/icon_status_success.webp';
  static const String statusInfo = '$_icons/icon_status_info.webp';
  static const String statusWarning = '$_icons/icon_status_warning.webp';
  static const String statusError = '$_icons/icon_status_error.webp';
  static const String txTransfer = '$_icons/icon_transfer.webp';
  static const String txArrowUp = '$_icons/icon_arrow_up.webp';
  static const String txArrowDown = '$_icons/icon_arrow_down.webp';
  static const String txArrowTransfer = '$_icons/icon_arrow_transfer.webp';
  static const String txWallet = '$_icons/icon_wallet.webp';
  static const String instBank = '$_icons/icon_payment.webp';
  static const String instEwallet = '$_icons/icon_wallet.webp';
  static const String instCash = '$_icons/financial_wallet.webp';
  static const String txFood = '$_icons/icon_food.webp';
  static const String txShopping = '$_icons/icon_shopping.webp';
  static const String txTransport = '$_icons/icon_transport.webp';
  static const String txEntertainment = '$_icons/icon_entertainment.webp';
  static const String txEducation = '$_icons/icon_education.webp';
  static const String txBills = '$_icons/icon_payment.webp';
  static const String txInvestment = '$_icons/icon_investment_sprout.webp';
  static const String txSavings = '$_icons/icon_savings.webp';
  static const String txHealth = '$_icons/icon_health.webp';
  static const String txGift = '$_icons/icon_gift.webp';
  static const String dashWallet = '$_icons/icon_wallet.webp';
  static const String dashChart = '$_icons/icon_chart.webp';
  static const String goalPiggy = '$_icons/icon_investment_piggybank.webp';
  static const String goalSavings = '$_icons/icon_savings.webp';
  static const String goalHouse = '$_icons/icon_home.webp';
  static const String goalVehicle = '$_icons/icon_transport.webp';
  static const String goalEducation = '$_icons/icon_education.webp';
  static const String goalGadget = '$_icons/icon_entertainment.webp';
  static const String goalHoliday = '$_icons/icon_gift.webp';
  static const String goalEmergency = '$_icons/icon_health.webp';
  static const String goalOthers = '$_icons/icon_goal_target.webp';

  /// Ikon 3D halaman Pengaturan Akun (Tahap 39: konsolidasi ke
  /// assets/icons/, tanpa subfolder).
  /// Dipakai kartu menu ProfileScreen; fallback outline bila gagal muat.
  static const String _settings = _icons;

  /// Ikon & header 3D fitur Goals (Tahap 32, terverifikasi ada di disk;
  /// Tahap 39: konsolidasi ke assets/icons/, tanpa subfolder).
  /// Header: assets/illustrations/header_*.webp (ilustrasi besar).
  /// Ikon: assets/icons/icon_goal_*.webp (BoxFit.contain).
  /// Pemetaan terpusat di goal_category_ui.dart; fallback outline
  /// bila berkas tidak termuat.
  static const String _goalIcons = _icons;
  static const String goalHeaderEmergency =
      '$_illustrations/header_emergency.webp';
  static const String goalHeaderSavings = '$_illustrations/header_savings.webp';
  static const String goalHeaderInvestment =
      '$_illustrations/header_investment.webp';
  static const String goalHeaderHouse = '$_illustrations/header_house.webp';
  static const String goalHeaderVehicle = '$_illustrations/header_vehicle.webp';
  static const String goalHeaderGadget = '$_illustrations/header_gadget.webp';
  static const String goalHeaderTravel = '$_illustrations/header_travel.webp';
  static const String goalHeaderEducation =
      '$_illustrations/header_education.webp';
  static const String goalHeaderOthers = '$_illustrations/header_others.webp';
  static const String goalIconEmergency = '$_goalIcons/icon_goal_emergency.webp';
  static const String goalIconSavings = '$_goalIcons/icon_goal_savings.webp';
  static const String goalIconInvestment =
      '$_goalIcons/icon_goal_investment.webp';
  static const String goalIconHouse = '$_goalIcons/icon_goal_house.webp';
  static const String goalIconVehicle = '$_goalIcons/icon_goal_vehicle.webp';
  static const String goalIconGadget = '$_goalIcons/icon_goal_gadget.webp';
  static const String goalIconTravel = '$_goalIcons/icon_goal_travel.webp';
  static const String goalIconEducation = '$_goalIcons/icon_goal_education.webp';
  static const String goalIconOthers = '$_goalIcons/icon_goal_others.webp';

  /// Ikon aksi/status Goals yang transparan & cocok semantik (Tahap 33).
  /// Ikon lain di folder ini berlatar hitam opaque sehingga tidak dipakai
  /// di UI terang (tercatat di laporan, bukan bug).
  static const String goalActionWarning = '$_goalIcons/icon_warning.webp';
  static const String goalActionInfo = '$_goalIcons/icon_info.webp';
  static const String goalActionCalendar = '$_goalIcons/icon_calendar.webp';

  /// Medali & badge peringkat Prioritas Target (Tahap 37).
  /// Terverifikasi transparan di disk; fallback outline bila gagal muat.
  static const String rankMedal1 = '$_goalIcons/rank_1_medal.webp';
  static const String rankMedal2 = '$_goalIcons/rank_2_medal.webp';
  static const String rankMedal3 = '$_goalIcons/rank_3_medal.webp';
  static const String rankBadge4 = '$_goalIcons/rank_4_badge.webp';
  static const String rankBadge5 = '$_goalIcons/rank_5_badge.webp';

  /// Tombol pindah prioritas (Tahap 37, transparan, varian nonaktif abu).
  static const String moveUp = '$_goalIcons/action_move_up.webp';
  static const String moveDown = '$_goalIcons/action_move_down.webp';
  static const String moveUpDisabled =
      '$_goalIcons/action_move_up_disabled.webp';
  static const String moveDownDisabled =
      '$_goalIcons/action_move_down_disabled.webp';

  /// Ikon navigasi Prioritas Target di app bar daftar (Tahap 38).
  /// Terverifikasi transparan di disk (alpha 0 di sudut).
  static const String priorityNavIcon = '$_icons/prioritas.webp';

  /// Header checklist Prioritas Target sesuai referensi (Tahap 40).
  /// Ilustrasi besar; fallback outline bila gagal muat.
  static const String priorityChecklistHeader =
      '$_icons/priority_checklist_header.webp';

  /// Ilustrasi empty state transaksi (Tahap 40, transparan).
  static const String transactionEmptyCheck =
      '$_icons/transaction_empty_check.webp';

  /// Ikon 3D Halaman Pilih Metode Catat Transaksi
  static const String txHero = '$_icons/transaction_hero.webp';
  static const String txMethodManual = '$_icons/input_manual.webp';
  static const String txMethodVoice = '$_icons/input_suara.webp';
  static const String txMethodScan = '$_icons/scan_struk.webp';
  static const String txSecurity = '$_icons/keamanan.webp';

  /// Ikon & ilustrasi 3D Scan Struk
  static const String scanReceiptHero = '$_icons/scan_receipt_3d.webp';
  static const String scanCamera3d = '$_icons/camera_3d.webp';
  static const String scanGallery3d = '$_icons/gallery_3d.webp';
  static const String scanStepCamera = '$_icons/step_camera.webp';
  static const String scanStepRead = '$_icons/step_read.webp';
  static const String scanStepReview = '$_icons/step_review.webp';
  static const String scanShieldCheck = '$_icons/shield_check.webp';
  static const String scanInfoOutline = '$_icons/info_outline.webp';

  /// Ikon & ilustrasi 3D Halaman Tambah Barang
  static const String tambahBarangHero = '$_icons/illustrasi_tambah_barang.webp';
  static const String tambahBarangManual = '$_icons/input_manual_3d.webp';
  static const String tambahBarangLink = '$_icons/link_produk_3d.webp';
  static const String tambahBarangFoto = '$_icons/upload_foto_3d.webp';
  static const String tambahBarangInfo = '$_icons/info_pengingat_3d.webp';

  /// Ikon 3D Navbar V2 (assets/icons/navbar/)
  static const String nav3dHome = '$_icons/beranda.webp';
  static const String nav3dTransaction = '$_icons/transaksi.webp';
  static const String nav3dRecord = '$_icons/catat.webp';
  static const String nav3dGoal = '$_icons/tujuan.webp';
  static const String nav3dProfile = '$_icons/profil.webp';
  static const String setProfile = '$_settings/icon_profile.webp';
  static const String setApp = '$_settings/icon_app_settings.webp';
  static const String setNotif = '$_settings/icon_notifications.webp';

  /// Ikon kategori 3D halaman Notifikasi (audit alpha: sudut transparan).
  /// Dipakai di tile pastel kartu notifikasi + fallback Material.
  static const String ntfSalary = '$_icons/financial_wallet.webp';
  static const String ntfGoal = '$_icons/icon_target.webp';
  static const String ntfBag = '$_icons/icon_shopping_bag.webp';
  static const String ntfPiggy = '$_icons/icon_savings_piggybank.webp';
  static const String ntfBudget = '$_icons/icon_budget_chart.webp';
  static const String ntfOverspend = '$_icons/icon_overspending_alert.webp';
  static const String setSecurity = '$_settings/icon_security.webp';
  static const String setPrivacy = '$_settings/icon_privacy.webp';
  static const String setHelp = '$_settings/icon_help_support.webp';
  static const String setAbout = '$_settings/icon_about.webp';

  /// Dekorasi header Pengaturan Akun (motif gerigi 3D, aset valid).
  static const String setHeader = '$_settings/icon_app_settings.webp';

  /// Ikon 3D kartu pengingat (latar putih).
  /// Ditampilkan utuh di atas kartu putih agar menyatu mulus.
  static const String setWallet = '$_settings/icon_settings_wallet.webp';
  static const String setSavingsPig = '$_settings/icon_savings_piggybank.webp';
  static const String setBills = '$_settings/icon_bills_receipt.webp';
  static const String setBudget = '$_settings/icon_budget_chart.webp';
  static const String setBag = '$_settings/icon_shopping_bag.webp';
  static const String setOverspend = '$_settings/icon_overspending_alert.webp';
  static const String setGoogle = '$_settings/icon_google_login.webp';
  static const String setLogoutIcon = '$_settings/icon_logout.webp';
  static const String setPrivacyPolicy = '$_settings/icon_privacy_policy.webp';
  static const String setDataUsage = '$_settings/icon_data_usage.webp';
  static const String setDeleteAccount = '$_settings/icon_delete_account.webp';
  static const String setTerms = '$_settings/icon_terms.webp';
  static const String setOpenSource = '$_settings/icon_open_source.webp';
  static const String setSession = '$_settings/icon_session.webp';
  static const String setCameraBadge = '$_settings/camera_overlay.webp';

  /// Ilustrasi settings transparan (latar menyatu). *_bg.webp tidak dipakai
  /// sebagai overlay karena background-nya hitam opaque (temuan audit).
  static const String illProfileSummary =
      '$_settingsIll/profile_summary_illustration.webp';
  static const String illEditProfile =
      '$_settingsIll/edit_profile_illustration.webp';

  /// Latar banner Edit Profil (dekorasi mint + daun, tanpa motif orang).
  /// Sudut transparan (audit alpha); tampilkan cover di atas warna mint
  /// agar piksel transparan menyatu. Dipakai sebagai backdrop tepat di
  /// belakang foto profil, bukan overlay ikon.
  static const String illEditProfileBg = '$_settingsIll/edit_profile_bg.webp';
  static const String illAboutApp = '$_settingsIll/about_app_illustration.webp';

  /// Ikon 3D onboarding (terverifikasi visual per file).
  /// Tile pastel bawaan gambar — tampilkan langsung 28–48px di kartu
  /// putih, contain, tanpa ColorFilter. Fallback outline bila gagal muat.
  static const String obSalaryWallet = '$_icons/icon_wallet.webp';
  static const String obBank = '$_icons/icon_payment.webp';
  static const String obDigitalBank = '$_icons/icon_transfer.webp';
  static const String obEWallet = '$_icons/icon_wallet.webp';
  static const String obNeeds = '$_icons/icon_home.webp';
  static const String obTransport = '$_icons/icon_transport.webp';
  static const String obBills = '$_settings/icon_bills_receipt.webp';
  static const String obShopping = '$_icons/icon_shopping.webp';
  static const String obEmergency = '$_icons/icon_savings.webp';
  static const String obGoalSavings = '$_settings/icon_savings_piggybank.webp';
  static const String obInvestment = '$_icons/icon_investment_sprout.webp';
  static const String obHouse = '$_icons/icon_home.webp';
  static const String obEducation = '$_icons/icon_education.webp';
  static const String obHoliday = '$_icons/icon_entertainment.webp';
  static const String obAllocSaving = '$_icons/icon_savings.webp';
  static const String obAllocFlexible = '$_icons/icon_wallet.webp';

  /// Ikon 3D Onboarding V2 (Atur Anggaran Bulanan & Ringkasan Rencana Keuangan)
  static const String ob3dWallet = '$_icons/penghasilan_bulanan.webp';
  static const String ob3dNeeds = '$_icons/kebutuhan_pokok.webp';
  static const String ob3dFlexible = '$_icons/pengeluaran_fleksibel.webp';
  static const String ob3dInvestment = '$_icons/investasi_tabungan.webp';
  static const String ob3dEmergency = '$_icons/dana_darurat.webp';
  static const String ob3dTotalAllocation = '$_icons/total_alokasi.webp';
  static const String ob3dDailyBudget = '$_icons/batas_belanja_harian.webp';
  static const String ob3dEmergencyTarget = '$_icons/target_dana_darurat.webp';
  static const String ob3dRecurring = '$_icons/pengeluaran_rutin.webp';

  /// Banner header settings (assets/illustrations/settings).
  /// Banner jadi dengan teks Indonesia bawaan — tampilkan utuh
  /// (contain, tanpa crop/teks overlay) selebar layar.
  static const String _settingsIll = '$_illustrations/settings';
  static const String illNotifActive =
      '$_settingsIll/header_notification_active.webp';
  static const String illAccountSecurity =
      '$_settingsIll/header_account_security.webp';
  static const String illPrivacy = '$_settingsIll/header_privacy.webp';
  static const String illPrivacyDataSafe =
      '$_settingsIll/header_privacy_data_safe.webp';
  static const String illSecurityTips =
      '$_settingsIll/header_security_tips.webp';

  // -----------------------------------------------------------------
  // TahanDulu Tahap 46 — ikon kategori 3D + header/ilustrasi hero.
  // Semua path di bawah terverifikasi ada di disk (audit 15/10/2026).
  // Ikon metode input 3D (manual/link/foto) TIDAK ada di disk sehingga
  // tidak didaftarkan di sini — layar memakai ikon Material + pastel.
  // -----------------------------------------------------------------

  /// Header hero TahanDulu (kartu kuning lembut, contain, sisi kanan).
  static const String tdHeaderList = '$_illustrations/header_tahandulu.webp';
  static const String tdHeaderAdd = '$_illustrations/header_tambah_barang.webp';
  static const String tdHeaderLink = '$_illustrations/header_link_produk.webp';
  static const String tdHeaderAnalysis =
      '$_illustrations/header_analisis_pembelian.webp';
  static const String tdHeaderSimulate =
      '$_illustrations/header_simulasi_dampak.webp';
  static const String tdHeaderWait = '$_illustrations/header_masa_tunggu.webp';

  /// Ilustrasi pendukung kecil (fallback hero bila header gagal muat).
  static const String tdIllBag =
      '$_illustrations/illustration_tas_tahandulu.webp';
  static const String tdIllAnalysis =
      '$_illustrations/illustration_analisis.webp';
  static const String tdIllLink =
      '$_illustrations/illustration_link_produk.webp';
  static const String tdIllCompare =
      '$_illustrations/illustration_perbandingan.webp';
  static const String tdIllPrice =
      '$_illustrations/illustration_produk_harga.webp';
  static const String tdIllWait =
      '$_illustrations/illustration_masa_tunggu.webp';
  static const String tdIllUpload =
      '$_illustrations/illustration_upload_foto.webp';

  /// Ikon kategori produk 3D (satu ikon per kategori, jangan diseragamkan).
  static const String tdCatFashion = '$_icons/icon_kategori_fashion.webp';
  static const String tdCatElectronics = '$_icons/icon_kategori_elektronik.webp';
  static const String tdCatFood = '$_icons/icon_kategori_makanan.webp';
  static const String tdCatTransport = '$_icons/icon_kategori_transportasi.webp';
  static const String tdCatEntertainment = '$_icons/icon_kategori_hiburan.webp';
  static const String tdCatHousehold = '$_icons/icon_kategori_rumah_tangga.webp';
  static const String tdCatEducation = '$_icons/icon_kategori_pendidikan.webp';
  static const String tdCatOthers = '$_icons/icon_kategori_lainnya.webp';

  /// Ikon aksi & keputusan TahanDulu (terverifikasi ada di disk: assets/icons/).
  static const String tdActionBuy = '$_icons/icon_shopping_cart.webp';
  static const String tdActionWait = '$_icons/icon_status_reminder.webp';
  static const String tdActionWishlist = '$_icons/icon_favorite_outline.webp';
  static const String tdPieChart = '$_icons/icon_pie_chart.webp';
  static const String tdFlag = '$_icons/icon_flag.webp';
  static const String tdSuccess = '$_icons/icon_success.webp';
}
