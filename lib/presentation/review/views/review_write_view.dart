import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../common/widgets/sutandard_text_field.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class ReviewWriteView extends ConsumerStatefulWidget {
  const ReviewWriteView({super.key});

  @override
  ConsumerState<ReviewWriteView> createState() => _ReviewWriteViewState();
}

class _ReviewWriteViewState extends ConsumerState<ReviewWriteView> {
  final _searchController = TextEditingController();
  final _contentController = TextEditingController();
  CourseList? _selectedCourse;
  int _gradeScore = 3;
  int _assignmentScore = 3;
  int _examScore = 3;
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool _isSearching = false;
  List<CourseList> _searchResults = [];

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
      final response = await repo.getCourses(CourseSearchParams(search: query));
      setState(() {
        _searchResults = response.results;
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedCourse == null) {
      showAppSnackBar(context, message: '과목을 선택해주세요', type: SnackBarType.error);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      showAppSnackBar(context, message: '후기 내용을 작성해주세요', type: SnackBarType.error);
      return;
    }
    if (_contentController.text.trim().length < 20) {
      showAppSnackBar(context, message: '후기는 20자 이상 작성해주세요', type: SnackBarType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.createReview(CreateReviewRequest(
        course: _selectedCourse!.id,
        content: _contentController.text.trim(),
        gradeScore: _gradeScore,
        assignmentScore: _assignmentScore,
        examScore: _examScore,
        isAnonymous: _isAnonymous,
      ));
      if (mounted) {
        showAppSnackBar(context,
            message: '후기가 등록되었습니다!', type: SnackBarType.success);
        context.go('/');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showAppSnackBar(context,
            message: '후기 등록에 실패했습니다', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: const [],
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLogoutTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              context.go('/');
            },
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('강의 후기 작성', style: AppTextStyles.heading2),
                      const SizedBox(height: 6),
                      Text('수강했던 강의에 대한 솔직한 후기를 남겨주세요',
                          style: AppTextStyles.bodyLight),
                      const SizedBox(height: 24),
                      _buildCourseSelector(),
                      const SizedBox(height: 20),
                      _buildScoreSection(),
                      const SizedBox(height: 20),
                      SutandardTextField(
                        controller: _contentController,
                        label: '후기 내용',
                        hint: '강의에 대한 솔직한 후기를 작성해주세요 (20자 이상)',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isAnonymous
                              ? AppColors.primary.withValues(alpha: 0.04)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAnonymous
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isAnonymous
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: _isAnonymous
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('익명으로 작성',
                                      style: AppTextStyles.subtitle
                                          .copyWith(fontSize: 13)),
                                  Text('학번이 공개되지 않습니다',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isAnonymous,
                              onChanged: (v) =>
                                  setState(() => _isAnonymous = v),
                              activeTrackColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SutandardButton(
                        label: '후기 등록',
                        onPressed: _submitReview,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('과목 선택', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        if (_selectedCourse != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedCourse!.name,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
                      Text(
                        '${_selectedCourse!.professorName} · ${_selectedCourse!.credits}학점',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() => _selectedCourse = null),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          )
        else ...[
          Container(
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
                hintText: '과목명으로 검색',
                hintStyle:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _searchCourses,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                    Container(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final course = _searchResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(course.name,
                        style: AppTextStyles.body.copyWith(fontSize: 14)),
                    subtitle: Text(
                      '${course.professorName} · ${course.credits}학점',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCourse = course;
                        _searchResults = [];
                        _searchController.clear();
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('평가', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 12),
        _ScoreRow(
          label: '강의',
          score: _gradeScore,
          onChanged: (v) => setState(() => _gradeScore = v),
        ),
        const SizedBox(height: 10),
        _ScoreRow(
          label: '과제',
          score: _assignmentScore,
          onChanged: (v) => setState(() => _assignmentScore = v),
        ),
        const SizedBox(height: 10),
        _ScoreRow(
          label: '시험',
          score: _examScore,
          onChanged: (v) => setState(() => _examScore = v),
        ),
      ],
    );
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
          width: 40,
          child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 14)),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (i) {
          final val = i + 1;
          final isSelected = val == score;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(val),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.background,
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
