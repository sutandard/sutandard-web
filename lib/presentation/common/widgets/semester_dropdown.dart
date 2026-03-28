import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../timetable/viewmodels/course_search_viewmodel.dart';

class SemesterDropdown extends ConsumerWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool compact;

  const SemesterDropdown({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesters =
        ref.watch(courseSearchViewModelProvider.select((s) => s.semesters));

    if (semesters.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedId,
            isDense: true,
            icon: const Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.textTertiary),
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            items: semesters
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.label),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded,
              size: 20, color: AppColors.textTertiary),
          hint: Text('학기 선택',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint)),
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          items: semesters
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.label),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
