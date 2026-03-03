import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/filter_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/review_model.dart';
import '../../viewmodels/course_search_viewmodel.dart';

class CourseSearchPanel extends ConsumerStatefulWidget {
  final void Function(int courseId, String color)? onCourseAdd;
  final void Function(CourseDetail course)? onCourseHoverEnter;
  final VoidCallback? onCourseHoverExit;
  final String? initialQuery;

  const CourseSearchPanel({
    super.key,
    this.onCourseAdd,
    this.onCourseHoverEnter,
    this.onCourseHoverExit,
    this.initialQuery,
  });

  @override
  ConsumerState<CourseSearchPanel> createState() => _CourseSearchPanelState();
}

class _CourseSearchPanelState extends ConsumerState<CourseSearchPanel>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;
  bool _showFilters = false;

  static const _courseColors = [
    '#4A6CF7', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#3B82F6', '#EC4899', '#06B6D4',
  ];
  int _colorCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _nextColor() {
    final color = _courseColors[_colorCounter % _courseColors.length];
    _colorCounter++;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseSearchViewModelProvider);
    final vm = ref.read(courseSearchViewModelProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildSearchBar(vm),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '강의'),
              Tab(text: '정보'),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showFilters
                ? _buildExpandedFilters(state, vm)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectList(state, vm),
                _buildInfoTab(state, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CourseSearchViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: '과목명, 교수명, 학수번호로 검색',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
              onSubmitted: (q) => vm.search(q),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _showFilters
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _showFilters
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_outlined,
                color:
                    _showFilters ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedFilters(
      CourseSearchState state, CourseSearchViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(
            label: '분류',
            selected: state.courseType,
            options: FilterConstants.courseTypes,
            onSelect: (v) => vm.setCourseType(v),
          ),
          const SizedBox(height: 10),
          _buildYearLevelRow(state, vm),
          const SizedBox(height: 10),
          if (state.colleges.isNotEmpty) ...[
            _buildCollegeRow(state, vm),
            const SizedBox(height: 10),
          ],
          if (state.filteredDepartments.isNotEmpty) ...[
            _buildDepartmentRow(state, vm),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.hasActiveFilters)
                GestureDetector(
                  onTap: () => vm.clearFilters(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('초기화',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  vm.searchWithFilters();
                  setState(() => _showFilters = false);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('검색',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required String? selected,
    required Map<String, String> options,
    required void Function(String?) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.captionBold.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _FilterChip(
              label: '전체',
              selected: selected == null,
              onTap: () => onSelect(null),
              showCheck: selected == null,
            ),
            ...options.entries.map((e) => _FilterChip(
                  label: e.value,
                  selected: selected == e.key,
                  onTap: () =>
                      onSelect(selected == e.key ? null : e.key),
                  showCheck: selected == e.key,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildYearLevelRow(
      CourseSearchState state, CourseSearchViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학년',
            style: AppTextStyles.captionBold.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _FilterChip(
              label: '전체',
              selected: state.yearLevel == null,
              onTap: () => vm.setYearLevel(null),
              showCheck: state.yearLevel == null,
            ),
            ...FilterConstants.yearLevels.entries.map((e) => _FilterChip(
                  label: e.value,
                  selected: state.yearLevel == e.key,
                  onTap: () => vm.setYearLevel(
                      state.yearLevel == e.key ? null : e.key),
                  showCheck: state.yearLevel == e.key,
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildCollegeRow(
      CourseSearchState state, CourseSearchViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('단과대',
            style: AppTextStyles.captionBold.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: '전체',
                selected: state.selectedCollegeId == null,
                onTap: () => vm.setCollege(null),
                showCheck: state.selectedCollegeId == null,
              ),
              ...state.colleges.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: _FilterChip(
                      label: c.name,
                      selected: state.selectedCollegeId == c.id,
                      onTap: () => vm.setCollege(
                          state.selectedCollegeId == c.id ? null : c.id),
                      showCheck: state.selectedCollegeId == c.id,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentRow(
      CourseSearchState state, CourseSearchViewModel vm) {
    final depts = state.filteredDepartments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학과',
            style: AppTextStyles.captionBold.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: '전체',
                selected: state.department == null,
                onTap: () => vm.setDepartment(null),
                showCheck: state.department == null,
              ),
              ...depts.map((d) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: _FilterChip(
                      label: d.name,
                      selected: state.department == d.code,
                      onTap: () => vm.setDepartment(
                          state.department == d.code ? null : d.code),
                      showCheck: state.department == d.code,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectList(
      CourseSearchState state, CourseSearchViewModel vm) {
    if (state.subjects.isEmpty && !state.isLoading) {
      final hasError = state.error != null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.search_rounded,
                size: 40,
                color: (hasError
                        ? AppColors.error
                        : AppColors.textTertiary)
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 14),
              Text(
                hasError
                    ? state.error!
                    : state.query.isEmpty && !state.hasActiveFilters
                        ? '과목명 또는 학수번호로\n검색해주세요'
                        : '검색 결과가 없습니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: hasError
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoading && state.subjects.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.subjects.length,
      itemBuilder: (context, index) {
        final subject = state.subjects[index];
        final isExpanded = state.expandedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SubjectCard(
            subject: subject,
            isExpanded: isExpanded,
            sections: isExpanded ? state.expandedSections : const [],
            loadingSections: isExpanded && state.loadingSections,
            onToggle: () => vm.toggleSubjectExpand(index),
            onSectionAdd: widget.onCourseAdd != null
                ? (courseId) => widget.onCourseAdd?.call(courseId, _nextColor())
                : null,
            onSectionTap: (course) {
              vm.selectCourseForInfo(course);
              _tabController.animateTo(1);
            },
            onSectionHoverEnter: widget.onCourseHoverEnter,
            onSectionHoverExit: widget.onCourseHoverExit,
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(CourseSearchState state, CourseSearchViewModel vm) {
    final course = state.selectedCourseDetail;
    if (course == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, size: 40,
                  color: AppColors.textTertiary.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text(
                '분반을 선택하면\n과목 상세 정보와 후기를 확인할 수 있습니다',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final reviews = state.selectedCourseReviews;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => vm.clearSelectedCourse(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(course.name,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // --- 과목 정보 카드 ---
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text('과목 정보',
                      style: AppTextStyles.captionBold
                          .copyWith(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              _infoLine('학수번호', course.courseCode),
              _infoLine('교수', course.professorName),
              _infoLine('분반', course.section),
              _infoLine('학점', '${course.credits}학점'),
              _infoLine('이수구분', course.courseTypeDisplay),
              if (course.departmentName.isNotEmpty)
                _infoLine('학과', course.departmentName),
              if (course.semesterStr.isNotEmpty)
                _infoLine('학기', course.semesterStr),
              if (course.isElearning)
                _infoLine('수업방식', '사이버강의 (이러닝)'),
              if (course.schedules.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('시간표', style: AppTextStyles.captionBold),
                const SizedBox(height: 4),
                ...course.schedules.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${s.dayDisplay} ${s.startTimeFormatted}~${s.endTimeFormatted}  ${s.classroomStr}',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    )),
              ],
              if (course.reviewStats != null) ...[
                const SizedBox(height: 10),
                _buildReviewStats(course.reviewStats!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // --- 후기 섹션 카드 ---
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text('강의 후기',
                      style: AppTextStyles.captionBold
                          .copyWith(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${reviews.length}개',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: 10),
              if (reviews.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('등록된 후기가 없습니다',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  ),
                )
              else
                ...reviews.map((r) => _ReviewCard(review: r)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStats(Map<String, dynamic> stats) {
    final avg = (stats['average_total_score'] as num?)?.toDouble();
    final count = stats['review_count'] as int? ?? 0;

    if (count == 0 && avg == null) return const SizedBox.shrink();

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
                Text(avg.toStringAsFixed(1),
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.primary)),
                Text('평균 평점',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary, fontSize: 10)),
              ],
            ),
          Column(
            children: [
              Text('$count',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.textPrimary)),
              Text('후기 수',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CourseReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _scoreChip('강의', review.gradeScore),
              const SizedBox(width: 4),
              _scoreChip('과제', review.assignmentScore),
              const SizedBox(width: 4),
              _scoreChip('시험', review.examScore),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _scoreColor(review.totalScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  review.totalScore.toStringAsFixed(1),
                  style: AppTextStyles.captionBold.copyWith(
                    color: _scoreColor(review.totalScore),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.content,
              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(review.authorName,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 11)),
              if (review.semesterTakenStr.isNotEmpty) ...[
                Text('  ·  ${review.semesterTakenStr}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary, fontSize: 11)),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label $grade',
          style: AppTextStyles.caption.copyWith(fontSize: 10)),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 4.0) return AppColors.successHigh;
    if (score >= 3.0) return AppColors.primary;
    if (score >= 2.0) return AppColors.warning;
    return AppColors.errorHigh;
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isExpanded;
  final List<CourseDetail> sections;
  final bool loadingSections;
  final VoidCallback onToggle;
  final void Function(int courseId)? onSectionAdd;
  final void Function(CourseDetail course) onSectionTap;
  final void Function(CourseDetail course)? onSectionHoverEnter;
  final VoidCallback? onSectionHoverExit;

  const _SubjectCard({
    required this.subject,
    required this.isExpanded,
    required this.sections,
    required this.loadingSections,
    required this.onToggle,
    this.onSectionAdd,
    required this.onSectionTap,
    this.onSectionHoverEnter,
    this.onSectionHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(subject.name,
                                  style: AppTextStyles.subtitle
                                      .copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            if (subject.courseTypeDisplay.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(subject.courseTypeDisplay,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    )),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.courseCode}  ·  ${subject.credits}학점'
                          '${subject.yearLevel != null ? '  ·  ${subject.yearLevel}학년' : ''}',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                        ),
                        if (subject.departmentName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subject.departmentName,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${subject.sectionCount}개 분반',
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 11,
                          color: AppColors.accent,
                        )),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, size: 22,
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child:
                isExpanded ? _buildSectionsArea() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsArea() {
    if (loadingSections) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('분반 정보를 불러올 수 없습니다',
            style: AppTextStyles.bodySmall),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text('분반 목록 (${sections.length}개)',
                    style: AppTextStyles.captionBold.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          ...sections.map((section) => _SectionRow(
                section: section,
                onAdd: onSectionAdd != null
                    ? () => onSectionAdd!(section.id)
                    : null,
                onTap: () => onSectionTap(section),
                onHoverEnter: onSectionHoverEnter != null
                    ? () => onSectionHoverEnter!(section)
                    : null,
                onHoverExit: onSectionHoverExit,
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final CourseDetail section;
  final VoidCallback? onAdd;
  final VoidCallback onTap;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  const _SectionRow({
    required this.section,
    this.onAdd,
    required this.onTap,
    this.onHoverEnter,
    this.onHoverExit,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleText = section.isElearning
        ? '사이버강의 (이러닝)'
        : section.schedules.isNotEmpty
            ? section.schedules
                .map((s) =>
                    '${s.dayDisplay} ${s.startTimeFormatted}~${s.endTimeFormatted} (${s.classroomStr})')
                .join(', ')
            : '시간 미정';

    return MouseRegion(
      onEnter: onHoverEnter != null ? (_) => onHoverEnter!() : null,
      onExit: onHoverExit != null ? (_) => onHoverExit!() : null,
      child: InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(section.section,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(section.professorName,
                            style:
                                AppTextStyles.subtitle.copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (section.isElearning) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('이러닝',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ],
                  ),
                  if (section.departmentName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(section.departmentName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Text(scheduleText,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 6),
              Material(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onAdd,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && selected) ...[
              Icon(Icons.check_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 2),
            ],
            Text(label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
