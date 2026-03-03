import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../viewmodels/timetable_viewmodel.dart';
import 'widgets/timetable_grid.dart';

class WizardView extends ConsumerStatefulWidget {
  const WizardView({super.key});

  @override
  ConsumerState<WizardView> createState() => _WizardViewState();
}

class _WizardViewState extends ConsumerState<WizardView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _mobileTabController;
  final List<WizardCourseGroup> _courseGroups = [];
  List<List<CourseDetail>> _generatedCombinations = [];
  int _currentComboIndex = 0;
  bool _isSearching = false;
  bool _isGenerating = false;
  List<CourseList> _searchResults = [];

  // Preferences
  bool _noMorning = false;
  bool _lunchBreak = false;
  int? _maxDays;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mobileTabController.dispose();
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

  void _addCourseToGroup(CourseList course) {
    setState(() {
      final existingGroup = _courseGroups.where(
        (g) => g.courseName == course.name,
      );
      if (existingGroup.isNotEmpty) {
        if (!existingGroup.first.sections.any((s) => s.id == course.id)) {
          existingGroup.first.sections.add(course);
        }
      } else {
        _courseGroups.add(WizardCourseGroup(
          courseName: course.name,
          sections: [course],
        ));
      }
      _searchResults = [];
      _searchController.clear();
      _generatedCombinations = [];
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _courseGroups.removeAt(index);
      _generatedCombinations = [];
    });
  }

  void _removeSection(int groupIdx, int sectionIdx) {
    setState(() {
      _courseGroups[groupIdx].sections.removeAt(sectionIdx);
      if (_courseGroups[groupIdx].sections.isEmpty) {
        _courseGroups.removeAt(groupIdx);
      }
      _generatedCombinations = [];
    });
  }

  Future<void> _generateCombinations() async {
    if (_courseGroups.isEmpty) return;
    setState(() => _isGenerating = true);

    try {
      final repo = ref.read(courseRepositoryProvider);
      final detailedGroups = <List<CourseDetail>>[];

      for (final group in _courseGroups) {
        final details = <CourseDetail>[];
        for (final section in group.sections) {
          final detail = await repo.getCourseDetail(section.id);
          details.add(detail);
        }
        detailedGroups.add(details);
      }

      final combos = _findValidCombinations(detailedGroups);

      if (!mounted) return;
      setState(() {
        _generatedCombinations = combos;
        _currentComboIndex = 0;
        _isGenerating = false;
      });
      if (combos.isNotEmpty && !Responsive(context).isDesktop) {
        _mobileTabController.animateTo(1);
      }
    } catch (_) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  List<List<CourseDetail>> _findValidCombinations(
      List<List<CourseDetail>> groups) {
    final results = <List<CourseDetail>>[];
    _backtrack(groups, 0, [], results);
    return results.take(50).toList();
  }

  void _backtrack(
    List<List<CourseDetail>> groups,
    int groupIdx,
    List<CourseDetail> current,
    List<List<CourseDetail>> results,
  ) {
    if (results.length >= 50) return;
    if (groupIdx == groups.length) {
      if (_matchesPreferences(current)) {
        results.add(List.from(current));
      }
      return;
    }

    for (final course in groups[groupIdx]) {
      if (!_hasConflict(current, course)) {
        current.add(course);
        _backtrack(groups, groupIdx + 1, current, results);
        current.removeLast();
      }
    }
  }

  bool _hasConflict(List<CourseDetail> selected, CourseDetail candidate) {
    for (final existing in selected) {
      for (final es in existing.schedules) {
        for (final cs in candidate.schedules) {
          if (es.dayOfWeek == cs.dayOfWeek) {
            if (es.startInMinutes < cs.endInMinutes &&
                cs.startInMinutes < es.endInMinutes) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  bool _matchesPreferences(List<CourseDetail> combo) {
    if (_noMorning) {
      for (final c in combo) {
        for (final s in c.schedules) {
          if (s.startHour < 10) return false;
        }
      }
    }
    if (_lunchBreak) {
      for (final c in combo) {
        for (final s in c.schedules) {
          if (s.startInMinutes < 780 && s.endInMinutes > 720) return false;
        }
      }
    }
    if (_maxDays != null) {
      final days = <int>{};
      for (final c in combo) {
        for (final s in c.schedules) {
          days.add(s.dayIndex);
        }
      }
      if (days.length > _maxDays!) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final responsive = Responsive(context);

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
            child: responsive.isDesktop
                ? Row(
                    children: [
                      Expanded(flex: 40, child: _buildLeftPanel()),
                      Container(width: 1, color: AppColors.border),
                      Expanded(flex: 60, child: _buildRightPanel()),
                    ],
                  )
                : Column(
                    children: [
                      TabBar(
                        controller: _mobileTabController,
                        tabs: const [
                          Tab(text: '과목 선택'),
                          Tab(text: '미리보기'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _mobileTabController,
                          children: [
                            _buildLeftPanel(),
                            _buildRightPanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_fix_high_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text('시간표 마법사', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 6),
                Text('듣고 싶은 과목을 추가하면\n가능한 시간표 조합을 만들어드려요',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 14),
                _buildSearchInput(),
              ],
            ),
          ),
          if (_searchResults.isNotEmpty || _isSearching)
            _buildSearchResults(),
          Container(height: 1, color: AppColors.border),
          Expanded(child: _buildCourseGroups()),
          Container(height: 1, color: AppColors.border),
          _buildPreferences(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SutandardButton(
              label: _isGenerating
                  ? '조합 생성 중...'
                  : '시간표 조합 생성 (${_courseGroups.length}과목)',
              onPressed:
                  _courseGroups.length >= 2 ? _generateCombinations : null,
              isLoading: _isGenerating,
              icon: Icons.auto_fix_high_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
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
          hintText: '과목명으로 검색해서 추가',
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: _searchCourses,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (_, i) {
          final course = _searchResults[i];
          return ListTile(
            dense: true,
            title: Text(course.name,
                style: AppTextStyles.body.copyWith(fontSize: 13)),
            subtitle: Text(
              '${course.professorName} · ${course.section}분반 · ${course.courseTypeDisplay}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: AppColors.primary),
              onPressed: () => _addCourseToGroup(course),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseGroups() {
    if (_courseGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_rounded,
                size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('과목을 2개 이상 추가해주세요', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _courseGroups.length,
      itemBuilder: (_, gi) {
        final group = _courseGroups[gi];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
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
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${gi + 1}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(group.courseName,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: () => _removeGroup(gi),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...group.sections.asMap().entries.map((e) {
                final si = e.key;
                final section = e.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${section.professorName} · ${section.section}분반',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeSection(gi, si),
                        child: const Icon(Icons.remove_circle_outline,
                            size: 16, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }),
              Text(
                '${group.sections.length}개 분반',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('조건 설정',
              style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PrefChip(
                label: '1교시 제외',
                selected: _noMorning,
                onTap: () => setState(() => _noMorning = !_noMorning),
              ),
              _PrefChip(
                label: '점심시간 확보',
                selected: _lunchBreak,
                onTap: () => setState(() => _lunchBreak = !_lunchBreak),
              ),
              _PrefChip(
                label: '주 3일',
                selected: _maxDays == 3,
                onTap: () => setState(
                    () => _maxDays = _maxDays == 3 ? null : 3),
              ),
              _PrefChip(
                label: '주 4일',
                selected: _maxDays == 4,
                onTap: () => setState(
                    () => _maxDays = _maxDays == 4 ? null : 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    if (_generatedCombinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_fix_high_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('시간표 마법사', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '과목을 추가하고 조합 생성 버튼을 누르면\n가능한 시간표 조합을 보여드려요',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final combo = _generatedCombinations[_currentComboIndex];
    final courses = combo
        .map((c) => TimetableCourse(
              id: c.id,
              course: c.id,
              courseDetail: CourseList(
                id: c.id,
                courseCode: c.courseCode,
                name: c.name,
                professorName: c.professorName,
                semester: c.semester,
                semesterStr: c.semesterStr,
                credits: c.credits,
                section: c.section,
                courseType: c.courseType,
                courseTypeDisplay: c.courseTypeDisplay,
              ),
              schedules: c.schedules,
              color: _colorForIndex(combo.indexOf(c)),
            ))
        .toList();

    final totalCredits = combo.fold<int>(0, (sum, c) => sum + c.credits);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _currentComboIndex > 0
                    ? () => setState(() => _currentComboIndex--)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '조합 ${_currentComboIndex + 1} / ${_generatedCombinations.length}'
                    ' · $totalCredits학점',
                    style: AppTextStyles.subtitle,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed:
                    _currentComboIndex < _generatedCombinations.length - 1
                        ? () => setState(() => _currentComboIndex++)
                        : null,
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TimetableGrid(courses: courses),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SutandardButton(
            label: '이 시간표로 저장',
            onPressed: () => _saveCombination(combo),
          ),
        ),
      ],
    );
  }

  String _colorForIndex(int i) {
    const colors = [
      '#4A6CF7', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#3B82F6', '#EC4899', '#06B6D4',
    ];
    return colors[i % colors.length];
  }

  Future<void> _saveCombination(List<CourseDetail> combo) async {
    final ttVm = ref.read(timetableViewModelProvider.notifier);
    for (final course in combo) {
      await ttVm.addCourse(AddCourseRequest(
        courseId: course.id,
        color: _colorForIndex(combo.indexOf(course)),
      ));
    }
    if (mounted) {
      context.go('/timetable');
    }
  }
}

class WizardCourseGroup {
  final String courseName;
  final List<CourseList> sections;

  WizardCourseGroup({required this.courseName, required this.sections});
}

class _PrefChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
