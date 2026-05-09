import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/community_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/timetable_viewmodel.dart';
import '../viewmodels/community_viewmodel.dart';
import 'widgets/widget_picker_sheet.dart';

class PostCreateView extends ConsumerStatefulWidget {
  const PostCreateView({super.key});

  @override
  ConsumerState<PostCreateView> createState() => _PostCreateViewState();
}

class _PostCreateViewState extends ConsumerState<PostCreateView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  int? _selectedTimetableId;
  final List<WidgetInput> _widgets = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final ttState = ref.watch(timetableViewModelProvider);
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/community'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLogoutTap: () =>
                ref.read(authViewModelProvider.notifier).logout(),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 뒤로가기
                      GestureDetector(
                        onTap: () => context.go('/community'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded,
                                size: 18, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text('목록으로', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('새 글 작성', style: AppTextStyles.heading2),
                      const SizedBox(height: 24),

                      // 제목
                      Text('제목', style: AppTextStyles.fieldLabel),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: _inputDecoration('제목을 입력하세요'),
                        style: AppTextStyles.fieldInput,
                        maxLength: 200,
                      ),
                      const SizedBox(height: 20),

                      // 내용
                      Text('내용', style: AppTextStyles.fieldLabel),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        decoration: _inputDecoration(
                            '시간표에 대한 의견을 자유롭게 작성해보세요'),
                        style: AppTextStyles.fieldInput,
                        maxLines: 8,
                        maxLength: 2000,
                      ),
                      const SizedBox(height: 20),

                      // 시간표 첨부
                      Text('시간표 첨부 (선택)',
                          style: AppTextStyles.fieldLabel),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int?>(
                          initialValue: _selectedTimetableId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          hint: Text('시간표를 선택하세요',
                              style: AppTextStyles.fieldHint),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('선택 안 함'),
                            ),
                            ...ttState.allTimetables.map((tt) =>
                                DropdownMenuItem<int?>(
                                  value: tt.id,
                                  child: Text(
                                    tt.name.isNotEmpty
                                        ? tt.name
                                        : tt.semesterStr,
                                  ),
                                )),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedTimetableId = v),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 위젯 첨부
                      Row(
                        children: [
                          Text('위젯 첨부', style: AppTextStyles.fieldLabel),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _showWidgetPicker,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('추가'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_widgets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._widgets.asMap().entries.map((entry) {
                          final typeLabel = switch (entry.value.widgetType) {
                            'course' => '강의 카드',
                            'timetable' => '시간표 미리보기',
                            'course_recommendation' => '강의 추천',
                            _ => '위젯',
                          };
                          final label = entry.value.displayName != null
                              ? '$typeLabel: ${entry.value.displayName}'
                              : typeLabel;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.widgets_outlined,
                                      size: 16,
                                      color: AppColors.textTertiary),
                                  const SizedBox(width: 8),
                                  Text(label, style: AppTextStyles.body),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _widgets.removeAt(entry.key)),
                                    child: const Icon(Icons.close,
                                        size: 16,
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 20),

                      // 익명 토글
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAnonymous,
                              onChanged: (v) =>
                                  setState(() => _isAnonymous = v ?? false),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('익명으로 작성', style: AppTextStyles.body),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 제출
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Text('게시하기',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.fieldHint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _showWidgetPicker() {
    final ttState = ref.read(timetableViewModelProvider);
    final timetables = ttState.allTimetables
        .map((tt) => (
              id: tt.id,
              name: tt.name.isNotEmpty ? tt.name : tt.semesterStr,
            ))
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => WidgetPickerSheet(
        parentContext: context,
        timetables: timetables,
        onWidgetSelected: (w) => setState(() => _widgets.add(w)),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(PostCreate(
        title: title,
        content: content,
        timetable: _selectedTimetableId,
        isAnonymous: _isAnonymous,
        widgets: _widgets,
      ));

      // 피드 새로고침
      ref.read(communityFeedViewModelProvider.notifier).loadPosts();

      if (mounted) {
        context.go('/community');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
