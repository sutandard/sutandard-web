import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_model.dart';
import 'dashboard_card.dart';
import 'today_class_item_widget.dart';

class TodayScheduleCard extends StatelessWidget {
  final TodayScheduleResponse schedule;

  const TodayScheduleCard({super.key, required this.schedule});

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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.dayOfWeek,
                    style: AppTextStyles.captionBold,
                  ),
                ),
                const SizedBox(width: 10),
                Text('오늘의 수업', style: AppTextStyles.heading3),
                const Spacer(),
                Text(
                  schedule.date,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          if (schedule.classes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.celebration_outlined,
                          size: 24, color: AppColors.successHigh),
                    ),
                    const SizedBox(height: 12),
                    Text('오늘은 수업이 없어요!',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.successHigh)),
                  ],
                ),
              ),
            )
          else
            ...schedule.classes.map(
              (item) => TodayClassItemWidget(item: item),
            ),
        ],
      ),
    );
  }
}
