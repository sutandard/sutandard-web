import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/common_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../common/widgets/semester_dropdown.dart';
import '../../timetable/viewmodels/course_search_viewmodel.dart';
import '../../timetable/views/widgets/timetable_grid.dart';

final _availableClassroomsProvider =
    FutureProvider.autoDispose<List<Classroom>>((ref) async {
  final repo = ref.read(courseRepositoryProvider);
  return repo.getAvailableClassrooms();
});

final _allClassroomsProvider =
    FutureProvider.autoDispose<List<Classroom>>((ref) async {
  final repo = ref.read(courseRepositoryProvider);
  return repo.getClassrooms();
});

class AvailableClassroomsView extends ConsumerStatefulWidget {
  const AvailableClassroomsView({super.key});

  @override
  ConsumerState<AvailableClassroomsView> createState() =>
      _AvailableClassroomsViewState();
}

class _AvailableClassroomsViewState
    extends ConsumerState<AvailableClassroomsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Classroom? _selectedClassroom;
  bool _loadingSchedule = false;
  List<TimetableCourse> _classroomTimetableCourses = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _colors = [
    '#4A6CF7', '#10B981', '#F59E0B', '#EF4444',
    '#8B5CF6', '#3B82F6', '#EC4899', '#06B6D4',
  ];

  Future<void> _loadClassroomSchedule(Classroom classroom) async {
    setState(() {
      _selectedClassroom = classroom;
      _loadingSchedule = true;
      _classroomTimetableCourses = [];
    });

    try {
      final repo = ref.read(courseRepositoryProvider);
      final semesterId = ref.read(courseSearchViewModelProvider).selectedSemesterId;
      final scheduleData = await repo.getClassroomSchedule(classroom.id,
          semester: semesterId);

      // API returns { classroom: {...}, semester: {...}, schedules: [...] }
      final schedulesList = scheduleData['schedules'] as List<dynamic>? ?? [];

      // Group schedules by course_code + section to create TimetableCourse entries
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final item in schedulesList) {
        if (item is Map<String, dynamic>) {
          final key =
              '${item['course_code'] ?? ''}_${item['section'] ?? ''}';
          grouped.putIfAbsent(key, () => []).add(item);
        }
      }

      final result = <TimetableCourse>[];
      var colorIndex = 0;

      for (final entry in grouped.entries) {
        final items = entry.value;
        final first = items.first;

        // Build CourseSchedule objects from the flat schedule data
        final schedules = items.map((item) {
          return CourseSchedule(
            id: item['id'] as int? ?? 0,
            dayOfWeek: item['day_of_week'] as String? ?? '',
            dayDisplay: item['day_display'] as String? ?? '',
            startTime: item['start_time'] as String? ?? '00:00',
            endTime: item['end_time'] as String? ?? '00:00',
            classroom: classroom.id,
            classroomStr: '${classroom.buildingName} ${classroom.roomNumber}',
          );
        }).toList();

        // Build a minimal CourseList for display
        final courseDetail = CourseList(
          id: first['id'] as int? ?? 0,
          courseCode: first['course_code'] as String? ?? '',
          name: first['course_name'] as String? ?? '',
          professorName: first['professor_name'] as String? ?? '',
          semester: 0,
          semesterStr: '',
          credits: 0,
          section: first['section'] as String? ?? '',
          courseType: '',
          courseTypeDisplay: '',
          departmentName: '',
        );

        result.add(TimetableCourse(
          id: -(colorIndex + 1), // negative IDs for synthetic entries
          course: courseDetail.id,
          courseDetail: courseDetail,
          schedules: schedules,
          color: _colors[colorIndex % _colors.length],
        ));
        colorIndex++;
      }

      if (mounted) {
        setState(() {
          _classroomTimetableCourses = result;
          _loadingSchedule = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSchedule = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final responsive = Responsive(context);
    final hPad =
        responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/classrooms'),
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
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.meeting_room_outlined,
                          color: AppColors.successHigh, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('강의실 정보', style: AppTextStyles.heading3),
                          const SizedBox(height: 2),
                          Text('빈 강의실 확인 및 강의실 시간표',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    SemesterDropdown(
                      selectedId: ref.watch(courseSearchViewModelProvider
                          .select((s) => s.selectedSemesterId)),
                      onChanged: (id) {
                        ref
                            .read(courseSearchViewModelProvider.notifier)
                            .setSemester(id);
                        if (_selectedClassroom != null) {
                          _loadClassroomSchedule(_selectedClassroom!);
                        }
                      },
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    if (_selectedClassroom != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _selectedClassroom = null;
                          _classroomTimetableCourses = [];
                        }),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textTertiary),
                        tooltip: '목록으로',
                      )
                    else
                      IconButton(
                        onPressed: () {
                          ref.invalidate(_availableClassroomsProvider);
                          ref.invalidate(_allClassroomsProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textTertiary),
                        tooltip: '새로고침',
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedClassroom != null)
            Expanded(child: _buildClassroomSchedule(hPad))
          else ...[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '빈 강의실'),
                      Tab(text: '전체 강의실'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableTab(hPad),
                  _buildAllClassroomsTab(hPad),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailableTab(double hPad) {
    final classroomsAsync = ref.watch(_availableClassroomsProvider);
    return classroomsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('강의실 정보를 불러올 수 없습니다', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(_availableClassroomsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (classrooms) {
        if (classrooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, size: 48,
                    color: AppColors.textTertiary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('현재 비어있는 강의실이 없습니다',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        final grouped = <String, List<Classroom>>{};
        for (final c in classrooms) {
          grouped.putIfAbsent(c.buildingName, () => []).add(c);
        }
        final buildings = grouped.keys.toList()..sort();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: ListView.builder(
              padding:
                  EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
              itemCount: buildings.length,
              itemBuilder: (context, i) {
                final building = buildings[i];
                final rooms = grouped[building]!;
                return _BuildingSection(
                  buildingName: building,
                  classrooms: rooms,
                  onClassroomTap: _loadClassroomSchedule,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllClassroomsTab(double hPad) {
    final classroomsAsync = ref.watch(_allClassroomsProvider);
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '건물명 또는 강의실 번호 검색',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onChanged: (q) =>
                      setState(() => _searchQuery = q.toLowerCase()),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: classroomsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => Center(
              child: Text('강의실 목록을 불러올 수 없습니다',
                  style: AppTextStyles.bodySmall),
            ),
            data: (classrooms) {
              var filtered = classrooms;
              if (_searchQuery.isNotEmpty) {
                filtered = classrooms
                    .where((c) =>
                        c.buildingName
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        c.roomNumber
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        (c.name?.toLowerCase().contains(_searchQuery) ??
                            false))
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Text('검색 결과가 없습니다',
                      style: AppTextStyles.bodySmall),
                );
              }

              final grouped = <String, List<Classroom>>{};
              for (final c in filtered) {
                grouped.putIfAbsent(c.buildingName, () => []).add(c);
              }
              final buildings = grouped.keys.toList()..sort();

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                    itemCount: buildings.length,
                    itemBuilder: (context, i) {
                      final building = buildings[i];
                      final rooms = grouped[building]!;
                      return _BuildingSection(
                        buildingName: building,
                        classrooms: rooms,
                        onClassroomTap: _loadClassroomSchedule,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassroomSchedule(double hPad) {
    final cr = _selectedClassroom!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.meeting_room_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cr.buildingName} ${cr.roomNumber}',
                              style: AppTextStyles.subtitle),
                          if (cr.name != null && cr.name!.isNotEmpty)
                            Text(cr.name!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    if (!_loadingSchedule)
                      Text('${_classroomTimetableCourses.length}개 수업',
                          style: AppTextStyles.captionBold),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _loadingSchedule
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _classroomTimetableCourses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_available_rounded, size: 48,
                                    color: AppColors.successHigh.withValues(alpha: 0.5)),
                                const SizedBox(height: 14),
                                Text('이 강의실에 배정된 수업이 없습니다',
                                    style: AppTextStyles.bodySmall),
                                const SizedBox(height: 4),
                                Text('강의실이 비어있을 가능성이 높습니다',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textTertiary)),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TimetableGrid(
                                    courses: _classroomTimetableCourses,
                                  ),
                                ),
                              ),
                              _buildCourseListBar(),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseListBar() {
    if (_classroomTimetableCourses.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _classroomTimetableCourses.map((c) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.colorValue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${c.name} (${c.professorName})',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BuildingSection extends StatelessWidget {
  final String buildingName;
  final List<Classroom> classrooms;
  final void Function(Classroom) onClassroomTap;

  const _BuildingSection({
    required this.buildingName,
    required this.classrooms,
    required this.onClassroomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(buildingName, style: AppTextStyles.subtitle),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${classrooms.length}실',
                  style: AppTextStyles.captionBold.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: classrooms
              .map((c) => _RoomChip(
                    classroom: c,
                    onTap: () => onClassroomTap(c),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RoomChip extends StatelessWidget {
  final Classroom classroom;
  final VoidCallback onTap;

  const _RoomChip({required this.classroom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  classroom.roomNumber,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textTertiary),
              ],
            ),
            if (classroom.name != null && classroom.name!.isNotEmpty)
              Text(
                classroom.name!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
