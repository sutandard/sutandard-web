import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/community_model.dart';
import '../../../data/repositories/community_repository.dart';

// ─── Feed ───

class CommunityFeedState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const CommunityFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  CommunityFeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CommunityFeedViewModel extends Notifier<CommunityFeedState> {
  @override
  CommunityFeedState build() {
    Future.microtask(() => loadPosts());
    return const CommunityFeedState(isLoading: true);
  }

  CommunityRepository get _repo => ref.read(communityRepositoryProvider);

  Future<void> loadPosts() async {
    state = const CommunityFeedState(isLoading: true);

    try {
      final response = await _repo.getPosts(page: 1);
      state = CommunityFeedState(
        posts: response.results,
        isLoading: false,
        currentPage: 1,
        hasMore: response.hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = await _repo.getPosts(page: nextPage);
      state = state.copyWith(
        posts: [...state.posts, ...response.results],
        isLoading: false,
        currentPage: nextPage,
        hasMore: response.hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> toggleLike(int postId) async {
    // 낙관적 업데이트
    final idx = state.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = state.posts[idx];
    final optimistic = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    final updated = List<Post>.from(state.posts);
    updated[idx] = optimistic;
    state = state.copyWith(posts: updated);

    try {
      final result = await _repo.toggleLike(postId);
      updated[idx] = post.copyWith(
        isLiked: result.liked,
        likeCount: result.likeCount,
      );
      state = state.copyWith(posts: updated);
    } catch (_) {
      // 롤백
      updated[idx] = post;
      state = state.copyWith(posts: updated);
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final communityFeedViewModelProvider =
    NotifierProvider<CommunityFeedViewModel, CommunityFeedState>(
        CommunityFeedViewModel.new);

// ─── Post Detail ───

class PostDetailState {
  final PostDetail? post;
  final List<Comment> comments;
  final bool isLoading;
  final bool isCommentsLoading;
  final String? error;

  const PostDetailState({
    this.post,
    this.comments = const [],
    this.isLoading = false,
    this.isCommentsLoading = false,
    this.error,
  });

  PostDetailState copyWith({
    PostDetail? post,
    List<Comment>? comments,
    bool? isLoading,
    bool? isCommentsLoading,
    String? error,
    bool clearError = false,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isCommentsLoading: isCommentsLoading ?? this.isCommentsLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PostDetailViewModel extends FamilyNotifier<PostDetailState, int> {
  @override
  PostDetailState build(int arg) {
    Future.microtask(() => loadPost());
    return const PostDetailState(isLoading: true);
  }

  CommunityRepository get _repo => ref.read(communityRepositoryProvider);
  int get _postId => arg;

  Future<void> loadPost() async {
    state = const PostDetailState(isLoading: true);

    try {
      final results = await Future.wait([
        _repo.getPost(_postId),
        _repo.getComments(_postId),
      ]);

      state = PostDetailState(
        post: results[0] as PostDetail,
        comments: (results[1] as dynamic).results as List<Comment>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> toggleLike() async {
    final post = state.post;
    if (post == null) return;

    // 낙관적 업데이트
    state = state.copyWith(
      post: post.copyWith(
        isLiked: !post.isLiked,
        likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
      ),
    );

    try {
      final result = await _repo.toggleLike(_postId);
      state = state.copyWith(
        post: state.post!.copyWith(
          isLiked: result.liked,
          likeCount: result.likeCount,
        ),
      );
    } catch (_) {
      // 롤백
      state = state.copyWith(post: post);
    }
  }

  Future<bool> addComment(CommentCreate request) async {
    try {
      final comment = await _repo.createComment(_postId, request);
      state = state.copyWith(
        comments: [...state.comments, comment],
        post: state.post?.copyWith(
          commentCount: (state.post?.commentCount ?? 0) + 1,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _repo.deleteComment(_postId, commentId);
      state = state.copyWith(
        comments: state.comments.where((c) => c.id != commentId).toList(),
        post: state.post?.copyWith(
          commentCount: (state.post?.commentCount ?? 1) - 1,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<bool> updatePost(PostUpdate request) async {
    try {
      final updated = await _repo.updatePost(_postId, request);
      state = state.copyWith(post: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }
}

final postDetailViewModelProvider =
    NotifierProvider.family<PostDetailViewModel, PostDetailState, int>(
        PostDetailViewModel.new);
