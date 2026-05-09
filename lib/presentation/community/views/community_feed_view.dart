import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../common/widgets/nav_items_builder.dart';
import '../../common/widgets/sutandard_nav_bar.dart';
import '../viewmodels/community_viewmodel.dart';
import 'widgets/post_card.dart';

class CommunityFeedView extends ConsumerStatefulWidget {
  const CommunityFeedView({super.key});

  @override
  ConsumerState<CommunityFeedView> createState() => _CommunityFeedViewState();
}

class _CommunityFeedViewState extends ConsumerState<CommunityFeedView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityFeedViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final feedState = ref.watch(communityFeedViewModelProvider);
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
            child: feedState.isLoading && feedState.posts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : feedState.error != null && feedState.posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(feedState.error!,
                                style: AppTextStyles.bodySmall),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => ref
                                  .read(communityFeedViewModelProvider.notifier)
                                  .loadPosts(),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(communityFeedViewModelProvider.notifier)
                            .loadPosts(),
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                  hPad, 24, hPad, 0),
                              sliver: SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 720),
                                    child: Row(
                                      children: [
                                        Text('시간표 공유',
                                            style: AppTextStyles.heading2),
                                        const Spacer(),
                                        if (authState.isAuthenticated)
                                          FilledButton.icon(
                                            onPressed: () =>
                                                context.go('/community/create'),
                                            icon: const Icon(
                                                Icons.edit_rounded,
                                                size: 18),
                                            label: const Text('글쓰기'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor:
                                                  AppColors.onPrimary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (feedState.posts.isEmpty)
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.forum_outlined,
                                            size: 28,
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('아직 게시글이 없습니다',
                                          style: AppTextStyles.bodySmall),
                                      const SizedBox(height: 4),
                                      Text('첫 번째 시간표 공유 글을 작성해보세요!',
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                    hPad, 16, hPad, 24),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (index >= feedState.posts.length) {
                                        return feedState.hasMore
                                            ? const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              )
                                            : null;
                                      }
                                      final post = feedState.posts[index];
                                      return Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 720),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: PostCard(
                                              post: post,
                                              onTap: () => context.go(
                                                  '/community/${post.id}'),
                                              onLikeTap: () => ref
                                                  .read(
                                                      communityFeedViewModelProvider
                                                          .notifier)
                                                  .toggleLike(post.id),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: feedState.posts.length +
                                        (feedState.hasMore ? 1 : 0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
