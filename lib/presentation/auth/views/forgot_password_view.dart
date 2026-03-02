import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../common/widgets/sutandard_text_field.dart';

enum _ResetStep { input, done }

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() =>
      _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  _ResetStep _step = _ResetStep.input;
  bool _isLoading = false;
  String? _error;
  bool _obscurePortalPw = true;
  bool _obscureNewPw = true;
  bool _obscureConfirmPw = true;

  final _studentIdController = TextEditingController();
  final _portalPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _portalPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    final studentId = _studentIdController.text.trim();
    final portalPw = _portalPwController.text;
    final newPw = _newPwController.text;
    final confirmPw = _confirmPwController.text;

    if (studentId.isEmpty) {
      setState(() => _error = '학번을 입력해주세요.');
      return;
    }
    if (portalPw.isEmpty) {
      setState(() => _error = '포털 비밀번호를 입력해주세요.');
      return;
    }
    if (newPw.length < 8) {
      setState(() => _error = '새 비밀번호는 8자 이상이어야 합니다.');
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPw)) {
      setState(() => _error = '특수문자를 포함해야 합니다.');
      return;
    }
    if (newPw != confirmPw) {
      setState(() => _error = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(ResetPasswordRequest(
        studentId: studentId,
        portalPassword: portalPw,
        newPassword: newPw,
        newPasswordConfirm: confirmPw,
      ));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _step = _ResetStep.done;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = extractErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SutandardNavBar(
      navItems: const [],
      hideAuthButton: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        onPressed: () => context.go('/login'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: switch (_step) {
        _ResetStep.input => _buildInputStep(),
        _ResetStep.done => _buildDoneStep(),
      },
    );
  }

  Widget _buildInputStep() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary),
          const SizedBox(height: 20),
          Text('포털에서 본인을 확인하고\n비밀번호를 재설정하고 있습니다..',
              style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 32),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('비밀번호 재설정', style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        Text('포털 비밀번호로 본인 인증 후\n수탠다드 비밀번호를 재설정합니다.',
            style: AppTextStyles.bodyLight),
        const SizedBox(height: 28),
        SutandardTextField(
          controller: _studentIdController,
          label: '학번',
          hint: '학번을 입력해주세요',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        SutandardTextField(
          controller: _portalPwController,
          label: '포털 비밀번호',
          hint: '포털 비밀번호를 입력해주세요',
          obscureText: _obscurePortalPw,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePortalPw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePortalPw = !_obscurePortalPw),
          ),
        ),
        const SizedBox(height: 14),
        SutandardTextField(
          controller: _newPwController,
          label: '새 비밀번호',
          hint: '8자 이상, 특수문자 포함',
          obscureText: _obscureNewPw,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureNewPw = !_obscureNewPw),
          ),
        ),
        const SizedBox(height: 14),
        SutandardTextField(
          controller: _confirmPwController,
          label: '새 비밀번호 확인',
          hint: '비밀번호를 다시 입력해주세요',
          obscureText: _obscureConfirmPw,
          textInputAction: TextInputAction.done,
          onEditingComplete: _submitReset,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirmPw = !_obscureConfirmPw),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppColors.errorHigh),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: AppTextStyles.error)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SutandardButton(
          label: '비밀번호 재설정',
          onPressed: _submitReset,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '포털 비밀번호는 인증에만 사용되며 저장되지 않습니다.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 32, color: AppColors.successHigh),
        ),
        const SizedBox(height: 20),
        Text('비밀번호가 재설정되었습니다', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Text('새 비밀번호로 로그인해주세요', style: AppTextStyles.bodyLight),
        const SizedBox(height: 28),
        SutandardButton(
          label: '로그인으로 돌아가기',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
