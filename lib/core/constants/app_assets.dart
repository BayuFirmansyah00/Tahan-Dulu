/// Path asset terpusat. Satu lokasi: assets/.
/// Ilustrasi dipakai untuk: Login, Onboarding, TahanDulu, Success/Confirmation.
abstract final class AppAssets {
  static const String _illustrations = 'assets/illustrations';
  static const String _icons = 'assets/icons';
  static const String _branding = 'assets/branding';

  /// Logo TahanDulu — dipakai di Splash, Login, Register.
  static const String logo = '$_branding/tahan_dulu_logo.png';

  // TODO: ganti ke '$_illustrations/login_illustration.png' saat file
  // tersedia. Sementara memakai income_setup.png yang artwork-nya sama
  // dengan ilustrasi Login pada desain (orang + HP + grafik + target + Rp).
  static const String loginIllustration = '$_illustrations/income_setup.png';
  static const String onboardingIllustration = '$_illustrations/onboarding.png';
  static const String tahanDuluIllustration = '$_illustrations/tahan_dulu.png';
  static const String incomeSetupIllustration =
      '$_illustrations/income_setup1.png';
  static const String successIllustration =
      '$_illustrations/financial_plan_success.png';
  static const String emptyIllustration = '$_illustrations/empty.png';

  /// Hero dashboard: pria duduk santai (latar gelap menyatu di kartu).
  static const String safeBudgetHero = '$_illustrations/safe_budget_hero.png';

  /// Banner TahanDulu: keranjang + bubble teks Indonesia.
  static const String tahanDuluBanner =
      '$_illustrations/tahan_dulu_illustration.png';

  /// Header ilustrasi Reports (terverifikasi transparan di disk).
  /// Dipakai sebagai aksen proporsional, bukan background penuh.
  static const String headerLaporanKeuangan =
      '$_illustrations/header_laporan_keuangan.png';
  static const String headerPengeluaran =
      '$_illustrations/header_pengeluaran.png';
  static const String headerKesehatanKeuangan =
      '$_illustrations/header_kesehatan_keuangan.png';
  static const String headerTabunganInvestasi =
      '$_illustrations/header_tabungan_investasi.png';

  /// Celengan biru untuk baris target kategori investasi.
  static const String goalsPiggy =
      '$_illustrations/financial_goals_illustration.png';

  /// Ikon 3D dashboard (set HD transparan, assets/icons).
  /// Dipakai untuk baris transaksi, ringkasan, shortcut, saldo, target.
  static const String navHome = '$_icons/icon_home.png';
  static const String navTransaction = '$_icons/icon_transaction.png';
  static const String navTarget = '$_icons/icon_goal_target.png';
  static const String navProfile = '$_icons/icon_profile.png';
  static const String navBack = '$_icons/icon_navigate_back.png';
  static const String navForward = '$_icons/icon_navigate_forward.png';
  static const String navDown = '$_icons/icon_navigate_down.png';
  static const String navMore = '$_icons/icon_more_vertical.png';
  static const String actionAddMoney = '$_icons/icon_add_money.png';
  static const String actionEdit = '$_icons/icon_edit.png';
  static const String actionDelete = '$_icons/icon_delete.png';
  static const String actionRefresh = '$_icons/icon_refresh.png';
  static const String actionCalendar = '$_icons/icon_calendar.png';
  static const String actionHistory = '$_icons/icon_history.png';
  static const String actionSimulation = '$_icons/icon_simulation.png';
  static const String statusSuccess = '$_icons/icon_status_success.png';
  static const String statusInfo = '$_icons/icon_status_info.png';
  static const String statusWarning = '$_icons/icon_status_warning.png';
  static const String statusError = '$_icons/icon_status_error.png';
  static const String txTransfer = '$_icons/icon_transfer.png';
  static const String txArrowUp = '$_icons/icon_arrow_up.png';
  static const String txArrowDown = '$_icons/icon_arrow_down.png';
  static const String txArrowTransfer = '$_icons/icon_arrow_transfer.png';
  static const String txWallet = '$_icons/icon_wallet.png';
  static const String instBank = '$_icons/icon_payment.png';
  static const String instEwallet = '$_icons/icon_wallet.png';
  static const String instCash = '$_icons/financial_wallet.png';
  static const String txFood = '$_icons/icon_food.png';
  static const String txShopping = '$_icons/icon_shopping.png';
  static const String txTransport = '$_icons/icon_transport.png';
  static const String txEntertainment = '$_icons/icon_entertainment.png';
  static const String txEducation = '$_icons/icon_education.png';
  static const String txBills = '$_icons/icon_payment.png';
  static const String txInvestment = '$_icons/icon_investment_sprout.png';
  static const String txSavings = '$_icons/icon_savings.png';
  static const String txHealth = '$_icons/icon_health.png';
  static const String txGift = '$_icons/icon_gift.png';
  static const String dashWallet = '$_icons/icon_wallet.png';
  static const String dashChart = '$_icons/icon_chart.png';
  static const String goalPiggy = '$_icons/icon_investment_piggybank.png';
  static const String goalSavings = '$_icons/icon_savings.png';
  static const String goalHouse = '$_icons/icon_home.png';
  static const String goalVehicle = '$_icons/icon_transport.png';
  static const String goalEducation = '$_icons/icon_education.png';
  static const String goalGadget = '$_icons/icon_entertainment.png';
  static const String goalHoliday = '$_icons/icon_gift.png';
  static const String goalEmergency = '$_icons/icon_health.png';
  static const String goalOthers = '$_icons/icon_goal_target.png';

  /// Ikon 3D halaman Pengaturan Akun (Tahap 39: konsolidasi ke
  /// assets/icons/, tanpa subfolder).
  /// Dipakai kartu menu ProfileScreen; fallback outline bila gagal muat.
  static const String _settings = _icons;

  /// Ikon & header 3D fitur Goals (Tahap 32, terverifikasi ada di disk;
  /// Tahap 39: konsolidasi ke assets/icons/, tanpa subfolder).
  /// Header: assets/illustrations/header_*.png (ilustrasi besar).
  /// Ikon: assets/icons/icon_goal_*.png (BoxFit.contain).
  /// Pemetaan terpusat di goal_category_ui.dart; fallback outline
  /// bila berkas tidak termuat.
  static const String _goalIcons = _icons;
  static const String goalHeaderEmergency =
      '$_illustrations/header_emergency.png';
  static const String goalHeaderSavings = '$_illustrations/header_savings.png';
  static const String goalHeaderInvestment =
      '$_illustrations/header_investment.png';
  static const String goalHeaderHouse = '$_illustrations/header_house.png';
  static const String goalHeaderVehicle = '$_illustrations/header_vehicle.png';
  static const String goalHeaderGadget = '$_illustrations/header_gadget.png';
  static const String goalHeaderTravel = '$_illustrations/header_travel.png';
  static const String goalHeaderEducation =
      '$_illustrations/header_education.png';
  static const String goalHeaderOthers = '$_illustrations/header_others.png';
  static const String goalIconEmergency = '$_goalIcons/icon_goal_emergency.png';
  static const String goalIconSavings = '$_goalIcons/icon_goal_savings.png';
  static const String goalIconInvestment =
      '$_goalIcons/icon_goal_investment.png';
  static const String goalIconHouse = '$_goalIcons/icon_goal_house.png';
  static const String goalIconVehicle = '$_goalIcons/icon_goal_vehicle.png';
  static const String goalIconGadget = '$_goalIcons/icon_goal_gadget.png';
  static const String goalIconTravel = '$_goalIcons/icon_goal_travel.png';
  static const String goalIconEducation = '$_goalIcons/icon_goal_education.png';
  static const String goalIconOthers = '$_goalIcons/icon_goal_others.png';

  /// Ikon aksi/status Goals yang transparan & cocok semantik (Tahap 33).
  /// Ikon lain di folder ini berlatar hitam opaque sehingga tidak dipakai
  /// di UI terang (tercatat di laporan, bukan bug).
  static const String goalActionWarning = '$_goalIcons/icon_warning.png';
  static const String goalActionInfo = '$_goalIcons/icon_info.png';
  static const String goalActionCalendar = '$_goalIcons/icon_calendar.png';

  /// Medali & badge peringkat Prioritas Target (Tahap 37).
  /// Terverifikasi transparan di disk; fallback outline bila gagal muat.
  static const String rankMedal1 = '$_goalIcons/rank_1_medal.png';
  static const String rankMedal2 = '$_goalIcons/rank_2_medal.png';
  static const String rankMedal3 = '$_goalIcons/rank_3_medal.png';
  static const String rankBadge4 = '$_goalIcons/rank_4_badge.png';
  static const String rankBadge5 = '$_goalIcons/rank_5_badge.png';

  /// Tombol pindah prioritas (Tahap 37, transparan, varian nonaktif abu).
  static const String moveUp = '$_goalIcons/action_move_up.png';
  static const String moveDown = '$_goalIcons/action_move_down.png';
  static const String moveUpDisabled =
      '$_goalIcons/action_move_up_disabled.png';
  static const String moveDownDisabled =
      '$_goalIcons/action_move_down_disabled.png';

  /// Ikon navigasi Prioritas Target di app bar daftar (Tahap 38).
  /// Terverifikasi transparan di disk (alpha 0 di sudut).
  static const String priorityNavIcon = '$_icons/prioritas.png';

  /// Header checklist Prioritas Target sesuai referensi (Tahap 40).
  /// Ilustrasi besar; fallback outline bila gagal muat.
  static const String priorityChecklistHeader =
      '$_icons/priority_checklist_header.png';

  /// Ilustrasi empty state transaksi (Tahap 40, transparan).
  static const String transactionEmptyCheck =
      '$_icons/transaction_empty_check.png';
  static const String setProfile = '$_settings/icon_profile.png';
  static const String setApp = '$_settings/icon_app_settings.png';
  static const String setNotif = '$_settings/icon_notifications.png';

  /// Ikon kategori 3D halaman Notifikasi (audit alpha: sudut transparan).
  /// Dipakai di tile pastel kartu notifikasi + fallback Material.
  static const String ntfSalary = '$_icons/financial_wallet.png';
  static const String ntfGoal = '$_icons/icon_target.png';
  static const String ntfBag = '$_icons/icon_shopping_bag.png';
  static const String ntfPiggy = '$_icons/icon_savings_piggybank.png';
  static const String ntfBudget = '$_icons/icon_budget_chart.png';
  static const String ntfOverspend = '$_icons/icon_overspending_alert.png';
  static const String setSecurity = '$_settings/icon_security.png';
  static const String setPrivacy = '$_settings/icon_privacy.png';
  static const String setHelp = '$_settings/icon_help_support.png';
  static const String setAbout = '$_settings/icon_about.png';

  /// Dekorasi header Pengaturan Akun (motif gerigi 3D, aset valid).
  static const String setHeader = '$_settings/icon_app_settings.png';

  /// Ikon 3D kartu pengingat (latar putih).
  /// Ditampilkan utuh di atas kartu putih agar menyatu mulus.
  static const String setWallet = '$_settings/icon_settings_wallet.png';
  static const String setSavingsPig = '$_settings/icon_savings_piggybank.png';
  static const String setBills = '$_settings/icon_bills_receipt.png';
  static const String setBudget = '$_settings/icon_budget_chart.png';
  static const String setBag = '$_settings/icon_shopping_bag.png';
  static const String setOverspend = '$_settings/icon_overspending_alert.png';
  static const String setGoogle = '$_settings/icon_google_login.png';
  static const String setLogoutIcon = '$_settings/icon_logout.png';
  static const String setPrivacyPolicy = '$_settings/icon_privacy_policy.png';
  static const String setDataUsage = '$_settings/icon_data_usage.png';
  static const String setDeleteAccount = '$_settings/icon_delete_account.png';
  static const String setTerms = '$_settings/icon_terms.png';
  static const String setOpenSource = '$_settings/icon_open_source.png';
  static const String setSession = '$_settings/icon_session.png';
  static const String setCameraBadge = '$_settings/camera_overlay.png';

  /// Ilustrasi settings transparan (latar menyatu). *_bg.png tidak dipakai
  /// sebagai overlay karena background-nya hitam opaque (temuan audit).
  static const String illProfileSummary =
      '$_settingsIll/profile_summary_illustration.png';
  static const String illEditProfile =
      '$_settingsIll/edit_profile_illustration.png';

  /// Latar banner Edit Profil (dekorasi mint + daun, tanpa motif orang).
  /// Sudut transparan (audit alpha); tampilkan cover di atas warna mint
  /// agar piksel transparan menyatu. Dipakai sebagai backdrop tepat di
  /// belakang foto profil, bukan overlay ikon.
  static const String illEditProfileBg = '$_settingsIll/edit_profile_bg.png';
  static const String illAboutApp = '$_settingsIll/about_app_illustration.png';

  /// Ikon 3D onboarding (terverifikasi visual per file).
  /// Tile pastel bawaan gambar — tampilkan langsung 28–48px di kartu
  /// putih, contain, tanpa ColorFilter. Fallback outline bila gagal muat.
  static const String obSalaryWallet = '$_icons/icon_wallet.png';
  static const String obBank = '$_icons/icon_payment.png';
  static const String obDigitalBank = '$_icons/icon_transfer.png';
  static const String obEWallet = '$_icons/icon_wallet.png';
  static const String obNeeds = '$_icons/icon_home.png';
  static const String obTransport = '$_icons/icon_transport.png';
  static const String obBills = '$_settings/icon_bills_receipt.png';
  static const String obShopping = '$_icons/icon_shopping.png';
  static const String obEmergency = '$_icons/icon_savings.png';
  static const String obGoalSavings = '$_settings/icon_savings_piggybank.png';
  static const String obInvestment = '$_icons/icon_investment_sprout.png';
  static const String obHouse = '$_icons/icon_home.png';
  static const String obEducation = '$_icons/icon_education.png';
  static const String obHoliday = '$_icons/icon_entertainment.png';
  static const String obAllocSaving = '$_icons/icon_savings.png';
  static const String obAllocFlexible = '$_icons/icon_wallet.png';

  /// Banner header settings (assets/illustrations/settings).
  /// Banner jadi dengan teks Indonesia bawaan — tampilkan utuh
  /// (contain, tanpa crop/teks overlay) selebar layar.
  static const String _settingsIll = '$_illustrations/settings';
  static const String illNotifActive =
      '$_settingsIll/header_notification_active.png';
  static const String illAccountSecurity =
      '$_settingsIll/header_account_security.png';
  static const String illPrivacy = '$_settingsIll/header_privacy.png';
  static const String illPrivacyDataSafe =
      '$_settingsIll/header_privacy_data_safe.png';
  static const String illSecurityTips =
      '$_settingsIll/header_security_tips.png';

  // -----------------------------------------------------------------
  // TahanDulu Tahap 46 — ikon kategori 3D + header/ilustrasi hero.
  // Semua path di bawah terverifikasi ada di disk (audit 15/10/2026).
  // Ikon metode input 3D (manual/link/foto) TIDAK ada di disk sehingga
  // tidak didaftarkan di sini — layar memakai ikon Material + pastel.
  // -----------------------------------------------------------------

  /// Header hero TahanDulu (kartu kuning lembut, contain, sisi kanan).
  static const String tdHeaderList = '$_illustrations/header_tahandulu.png';
  static const String tdHeaderAdd = '$_illustrations/header_tambah_barang.png';
  static const String tdHeaderLink = '$_illustrations/header_link_produk.png';
  static const String tdHeaderAnalysis =
      '$_illustrations/header_analisis_pembelian.png';
  static const String tdHeaderSimulate =
      '$_illustrations/header_simulasi_dampak.png';
  static const String tdHeaderWait = '$_illustrations/header_masa_tunggu.png';

  /// Ilustrasi pendukung kecil (fallback hero bila header gagal muat).
  static const String tdIllBag =
      '$_illustrations/illustration_tas_tahandulu.png';
  static const String tdIllAnalysis =
      '$_illustrations/illustration_analisis.png';
  static const String tdIllLink =
      '$_illustrations/illustration_link_produk.png';
  static const String tdIllCompare =
      '$_illustrations/illustration_perbandingan.png';
  static const String tdIllPrice =
      '$_illustrations/illustration_produk_harga.png';
  static const String tdIllWait =
      '$_illustrations/illustration_masa_tunggu.png';
  static const String tdIllUpload =
      '$_illustrations/illustration_upload_foto.png';

  /// Ikon kategori produk 3D (satu ikon per kategori, jangan diseragamkan).
  static const String tdCatFashion = '$_icons/icon_kategori_fashion.png';
  static const String tdCatElectronics = '$_icons/icon_kategori_elektronik.png';
  static const String tdCatFood = '$_icons/icon_kategori_makanan.png';
  static const String tdCatTransport = '$_icons/icon_kategori_transportasi.png';
  static const String tdCatEntertainment = '$_icons/icon_kategori_hiburan.png';
  static const String tdCatHousehold = '$_icons/icon_kategori_rumah_tangga.png';
  static const String tdCatEducation = '$_icons/icon_kategori_pendidikan.png';
  static const String tdCatOthers = '$_icons/icon_kategori_lainnya.png';

  /// Ikon aksi & keputusan TahanDulu (terverifikasi ada di disk: assets/icons/).
  static const String tdActionBuy = '$_icons/icon_shopping_cart.png';
  static const String tdActionWait = '$_icons/icon_status_reminder.png';
  static const String tdActionWishlist = '$_icons/icon_favorite_outline.png';
  static const String tdPieChart = '$_icons/icon_pie_chart.png';
  static const String tdFlag = '$_icons/icon_flag.png';
  static const String tdSuccess = '$_icons/icon_success.png';
}
