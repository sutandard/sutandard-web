import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/timetable_model.dart';
import 'lecture_card.dart';

class TimetableGrid extends StatelessWidget {
  final List<TimetableCourse> courses;
  final void Function(TimetableCourse course, CourseSchedule schedule)?
      onCourseTap;
  final void Function(TimetableCourse course)? onCourseLongPress;

  const TimetableGrid({
    super.key,
    required this.courses,
    this.onCourseTap,
    this.onCourseLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final periodHeight = responsive.timetablePeriodHeight;
    final timeLabelWidth = responsive.timetableTimeLabelWidth;
    final headerHeight = responsive.timetableHeaderHeight;
    final totalHours =
        AppConstants.timetableEndHour - AppConstants.timetableStartHour;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _DayHeader(
              timeLabelWidth: timeLabelWidth,
              height: headerHeight,
            ),
            const Divider(height: 0),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: totalHours * periodHeight,
                  child: Row(
                    children: [
                      _TimeLabels(
                        width: timeLabelWidth,
                        periodHeight: periodHeight,
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                _GridLines(periodHeight: periodHeight),
                                ..._buildCourseCards(
                                  periodHeight: periodHeight,
                                  totalWidth: constraints.maxWidth,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCourseCards({
    required double periodHeight,
    required double totalWidth,
  }) {
    final dayCount = AppConstants.timetableDays.length;
    final columnWidth = totalWidth / dayCount;
    final widgets = <Widget>[];

    for (final course in courses) {
      for (final schedule in course.schedules) {
        if (schedule.dayIndex < 0 || schedule.dayIndex >= dayCount) continue;

        final topOffset =
            (schedule.startHour - AppConstants.timetableStartHour +
                    schedule.startMinute / 60) *
                periodHeight;
        final height = schedule.durationInMinutes / 60 * periodHeight;

        widgets.add(
          Positioned(
            left: schedule.dayIndex * columnWidth,
            top: topOffset,
            width: columnWidth,
            height: height,
            child: LectureCard(
              course: course,
              schedule: schedule,
              onTap: onCourseTap != null
                  ? () => onCourseTap!(course, schedule)
                  : null,
              onLongPress: onCourseLongPress != null
                  ? () => onCourseLongPress!(course)
                  : null,
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _DayHeader extends StatelessWidget {
  final double timeLabelWidth;
  final double height;

  const _DayHeader({
    required this.timeLabelWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(width: timeLabelWidth),
          ...AppConstants.timetableDays.map(
            (day) => Expanded(
              child: Center(
                child: Text(day, style: AppTextStyles.captionBold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLabels extends StatelessWidget {
  final double width;
  final double periodHeight;

  const _TimeLabels({
    required this.width,
    required this.periodHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: List.generate(
          AppConstants.timetableEndHour - AppConstants.timetableStartHour,
          (index) {
            final hour = AppConstants.timetableStartHour + index;
            return SizedBox(
              height: periodHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$hour',
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridLines extends StatelessWidget {
  final double periodHeight;

  const _GridLines({required this.periodHeight});

  @override
  Widget build(BuildContext context) {
    final totalHours =
        AppConstants.timetableEndHour - AppConstants.timetableStartHour;
    final dayCount = AppConstants.timetableDays.length;

    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(
        periodHeight: periodHeight,
        totalHours: totalHours,
        dayCount: dayCount,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double periodHeight;
  final int totalHours;
  final int dayCount;

  _GridPainter({
    required this.periodHeight,
    required this.totalHours,
    required this.dayCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final columnWidth = size.width / dayCount;

    for (var i = 0; i <= totalHours; i++) {
      final y = i * periodHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 1; i < dayCount; i++) {
      final x = i * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      periodHeight != old.periodHeight ||
      totalHours != old.totalHours ||
      dayCount != old.dayCount;
}
