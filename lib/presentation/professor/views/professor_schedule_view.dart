import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/common_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/course_search_viewmodel.dart';
import '../../timetable/views/widgets/timetable_grid.dart';
import '../../../data/models/timetable_model.dart';

final _professorsProvider =
    FutureProvider.family.autoDispose<List<Professor>, String?>(
  (ref, search) async {
    final repo = ref.read(courseRepositoryProvider);
    return repo.getProfessors(search: search);
  },
);

class ProfessorScheduleView extends ConsumerStatefulWidget {
  const ProfessorScheduleView({super.key});

  @override
  ConsumerState<ProfessorScheduleView> createState() =>
      _ProfessorScheduleViewState();
}

class _ProfessorScheduleViewState
    extends ConsumerState<ProfessorScheduleView> {
  final _searchController = TextEditingController();
  String? _searchQuery;
  Professor? _selectedProfessor;
  bool _loadingSchedule = false;
  bool _disclaimerShown = false;

  ProfessorDetail? _professorDetail;
  List<CourseDetail> _scheduleCourses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disclaimerShown) {
        _showDisclaimer();
        _disclaimerShown = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDisclaimer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 28, color: AppColors.warning),
              ),
              const SizedBox(height: 18),
              Text('주의사항',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '이 기능은 공식 오피스아워 정보가 아닙니다.',
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '수탠다드에 등록된 과목 데이터를 기반으로 '
                      '교수님이 어떤 수업을 담당하고 계신지 '
                      '시간표 형태로 보여주는 참고용 기능입니다.\n\n'
                      '실제 오피스아워, 상담 시간, 연구실 방문 가능 시간은 '
                      '해당 교수님께 직접 확인하시기 바랍니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('확인했습니다'),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _loadProfessorSchedule(Professor prof) async {
    setState(() {
      _selectedProfessor = prof;
      _loadingSchedule = true;
      _professorDetail = null;
      _scheduleCourses = [];
    });

    final repo = ref.read(courseRepositoryProvider);
    final currentSemesterId =
        ref.read(courseSearchViewModelProvider).selectedSemesterId;

    // 교수 상세 정보 (실패해도 과목 로딩은 계속)
    ProfessorDetail? detail;
    try {
      detail = await repo.getProfessorDetail(prof.id);
    } catch (_) {}

    // 교수 시간표 API 시도 (현재 학기 필터 적용)
    var courses = <CourseDetail>[];
    try {
      final scheduleData = await repo.getProfessorSchedule(
        prof.id,
        semester: currentSemesterId,
      );
      final list = scheduleData['courses'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            try {
              courses.add(CourseDetail.fromJson(item));
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // schedule API 실패 또는 결과 없으면 courses API로 fallback
    if (courses.isEmpty) {
      try {
        final response = await repo.getCourses(
          CourseSearchParams(
            professor: prof.id,
            semester: currentSemesterId,
          ),
        );
        for (final course in response.results) {
          try {
            courses.add(await repo.getCourseDetail(course.id));
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _professorDetail = detail;
        _scheduleCourses = courses;
        _loadingSchedule = false;
      });
    }
  }

  List<TimetableCourse> _toTimetableCourses() {
    if (_scheduleCourses.isEmpty) return [];
    const colors = [
      '#4A6CF7', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#3B82F6', '#EC4899', '#06B6D4',
    ];
    return _scheduleCourses
        .asMap()
        .entries
        .map((entry) => TimetableCourse(
              id: entry.value.id,
              course: entry.value.id,
              courseDetail: entry.value,
              schedules: entry.value.schedules,
              color: colors[entry.key % colors.length],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final profsAsync = ref.watch(_professorsProvider(_searchQuery));
    final responsive = Responsive(context);
    final hPad =
        responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/professor-schedule'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLoginTap: () => context.go('/login'),
            onLogoutTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              context.go('/');
            },
          ),
          Container(height: 1, color: AppColors.border),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_search_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('교수님 시간표 엿보기',
                              style: AppTextStyles.heading3),
                          const SizedBox(height: 2),
                          Text('과목 데이터 기반 · 공식 오피스아워가 아닙니다',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _showDisclaimer,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Container(
                margin: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 15, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '참고용 정보입니다. 실제 오피스아워는 교수님께 직접 확인하세요.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '교수님 성함을 검색하세요',
                      hintStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (q) =>
                        setState(() => _searchQuery = q.isEmpty ? null : q),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedProfessor != null
                ? _buildProfessorDetail(hPad)
                : _buildProfessorList(profsAsync, hPad),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessorList(
      AsyncValue<List<Professor>> profsAsync, double hPad) {
    return profsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => Center(
        child: Text('교수님 목록을 불러올 수 없습니다',
            style: AppTextStyles.bodySmall),
      ),
      data: (professors) {
        if (professors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_outlined,
                    size: 48,
                    color: AppColors.textTertiary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  _searchQuery != null ? '검색 결과가 없습니다' : '교수님 이름을 검색해주세요',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        // 단과대/학과별 그룹핑
        final grouped = <String, List<Professor>>{};
        for (final prof in professors) {
          final dept = prof.department ?? '소속 미지정';
          grouped.putIfAbsent(dept, () => []).add(prof);
        }
        final sortedKeys = grouped.keys.toList()..sort();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
              itemCount: sortedKeys.length,
              itemBuilder: (_, gi) {
                final deptName = sortedKeys[gi];
                final profs = grouped[deptName]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(deptName,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                )),
                          ),
                          const SizedBox(width: 8),
                          Text('${profs.length}명',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    ...profs.map((prof) => Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.08),
                            child: Text(
                              prof.name.isNotEmpty ? prof.name[0] : '?',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                          title: Text(prof.name, style: AppTextStyles.subtitle),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textTertiary),
                          onTap: () => _loadProfessorSchedule(prof),
                        ),
                        const Divider(height: 1),
                      ],
                    )),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessorDetail(double hPad) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _selectedProfessor = null;
                        _professorDetail = null;
                        _scheduleCourses = [];
                      }),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedProfessor!.name} 교수님',
                        style: AppTextStyles.heading3,
                      ),
                    ),
                    if (_selectedProfessor!.department != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_selectedProfessor!.department!,
                            style: AppTextStyles.captionBold),
                      ),
                  ],
                ),
              ),
              if (_professorDetail != null) _buildProfessorInfoCard(hPad),
              const SizedBox(height: 8),
              if (_loadingSchedule)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_scheduleCourses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Text('담당 과목이 없습니다',
                        style: AppTextStyles.bodySmall),
                  ),
                )
              else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Text(
                    '담당 과목 ${_scheduleCourses.length}개',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: SizedBox(
                    height: 600,
                    child: TimetableGrid(
                      courses: _toTimetableCourses(),
                    ),
                  ),
                ),
                _buildCourseListBar(hPad),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessorInfoCard(double hPad) {
    final detail = _professorDetail!;
    final hasContactInfo = detail.email != null ||
        detail.phone != null ||
        detail.officeLocation != null;
    if (!hasContactInfo && detail.officeHours.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.email != null)
            _infoRow(Icons.email_outlined, detail.email!),
          if (detail.phone != null)
            _infoRow(Icons.phone_outlined, detail.phone!),
          if (detail.officeLocation != null)
            _infoRow(Icons.location_on_outlined, detail.officeLocation!),
          if (detail.officeHours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오피스아워',
                      style: AppTextStyles.captionBold
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 6),
                  ...detail.officeHours.map((oh) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '${oh.dayDisplay} ${oh.startTime.substring(0, 5)}~${oh.endTime.substring(0, 5)}'
                          '${oh.location != null ? '  (${oh.location})' : ''}'
                          '${oh.note != null && oh.note!.isNotEmpty ? '  ${oh.note}' : ''}',
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 12, height: 1.4),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseListBar(double hPad) {
    if (_scheduleCourses.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _scheduleCourses.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${c.name} (${c.section})',
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}
