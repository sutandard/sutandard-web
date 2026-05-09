import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/community_model.dart';
import 'content_widget_card.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.isAnonymous
                    ? '?'
                    : comment.authorName.isNotEmpty
                        ? comment.authorName[0]
                        : '?',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.isAnonymous ? '익명' : comment.authorName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment.createdAt),
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    if (comment.isMine && onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.textHint),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTextStyles.body,
                ),
                if (comment.widgets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...comment.widgets.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ContentWidgetCard(widget: w),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
