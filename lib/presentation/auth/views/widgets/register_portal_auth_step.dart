import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/sutandard_button.dart';
import '../../../common/widgets/sutandard_text_field.dart';
import '../../viewmodels/register_viewmodel.dart';

class RegisterPortalAuthStep extends ConsumerStatefulWidget {
  const RegisterPortalAuthStep({super.key});

  @override
  ConsumerState<RegisterPortalAuthStep> createState() =>
      _RegisterPortalAuthStepState();
}

class _RegisterPortalAuthStepState
    extends ConsumerState<RegisterPortalAuthStep> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);

    if (state.isLoading) {
      return _buildLoading();
    }

    if (state.error != null && !state.portalVerified) {
      return _buildError(vm);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '포털 인증',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTextStyles.body,
            children: [
              const TextSpan(text: '학번 '),
              TextSpan(
                text: state.studentId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' 학생의 포털 비밀번호를 입력해주세요.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SutandardTextField(
          controller: _passwordController,
          label: '포털 비밀번호',
          hint: '포털 비밀번호를 입력해주세요.',
          obscureText: true,
          textInputAction: TextInputAction.done,
          onEditingComplete: () => _verify(vm),
        ),
        const SizedBox(height: 40),
        SutandardButton(
          label: '포털 인증하기',
          onPressed: () => _verify(vm),
        ),
      ],
    );
  }

  void _verify(RegisterViewModel vm) {
    if (_passwordController.text.isNotEmpty) {
      vm.verifyPortal(_passwordController.text);
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '포털에서 정보를 불러오고 있습니다..',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(RegisterViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            '포털에서 정보를 불러오는데\n실패하였습니다.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SutandardButton(
            label: '다시 시도',
            onPressed: () => vm.clearError(),
            isExpanded: false,
            height: 50,
            fontSize: 18,
          ),
        ],
      ),
    );
  }
}
