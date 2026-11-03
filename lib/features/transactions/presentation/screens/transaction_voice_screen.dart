import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/models/financial_instrument.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../domain/voice_transaction_parser.dart';
import '../providers/native_input_providers.dart';
import '../providers/transactions_controller.dart';
import '../utils/transaction_categories.dart';

AccountType _toAccountType(InstrumentType type) {
  switch (type) {
    case InstrumentType.bank:
      return AccountType.bank;
    case InstrumentType.digitalBank:
      return AccountType.digitalBank;
    case InstrumentType.ewallet:
      return AccountType.ewallet;
  }
}

/// Halaman Input Suara TahanDulu.
///
/// Terintegrasi dengan speech_to_text dan permission_handler:
/// - Minta izin mikrofon saat pengguna mulai merekam (bukan saat app dibuka).
/// - Mendeteksi bahasa Indonesia (id_ID) jika tersedia pada perangkat.
/// - Menampilkan status mendengarkan, hasil transkripsi real-time, dan status selesai.
/// - Menyediakan tombol untuk menghentikan dan mengulangi rekaman.
/// - Hasil suara diproses oleh [VoiceTransactionParser] dan dapat diedit.
/// - Konfirmasi mengisi draf [transactionFormProvider] dan membuka formulir verifikasi.
class TransactionVoiceScreen extends ConsumerStatefulWidget {
  const TransactionVoiceScreen({super.key});

  @override
  ConsumerState<TransactionVoiceScreen> createState() =>
      _TransactionVoiceScreenState();
}

class _TransactionVoiceScreenState
    extends ConsumerState<TransactionVoiceScreen> {
  final _parser = const VoiceTransactionParser();
  late final TextEditingController _textController;

  bool _isRecording = false;
  String _transcription = '';
  ParsedVoiceTransaction? _parsedResult;
  bool _isEditingTranscription = false;
  String? _errorMessage;
  String? _detectedLocaleId;

  final List<String> _samplePhrases = const [
    'Makan siang dua puluh lima ribu menggunakan BCA',
    'Beli bensin lima puluh ribu pakai Mandiri',
    'Gaji bulanan lima juta masuk BCA',
    'Bayar tagihan listrik seratus ribu',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  List<FinancialAccount> _getUserAccounts() {
    final accountsAsync = ref.read(accountsProvider);
    return accountsAsync.maybeWhen(
      data: (items) => items,
      orElse: () {
        final data =
            ref.read(onboardingRepositoryProvider).getOnboardingData();
        return (data?.financialInstruments ?? const [])
            .map((e) => FinancialAccount(
                  id: e.id,
                  name: e.name,
                  type: _toAccountType(e.type),
                  balance: e.initialBalance,
                  institutionName: e.institutionName,
                ))
            .toList();
      },
    );
  }

  void _processText(String text, {bool updateEditing = true}) {
    final accounts = _getUserAccounts();
    final parsed = _parser.parse(text, userAccounts: accounts);
    setState(() {
      _transcription = text;
      _textController.text = text;
      _parsedResult = parsed;
      if (updateEditing) {
        _isEditingTranscription = false;
      }
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _errorMessage = null;
    });

    final speechService = ref.read(speechRecognitionServiceProvider);

    // 1. Periksa dan minta izin mikrofon hanya saat user ingin merekam
    final hasPerm = await speechService.checkMicrophonePermission();
    if (!hasPerm) {
      final granted = await speechService.requestMicrophonePermission();
      if (!granted) {
        setState(() {
          _isRecording = false;
          _errorMessage =
              'Izin mikrofon diperlukan untuk mendengarkan transaksi. Aktifkan izin mikrofon di Pengaturan perangkat.';
        });
        _showPermissionDeniedDialog();
        return;
      }
    }

    // 2. Inisialisasi layanan pengenalan suara
    final available = await speechService.initialize(
      onStatus: (status) {
        if (!mounted) return;
        debugPrint('[VoiceScreen] Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_isRecording) {
            setState(() {
              _isRecording = false;
            });
            if (_transcription.trim().isEmpty) {
              setState(() {
                _errorMessage =
                    'Suara tidak terdengar. Silakan coba lagi atau gunakan frasa contoh.';
              });
            }
          }
        }
      },
      onError: (errorMsg) {
        if (!mounted) return;
        debugPrint('[VoiceScreen] Speech error: $errorMsg');
        setState(() {
          _isRecording = false;
          _errorMessage = 'Kendala pengenalan suara: $errorMsg';
        });
      },
    );

    if (!available) {
      setState(() {
        _isRecording = false;
        _errorMessage =
            'Pengenalan suara tidak didukung atau belum siap pada perangkat ini.';
      });
      return;
    }

    // 3. Deteksi bahasa Indonesia jika tersedia
    _detectedLocaleId ??= await speechService.findIndonesianLocale();

    // 4. Mulai mendengarkan ucapan
    setState(() {
      _isRecording = true;
      _errorMessage = null;
    });

    final started = await speechService.startListening(
      localeId: _detectedLocaleId,
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcription = words;
          _textController.text = words;
          if (words.trim().isNotEmpty) {
            _processText(words, updateEditing: false);
          }
          if (isFinal) {
            _isRecording = false;
            if (words.trim().isEmpty) {
              _errorMessage =
                  'Suara tidak terdengar. Silakan coba lagi atau gunakan frasa contoh.';
            }
          }
        });
      },
    );

    if (!started) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Gagal mengaktifkan mikrofon perangkat.';
      });
    }
  }

  Future<void> _stopRecording() async {
    final speechService = ref.read(speechRecognitionServiceProvider);
    await speechService.stopListening();
    setState(() {
      _isRecording = false;
    });

    if (_transcription.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Tidak ada ucapan yang terdeteksi. Silakan coba berbicara lebih dekat ke mikrofon.';
      });
    } else {
      _processText(_transcription);
    }
  }

  Future<void> _resetRecording() async {
    final speechService = ref.read(speechRecognitionServiceProvider);
    await speechService.cancelListening();
    setState(() {
      _isRecording = false;
      _transcription = '';
      _textController.clear();
      _parsedResult = null;
      _errorMessage = null;
      _isEditingTranscription = false;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Mikrofon Diperlukan'),
        content: const Text(
          'Untuk menggunakan fitur input suara, TahanDulu memerlukan akses ke mikrofon perangkat Anda.\n\n'
          'Silakan izinkan akses mikrofon di pengaturan sistem Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmAndNavigateToForm() {
    final result = _parsedResult;
    if (result == null) return;

    final notifier = ref.read(transactionFormProvider.notifier);

    // Terapkan hasil suara ke draf form transaksi
    notifier.setType(result.type);
    if (result.hasAmount) {
      notifier.setAmount(result.amount);
    }
    if (result.hasCategory) {
      notifier.setCategory(result.category!);
    }
    if (result.hasAccount) {
      notifier.setAccount(result.accountId);
    }
    if (result.description.isNotEmpty) {
      notifier.setNote(result.description);
    }

    // Arahkan ke formulir transaksi manual untuk verifikasi dan review pengguna
    context.push(AppRoutes.transactionAdd);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accountsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Input Suara'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_transcription.isNotEmpty || _parsedResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Ulangi Rekaman',
              onPressed: _resetRecording,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sebutkan transaksimu',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ucapkan detail transaksi seperti nominal, kebutuhan, dan akun pembayaran dalam bahasa Indonesia.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Banner bila ada kendala
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Microphone Button Area
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isRecording ? _stopRecording : _startRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? AppColors.error
                                  : AppColors.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording
                                          ? AppColors.error
                                          : AppColors.secondary)
                                      .withValues(alpha: 0.35),
                                  blurRadius: _isRecording ? 24 : 14,
                                  spreadRadius: _isRecording ? 6 : 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 46,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isRecording
                              ? 'Mendengarkan... Tekan untuk berhenti'
                              : (_transcription.isNotEmpty
                                  ? 'Rekaman selesai. Tekan untuk bicara lagi.'
                                  : 'Tekan tombol mikrofon untuk mulai'),
                          style: textTheme.bodySmall?.copyWith(
                            color: _isRecording
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preset Samples
                  Text(
                    'Atau coba contoh ucapan berikut:',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _samplePhrases.map((phrase) {
                      return ActionChip(
                        label: Text(
                          phrase,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: () => _processText(phrase),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Hasil Transkripsi
                  if (_transcription.isNotEmpty) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.record_voice_over_outlined,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hasil Ucapan Terdeteksi',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  _isEditingTranscription
                                      ? Icons.check
                                      : Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                onPressed: () {
                                  if (_isEditingTranscription) {
                                    _processText(_textController.text);
                                  } else {
                                    setState(() {
                                      _isEditingTranscription = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isEditingTranscription)
                            TextField(
                              controller: _textController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Ubah teks ucapan di sini...',
                                border: OutlineInputBorder(),
                              ),
                            )
                          else
                            Text(
                              '"$_transcription"',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Parsed Detail Preview
                  if (_parsedResult != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Transaksi yang Dikenali',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Jenis Transaksi',
                            value: _parsedResult!.type ==
                                    TransactionType.income
                                ? 'Pemasukan'
                                : 'Pengeluaran',
                            isHighlight: true,
                            highlightColor: _parsedResult!.type ==
                                    TransactionType.income
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const Divider(height: 16),
                          _DetailRow(
                            label: 'Nominal',
                            value: _parsedResult!.hasAmount
                                ? CurrencyFormatter.format(
                                    _parsedResult!.amount)
                                : 'Belum terdeteksi (isi di form)',
                          ),
                          const Divider(height: 16),
                          _DetailRow(
                            label: 'Kategori',
                            value: _parsedResult!.hasCategory
                                ? categoryLabel(_parsedResult!.category!)
                                : 'Belum pasti (pilih di form)',
                          ),
                          const Divider(height: 16),
                          _DetailRow(
                            label: 'Akun / Rekening',
                            value: _parsedResult!.hasAccount
                                ? (_parsedResult!.accountName ?? '-')
                                : 'Belum pasti (pilih di form)',
                          ),
                          const Divider(height: 16),
                          _DetailRow(
                            label: 'Catatan',
                            value: _parsedResult!.description.isNotEmpty
                                ? _parsedResult!.description
                                : '-',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Action Button
                    AppButton(
                      label: 'Lanjutkan ke Form Transaksi',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _confirmAndNavigateToForm,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Catatan Transparansi Sistem
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: AppRadius.card,
                    ),
                    child: Text(
                      'Catatan: Fitur speech-to-text mengubah ucapan menjadi teks. Seluruh detail selalu ditinjau kembali di formulir transaksi sebelum disimpan ke sistem.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: isHighlight
                  ? (highlightColor ?? AppColors.textPrimary)
                  : AppColors.textPrimary,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
