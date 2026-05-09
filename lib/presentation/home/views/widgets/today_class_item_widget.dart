import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_model.dart';

class TodayClassItemWidget extends StatelessWidget {
  final TodayClassItem item;

  const TodayClassItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(item.color);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // 상태 인디케이터 + 색상 바
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: item.isDone
                    ? AppColors.disabled
                    : item.isInProgress
                        ? color
                        : color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),

            // 시간
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(item.startTime),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.isDone
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    _formatTime(item.endTime),
                    style: AppTextStyles.caption.copyWith(
                      color: item.isDone
                          ? AppColors.textHint
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 과목 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.courseName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.isDone
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    [item.professor, item.classroom]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 상태 뱃지
            _StatusBadge(status: item.status),
          ],
        ),
      ),
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

  String _formatTime(String time) {
    // "09:00:00" → "09:00"
    if (time.length >= 5) return time.substring(0, 5);
    return time;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = switch (status) {
      'done' => ('완료', AppColors.disabled.withValues(alpha: 0.2), AppColors.textHint),
      'in_progress' => ('수업 중', AppColors.success.withValues(alpha: 0.15), AppColors.successHigh),
      'upcoming' => ('예정', AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
      _ => ('', AppColors.cardBackground, AppColors.textTertiary),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
