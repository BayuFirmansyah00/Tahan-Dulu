import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/financial_instrument.dart';
import '../../../../data/providers/onboarding_providers.dart';

/// State No.4: daftar instrumen + pilihan sebagai source of truth.
class InstrumentsState extends Equatable {
  const InstrumentsState({required this.instruments, this.isSaving = false});

  final List<FinancialInstrument> instruments;
  final bool isSaving;

  /// Instrumen terpilih (untuk validasi & langkah berikutnya).
  List<FinancialInstrument> get selected =>
      instruments.where((e) => e.isSelected).toList();

  /// Bank terpilih pertama — pemilik panel "Detail instrumen".
  FinancialInstrument? get focusedBank {
    for (final e in selected) {
      if (e.type == InstrumentType.bank) return e;
    }
    return null;
  }

  bool get canContinue => selected.isNotEmpty && !isSaving;

  InstrumentsState copyWith({
    List<FinancialInstrument>? instruments,
    bool? isSaving,
  }) {
    return InstrumentsState(
      instruments: instruments ?? this.instruments,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [instruments, isSaving];
}

/// Controller No.4: pilih, ubah fee, tambah instrumen, simpan.
/// Data No.3 tidak disentuh — repository hanya menulis field instrumen.
class InstrumentsController extends Notifier<InstrumentsState> {
  @override
  InstrumentsState build() {
    final saved = ref.read(onboardingRepositoryProvider).getOnboardingData();
    return InstrumentsState(
      instruments: List.of(saved?.financialInstruments ?? const []),
    );
  }

  void toggleSelect(String id) {
    state = state.copyWith(
      instruments: [
        for (final e in state.instruments)
          if (e.id == id) e.copyWith(isSelected: !e.isSelected) else e,
      ],
    );
  }

  void updateAdminFee(String id, double fee) {
    state = state.copyWith(
      instruments: [
        for (final e in state.instruments)
          if (e.id == id)
            e.copyWith(
              monthlyAdminFee: fee,
              adminFeeEnabled: fee > 0 ? true : e.adminFeeEnabled,
            )
          else
            e,
      ],
    );
  }

  void updateAdminFeeDay(String id, int day) {
    state = state.copyWith(
      instruments: [
        for (final e in state.instruments)
          if (e.id == id) e.copyWith(adminFeeDay: day) else e,
      ],
    );
  }

  void updateAdminFeeEnabled(String id, bool enabled) {
    state = state.copyWith(
      instruments: [
        for (final e in state.instruments)
          if (e.id == id)
            e.copyWith(
              adminFeeEnabled: enabled,
              monthlyAdminFee: enabled ? e.monthlyAdminFee : 0,
            )
          else
            e,
      ],
    );
  }

  /// Tambah instrumen — langsung disimpan ke backend via repository.
  /// Instrumen hanya masuk ke state setelah backend mengembalikan ID asli.
  /// Tidak ada instrumen palsu atau saldo fiktif.
  Future<void> addInstrument(FinancialInstrument instrument) async {
    state = state.copyWith(isSaving: true);
    try {
      final saved = await ref
          .read(onboardingRepositoryProvider)
          .addInstrument(instrument);
      state = state.copyWith(
        instruments: [...state.instruments, saved],
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> loadExisting() async {
    final repo = ref.read(onboardingRepositoryProvider);
    try {
      final items = await repo.fetchExistingInstruments();
      if (items.isNotEmpty && state.instruments.isEmpty) {
        state = state.copyWith(instruments: items);
      }
    } catch (_) {}
  }

  /// Reset state onboarding (digunakan saat logout / ganti akun).
  void reset() {
    state = InstrumentsState(instruments: const []);
  }

  /// Simpan instrumen yang dipilih ke repository dan backend.
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .saveInstruments(state.instruments);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final instrumentsControllerProvider =
    NotifierProvider<InstrumentsController, InstrumentsState>(
      InstrumentsController.new,
    );
