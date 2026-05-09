import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/community_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../timetable/views/widgets/timetable_grid.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../../timetable/viewmodels/timetable_viewmodel.dart';
import '../viewmodels/community_viewmodel.dart';
import 'widgets/comment_item.dart';
import 'widgets/content_widget_card.dart';
import 'widgets/widget_picker_sheet.dart';

class PostDetailView extends ConsumerStatefulWidget {
  final int postId;
  const PostDetailView({super.key, required this.postId});

  @override
  ConsumerState<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends ConsumerState<PostDetailView> {
  final _commentController = TextEditingController();
  bool _isAnonymousComment = false;
  final List<WidgetInput> _commentWidgets = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final detailState = ref.watch(postDetailViewModelProvider(widget.postId));
    final responsive = Responsive(context);
    final hPad = responsive.value(mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SutandardNavBar(
            navItems: buildMainNavItems(context, '/community'),
            onLoginTap: authState.isAuthenticated
                ? null
                : () => context.go('/login'),
            showProfile: authState.isAuthenticated,
            userName: authState.user?.name,
            onLogoutTap: () =>
                ref.read(authViewModelProvider.notifier).logout(),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: detailState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : detailState.error != null && detailState.post == null
                    ? Center(
                        child: Text(detailState.error!,
                            style: AppTextStyles.bodySmall))
                    : detailState.post == null
                        ? const SizedBox.shrink()
                        : _buildContent(
                            context,
                            ref,
                            detailState,
                            authState,
                            hPad,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PostDetailState detailState,
    AuthState authState,
    double hPad,
  ) {
    final post = detailState.post!;
    return Column(
      children: [
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

                    // 작성자 정보
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              post.isAnonymous
                                  ? '?'
                                  : post.authorName.isNotEmpty
                                      ? post.authorName[0]
                                      : '?',
                              style: AppTextStyles.captionBold
                                  .copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.isAnonymous ? '익명' : post.authorName,
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatDateTime(post.createdAt),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (post.isMine)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: AppColors.textTertiary),
                            onSelected: (v) => _handlePostAction(v, ref),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('수정')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('삭제')),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 제목
                    Text(post.title, style: AppTextStyles.heading2),
                    const SizedBox(height: 12),

                    // 본문
                    Text(post.content, style: AppTextStyles.body),
                    const SizedBox(height: 16),

                    // 첨부된 시간표
                    if (post.timetableDetail != null) ...[
                      _buildTimetablePreview(post.timetableDetail!),
                      const SizedBox(height: 16),
                    ],

                    // 위젯들
                    if (post.widgets.isNotEmpty) ...[
                      ...post.widgets.map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ContentWidgetCard(widget: w),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 좋아요 + 댓글 수
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(postDetailViewModelProvider(widget.postId)
                                    .notifier)
                                .toggleLike(),
                            child: Row(
                              children: [
                                Icon(
                                  post.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: post.isLiked
                                      ? AppColors.error
                                      : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '좋아요 ${post.likeCount}',
                                  style: AppTextStyles.body.copyWith(
                                    color: post.isLiked
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 18, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            '댓글 ${post.commentCount}',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 댓글 목록
                    Text('댓글', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    if (detailState.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('아직 댓글이 없습니다',
                              style: AppTextStyles.bodySmall),
                        ),
                      )
                    else
                      ...detailState.comments.map(
                        (c) => CommentItem(
                          comment: c,
                          onDelete: c.isMine
                              ? () => _deleteComment(ref, c.id)
                              : null,
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 댓글 입력
        if (authState.isAuthenticated)
          Container(
            padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_commentWidgets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _commentWidgets.asMap().entries.map((entry) {
                            final typeLabel = switch (entry.value.widgetType) {
                              'course' => '강의',
                              'timetable' => '시간표',
                              'course_recommendation' => '추천',
                              _ => '위젯',
                            };
                            final label = entry.value.displayName != null
                                ? '$typeLabel: ${entry.value.displayName}'
                                : typeLabel;
                            return Chip(
                              label: Text(label, style: AppTextStyles.caption),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => setState(
                                  () => _commentWidgets.removeAt(entry.key)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _isAnonymousComment = !_isAnonymousComment),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isAnonymousComment
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '익명',
                              style: AppTextStyles.caption.copyWith(
                                color: _isAnonymousComment
                                    ? AppColors.primary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _showCommentWidgetPicker,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: _commentWidgets.isNotEmpty
                              ? AppColors.primary
                              : AppColors.textHint,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: '위젯 첨부',
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: '댓글을 입력하세요',
                              hintStyle: AppTextStyles.fieldHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              isDense: true,
                            ),
                            style: AppTextStyles.fieldInput,
                            maxLines: 1,
                            onSubmitted: (_) => _submitComment(ref),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _submitComment(ref),
                          icon: const Icon(Icons.send_rounded),
                          color: AppColors.primary,
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _submitComment(WidgetRef ref) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(postDetailViewModelProvider(widget.postId).notifier)
        .addComment(CommentCreate(
          content: text,
          isAnonymous: _isAnonymousComment,
          widgets: _commentWidgets,
        ));

    if (success) {
      _commentController.clear();
      setState(() => _commentWidgets.clear());
    }
  }

  void _deleteComment(WidgetRef ref, int commentId) {
    ref
        .read(postDetailViewModelProvider(widget.postId).notifier)
        .deleteComment(commentId);
  }

  void _showCommentWidgetPicker() {
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
        onWidgetSelected: (w) => setState(() => _commentWidgets.add(w)),
      ),
    );
  }

  void _handlePostAction(String action, WidgetRef ref) async {
    if (action == 'edit') {
      final post = ref.read(postDetailViewModelProvider(widget.postId)).post;
      if (post == null) return;
      await _showEditDialog(ref, post);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제',
                    style: TextStyle(color: AppColors.errorHigh))),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await ref
            .read(communityFeedViewModelProvider.notifier)
            .deletePost(widget.postId);
        if (mounted) context.go('/community');
      }
    }
  }

  Future<void> _showEditDialog(WidgetRef ref, PostDetail post) async {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 수정'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: AppTextStyles.fieldInput,
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: AppTextStyles.fieldInput,
                maxLines: 6,
                maxLength: 2000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final title = titleController.text.trim();
      final content = contentController.text.trim();
      if (title.isEmpty || content.isEmpty) return;

      final success = await ref
          .read(postDetailViewModelProvider(widget.postId).notifier)
          .updatePost(PostUpdate(title: title, content: content));

      if (success && mounted) {
        // 피드도 새로고침
        ref.read(communityFeedViewModelProvider.notifier).loadPosts();
      }
    }

    titleController.dispose();
    contentController.dispose();
  }

  Widget _buildTimetablePreview(Map<String, dynamic> timetableJson) {
    final timetable = Timetable.fromJson(timetableJson);
    final courses = timetable.courses;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timetable.name.isNotEmpty
                        ? timetable.name
                        : timetable.semesterStr,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${timetable.totalCredits}학점',
                    style: AppTextStyles.captionBold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          if (courses.isNotEmpty)
            SizedBox(
              height: 360,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TimetableGrid(courses: courses),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('등록된 과목이 없습니다',
                    style: AppTextStyles.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
