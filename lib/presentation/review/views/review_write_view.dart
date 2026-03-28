import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/semester_dropdown.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/course_search_viewmodel.dart';

// Renamed class — route /reviews
class ReviewView extends ConsumerStatefulWidget {
  const ReviewView({super.key});

  @override
  ConsumerState<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends ConsumerState<ReviewView> {
  // Phase 1: search
  final _searchController = TextEditingController();
  List<CourseList> _searchResults = [];
  bool _isSearching = false;

  // Phase 2: selected course
  CourseList? _selectedCourse;
  CourseDetail? _courseDetail;
  List<CourseReview> _reviews = [];
  bool _isLoadingDetail = false;

  // Phase 3: write form
  bool _showWriteForm = false;
  final _contentController = TextEditingController();
  int _gradeScore = 3;
  int _assignmentScore = 3;
  int _examScore = 3;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _searchCourses(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      final response =
          await repo.getCourses(CourseSearchParams(search: query));
      if (mounted) {
        setState(() {
          _searchResults = response.results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectCourse(CourseList course) async {
    setState(() {
      _selectedCourse = course;
      _searchResults = [];
      _searchController.clear();
      _courseDetail = null;
      _reviews = [];
      _showWriteForm = false;
      _isLoadingDetail = true;
    });

    try {
      final courseRepo = ref.read(courseRepositoryProvider);
      final reviewRepo = ref.read(reviewRepositoryProvider);

      final detail = await courseRepo.getCourseDetail(course.id);
      final reviewResponse = await reviewRepo.getReviews(
        course: course.id,
        ordering: '-created_at',
      );

      if (mounted) {
        setState(() {
          _courseDetail = detail;
          _reviews = reviewResponse.results;
          _isLoadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _submitReview() async {
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
        course: _selectedCourse!.id,
        semesterTaken: _selectedCourse!.semester,
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
        // Reload reviews
        await _reloadReviews();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMsg = extractErrorMessage(e);
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

  Future<void> _showEditDialog(CourseReview review) async {
    final editContent = TextEditingController(text: review.content);
    int editGrade = review.gradeScore;
    int editAssignment = review.assignmentScore;
    int editExam = review.examScore;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('후기 수정'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreRow(
                  label: '강의',
                  score: editGrade,
                  onChanged: (v) => setDialogState(() => editGrade = v),
                ),
                const SizedBox(height: 8),
                _ScoreRow(
                  label: '과제',
                  score: editAssignment,
                  onChanged: (v) => setDialogState(() => editAssignment = v),
                ),
                const SizedBox(height: 8),
                _ScoreRow(
                  label: '시험',
                  score: editExam,
                  onChanged: (v) => setDialogState(() => editExam = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editContent,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '후기 내용 (20자 이상)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;
    if (editContent.text.trim().length < 20) {
      showAppSnackBar(context,
          message: '후기는 20자 이상 작성해주세요', type: SnackBarType.error);
      return;
    }

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.updateReview(
        review.id,
        CreateReviewRequest(
          course: review.course,
          semesterTaken: review.semesterTaken,
          content: editContent.text.trim(),
          gradeScore: editGrade,
          assignmentScore: editAssignment,
          examScore: editExam,
          isAnonymous: review.isAnonymous,
        ),
      );
      if (mounted) {
        showAppSnackBar(context,
            message: '후기가 수정되었습니다', type: SnackBarType.success);
        await _reloadReviews();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: '후기 수정에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  Future<void> _showDeleteDialog(CourseReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('후기 삭제'),
        content: const Text('이 후기를 삭제하시겠습니까? 삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.deleteReview(review.id);
      if (mounted) {
        showAppSnackBar(context,
            message: '후기가 삭제되었습니다', type: SnackBarType.success);
        await _reloadReviews();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context,
            message: '후기 삭제에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  Future<void> _reloadReviews() async {
    if (_selectedCourse == null) return;
    try {
      final reviewRepo = ref.read(reviewRepositoryProvider);
      final response = await reviewRepo.getReviews(
        course: _selectedCourse!.id,
        ordering: '-created_at',
      );
      if (mounted) setState(() => _reviews = response.results);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/reviews'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLoginTap: () => context.go('/login'),
            onLogoutTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              context.go('/');
            },
            onDeleteAccountTap: () async {
              final success = await ref
                  .read(authViewModelProvider.notifier)
                  .deleteAccount();
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
                child: responsive.isDesktop
                    ? _buildDesktopLayout(context, authState, hPad)
                    : _buildMobileLayout(context, authState, hPad),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, AuthState authState, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 350,
            child: _buildSearchPanel(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildDetailPanel(context, authState),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, AuthState authState, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchPanel(),
          if (_selectedCourse != null) ...[
            const SizedBox(height: 20),
            _buildDetailPanel(context, authState),
          ],
        ],
      ),
    );
  }

  // ─── Left/Top: Search Panel ──────────────────────────────
  Widget _buildSearchPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('강의 후기', style: AppTextStyles.heading2),
                    const Spacer(),
                    SemesterDropdown(
                      selectedId: ref.watch(courseSearchViewModelProvider
                          .select((s) => s.selectedSemesterId)),
                      onChanged: (id) => ref
                          .read(courseSearchViewModelProvider.notifier)
                          .setSemester(id),
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('과목을 검색하여 후기를 확인하세요',
                    style: AppTextStyles.bodyLight),
                const SizedBox(height: 14),
                _buildSearchField(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_searchResults.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                    Container(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final course = _searchResults[i];
                  final isSelected = _selectedCourse?.id == course.id;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor:
                        AppColors.primary.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text(course.name,
                        style: AppTextStyles.body.copyWith(fontSize: 14)),
                    subtitle: Text(
                      '${course.professorName} · ${course.credits}학점',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                    onTap: () => _selectCourse(course),
                  );
                },
              ),
            )
          else if (_selectedCourse != null && _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCourse!.name,
                              style:
                                  AppTextStyles.subtitle.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${_selectedCourse!.professorName} · ${_selectedCourse!.credits}학점',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedCourse = null;
                        _courseDetail = null;
                        _reviews = [];
                        _showWriteForm = false;
                      }),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '과목명, 교수명, 학수번호로 검색하세요',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.body.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: '과목명, 교수명, 학수번호 검색',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _searchCourses,
      ),
    );
  }

  // ─── Right/Bottom: Detail Panel ──────────────────────────
  Widget _buildDetailPanel(BuildContext context, AuthState authState) {
    if (_selectedCourse == null) {
      return _buildEmptyDetail();
    }
    if (_isLoadingDetail) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(strokeWidth: 2),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_courseDetail != null) _buildCourseInfoCard(_courseDetail!),
        const SizedBox(height: 20),
        _buildReviewsSection(context, authState),
      ],
    );
  }

  Widget _buildEmptyDetail() {
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
            child: const Icon(Icons.rate_review_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('강의를 선택하세요', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            '왼쪽 검색창에서 과목을 선택하면\n강의 정보와 후기를 확인할 수 있습니다',
            style: AppTextStyles.bodyLight,
            textAlign: TextAlign.center,
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
                    Text(detail.name,
                        style: AppTextStyles.heading3),
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

  // ─── Reviews Section ─────────────────────────────────────
  Widget _buildReviewsSection(BuildContext context, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('강의 후기', style: AppTextStyles.subtitle),
            const SizedBox(width: 8),
            Text('${_reviews.length}개',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
            const Spacer(),
            if (!_showWriteForm)
              _WriteButton(
                isAuthenticated: authState.isAuthenticated,
                onTap: () {
                  if (!authState.isAuthenticated) {
                    context.go('/login');
                  } else {
                    setState(() => _showWriteForm = true);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child: _showWriteForm
              ? _buildWriteForm(context)
              : const SizedBox.shrink(),
        ),
        if (_reviews.isEmpty)
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
          ..._reviews.map((r) => _ReviewCard(
                review: r,
                onEdit: r.isMine ? () => _showEditDialog(r) : null,
                onDelete: r.isMine ? () => _showDeleteDialog(r) : null,
              )),
      ],
    );
  }

  Widget _buildWriteForm(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
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
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: '강의에 대한 솔직한 후기를 작성해주세요 (20자 이상)',
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
            onPressed: _submitReview,
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

}

// ─── Subwidgets ────────────────────────────────────────────

class _WriteButton extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onTap;

  const _WriteButton({required this.isAuthenticated, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, size: 16),
          const SizedBox(width: 6),
          Text(
            isAuthenticated ? '후기 작성하기' : '로그인 후 작성',
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CourseReview review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ReviewCard({required this.review, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor(review.totalScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 13,
                        color: _scoreColor(review.totalScore)),
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
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                          value: 'edit', child: Text('수정')),
                    if (onDelete != null)
                      const PopupMenuItem(
                          value: 'delete', child: Text('삭제')),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                ),
              ],
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
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

