import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/views/widgets/course_search_panel.dart';

class CourseListView extends ConsumerWidget {
  const CourseListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/courses'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLoginTap: () => context.go('/login'),
            onLogoutTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              context.go('/');
            },
            onDeleteAccountTap: () async {
              final success =
                  await ref.read(authViewModelProvider.notifier).deleteAccount();
              if (success && context.mounted) {
                context.go('/');
              }
            },
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
                  child: responsive.isDesktop
                      ? _buildDesktopLayout(context)
                      : _buildMobileLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 420,
          child: const CourseSearchPanel(onCourseAdd: null),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _BrowseGuide(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return const CourseSearchPanel(onCourseAdd: null);
  }
}

class _BrowseGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text('강의 목록', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            '왼쪽 검색 패널에서 과목명, 교수명,\n학수번호로 강의를 검색하세요',
            style: AppTextStyles.bodyLight,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TipRow(
                  icon: Icons.search_rounded,
                  text: '과목명, 교수명, 학수번호로 검색',
                ),
                const SizedBox(height: 12),
                _TipRow(
                  icon: Icons.filter_alt_outlined,
                  text: '이수구분, 학년, 단과대, 학과로 필터링',
                ),
                const SizedBox(height: 12),
                _TipRow(
                  icon: Icons.info_outline_rounded,
                  text: '분반 선택 시 상세 정보와 후기 확인 가능',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppTextStyles.body),
        ),
      ],
    );
  }
}
