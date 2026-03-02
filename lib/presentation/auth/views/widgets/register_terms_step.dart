import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/legal_texts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/sutandard_button.dart';
import '../../viewmodels/register_viewmodel.dart';

class RegisterTermsStep extends ConsumerWidget {
  const RegisterTermsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('약관에 동의해주세요', style: AppTextStyles.heading2),
        const SizedBox(height: 28),
        _AllAgreeCheckbox(
          value: state.allTermsAgreed,
          onChanged: (v) => vm.toggleAllTerms(v ?? false),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: AppColors.border,
        ),
        _TermCheckbox(
          label: '서비스 이용약관 동의 (필수)',
          value: state.termsAgreed,
          onChanged: (v) => vm.setTermsAgreed(v ?? false),
          onViewTap: () => _showLegalText(
            context,
            title: '서비스 이용약관',
            text: LegalTexts.termsOfService,
          ),
        ),
        const SizedBox(height: 10),
        _TermCheckbox(
          label: '개인정보 처리방침 동의 (필수)',
          value: state.privacyAgreed,
          onChanged: (v) => vm.setPrivacyAgreed(v ?? false),
          onViewTap: () => _showLegalText(
            context,
            title: '개인정보 처리방침',
            text: LegalTexts.privacyPolicy,
          ),
        ),
        const SizedBox(height: 32),
        SutandardButton(
          label: '다음',
          onPressed: state.allTermsAgreed ? () => vm.goToStudentId() : null,
        ),
      ],
    );
  }

  void _showLegalText(BuildContext context,
      {required String title, required String text}) {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 560, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                          child:
                              Text(title, style: AppTextStyles.heading3)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(text, style: AppTextStyles.bodyLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(title,
                              style: AppTextStyles.heading3)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Text(text, style: AppTextStyles.bodyLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _AllAgreeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AllAgreeCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '약관 전체 동의',
              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onViewTap;

  const _TermCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: value ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: value ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: value
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: AppColors.onPrimary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: AppTextStyles.body.copyWith(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onViewTap != null)
          GestureDetector(
            onTap: onViewTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '보기',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          ),
      ],
    );
  }
}
