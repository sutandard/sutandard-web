import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/timetable_model.dart';

class LectureCard extends StatelessWidget {
  final TimetableCourse course;
  final CourseSchedule schedule;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LectureCard({
    super.key,
    required this.course,
    required this.schedule,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = course.colorValue.withValues(alpha: 0.15);
    final fgColor = course.colorValue;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: fgColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: AppTextStyles.timetableLabel.copyWith(color: fgColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              schedule.classroomStr,
              style: AppTextStyles.timetableSublabel
                  .copyWith(color: fgColor.withValues(alpha: 0.7)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
