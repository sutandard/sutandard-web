import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../common/widgets/sutandard_logo.dart';
import '../viewmodels/register_viewmodel.dart';
import 'widgets/register_terms_step.dart';
import 'widgets/register_student_id_step.dart';
import 'widgets/register_portal_auth_step.dart';
import 'widgets/register_password_step.dart';

class RegisterView extends ConsumerWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, state, vm),
            Expanded(
              child: Center(
                child: _buildCard(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, RegisterState state, RegisterViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          if (state.step != RegisterStep.terms)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              onPressed: () => vm.goBack(),
              visualDensity: VisualDensity.compact,
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: () {
                vm.reset();
                context.go('/login');
              },
              visualDensity: VisualDensity.compact,
            ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                vm.reset();
                context.go('/');
              },
              child: const SutandardLogo(
                variant: SutandardLogoVariant.textOnly,
                height: 18,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, RegisterState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(state.step),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 350),
              child: _buildStep(state.step),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(RegisterStep currentStep) {
    final steps = RegisterStep.values;
    final currentIndex = steps.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: i ~/ 2 < currentIndex
                  ? AppColors.primary
                  : AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentIndex;
        final isCurrent = stepIndex == currentIndex;

        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent
                ? AppColors.primary
                : AppColors.surface,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.onPrimary)
                : Text(
                    '${stepIndex + 1}',
                    style: AppTextStyles.captionBold.copyWith(
                      color: isCurrent
                          ? AppColors.onPrimary
                          : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildStep(RegisterStep step) {
    return switch (step) {
      RegisterStep.terms => const RegisterTermsStep(),
      RegisterStep.studentId => const RegisterStudentIdStep(),
      RegisterStep.portalAuth => const RegisterPortalAuthStep(),
      RegisterStep.password => const RegisterPasswordStep(),
    };
  }
}
