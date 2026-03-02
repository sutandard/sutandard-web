import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/widgets/sutandard_button.dart';
import '../../../common/widgets/sutandard_text_field.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/register_viewmodel.dart';

class RegisterPasswordStep extends ConsumerStatefulWidget {
  const RegisterPasswordStep({super.key});

  @override
  ConsumerState<RegisterPasswordStep> createState() =>
      _RegisterPasswordStepState();
}

class _RegisterPasswordStepState
    extends ConsumerState<RegisterPasswordStep> {
  final _pwController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pwController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final vm = ref.read(registerViewModelProvider.notifier);
    final success = await vm.completeRegistration(
      _pwController.text,
      _confirmController.text,
    );
    if (success && mounted) {
      final regState = ref.read(registerViewModelProvider);
      if (regState.userInfo != null) {
        ref
            .read(authViewModelProvider.notifier)
            .setAuthenticated(regState.userInfo!);
      }
      context.go('/timetable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final user = state.userInfo;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환영합니다!',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            '마지막으로 수탠다드에서 사용할\n비밀번호를 설정해주세요.',
            style: AppTextStyles.body,
          ),
          if (user != null) ...[
            const SizedBox(height: 24),
            _UserInfoCard(user: user),
          ],
          const SizedBox(height: 32),
          SutandardTextField(
            controller: _pwController,
            label: '비밀번호',
            hint: '비밀번호를 입력해주세요.',
            obscureText: _obscurePw,
            textInputAction: TextInputAction.next,
            enabled: !state.isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePw
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePw = !_obscurePw),
            ),
          ),
          const SizedBox(height: 12),
          SutandardTextField(
            controller: _confirmController,
            label: '비밀번호 확인',
            hint: '비밀번호를 다시 입력해주세요.',
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            enabled: !state.isLoading,
            onEditingComplete: _handleRegister,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              '* ${state.error}',
              style: AppTextStyles.error,
            ),
          ],
          const SizedBox(height: 32),
          SutandardButton(
            label: '회원가입',
            onPressed: _handleRegister,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final dynamic user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('이름', user.name),
          const SizedBox(height: 8),
          _infoRow('학번', user.studentId),
          const SizedBox(height: 8),
          _infoRow('학과', user.major),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
