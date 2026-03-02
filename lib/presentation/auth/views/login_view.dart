import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_logo.dart';
import '../../common/widgets/sutandard_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await ref.read(authViewModelProvider.notifier).login(
          _studentIdController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      context.go('/timetable');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

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
                  child: _buildLoginCard(authState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: const SutandardLogo(
                variant: SutandardLogoVariant.textOnly,
                height: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(AuthState authState) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SutandardLogo(
            variant: SutandardLogoVariant.full,
            height: 60,
          ),
          const SizedBox(height: 12),
          Text(
            '수탠다드에 오신 것을 환영합니다',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SutandardTextField(
            controller: _studentIdController,
            label: '학번',
            hint: '학번을 입력해주세요',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !authState.isLoading,
          ),
          const SizedBox(height: 12),
          SutandardTextField(
            controller: _passwordController,
            label: '비밀번호',
            hint: '비밀번호를 입력해주세요',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !authState.isLoading,
            onEditingComplete: _handleLogin,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(authState.error!, style: AppTextStyles.error),
            ),
          ],
          const SizedBox(height: 20),
          SutandardButton(
            label: '로그인',
            onPressed: _handleLogin,
            isLoading: authState.isLoading,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(
                  '회원가입',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 12,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: Text(
                  '비밀번호 찾기',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
