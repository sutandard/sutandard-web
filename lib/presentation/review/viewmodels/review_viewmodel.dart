import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';

class ReviewState {
  final List<CourseReview> reviews;
  final bool isLoading;
  final String? error;
  final int? courseFilter;

  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.courseFilter,
  });

  ReviewState copyWith({
    List<CourseReview>? reviews,
    bool? isLoading,
    String? error,
    int? courseFilter,
    bool clearError = false,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      courseFilter: courseFilter ?? this.courseFilter,
    );
  }
}

class ReviewViewModel extends Notifier<ReviewState> {
  @override
  ReviewState build() => const ReviewState();

  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  Future<void> loadReviews({int? courseId}) async {
    state = state.copyWith(
        isLoading: true, clearError: true, courseFilter: courseId);

    try {
      final response = await _repo.getReviews(course: courseId);
      state = state.copyWith(
        reviews: response.results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<bool> createReview(CreateReviewRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repo.createReview(request);
      await loadReviews(courseId: state.courseFilter);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateReview(int id, CreateReviewRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateReview(id, request);
      state = state.copyWith(
        isLoading: false,
        reviews: state.reviews.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
      return false;
    }
  }

  Future<void> deleteReview(int id) async {
    try {
      await _repo.deleteReview(id);
      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final reviewViewModelProvider =
    NotifierProvider<ReviewViewModel, ReviewState>(ReviewViewModel.new);
