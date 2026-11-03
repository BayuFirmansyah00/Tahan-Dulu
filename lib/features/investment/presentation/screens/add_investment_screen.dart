import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/investment_controller.dart';

/// Form tambah portofolio investasi: judul, jenis, nilai capaian, target.
class AddInvestmentScreen extends ConsumerStatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  ConsumerState<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends ConsumerState<AddInvestmentScreen> {
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  final _achievedController = TextEditingController();
  final _targetController = TextEditingController();
  bool _attempted = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _achievedController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text;
    final type = _typeController.text;
    final achieved =
        RupiahInputFormatter.parse(_achievedController.text);
    final targetText = _targetController.text.trim();
    final target = targetText.isEmpty
        ? null
        : RupiahInputFormatter.parse(targetText).toInt();

    if (title.trim().isEmpty) {
      setState(() => _attempted = true);
      return;
    }
    if (achieved < 0) {
      setState(() => _attempted = true);
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      final ok = await ref.read(investmentControllerProvider).addInvestment(
            title: title,
            type: type,
            achieved: achieved,
            target: target,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showTitleError = _attempted && _titleController.text.trim().isEmpty;
    final showAchievedError = _attempted &&
        RupiahInputFormatter.parse(_achievedController.text) < 0;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addInvestmentTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.investmentTitle,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _titleController,
                          label: AppStrings.investmentName,
                          hint: AppStrings.investmentNameHint,
                        ),
                        if (showTitleError) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.investmentNameRequired,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.investmentType,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _typeController,
                          label: AppStrings.investmentTypeLabel,
                          hint: AppStrings.investmentTypeHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.investmentAchieved,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _achievedController,
                          label: AppStrings.investmentAchievedLabel,
                          hint: '0',
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                        ),
                        if (showAchievedError) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.investmentAchievedRequired,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.investmentTarget,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _targetController,
                          label: AppStrings.investmentTargetLabel,
                          hint: '0 (opsional)',
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.saveInvestment,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
