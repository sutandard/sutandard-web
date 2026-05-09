import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/community_model.dart';
import 'course_search_dialog.dart';

class WidgetPickerSheet extends StatelessWidget {
  final void Function(WidgetInput widget) onWidgetSelected;
  final BuildContext parentContext;

  /// 시간표 위젯 첨부 시 선택 가능한 시간표 목록
  final List<({int id, String name})> timetables;

  const WidgetPickerSheet({
    super.key,
    required this.onWidgetSelected,
    required this.parentContext,
    this.timetables = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('위젯 첨부', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text('게시글에 첨부할 위젯을 선택하세요',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          _OptionTile(
            icon: Icons.book_outlined,
            color: AppColors.primary,
            title: '강의 카드',
            description: '특정 강의를 카드로 첨부합니다',
            onTap: () async {
              Navigator.pop(context);
              final course =
                  await CourseSearchDialog.show(parentContext);
              if (course != null) {
                onWidgetSelected(WidgetInput(
                  widgetType: 'course',
                  data: {'course_id': course.id},
                  displayName: '${course.name} · ${course.professorName}',
                ));
              }
            },
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.calendar_today_rounded,
            color: AppColors.accent,
            title: '시간표 미리보기',
            description: '내 시간표를 미리보기로 첨부합니다',
            onTap: () async {
              Navigator.pop(context);
              if (timetables.isEmpty) return;
              if (timetables.length == 1) {
                final tt = timetables.first;
                onWidgetSelected(WidgetInput(
                  widgetType: 'timetable',
                  data: {'timetable_id': tt.id},
                  displayName: tt.name,
                ));
                return;
              }
              final selected = await showDialog<({int id, String name})>(
                context: parentContext,
                builder: (ctx) => SimpleDialog(
                  title: const Text('시간표 선택'),
                  children: timetables
                      .map((tt) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, tt),
                            child: Text(tt.name),
                          ))
                      .toList(),
                ),
              );
              if (selected != null) {
                onWidgetSelected(WidgetInput(
                  widgetType: 'timetable',
                  data: {'timetable_id': selected.id},
                  displayName: selected.name,
                ));
              }
            },
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.thumb_up_outlined,
            color: AppColors.successHigh,
            title: '강의 추천',
            description: '추천할 강의를 카드로 첨부합니다',
            onTap: () async {
              Navigator.pop(context);
              final course =
                  await CourseSearchDialog.show(parentContext);
              if (course != null) {
                onWidgetSelected(WidgetInput(
                  widgetType: 'course_recommendation',
                  data: {
                    'original_course_id': course.id,
                    'recommended_course_id': course.id,
                  },
                  displayName: '${course.name} · ${course.professorName}',
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
