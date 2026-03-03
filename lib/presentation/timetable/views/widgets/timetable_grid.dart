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
  final List<TimetableCourse>? previewCourses;
  final void Function(TimetableCourse course, CourseSchedule schedule)?
      onCourseTap;
  final void Function(TimetableCourse course)? onCourseLongPress;

  const TimetableGrid({
    super.key,
    required this.courses,
    this.previewCourses,
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
                                if (previewCourses != null && previewCourses!.isNotEmpty)
                                  ..._buildCourseCards(
                                    periodHeight: periodHeight,
                                    totalWidth: constraints.maxWidth,
                                    isPreview: true,
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
    bool isPreview = false,
  }) {
    final dayCount = AppConstants.timetableDays.length;
    final columnWidth = totalWidth / dayCount;
    final totalHours =
        AppConstants.timetableEndHour - AppConstants.timetableStartHour;
    final gridHeight = totalHours * periodHeight;

    // Build a list of all schedule entries with their course reference
    final entries = <_ScheduleEntry>[];
    final coursesToRender = isPreview ? (previewCourses ?? []) : courses;
    for (final course in coursesToRender) {
      for (final schedule in course.schedules) {
        if (schedule.dayIndex < 0 || schedule.dayIndex >= dayCount) continue;
        entries.add(_ScheduleEntry(course: course, schedule: schedule));
      }
    }

    // Group entries by day and compute overlap layout
    final dayEntries = <int, List<_ScheduleEntry>>{};
    for (final entry in entries) {
      dayEntries
          .putIfAbsent(entry.schedule.dayIndex, () => [])
          .add(entry);
    }

    final widgets = <Widget>[];

    for (final dayIndex in dayEntries.keys) {
      final dayList = dayEntries[dayIndex]!;
      // Sort by start time
      dayList.sort(
          (a, b) => a.schedule.startInMinutes.compareTo(b.schedule.startInMinutes));

      // Assign columns to overlapping entries
      final columns = _assignOverlapColumns(dayList);

      for (var i = 0; i < dayList.length; i++) {
        final entry = dayList[i];
        final col = columns[i];

        final topOffset =
            (entry.schedule.startHour - AppConstants.timetableStartHour +
                    entry.schedule.startMinute / 60) *
                periodHeight;
        final height = entry.schedule.durationInMinutes / 60 * periodHeight;

        // Clamp cards that extend outside the grid area
        if (topOffset + height <= 0 || topOffset >= gridHeight) continue;
        final clampedTop = topOffset.clamp(0.0, gridHeight - 4.0);
        final clampedHeight = (height - (clampedTop - topOffset)).clamp(4.0, gridHeight - clampedTop);

        final slotWidth = columnWidth / col.total;
        final left = dayIndex * columnWidth + col.index * slotWidth;

        widgets.add(
          Positioned(
            left: left,
            top: clampedTop,
            width: slotWidth,
            height: clampedHeight,
            child: isPreview
                ? _buildPreviewCard(entry.course, entry.schedule)
                : LectureCard(
                    course: entry.course,
                    schedule: entry.schedule,
                    isOverlapping: col.total > 1,
                    onTap: onCourseTap != null
                        ? () => onCourseTap!(entry.course, entry.schedule)
                        : null,
                    onLongPress: onCourseLongPress != null
                        ? () => onCourseLongPress!(entry.course)
                        : null,
                  ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildPreviewCard(TimetableCourse course, CourseSchedule schedule) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: course.colorValue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: course.colorValue.withValues(alpha: 0.4),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          course.name,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: course.colorValue.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Assigns column index and total columns for overlapping schedule entries.
  List<_OverlapColumn> _assignOverlapColumns(List<_ScheduleEntry> entries) {
    final result = List.filled(entries.length, const _OverlapColumn(0, 1));

    // Find overlap groups
    final groups = <List<int>>[];
    final visited = <int>{};

    for (var i = 0; i < entries.length; i++) {
      if (visited.contains(i)) continue;

      final group = [i];
      visited.add(i);

      for (var j = i + 1; j < entries.length; j++) {
        if (visited.contains(j)) continue;
        // Check if j overlaps with any member of the group
        for (final member in group) {
          if (_overlaps(entries[member].schedule, entries[j].schedule)) {
            group.add(j);
            visited.add(j);
            break;
          }
        }
      }
      groups.add(group);
    }

    for (final group in groups) {
      final total = group.length;
      // Sort group members by start time for consistent column assignment
      group.sort((a, b) => entries[a]
          .schedule
          .startInMinutes
          .compareTo(entries[b].schedule.startInMinutes));
      for (var col = 0; col < group.length; col++) {
        result[group[col]] = _OverlapColumn(col, total);
      }
    }

    return result;
  }

  bool _overlaps(CourseSchedule a, CourseSchedule b) {
    if (a.dayIndex != b.dayIndex) return false;
    return a.startInMinutes < b.endInMinutes &&
        a.endInMinutes > b.startInMinutes;
  }
}

class _ScheduleEntry {
  final TimetableCourse course;
  final CourseSchedule schedule;
  const _ScheduleEntry({required this.course, required this.schedule});
}

class _OverlapColumn {
  final int index;
  final int total;
  const _OverlapColumn(this.index, this.total);
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
