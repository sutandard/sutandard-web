import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/download_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../viewmodels/course_search_viewmodel.dart';
import '../viewmodels/timetable_viewmodel.dart';
import 'widgets/course_search_panel.dart';
import 'widgets/timetable_empty_state.dart';
import 'widgets/timetable_grid.dart';

class TimetableView extends ConsumerStatefulWidget {
  const TimetableView({super.key});

  @override
  ConsumerState<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends ConsumerState<TimetableView> {
  final _timetableKey = GlobalKey();
  final List<TimetableCourse> _mockCourses = [];
  int _mockIdCounter = -1;

  void _addMockCourse(int courseId, String color) async {
    try {
      final repo = ref.read(courseRepositoryProvider);
      final detail = await repo.getCourseDetail(courseId);
      setState(() {
        _mockCourses.add(TimetableCourse(
          id: _mockIdCounter--,
          course: courseId,
          courseDetail: detail,
          schedules: detail.schedules,
          color: color,
        ));
      });
    } catch (_) {}
  }

  void _removeMockCourse(TimetableCourse course) {
    setState(() {
      _mockCourses.removeWhere((c) => c.id == course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/timetable'),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildBody(context, state, ref, responsive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TimetableState state, WidgetRef ref,
      Responsive responsive) {
    final authState = ref.watch(authViewModelProvider);

    if (!authState.isAuthenticated) {
      if (responsive.isDesktop) {
        return _buildGuestDesktopLayout(context, ref);
      }
      return _buildGuestMobileLayout(context, ref);
    }

    if (state.isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (state.error != null) {
      return _buildError(context, state.error!, ref);
    }

    if (responsive.isDesktop) {
      return _buildDesktopLayout(context, state, ref);
    }
    return _buildMobileLayout(context, state, ref);
  }

  Widget _buildGuestDesktopLayout(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          key: const ValueKey('guest-desktop'),
          padding: EdgeInsets.symmetric(
            horizontal:
                responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0),
            vertical: 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 60,
                child: _buildGuestTimetableSection(context),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 40,
                child: CourseSearchPanel(
                  onCourseAdd: (courseId, color) =>
                      _addMockCourse(courseId, color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestMobileLayout(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      key: const ValueKey('guest-mobile'),
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '모의 시간표'),
              Tab(text: '과목 검색'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildGuestTimetableSection(context),
                ),
                CourseSearchPanel(
                  onCourseAdd: (courseId, color) =>
                      _addMockCourse(courseId, color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestTimetableSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('모의',
                      style: AppTextStyles.captionBold
                          .copyWith(color: AppColors.warning)),
                ),
                const SizedBox(width: 8),
                Text('모의 시간표', style: AppTextStyles.subtitle),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('로그인'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: AppTextStyles.captionBold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: _mockCourses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined,
                              size: 40,
                              color: AppColors.textTertiary
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 14),
                          Text(
                            '비로그인 모의 시간표입니다\n과목을 검색해서 추가해보세요',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: TimetableGrid(
                      courses: _mockCourses,
                      onCourseLongPress: _removeMockCourse,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, TimetableState state, WidgetRef ref) {
    final responsive = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          key: const ValueKey('desktop'),
          padding: EdgeInsets.symmetric(
            horizontal:
                responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0),
            vertical: 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 60,
                child: _buildTimetableSection(context, state, ref),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 40,
                child: CourseSearchPanel(
                  onCourseAdd: (courseId, color) {
                    ref.read(timetableViewModelProvider.notifier).addCourse(
                          AddCourseRequest(courseId: courseId, color: color),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, TimetableState state, WidgetRef ref) {
    return DefaultTabController(
      key: const ValueKey('mobile'),
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '시간표'),
              Tab(text: '과목 검색'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildTimetableSection(context, state, ref),
                ),
                CourseSearchPanel(
                  onCourseAdd: (courseId, color) {
                    ref.read(timetableViewModelProvider.notifier).addCourse(
                          AddCourseRequest(courseId: courseId, color: color),
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSection(
      BuildContext context, TimetableState state, WidgetRef ref) {
    return RepaintBoundary(
      key: _timetableKey,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            _buildTimetableHeader(context, state, ref),
            Container(height: 1, color: AppColors.border),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state.courses.isEmpty
                    ? const TimetableEmptyState(key: ValueKey('empty'))
                    : Padding(
                        key: const ValueKey('grid'),
                        padding: const EdgeInsets.all(8),
                        child: TimetableGrid(
                          courses: state.courses,
                          onCourseTap: (course, schedule) =>
                              _showCourseDetail(context, course, schedule),
                          onCourseLongPress: (course) =>
                              _showDeleteConfirm(context, ref, course),
                        ),
                      ),
              ),
            ),
            if (state.courses.isNotEmpty) _buildElearningBar(state),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableHeader(
      BuildContext context, TimetableState state, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${state.totalCredits}학점',
              style: AppTextStyles.captionBold,
            ),
          ),
          const SizedBox(width: 8),
          if (state.allTimetables.length > 1)
            GestureDetector(
              onTap: () => _showTimetableSelector(context, state, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.name.isNotEmpty ? state.name : '시간표',
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        size: 16, color: AppColors.textTertiary),
                  ],
                ),
              ),
            )
          else
            Text(
              state.name.isNotEmpty ? state.name : '나의 시간표',
              style: AppTextStyles.subtitle.copyWith(fontSize: 15),
            ),
          const Spacer(),
          if (state.semesterStr.isNotEmpty)
            Text(state.semesterStr, style: AppTextStyles.bodySmall),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: AppColors.textTertiary),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('새 시간표 후보'),
                  ],
                ),
              ),
              if (state.courses.isNotEmpty)
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('이미지로 내보내기'),
                    ],
                  ),
                ),
              if (state.courses.isNotEmpty)
                const PopupMenuItem(
                  value: 'ics',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('캘린더로 내보내기 (.ics)'),
                    ],
                  ),
                ),
              if (state.allTimetables.length > 1)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('이 시간표 삭제',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'wizard',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('시간표 마법사'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _showCreateTimetableDialog(context, ref, state);
                case 'export':
                  _exportTimetableImage(context, state);
                case 'ics':
                  _exportTimetableICS(context, state);
                case 'delete':
                  _showDeleteTimetableConfirm(context, ref, state);
                case 'wizard':
                  context.go('/wizard');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTimetableSelector(
      BuildContext context, TimetableState state, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('시간표 후보 목록', style: AppTextStyles.heading3),
              ),
              const SizedBox(height: 12),
              ...state.allTimetables.map((tt) {
                final isSelected = tt.id == state.timetable?.id;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textTertiary,
                    size: 22,
                  ),
                  title: Text(
                    tt.name.isNotEmpty ? tt.name : '시간표 ${tt.id}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${tt.semesterStr} · ${tt.totalCredits}학점 · ${tt.courses.length}과목',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(timetableViewModelProvider.notifier)
                              .setMainTimetable(tt.id);
                        },
                        child: Tooltip(
                          message: tt.isMain ? '대표 시간표' : '대표로 지정',
                          child: Icon(
                            tt.isMain
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: tt.isMain
                                ? AppColors.warning
                                : AppColors.textTertiary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref
                        .read(timetableViewModelProvider.notifier)
                        .selectTimetable(tt.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SutandardButton(
                  label: '+ 새 시간표 후보',
                  variant: SutandardButtonVariant.secondary,
                  height: 42,
                  fontSize: 14,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCreateTimetableDialog(context, ref, state);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTimetableDialog(
      BuildContext context, WidgetRef ref, TimetableState state) {
    final nameController = TextEditingController();
    final semesters =
        ref.read(courseSearchViewModelProvider).semesters;

    int? selectedSemesterId =
        state.timetable?.semester ?? semesters.firstOrNull?.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('새 시간표 후보', style: AppTextStyles.heading3),
                const SizedBox(height: 6),
                Text('같은 학기에 여러 시간표를 만들어\n수강신청에 대비하세요',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '시간표 이름 (예: 1안, 2안)',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (semesters.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedSemesterId,
                        isExpanded: true,
                        items: semesters
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.label,
                                      style: AppTextStyles.body
                                          .copyWith(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedSemesterId = v),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SutandardButton(
                        label: '취소',
                        variant: SutandardButtonVariant.secondary,
                        onPressed: () => Navigator.pop(ctx),
                        height: 44,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SutandardButton(
                        label: '생성',
                        onPressed: selectedSemesterId != null
                            ? () {
                                ref
                                    .read(
                                        timetableViewModelProvider.notifier)
                                    .createTimetable(TimetableCreate(
                                      semester: selectedSemesterId!,
                                      name: nameController.text.trim().isEmpty
                                          ? null
                                          : nameController.text.trim(),
                                    ));
                                Navigator.pop(ctx);
                              }
                            : null,
                        height: 44,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteTimetableConfirm(
      BuildContext context, WidgetRef ref, TimetableState state) {
    final tt = state.timetable;
    if (tt == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    size: 28, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text('시간표 삭제', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(
                "'${tt.name.isNotEmpty ? tt.name : '시간표'}' 후보를\n삭제할까요?",
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SutandardButton(
                      label: '취소',
                      variant: SutandardButtonVariant.secondary,
                      onPressed: () => Navigator.pop(ctx),
                      height: 44,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(timetableViewModelProvider.notifier)
                            .deleteTimetable(tt.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorHigh,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElearningBar(TimetableState state) {
    final eLearningCourses = state.courses
        .where((c) => c.courseDetail?.isElearning == true)
        .toList();

    if (eLearningCourses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('이러닝',
                style: AppTextStyles.captionBold.copyWith(fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: eLearningCourses
                  .map((c) => Chip(
                        label: Text(c.name,
                            style: AppTextStyles.caption.copyWith(fontSize: 11)),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.border),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, WidgetRef ref) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 28, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(error,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SutandardButton(
              label: '다시 시도',
              onPressed: () =>
                  ref.read(timetableViewModelProvider.notifier).refresh(),
              isExpanded: false,
              height: 42,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTimetableImage(
      BuildContext context, TimetableState state) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final boundary = _timetableKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final name = state.name.isNotEmpty ? state.name : '시간표';

      if (kIsWeb) {
        downloadFile(bytes.toList(), '${name}_시간표.png', 'image/png');
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '수탠다드 - $name',
        ),
      );
    } catch (_) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('이미지 내보내기에 실패했습니다')),
      );
    }
  }

  Future<void> _exportTimetableICS(
      BuildContext context, TimetableState state) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final name = state.name.isNotEmpty ? state.name : '시간표';
      final icsContent = _generateICS(state, name);
      final bytes = utf8.encode(icsContent);

      if (kIsWeb) {
        downloadFile(bytes, '$name.ics', 'text/calendar');
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.ics');
      await file.writeAsString(icsContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '수탠다드 - $name',
        ),
      );
    } catch (_) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('캘린더 내보내기에 실패했습니다')),
      );
    }
  }

  String _generateICS(TimetableState state, String name) {
    final buf = StringBuffer();
    buf.writeln('BEGIN:VCALENDAR');
    buf.writeln('VERSION:2.0');
    buf.writeln('PRODID:-//Sutandard//Sutandard Timetable//KO');
    buf.writeln('CALSCALE:GREGORIAN');
    buf.writeln('METHOD:PUBLISH');
    buf.writeln('X-WR-CALNAME:$name');
    buf.writeln('X-WR-TIMEZONE:Asia/Seoul');

    for (final course in state.courses) {
      for (final schedule in course.schedules) {
        final base = _nextOccurrence(schedule.dayIndex);
        final dateStr =
            '${base.year}${base.month.toString().padLeft(2, '0')}${base.day.toString().padLeft(2, '0')}';
        final sH = schedule.startHour.toString().padLeft(2, '0');
        final sM = schedule.startMinute.toString().padLeft(2, '0');
        final eH = schedule.endHour.toString().padLeft(2, '0');
        final eM = schedule.endMinute.toString().padLeft(2, '0');

        buf.writeln('BEGIN:VEVENT');
        buf.writeln(
            'UID:sutandard-${course.id}-${schedule.id}@sutandard.kr');
        buf.writeln(
            'DTSTART;TZID=Asia/Seoul:${dateStr}T$sH${sM}00');
        buf.writeln(
            'DTEND;TZID=Asia/Seoul:${dateStr}T$eH${eM}00');
        buf.writeln('RRULE:FREQ=WEEKLY;COUNT=16');
        buf.writeln('SUMMARY:${_icsEscape(course.name)}');
        buf.writeln(
            'DESCRIPTION:${_icsEscape(course.professorName)} · ${course.credits}학점');
        if (schedule.classroomStr.isNotEmpty) {
          buf.writeln('LOCATION:${_icsEscape(schedule.classroomStr)}');
        }
        buf.writeln('END:VEVENT');
      }
    }

    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  DateTime _nextOccurrence(int dayIndex) {
    // dayIndex: 0=Mon, 6=Sun; DateTime.weekday: 1=Mon, 7=Sun
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;
    final daysAhead = (dayIndex - todayIndex) % 7;
    return DateTime(today.year, today.month, today.day + daysAhead);
  }

  String _icsEscape(String text) =>
      text.replaceAll(',', '\\,').replaceAll(';', '\\;').replaceAll('\n', '\\n');

  void _showCourseDetail(
    BuildContext context,
    TimetableCourse course,
    CourseSchedule schedule,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(course.name, style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _detailRow(Icons.person_outline, course.professorName),
            _detailRow(Icons.tag_rounded, course.courseDetail?.courseCode ?? ''),
            _detailRow(Icons.room_outlined, schedule.classroomStr),
            _detailRow(
              Icons.access_time_outlined,
              '${schedule.startTimeFormatted} - ${schedule.endTimeFormatted}',
            ),
            _detailRow(Icons.school_outlined, '${course.credits}학점'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    TimetableCourse course,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    size: 28, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text('수업 삭제', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(
                "'${course.name}' 수업을\n시간표에서 삭제할까요?",
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SutandardButton(
                      label: '취소',
                      variant: SutandardButtonVariant.secondary,
                      onPressed: () => Navigator.pop(ctx),
                      height: 44,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(timetableViewModelProvider.notifier)
                            .removeCourse(course.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorHigh,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
