import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/financial_instrument.dart';
import '../../../../data/providers/onboarding_providers.dart';

/// State No.4: daftar instrumen + pilihan sebagai source of truth.
class InstrumentsState extends Equatable {
  const InstrumentsState({
    required this.instruments,
    this.isSaving = false,
  });

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
    final saved =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
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
          if (e.id == id) e.copyWith(monthlyAdminFee: fee) else e,
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

  void addInstrument(FinancialInstrument instrument) {
    state = state.copyWith(
      instruments: [...state.instruments, instrument],
    );
  }

  /// Simpan instrumen terpilih. Berhasil -> true (UI ke No.5).
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .saveInstruments(state.instruments);
      state = state.copyWith(isSaving: false);
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
