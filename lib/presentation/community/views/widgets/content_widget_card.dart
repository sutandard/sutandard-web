import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/community_model.dart';

class ContentWidgetCard extends StatelessWidget {
  final ContentWidget widget;

  const ContentWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return switch (widget.widgetType) {
      'course' => _CourseWidget(data: widget.resolvedData ?? widget.data),
      'timetable' => _TimetableWidget(data: widget.resolvedData ?? widget.data),
      'course_recommendation' => _RecommendationWidget(
          data: widget.resolvedData ?? widget.data),
      _ => _UnknownWidget(type: widget.widgetType),
    };
  }
}

class _CourseWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CourseWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final courseName = data['name'] as String? ?? data['course_name'] as String? ?? '과목';
    final professorName = data['professor_name'] as String? ?? '';
    final scheduleStr = data['schedule'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/courses?q=${Uri.encodeComponent(courseName)}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book_outlined,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (professorName.isNotEmpty || scheduleStr.isNotEmpty)
                    Text(
                      [professorName, scheduleStr]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _TimetableWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TimetableWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '시간표';
    final courses = data['courses'] as List<dynamic>? ?? [];
    final onlineCourses = data['online_courses'] as List<dynamic>? ?? [];
    final allCourseCount = courses.length + onlineCourses.length;
    final courseCount = data['course_count'] as int? ?? allCourseCount;
    final totalCredits = data['total_credits'] as int? ??
        _computeCredits([...courses, ...onlineCourses]);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$courseCount과목 · $totalCredits학점',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _computeCredits(List<dynamic> courses) {
    var total = 0;
    for (final c in courses) {
      if (c is Map<String, dynamic>) {
        final detail = c['course_detail'] as Map<String, dynamic>?;
        total += (detail?['credits'] as int?) ?? (c['credits'] as int? ?? 0);
      }
    }
    return total;
  }
}

class _RecommendationWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RecommendationWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final recommended = data['recommended'] as Map<String, dynamic>?;
    final courseName = recommended?['name'] as String?
        ?? data['name'] as String?
        ?? data['course_name'] as String?
        ?? '추천 강의';
    final professorName = recommended?['professor_name'] as String?
        ?? data['professor_name'] as String?
        ?? '';
    final reason = data['reason'] as String? ?? '';
    final subtitle = [
      if (professorName.isNotEmpty) professorName,
      if (reason.isNotEmpty) reason,
    ].join(' · ');

    return GestureDetector(
      onTap: () {
        context.push('/courses?q=${Uri.encodeComponent(courseName)}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.thumb_up_outlined,
                  size: 18, color: AppColors.successHigh),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _UnknownWidget extends StatelessWidget {
  final String type;
  const _UnknownWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('위젯: $type', style: AppTextStyles.bodySmall),
    );
  }
}
