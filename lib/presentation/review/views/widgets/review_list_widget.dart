import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/review_model.dart';
import '../../viewmodels/review_viewmodel.dart';

class ReviewListWidget extends ConsumerWidget {
  final int? courseId;

  const ReviewListWidget({super.key, this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewViewModelProvider);

    if (state.isLoading && state.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 48, color: AppColors.textTertiary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                '아직 후기가 없습니다.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) =>
          _ReviewItem(review: state.reviews[index]),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final CourseReview review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              review.semesterTakenStr,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
            const Spacer(),
            _ScoreBadge(label: '강의', score: review.gradeScore),
            const SizedBox(width: 6),
            _ScoreBadge(label: '과제', score: review.assignmentScore),
            const SizedBox(width: 6),
            _ScoreBadge(label: '시험', score: review.examScore),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.content,
          style: AppTextStyles.bodySmall.copyWith(height: 1.6),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                i < review.totalScore.round()
                    ? Icons.star
                    : Icons.star_border,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              review.totalScore.toStringAsFixed(1),
              style: AppTextStyles.captionBold,
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBadge({required this.label, required this.score});

  static const _grades = ['F', 'D', 'C', 'B', 'A'];

  @override
  Widget build(BuildContext context) {
    final grade = score >= 1 && score <= 5 ? _grades[score - 1] : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $grade',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
