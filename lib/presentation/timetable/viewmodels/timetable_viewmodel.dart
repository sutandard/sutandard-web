import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/timetable_repository.dart';

class TimetableState {
  final Timetable? timetable;
  final List<Timetable> allTimetables;
  final bool isLoading;
  final String? error;

  const TimetableState({
    this.timetable,
    this.allTimetables = const [],
    this.isLoading = false,
    this.error,
  });

  List<TimetableCourse> get courses => timetable?.courses ?? [];
  int get totalCredits => timetable?.totalCredits ?? 0;
  String get semesterStr => timetable?.semesterStr ?? '';
  String get name => timetable?.name ?? '';

  TimetableState copyWith({
    Timetable? timetable,
    List<Timetable>? allTimetables,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TimetableState(
      timetable: timetable ?? this.timetable,
      allTimetables: allTimetables ?? this.allTimetables,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TimetableViewModel extends Notifier<TimetableState> {
  @override
  TimetableState build() {
    _loadTimetables();
    return const TimetableState(isLoading: true);
  }

  TimetableRepository get _repository =>
      ref.read(timetableRepositoryProvider);

  CourseRepository get _courseRepo =>
      ref.read(courseRepositoryProvider);

  Future<void> _loadTimetables() async {
    try {
      final timetables = await _repository.getTimetables();

      if (timetables.isEmpty) {
        await _autoCreateLatestSemesterTimetable();
        return;
      }

      final main = timetables.firstWhere(
        (t) => t.isMain,
        orElse: () => timetables.first,
      );
      state = TimetableState(
        timetable: main,
        allTimetables: timetables,
      );
    } catch (e) {
      if (e is DioException && e.error is ApiException) {
        final apiErr = e.error as ApiException;
        if (apiErr.statusCode == 401) {
          state = const TimetableState();
          return;
        }
      }
      state = TimetableState(error: extractErrorMessage(e));
    }
  }

  Future<void> _autoCreateLatestSemesterTimetable() async {
    try {
      final semesters = await _courseRepo.getSemesters();
      if (semesters.isEmpty) {
        state = const TimetableState();
        return;
      }

      final latest = semesters.first;
      final newTt = await _repository.createTimetable(
        TimetableCreate(
          semester: latest.id,
          name: latest.shortLabel,
          isMain: true,
        ),
      );

      state = TimetableState(
        timetable: newTt,
        allTimetables: [newTt],
      );
    } catch (_) {
      state = const TimetableState();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadTimetables();
  }

  void selectTimetable(int id) {
    final tt = state.allTimetables.where((t) => t.id == id).firstOrNull;
    if (tt != null) {
      state = state.copyWith(timetable: tt);
    }
  }

  Future<void> createTimetable(TimetableCreate request) async {
    try {
      final newTt = await _repository.createTimetable(request);
      state = state.copyWith(
        timetable: newTt,
        allTimetables: [...state.allTimetables, newTt],
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> deleteTimetable(int id) async {
    try {
      await _repository.deleteTimetable(id);
      final remaining = state.allTimetables.where((t) => t.id != id).toList();
      state = TimetableState(
        timetable: remaining.isNotEmpty ? remaining.first : null,
        allTimetables: remaining,
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> addCourse(AddCourseRequest request) async {
    final timetable = state.timetable;
    if (timetable == null) return;

    try {
      final newCourse =
          await _repository.addCourse(timetable.id, request);
      final updatedCourses = [...timetable.courses, newCourse];
      final updated = Timetable(
        id: timetable.id,
        semester: timetable.semester,
        semesterStr: timetable.semesterStr,
        name: timetable.name,
        isMain: timetable.isMain,
        createdAt: timetable.createdAt,
        courses: updatedCourses,
      );
      state = state.copyWith(timetable: updated);
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> removeCourse(int timetableCourseId) async {
    final timetable = state.timetable;
    if (timetable == null) return;

    try {
      await _repository.removeCourse(timetable.id, timetableCourseId);
      final updatedCourses =
          timetable.courses.where((c) => c.id != timetableCourseId).toList();
      final updated = Timetable(
        id: timetable.id,
        semester: timetable.semester,
        semesterStr: timetable.semesterStr,
        name: timetable.name,
        isMain: timetable.isMain,
        createdAt: timetable.createdAt,
        courses: updatedCourses,
      );
      state = state.copyWith(timetable: updated);
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> setMainTimetable(int id) async {
    try {
      final updated = await _repository.updateTimetable(id, isMain: true);
      final updatedList = state.allTimetables.map((t) {
        if (t.id == id) return updated;
        if (t.isMain) {
          return Timetable(
            id: t.id,
            semester: t.semester,
            semesterStr: t.semesterStr,
            name: t.name,
            isMain: false,
            createdAt: t.createdAt,
            courses: t.courses,
          );
        }
        return t;
      }).toList();
      state = state.copyWith(
        timetable: state.timetable?.id == id ? updated : state.timetable,
        allTimetables: updatedList,
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final timetableViewModelProvider =
    NotifierProvider<TimetableViewModel, TimetableState>(
  TimetableViewModel.new,
);
