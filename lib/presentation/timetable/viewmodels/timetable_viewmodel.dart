import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

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
  bool _isLoadingInProgress = false;

  @override
  TimetableState build() {
    // auth 상태를 watch하여 로그인/로그아웃 시 자동으로 build()가 재실행됨
    final authState = ref.watch(authViewModelProvider);

    if (!authState.isAuthenticated) {
      // 비로그인 상태: 빈 상태 반환 (로딩 없음)
      return const TimetableState();
    }

    // 로그인 상태: 동기적으로 isLoading: true를 반환하여
    // UI가 "시간표 만들기" 가이드를 보여주지 않도록 함
    _isLoadingInProgress = false; // auth 변경 시 재로드 허용
    _loadTimetables();
    return const TimetableState(isLoading: true);
  }

  TimetableRepository get _repository =>
      ref.read(timetableRepositoryProvider);

  CourseRepository get _courseRepo =>
      ref.read(courseRepositoryProvider);

  Future<void> _loadTimetables() async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;
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
    } finally {
      _isLoadingInProgress = false;
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
          name: latest.label,
          isMain: true,
        ),
      );

      state = TimetableState(
        timetable: newTt,
        allTimetables: [newTt],
      );
    } catch (e) {
      state = TimetableState(error: '시간표 자동 생성에 실패했습니다. 아래에서 직접 만들어주세요.');
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

  Future<void> removeCourse(int courseId) async {
    final timetable = state.timetable;
    if (timetable == null) return;

    try {
      await _repository.removeCourse(timetable.id, courseId);
      final updatedCourses =
          timetable.courses.where((c) => c.course != courseId).toList();
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

  Future<void> updateCourseColor(int courseId, String color) async {
    final timetable = state.timetable;
    if (timetable == null) return;

    try {
      final updated = await _repository.updateCourse(
        timetable.id,
        courseId,
        color: color,
      );
      final updatedCourses = timetable.courses.map((c) {
        if (c.course == courseId) return updated;
        return c;
      }).toList();
      state = state.copyWith(
        timetable: Timetable(
          id: timetable.id,
          semester: timetable.semester,
          semesterStr: timetable.semesterStr,
          name: timetable.name,
          isMain: timetable.isMain,
          createdAt: timetable.createdAt,
          courses: updatedCourses,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  /// Returns list of existing courses that conflict with the given schedules.
  List<TimetableCourse> findConflicts(List<CourseSchedule> newSchedules) {
    final existing = state.courses;
    final conflicts = <TimetableCourse>{};
    for (final newSch in newSchedules) {
      for (final course in existing) {
        for (final existSch in course.schedules) {
          if (_schedulesOverlap(newSch, existSch)) {
            conflicts.add(course);
          }
        }
      }
    }
    return conflicts.toList();
  }

  static bool _schedulesOverlap(CourseSchedule a, CourseSchedule b) {
    if (a.dayIndex != b.dayIndex) return false;
    return a.startInMinutes < b.endInMinutes &&
        a.endInMinutes > b.startInMinutes;
  }

  Future<TimetableImportResult?> importFromPortal(
      String portalPassword, {int? semester}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.importFromPortal(
        portalPassword,
        semester: semester,
      );
      // 가져온 시간표로 상태 업데이트
      final updatedList = [...state.allTimetables];
      final existingIdx =
          updatedList.indexWhere((t) => t.id == result.timetable.id);
      if (existingIdx >= 0) {
        updatedList[existingIdx] = result.timetable;
      } else {
        updatedList.add(result.timetable);
      }
      state = TimetableState(
        timetable: result.timetable,
        allTimetables: updatedList,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
      return null;
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
