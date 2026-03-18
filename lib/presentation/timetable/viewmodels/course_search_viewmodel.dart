import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/common_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';

class CourseSearchState {
  final String query;
  final String? courseType;
  final bool? isElearning;
  final int? yearLevel;
  final String? department;
  final int? selectedCollegeId;
  final List<Subject> subjects;
  final bool isLoading;
  final String? error;
  final List<Semester> semesters;
  final int? selectedSemesterId;
  final List<College> colleges;
  final List<Department> departments;

  final int? expandedIndex;
  final List<CourseDetail> expandedSections;
  final bool loadingSections;

  final CourseDetail? selectedCourseDetail;
  final List<CourseReview> selectedCourseReviews;

  const CourseSearchState({
    this.query = '',
    this.courseType,
    this.isElearning,
    this.yearLevel,
    this.department,
    this.selectedCollegeId,
    this.subjects = const [],
    this.isLoading = false,
    this.error,
    this.semesters = const [],
    this.selectedSemesterId,
    this.colleges = const [],
    this.departments = const [],
    this.expandedIndex,
    this.expandedSections = const [],
    this.loadingSections = false,
    this.selectedCourseDetail,
    this.selectedCourseReviews = const [],
  });

  bool get hasActiveFilters =>
      courseType != null ||
      isElearning != null ||
      yearLevel != null ||
      department != null ||
      selectedCollegeId != null;

  /// Returns filtered departments based on selected college
  List<Department> get filteredDepartments {
    if (selectedCollegeId == null) return departments;
    return departments
        .where((d) => d.college == selectedCollegeId)
        .toList();
  }

  CourseSearchState copyWith({
    String? query,
    Object? courseType = _sentinel,
    Object? isElearning = _sentinel,
    Object? yearLevel = _sentinel,
    Object? department = _sentinel,
    Object? selectedCollegeId = _sentinel,
    List<Subject>? subjects,
    bool? isLoading,
    String? error,
    List<Semester>? semesters,
    int? selectedSemesterId,
    List<College>? colleges,
    List<Department>? departments,
    Object? expandedIndex = _sentinel,
    List<CourseDetail>? expandedSections,
    bool? loadingSections,
    Object? selectedCourseDetail = _sentinel,
    List<CourseReview>? selectedCourseReviews,
    bool clearFilters = false,
    bool clearError = false,
  }) {
    return CourseSearchState(
      query: query ?? this.query,
      courseType: clearFilters
          ? null
          : courseType == _sentinel
              ? this.courseType
              : courseType as String?,
      isElearning: clearFilters
          ? null
          : isElearning == _sentinel
              ? this.isElearning
              : isElearning as bool?,
      yearLevel: clearFilters
          ? null
          : yearLevel == _sentinel
              ? this.yearLevel
              : yearLevel as int?,
      department: clearFilters
          ? null
          : department == _sentinel
              ? this.department
              : department as String?,
      selectedCollegeId: clearFilters
          ? null
          : selectedCollegeId == _sentinel
              ? this.selectedCollegeId
              : selectedCollegeId as int?,
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      semesters: semesters ?? this.semesters,
      selectedSemesterId: selectedSemesterId ?? this.selectedSemesterId,
      colleges: colleges ?? this.colleges,
      departments: departments ?? this.departments,
      expandedIndex: expandedIndex == _sentinel
          ? this.expandedIndex
          : expandedIndex as int?,
      expandedSections: expandedSections ?? this.expandedSections,
      loadingSections: loadingSections ?? this.loadingSections,
      selectedCourseDetail: selectedCourseDetail == _sentinel
          ? this.selectedCourseDetail
          : selectedCourseDetail as CourseDetail?,
      selectedCourseReviews:
          selectedCourseReviews ?? this.selectedCourseReviews,
    );
  }
}

const _sentinel = Object();

class CourseSearchViewModel extends Notifier<CourseSearchState> {
  @override
  CourseSearchState build() {
    _loadInitialData();
    return const CourseSearchState();
  }

  CourseRepository get _repo => ref.read(courseRepositoryProvider);
  ReviewRepository get _reviewRepo => ref.read(reviewRepositoryProvider);

  Future<void> _loadInitialData() async {
    List<Semester> semesters = [];
    List<College> colleges = [];
    List<Department> departments = [];

    // Load each independently so one failure doesn't block others
    try {
      semesters = await _repo.getSemesters();
    } catch (_) {}

    try {
      colleges = await _repo.getColleges();
    } catch (_) {}

    try {
      departments = await _repo.getDepartments();
    } catch (_) {}

    state = state.copyWith(
      semesters: semesters,
      selectedSemesterId: semesters.isNotEmpty ? semesters.first.id : null,
      colleges: colleges,
      departments: departments,
    );
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      query: query,
      isLoading: true,
      clearError: true,
      subjects: [],
      expandedIndex: null,
      expandedSections: [],
      selectedCourseDetail: null,
      selectedCourseReviews: [],
    );

    // Determine college name for API filter (subjects endpoint takes string)
    String? collegeName;
    if (state.selectedCollegeId != null) {
      final match = state.colleges
          .where((c) => c.id == state.selectedCollegeId)
          .firstOrNull;
      collegeName = match?.name;
    }

    try {
      final results = await _repo.getSubjects(SubjectSearchParams(
        search: query.isEmpty ? null : query,
        semester: state.selectedSemesterId,
        courseType: state.courseType,
        department: state.department,
        yearLevel: state.yearLevel,
        college: collegeName,
      ));
      state = state.copyWith(
        subjects: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> searchWithFilters() async {
    await search(state.query);
  }

  Future<void> toggleSubjectExpand(int index) async {
    if (state.expandedIndex == index) {
      state = state.copyWith(
        expandedIndex: null,
        expandedSections: [],
      );
      return;
    }

    final subject = state.subjects[index];
    state = state.copyWith(
      expandedIndex: index,
      expandedSections: [],
      loadingSections: true,
    );

    // Find semester label for display
    final semesterStr = state.semesters
        .where((s) => s.id == state.selectedSemesterId)
        .firstOrNull
        ?.label;

    try {
      final detail = await _repo.getSubjectDetail(
        subject.courseCode,
        semester: state.selectedSemesterId,
      );
      // Convert CourseSection → CourseDetail for UI compatibility
      final sections = detail.sections
          .map((s) => s.toCourseDetail(
                courseCode: detail.courseCode,
                name: detail.name,
                credits: detail.credits,
                semesterId: state.selectedSemesterId,
                semesterStr: semesterStr,
              ))
          .toList();
      state = state.copyWith(
        expandedSections: sections,
        loadingSections: false,
      );
    } catch (_) {
      try {
        final response = await _repo.getCourses(CourseSearchParams(
          search: subject.courseCode,
          semester: state.selectedSemesterId,
        ));
        final details = <CourseDetail>[];
        for (final c in response.results
            .where((r) => r.courseCode == subject.courseCode)) {
          try {
            details.add(await _repo.getCourseDetail(c.id));
          } catch (_) {}
        }
        state = state.copyWith(
          expandedSections: details,
          loadingSections: false,
        );
      } catch (_) {
        state = state.copyWith(loadingSections: false);
      }
    }
  }

  Future<void> selectCourseForInfo(CourseDetail course) async {
    state = state.copyWith(
      selectedCourseDetail: course,
      selectedCourseReviews: [],
    );

    try {
      final reviews = await _reviewRepo.getReviews(course: course.id);
      state = state.copyWith(selectedCourseReviews: reviews.results);
    } catch (_) {}
  }

  void clearSelectedCourse() {
    state = state.copyWith(
      selectedCourseDetail: null,
      selectedCourseReviews: [],
    );
  }

  void setCourseType(String? type) {
    state = state.copyWith(courseType: type);
    searchWithFilters();
  }

  void setElearning(bool? value) {
    state = state.copyWith(isElearning: value);
    searchWithFilters();
  }

  void setYearLevel(int? level) {
    state = state.copyWith(yearLevel: level);
    searchWithFilters();
  }

  void setCollege(int? collegeId) {
    // When college changes, clear department selection
    state = state.copyWith(
      selectedCollegeId: collegeId,
      department: null,
    );
    searchWithFilters();
  }

  void setDepartment(String? code) {
    state = state.copyWith(department: code);
    searchWithFilters();
  }

  void setSemester(int? id) {
    state = state.copyWith(selectedSemesterId: id);
    searchWithFilters();
  }

  void clearFilters() {
    state = state.copyWith(clearFilters: true);
    searchWithFilters();
  }
}

final courseSearchViewModelProvider =
    NotifierProvider<CourseSearchViewModel, CourseSearchState>(
  CourseSearchViewModel.new,
);
