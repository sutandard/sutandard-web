import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/review_model.dart';
import '../../../common/widgets/sutandard_button.dart';
import '../../viewmodels/review_viewmodel.dart';

class ReviewFormWidget extends ConsumerStatefulWidget {
  final int courseId;
  final VoidCallback? onSuccess;

  const ReviewFormWidget({
    super.key,
    required this.courseId,
    this.onSuccess,
  });

  @override
  ConsumerState<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends ConsumerState<ReviewFormWidget> {
  final _contentController = TextEditingController();
  int _gradeScore = 3;
  int _assignmentScore = 3;
  int _examScore = 3;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;

    final success =
        await ref.read(reviewViewModelProvider.notifier).createReview(
              CreateReviewRequest(
                course: widget.courseId,
                content: _contentController.text.trim(),
                gradeScore: _gradeScore,
                assignmentScore: _assignmentScore,
                examScore: _examScore,
              ),
            );

    if (success && mounted) {
      _contentController.clear();
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewViewModelProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('후기 작성', style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          _ScoreRow(
            label: '강의',
            score: _gradeScore,
            onChanged: (v) => setState(() => _gradeScore = v),
          ),
          const SizedBox(height: 8),
          _ScoreRow(
            label: '과제',
            score: _assignmentScore,
            onChanged: (v) => setState(() => _assignmentScore = v),
          ),
          const SizedBox(height: 8),
          _ScoreRow(
            label: '시험',
            score: _examScore,
            onChanged: (v) => setState(() => _examScore = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: '강의에 대한 솔직한 후기를 남겨주세요. (20~500자)',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text('* ${state.error}', style: AppTextStyles.error),
          ],
          const SizedBox(height: 16),
          SutandardButton(
            label: '후기 등록',
            height: 50,
            fontSize: 16,
            onPressed: _submit,
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final ValueChanged<int> onChanged;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: AppTextStyles.body),
        ),
        ...List.generate(5, (i) {
          final val = i + 1;
          return GestureDetector(
            onTap: () => onChanged(val),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                val <= score ? Icons.star : Icons.star_border,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          );
        }),
      ],
    );
  }
}
