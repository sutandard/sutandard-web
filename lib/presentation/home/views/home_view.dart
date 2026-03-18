import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';

import '../../../data/models/review_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_button.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/timetable_viewmodel.dart';
import '../../timetable/views/widgets/timetable_grid.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/home_footer.dart';
import 'widgets/home_search_panel.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/'),
            onLoginTap: authState.isAuthenticated
                ? null
                : () => context.go('/login'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLogoutTap: () => ref.read(authViewModelProvider.notifier).logout(),
            onDeleteAccountTap: () async {
              final success = await ref.read(authViewModelProvider.notifier).deleteAccount();
              if (success && context.mounted) {
                context.go('/');
              }
            },
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  const _HeroSection(),
                  const SizedBox(height: 32),
                  _MainDashboard(),
                  const SizedBox(height: 28),
                  const _QuickAccessCards(),
                  const SizedBox(height: 48),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatefulWidget {
  const _HeroSection();

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  bool _showSearchPanel = false;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final maxWidth = responsive.value(
      mobile: double.infinity,
      tablet: 660.0,
      desktop: 720.0,
    );
    final hPad = responsive.value(mobile: 16.0, tablet: 20.0, desktop: 0.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Text(
                '수원대 시간표, 더 스마트하게',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: responsive.value(mobile: 24.0, desktop: 30.0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '과목 검색부터 시간표 관리까지 한 곳에서',
                style: AppTextStyles.bodyLight,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!_showSearchPanel) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearchPanel = true),
                    child: Container(
                      height: responsive.value(mobile: 50.0, desktop: 56.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '과목명, 교수명을 등을 검색해보세요',
                              style: AppTextStyles.searchHint,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '검색',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                HomeSearchPanel(
                  onSearch: (filters) {
                    setState(() => _showSearchPanel = false);
                    final query = filters.query;
                    if (query.isNotEmpty) {
                      context.go('/courses?q=${Uri.encodeComponent(query)}');
                    } else {
                      context.go('/courses');
                    }
                  },
                  onClose: () => setState(() => _showSearchPanel = false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MainDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: responsive.isDesktop
              ? _desktopLayout(context, ref)
              : _mobileLayout(context, ref),
        ),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 60,
          child: SizedBox(height: 680, child: _TimetableCard()),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 40,
          child: Column(
            children: [
              const _CurrentTimeCard(),
              const SizedBox(height: 16),
              _CurrentLectureCard(),
              const SizedBox(height: 16),
              const SizedBox(height: 500, child: _ReviewCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const _CurrentTimeCard(),
        const SizedBox(height: 16),
        _CurrentLectureCard(),
        const SizedBox(height: 16),
        SizedBox(height: 480, child: _TimetableCard()),
        const SizedBox(height: 16),
        const SizedBox(height: 400, child: _ReviewCard()),
      ],
    );
  }
}

class _TimetableCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttState = ref.watch(timetableViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    return DashboardCard(
      child: Column(
        children: [
          _timetableHeader(ttState),
          Container(height: 1, color: AppColors.border),
          Expanded(child: _timetableBody(context, ttState, authState)),
        ],
      ),
    );
  }

  Widget _timetableBody(
      BuildContext context, TimetableState ttState, AuthState authState) {
    if (!authState.isAuthenticated) {
      return _loginPrompt(context);
    }
    if (ttState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (ttState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            ttState.error!,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (ttState.courses.isEmpty) {
      return _emptyTimetable(context);
    }

    final elearningCourses =
        ttState.courses.where((c) => c.isElearning).toList();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TimetableGrid(courses: ttState.courses),
          ),
        ),
        if (elearningCourses.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.laptop_chromebook_rounded,
                          size: 11, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text('사이버강의',
                          style: AppTextStyles.captionBold.copyWith(
                            fontSize: 10,
                            color: AppColors.accent,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: elearningCourses
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        c.colorValue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: c.colorValue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(c.name,
                                      style: AppTextStyles.caption
                                          .copyWith(fontSize: 10)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _loginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '로그인하면 나의 시간표를\n확인할 수 있어요',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SutandardButton(
              label: '로그인',
              onPressed: () => context.go('/login'),
              isExpanded: false,
              height: 42,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTimetable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 등록된 과목이 없습니다',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            SutandardButton(
              label: '시간표 만들기',
              onPressed: () => context.go('/timetable'),
              isExpanded: false,
              height: 42,
              fontSize: 14,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _timetableHeader(TimetableState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          const Spacer(),
          Text(
            state.name.isNotEmpty ? state.name : '나의 시간표',
            style: AppTextStyles.heading3,
          ),
          const Spacer(),
          if (state.semesterStr.isNotEmpty)
            Text(
              state.semesterStr,
              style: AppTextStyles.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _CurrentTimeCard extends StatefulWidget {
  const _CurrentTimeCard();

  @override
  State<_CurrentTimeCard> createState() => _CurrentTimeCardState();
}

class _CurrentTimeCardState extends State<_CurrentTimeCard> {
  late DateTime _now;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String get _formattedDate {
    final weekday = _weekdays[_now.weekday - 1];
    return '${_now.year}년 ${_now.month}월 ${_now.day}일 ($weekday)';
  }

  String get _formattedClock {
    final amPm = _now.hour < 12 ? '오전' : '오후';
    final hour = _now.hour == 0
        ? 12
        : _now.hour > 12
            ? _now.hour - 12
            : _now.hour;
    return '$amPm $hour:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formattedDate,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(_formattedClock,
                    style: AppTextStyles.heading2.copyWith(
                      fontFeatures: [const FontFeature.tabularFigures()],
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PortalChip(onTap: _openPortal),
        ],
      ),
    );
  }

  Future<void> _openPortal() async {
    final uri = Uri.parse('https://portal.suwon.ac.kr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _PortalChip extends StatefulWidget {
  final VoidCallback onTap;
  const _PortalChip({required this.onTap});

  @override
  State<_PortalChip> createState() => _PortalChipState();
}

class _PortalChipState extends State<_PortalChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('수원대 포털',
                  style: AppTextStyles.captionBold
                      .copyWith(color: AppColors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 13, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLectureCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final ttState = ref.watch(timetableViewModelProvider);

    if (!authState.isAuthenticated || ttState.courses.isEmpty) {
      return _emptyLectureCard(context, authState.isAuthenticated);
    }

    final now = DateTime.now();
    final dayIndex = now.weekday - 1;
    final nowMinutes = now.hour * 60 + now.minute;

    Map<String, String>? currentLecture;
    Map<String, String>? nextLecture;

    for (final course in ttState.courses) {
      for (final schedule in course.schedules) {
        if (schedule.dayIndex != dayIndex) continue;

        final start = schedule.startInMinutes;
        final end = schedule.endInMinutes;

        if (nowMinutes >= start && nowMinutes < end) {
          currentLecture = {
            'name': course.name,
            'time':
                '${schedule.startTimeFormatted} ~ ${schedule.endTimeFormatted}',
            'room': schedule.classroomStr ?? '',
          };
        } else if (nowMinutes < start) {
          if (nextLecture == null ||
              start < int.parse(nextLecture['_start'] ?? '9999')) {
            nextLecture = {
              'name': course.name,
              'time':
                  '${schedule.startTimeFormatted} ~ ${schedule.endTimeFormatted}',
              'room': schedule.classroomStr ?? '',
              '_start': '$start',
            };
          }
        }
      }
    }

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
            child: Row(
              children: [
                Expanded(child: _lectureLabel('현재', '강의')),
                Container(width: 1, height: 18, color: AppColors.border),
                Expanded(child: _lectureLabel('다음', '강의')),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: currentLecture != null
                        ? _lectureInfo(
                            name: currentLecture['name']!,
                            time: currentLecture['time']!,
                            room: currentLecture['room']!,
                          )
                        : _noLectureInfo('진행 중인 강의가\n없습니다'),
                  ),
                  Container(width: 1, color: AppColors.border),
                  Expanded(
                    child: nextLecture != null
                        ? _lectureInfo(
                            name: nextLecture['name']!,
                            time: nextLecture['time']!,
                            room: nextLecture['room']!,
                          )
                        : _noLectureInfo('오늘 남은 강의가\n없습니다'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lectureLabel(String accent, String text) {
    return Center(
      child: RichText(
        text: TextSpan(style: AppTextStyles.body, children: [
          TextSpan(
            text: accent,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
          ),
          TextSpan(text: ' $text'),
        ]),
      ),
    );
  }

  Widget _emptyLectureCard(BuildContext context, bool isAuthenticated) {
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
            child: Row(
              children: [
                Expanded(child: _lectureLabel('현재', '강의')),
                Container(width: 1, height: 18, color: AppColors.border),
                Expanded(child: _lectureLabel('다음', '강의')),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                isAuthenticated
                    ? '시간표에 과목을 추가하면\n현재/다음 강의를 확인할 수 있어요'
                    : '로그인하면 오늘의 강의를\n확인할 수 있어요',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lectureInfo({
    required String name,
    required String time,
    required String room,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            name,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(time, style: AppTextStyles.bodyLight, textAlign: TextAlign.center),
          Text(room, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _noLectureInfo(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        message,
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Review Card - course detail 조회로 강의명/교수명 보강

final _homeReviewsProvider = FutureProvider.autoDispose((ref) async {
  final reviewRepo = ref.read(reviewRepositoryProvider);
  final courseRepo = ref.read(courseRepositoryProvider);
  final response = await reviewRepo.getReviews(ordering: '-created_at');

  final enriched = <_EnrichedReview>[];
  for (final review in response.results.take(10)) {
    String courseName = review.courseName;
    String professorName = review.professorName;

    if (courseName.isEmpty) {
      try {
        final detail = await courseRepo.getCourseDetail(review.course);
        courseName = detail.name;
        professorName =
            professorName.isEmpty ? detail.professorName : professorName;
      } catch (_) {}
    }

    enriched.add(_EnrichedReview(
      review: review,
      courseName: courseName,
      professorName: professorName,
    ));
  }
  return enriched;
});

class _EnrichedReview {
  final CourseReview review;
  final String courseName;
  final String professorName;

  const _EnrichedReview({
    required this.review,
    required this.courseName,
    required this.professorName,
  });
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_homeReviewsProvider);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.subtitle,
                    children: [
                      const TextSpan(text: '강의 '),
                      TextSpan(
                        text: '후기',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.rate_review_outlined,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 32,
                          color: AppColors.textTertiary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('후기를 불러올 수 없습니다', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => ref.invalidate(_homeReviewsProvider),
                        child: Text(
                          '다시 시도',
                          style: AppTextStyles.captionBold
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 32,
                              color:
                                  AppColors.textTertiary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('아직 작성된 후기가 없습니다',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(height: 1, color: AppColors.divider),
                  ),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      final courseName = reviews[i].courseName;
                      if (courseName.isNotEmpty) {
                        context.go('/courses?q=${Uri.encodeComponent(courseName)}');
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _ReviewItem(enriched: reviews[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final _EnrichedReview enriched;
  const _ReviewItem({required this.enriched});

  @override
  Widget build(BuildContext context) {
    final review = enriched.review;
    final courseName = enriched.courseName;
    final professorName = enriched.professorName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (courseName.isNotEmpty)
                    Text(
                      courseName,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (professorName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        professorName,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor(review.totalScore).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 14, color: _scoreColor(review.totalScore)),
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
        const SizedBox(height: 8),
        Text(
          review.content,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _gradeChip('학점', review.gradeGrade),
            const SizedBox(width: 6),
            _gradeChip('과제', review.assignmentGrade),
            const SizedBox(width: 6),
            _gradeChip('시험', review.examGrade),
            const Spacer(),
            if (review.semesterTakenStr.isNotEmpty)
              Text(
                review.semesterTakenStr,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 11),
              ),
          ],
        ),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 4) return AppColors.successHigh;
    if (score >= 3) return AppColors.primary;
    if (score >= 2) return AppColors.warning;
    return AppColors.error;
  }

  Widget _gradeChip(String label, String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $grade',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _QuickAccessCards extends StatelessWidget {
  const _QuickAccessCards();

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: responsive.isMobile
              ? Column(
                  children: [
                    _QuickCard(
                      title: '빈 강의실',
                      subtitle: '지금 비어있는 강의실 찾기',
                      icon: Icons.door_back_door_outlined,
                      onTap: () => context.go('/classrooms'),
                    ),
                    const SizedBox(height: 12),
                    _QuickCard(
                      title: '시간표 엿보기',
                      subtitle: '교수님 담당 과목 확인',
                      icon: Icons.person_search_outlined,
                      onTap: () => context.go('/professor-schedule'),
                    ),
                    const SizedBox(height: 12),
                    _QuickCard(
                      title: '오늘의 학식',
                      subtitle: '학생식당 메뉴 보기',
                      icon: Icons.restaurant_menu_rounded,
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        title: '빈 강의실',
                        subtitle: '지금 비어있는 강의실 찾기',
                        icon: Icons.door_back_door_outlined,
                        onTap: () => context.go('/classrooms'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickCard(
                        title: '시간표 엿보기',
                        subtitle: '교수님 담당 과목 확인',
                        icon: Icons.person_search_outlined,
                        onTap: () => context.go('/professor-schedule'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickCard(
                        title: '오늘의 학식',
                        subtitle: '학생식당 메뉴 보기',
                        icon: Icons.restaurant_menu_rounded,
                        onTap: () => _showComingSoon(context),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('학식 메뉴 기능은 곧 출시됩니다!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _QuickCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovering ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hovering
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: _hovering ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.subtitle),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _hovering ? AppColors.primary : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
