import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum SutandardButtonVariant { primary, secondary, text }

class SutandardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SutandardButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final double height;
  final double fontSize;
  final IconData? icon;

  const SutandardButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SutandardButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 52,
    this.fontSize = 16,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == SutandardButtonVariant.primary
                  ? AppColors.onPrimary
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return switch (variant) {
      SutandardButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.button.copyWith(fontSize: fontSize),
          ),
          child: child,
        ),
      SutandardButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            textStyle: AppTextStyles.button.copyWith(fontSize: fontSize),
          ),
          child: child,
        ),
      SutandardButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isExpanded ? double.infinity : 0, height),
          ),
          child: child,
        ),
    };
  }
}
