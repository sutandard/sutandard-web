import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/common_model.dart';
import '../models/review_model.dart';

abstract class ReviewRepository {
  Future<PaginatedResponse<CourseReview>> getReviews({
    int? course,
    String? ordering,
    int? page,
  });
  Future<CourseReview> createReview(CreateReviewRequest request);
  Future<CourseReview> updateReview(int id, CreateReviewRequest request);
  Future<void> deleteReview(int id);
  Future<PaginatedResponse<CourseReview>> getSubjectReviews(
    String courseCode, {
    String? professor,
    int? semester,
  });
}

class ReviewRepositoryImpl implements ReviewRepository {
  final ApiClient _client;

  ReviewRepositoryImpl(this._client);

  @override
  Future<PaginatedResponse<CourseReview>> getReviews({
    int? course,
    String? ordering,
    int? page,
  }) async {
    final params = <String, dynamic>{};
    if (course != null) params['course'] = course;
    if (ordering != null) params['ordering'] = ordering;
    if (page != null) params['page'] = page;

    final response = await _client.get(
      ApiConstants.reviews,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      CourseReview.fromJson,
    );
  }

  @override
  Future<CourseReview> createReview(CreateReviewRequest request) async {
    final response = await _client.post(
      ApiConstants.reviews,
      data: request.toJson(),
    );
    return CourseReview.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CourseReview> updateReview(
      int id, CreateReviewRequest request) async {
    final response = await _client.patch(
      ApiConstants.reviewDetail(id),
      data: request.toJson(),
    );
    return CourseReview.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReview(int id) async {
    await _client.delete(ApiConstants.reviewDetail(id));
  }

  @override
  Future<PaginatedResponse<CourseReview>> getSubjectReviews(
    String courseCode, {
    String? professor,
    int? semester,
  }) async {
    final params = <String, dynamic>{};
    if (professor != null) params['professor'] = professor;
    if (semester != null) params['semester'] = semester;

    final response = await _client.get(
      ApiConstants.reviewsBySubject(courseCode),
      queryParameters: params.isEmpty ? null : params,
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      CourseReview.fromJson,
    );
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return ReviewRepositoryImpl(client);
});
