import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/course_search_viewmodel.dart';
import '../../timetable/views/widgets/course_search_panel.dart';

class CourseListView extends ConsumerStatefulWidget {
  final String? initialQuery;

  const CourseListView({super.key, this.initialQuery});

  @override
  ConsumerState<CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends ConsumerState<CourseListView> {
  // Review write form state
  bool _showWriteForm = false;
  final _contentController = TextEditingController();
  int _gradeScore = 3;
  int _assignmentScore = 3;
  int _examScore = 3;
  bool _isSubmitting = false;
  bool _initialSearchDone = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialSearchDone && widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _initialSearchDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(courseSearchViewModelProvider.notifier).search(widget.initialQuery!);
      });
    }

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
          child: CourseSearchPanel(
            onCourseAdd: null,
            initialQuery: widget.initialQuery,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final state = ref.watch(courseSearchViewModelProvider);
    final course = state.selectedCourseDetail;

    // 분반 선택 시 상세+후기 표시, 아니면 검색 패널
    if (course != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => ref
                      .read(courseSearchViewModelProvider.notifier)
                      .clearSelectedCourse(),
                ),
                Expanded(
                  child: Text(course.name,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }

    return CourseSearchPanel(
      onCourseAdd: null,
      initialQuery: widget.initialQuery,
    );
  }

  Widget _buildDetailPanel() {
    final state = ref.watch(courseSearchViewModelProvider);
    final course = state.selectedCourseDetail;
    final authState = ref.watch(authViewModelProvider);

    if (course == null) {
      return _buildBrowseGuide();
    }

    final reviews = state.selectedCourseReviews;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseInfoCard(course),
          const SizedBox(height: 20),
          _buildReviewsSection(reviews, authState),
        ],
      ),
    );
  }

  Widget _buildBrowseGuide() {
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
          Text('강의 탐색', style: AppTextStyles.heading2),
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
                const SizedBox(height: 12),
                _TipRow(
                  icon: Icons.rate_review_outlined,
                  text: '로그인 후 강의 후기 작성 가능',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(CourseDetail detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.name, style: AppTextStyles.heading3),
                    const SizedBox(height: 4),
                    Text(
                      '${detail.professorName} · ${detail.credits}학점',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (detail.courseTypeDisplay.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detail.courseTypeDisplay,
                    style: AppTextStyles.captionBold
                        .copyWith(color: AppColors.primary, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _infoChip('학수번호', detail.courseCode),
              if (detail.section.isNotEmpty)
                _infoChip('분반', detail.section),
              if (detail.departmentName.isNotEmpty)
                _infoChip('학과', detail.departmentName),
              if (detail.semesterStr.isNotEmpty)
                _infoChip('학기', detail.semesterStr),
              if (detail.gradeEvalTypeDisplay.isNotEmpty)
                _infoChip('성적처리', detail.gradeEvalTypeDisplay),
            ],
          ),
          if (detail.schedules.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Text('시간표', style: AppTextStyles.captionBold),
            const SizedBox(height: 6),
            ...detail.schedules.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${s.dayDisplay} ${s.startTimeFormatted}~${s.endTimeFormatted}  ${s.classroomStr ?? ''}',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                )),
          ],
          if (detail.reviewStats != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            _buildReviewStats(detail.reviewStats!),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textTertiary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _buildReviewStats(Map<String, dynamic> stats) {
    final avg = (stats['avg_total'] as num?)?.toDouble();
    final count = stats['count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (avg != null)
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(avg.toStringAsFixed(1),
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
                Text('평균 평점',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary, fontSize: 10)),
              ],
            ),
          Column(
            children: [
              Text('$count',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.textPrimary)),
              Text('후기 수',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
      List<CourseReview> reviews, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('강의 후기', style: AppTextStyles.subtitle),
            const SizedBox(width: 8),
            Text('${reviews.length}개',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
            const Spacer(),
            if (!_showWriteForm)
              FilledButton.tonal(
                onPressed: () {
                  if (!authState.isAuthenticated) {
                    context.go('/login');
                  } else {
                    setState(() => _showWriteForm = true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      authState.isAuthenticated ? '후기 작성하기' : '로그인 후 작성',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _showWriteForm
              ? _buildWriteForm()
              : const SizedBox.shrink(),
        ),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 32,
                      color: AppColors.textTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text('등록된 후기가 없습니다',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          )
        else
          ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }

  Widget _buildWriteForm() {
    final state = ref.watch(courseSearchViewModelProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('후기 작성', style: AppTextStyles.subtitle),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _showWriteForm = false),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreSection(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: 4,
              maxLength: 500,
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: '강의에 대한 솔직한 후기를 작성해주세요 (20~500자)',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SutandardButton(
            label: '후기 등록',
            onPressed: () => _submitReview(state),
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('평가', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 10),
        _ScoreRow(
          label: '강의',
          score: _gradeScore,
          onChanged: (v) => setState(() => _gradeScore = v),
        ),
        const SizedBox(height: 8),
        _ScoreRow(
          label: '과제',
          score: _assignmentScore,
          onChanged: (v) => setState(() => _assignmentScore = v),
        ),
        const SizedBox(height: 8),
        _ScoreRow(
          label: '시험',
          score: _examScore,
          onChanged: (v) => setState(() => _examScore = v),
        ),
      ],
    );
  }

  Future<void> _submitReview(CourseSearchState state) async {
    final course = state.selectedCourseDetail;
    if (course == null) return;

    if (_contentController.text.trim().isEmpty) {
      showAppSnackBar(context,
          message: '후기 내용을 작성해주세요', type: SnackBarType.error);
      return;
    }
    if (_contentController.text.trim().length < 20) {
      showAppSnackBar(context,
          message: '후기는 20자 이상 작성해주세요', type: SnackBarType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.createReview(CreateReviewRequest(
        course: course.id,
        semesterTaken: course.semester,
        content: _contentController.text.trim(),
        gradeScore: _gradeScore,
        assignmentScore: _assignmentScore,
        examScore: _examScore,
        isAnonymous: true,
      ));
      if (mounted) {
        showAppSnackBar(context,
            message: '후기가 등록되었습니다!', type: SnackBarType.success);
        _contentController.clear();
        setState(() {
          _showWriteForm = false;
          _gradeScore = 3;
          _assignmentScore = 3;
          _examScore = 3;
          _isSubmitting = false;
        });
        // Reload selected course info to refresh reviews
        ref
            .read(courseSearchViewModelProvider.notifier)
            .selectCourseForInfo(course);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMsg = e.toString();
        if (errorMsg.contains('already') || errorMsg.contains('duplicate') || errorMsg.contains('이미')) {
          showAppSnackBar(context,
              message: '이미 이 강의에 후기를 등록하셨습니다', type: SnackBarType.error);
        } else {
          showAppSnackBar(context,
              message: '후기 등록에 실패했습니다', type: SnackBarType.error);
        }
      }
    }
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

class _ReviewCard extends ConsumerWidget {
  final CourseReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final isMyReview = authState.isAuthenticated &&
        authState.user?.studentId != null &&
        review.authorName == authState.user!.studentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _scoreChip('강의', review.gradeScore),
              const SizedBox(width: 5),
              _scoreChip('과제', review.assignmentScore),
              const SizedBox(width: 5),
              _scoreChip('시험', review.examScore),
              const Spacer(),
              if (isMyReview)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          SizedBox(width: 6),
                          Text('삭제', style: TextStyle(color: AppColors.error, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('후기 삭제'),
                          content: const Text('이 후기를 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('삭제',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          final repo = ref.read(reviewRepositoryProvider);
                          await repo.deleteReview(review.id);
                          if (context.mounted) {
                            showAppSnackBar(context,
                                message: '후기가 삭제되었습니다',
                                type: SnackBarType.success);
                            // Reload reviews
                            final state = ref.read(courseSearchViewModelProvider);
                            if (state.selectedCourseDetail != null) {
                              ref
                                  .read(courseSearchViewModelProvider.notifier)
                                  .selectCourseForInfo(state.selectedCourseDetail!);
                            }
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showAppSnackBar(context,
                                message: '후기 삭제에 실패했습니다',
                                type: SnackBarType.error);
                          }
                        }
                      }
                    }
                  },
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      _scoreColor(review.totalScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 13, color: _scoreColor(review.totalScore)),
                    const SizedBox(width: 2),
                    Text(
                      review.totalScore.toStringAsFixed(1),
                      style: AppTextStyles.captionBold.copyWith(
                        color: _scoreColor(review.totalScore),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.content,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                review.authorName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 11),
              ),
              if (review.semesterTakenStr.isNotEmpty)
                Text(
                  '  ·  ${review.semesterTakenStr}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int score) {
    final grade = switch (score) {
      5 => 'A+',
      4 => 'A',
      3 => 'B',
      2 => 'C',
      _ => 'D',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text('$label $grade',
          style: AppTextStyles.caption.copyWith(fontSize: 11)),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 4.0) return AppColors.successHigh;
    if (score >= 3.0) return AppColors.primary;
    if (score >= 2.0) return AppColors.warning;
    return AppColors.error;
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final ValueChanged<int> onChanged;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.onChanged,
  });

  static const _labels = ['D', 'C', 'B', 'A', 'A+'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child:
              Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 10),
        ...List.generate(5, (i) {
          final val = i + 1;
          final isSelected = val == score;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  _labels[i],
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
