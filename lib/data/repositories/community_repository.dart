import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/common_model.dart';
import '../models/community_model.dart';

abstract class CommunityRepository {
  Future<PaginatedResponse<Post>> getPosts({
    int? page,
    String? ordering,
    String? search,
  });
  Future<PostDetail> getPost(int id);
  Future<PostDetail> createPost(PostCreate request);
  Future<PostDetail> updatePost(int id, PostUpdate request);
  Future<void> deletePost(int id);
  Future<LikeToggleResponse> toggleLike(int id);
  Future<PaginatedResponse<Comment>> getComments(int postId, {int? page});
  Future<Comment> createComment(int postId, CommentCreate request);
  Future<void> updateComment(int postId, int commentId, {String? content, bool? isAnonymous});
  Future<void> deleteComment(int postId, int commentId);
}

class CommunityRepositoryImpl implements CommunityRepository {
  final ApiClient _client;

  CommunityRepositoryImpl(this._client);

  @override
  Future<PaginatedResponse<Post>> getPosts({
    int? page,
    String? ordering,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (page != null) params['page'] = page;
    if (ordering != null) params['ordering'] = ordering;
    if (search != null) params['search'] = search;

    final response = await _client.get(
      ApiConstants.communityPosts,
      queryParameters: params.isEmpty ? null : params,
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Post.fromJson,
    );
  }

  @override
  Future<PostDetail> getPost(int id) async {
    final response = await _client.get(ApiConstants.communityPostDetail(id));
    return PostDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PostDetail> createPost(PostCreate request) async {
    final response = await _client.post(
      ApiConstants.communityPosts,
      data: request.toJson(),
    );
    return PostDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PostDetail> updatePost(int id, PostUpdate request) async {
    final response = await _client.patch(
      ApiConstants.communityPostDetail(id),
      data: request.toJson(),
    );
    return PostDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deletePost(int id) async {
    await _client.delete(ApiConstants.communityPostDetail(id));
  }

  @override
  Future<LikeToggleResponse> toggleLike(int id) async {
    final response = await _client.post(ApiConstants.communityPostLike(id));
    return LikeToggleResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResponse<Comment>> getComments(
    int postId, {
    int? page,
  }) async {
    final params = <String, dynamic>{};
    if (page != null) params['page'] = page;

    final response = await _client.get(
      ApiConstants.communityPostComments(postId),
      queryParameters: params.isEmpty ? null : params,
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Comment.fromJson,
    );
  }

  @override
  Future<Comment> createComment(int postId, CommentCreate request) async {
    final response = await _client.post(
      ApiConstants.communityPostComments(postId),
      data: request.toJson(),
    );
    return Comment.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateComment(
    int postId,
    int commentId, {
    String? content,
    bool? isAnonymous,
  }) async {
    final data = <String, dynamic>{};
    if (content != null) data['content'] = content;
    if (isAnonymous != null) data['is_anonymous'] = isAnonymous;

    await _client.patch(
      ApiConstants.communityCommentDetail(postId, commentId),
      data: data,
    );
  }

  @override
  Future<void> deleteComment(int postId, int commentId) async {
    await _client.delete(
      ApiConstants.communityCommentDetail(postId, commentId),
    );
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return CommunityRepositoryImpl(client);
});
