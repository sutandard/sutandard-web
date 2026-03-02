import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';

class TimetableEmptyState extends StatelessWidget {
  const TimetableEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '담은 과목이 아직 없습니다',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              responsive.isDesktop
                  ? '오른쪽 패널에서 과목을 검색하고\n시간표에 추가해보세요'
                  : '과목 검색 탭에서 과목을 검색하고\n시간표에 추가해보세요',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
