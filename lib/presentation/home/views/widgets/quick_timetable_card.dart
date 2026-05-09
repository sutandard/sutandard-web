import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_model.dart';
import 'dashboard_card.dart';

class QuickTimetableCard extends StatelessWidget {
  final QuickTimetableResponse data;

  const QuickTimetableCard({super.key, required this.data});

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
  static const _dayKorean = {'MON': '월', 'TUE': '화', 'WED': '수', 'THU': '목', 'FRI': '금', 'SAT': '토', 'SUN': '일'};

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Text('주간 시간표', style: AppTextStyles.heading3),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.semester,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(data.timetableName, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _dayLabels.map((day) {
                final classes =
                    (data.days[day] as List<dynamic>?) ?? [];
                final dayLabel = _dayKorean[day] ?? day;

                return Expanded(
                  child: _DayColumn(
                    dayLabel: dayLabel,
                    classes: classes,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final String dayLabel;
  final List<dynamic> classes;

  const _DayColumn({required this.dayLabel, required this.classes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            dayLabel,
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (classes.isEmpty)
          Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        else
          ...classes.map((cls) {
            final courseMap = cls as Map<String, dynamic>;
            final name = courseMap['course_name'] as String? ?? '';
            final color = _parseColor(courseMap['color'] as String? ?? '#4F46E5');

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 3, left: 2, right: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(color: color, width: 2),
                ),
              ),
              child: Text(
                name,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      final code = hex.replaceFirst('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
