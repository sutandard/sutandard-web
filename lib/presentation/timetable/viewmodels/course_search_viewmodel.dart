import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/common_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';

class CourseSearchState {
  final String query;
  final Set<String> courseTypes;
  final bool? isElearning;
  final Set<int> yearLevels;
  final Set<String> departments_;
  final Set<int> selectedCollegeIds;
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
    this.courseTypes = const {},
    this.isElearning,
    this.yearLevels = const {},
    this.departments_ = const {},
    this.selectedCollegeIds = const {},
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
      courseTypes.isNotEmpty ||
      isElearning != null ||
      yearLevels.isNotEmpty ||
      departments_.isNotEmpty ||
      selectedCollegeIds.isNotEmpty;

  /// Returns filtered departments based on selected colleges
  List<Department> get filteredDepartments {
    if (selectedCollegeIds.isEmpty) return departments;
    return departments
        .where((d) => selectedCollegeIds.contains(d.college))
        .toList();
  }

  CourseSearchState copyWith({
    String? query,
    Set<String>? courseTypes,
    Object? isElearning = _sentinel,
    Set<int>? yearLevels,
    Set<String>? departments_,
    Set<int>? selectedCollegeIds,
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
      courseTypes: clearFilters ? const {} : (courseTypes ?? this.courseTypes),
      isElearning: clearFilters
          ? null
          : isElearning == _sentinel
              ? this.isElearning
              : isElearning as bool?,
      yearLevels: clearFilters ? const {} : (yearLevels ?? this.yearLevels),
      departments_:
          clearFilters ? const {} : (departments_ ?? this.departments_),
      selectedCollegeIds: clearFilters
          ? const {}
          : (selectedCollegeIds ?? this.selectedCollegeIds),
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

    // Determine college names for API filter (subjects endpoint takes string)
    String? collegeName;
    if (state.selectedCollegeIds.isNotEmpty) {
      final names = state.colleges
          .where((c) => state.selectedCollegeIds.contains(c.id))
          .map((c) => c.name);
      if (names.isNotEmpty) collegeName = names.join(',');
    }

    try {
      final results = await _repo.getSubjects(SubjectSearchParams(
        search: query.isEmpty ? null : query,
        semester: state.selectedSemesterId,
        courseType: state.courseTypes.isEmpty
            ? null
            : state.courseTypes.join(','),
        department: state.departments_.isEmpty
            ? null
            : state.departments_.join(','),
        yearLevel: state.yearLevels.isEmpty
            ? null
            : state.yearLevels.join(','),
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

      // Subject 목록은 college/department 필터가 적용된 sectionCount를 보여줌.
      // SubjectDetail은 해당 courseCode의 전체 분반을 반환하므로,
      // Subject의 college/offeringDepartment로 필터링하여 일치시킴.
      var filtered = detail.sections;
      if (subject.offeringDepartment.isNotEmpty) {
        final byDept = filtered
            .where((s) => s.offeringDepartment == subject.offeringDepartment)
            .toList();
        if (byDept.isNotEmpty) filtered = byDept;
      } else if (subject.college.isNotEmpty) {
        final byCollege = filtered
            .where((s) => s.college == subject.college)
            .toList();
        if (byCollege.isNotEmpty) filtered = byCollege;
      }

      // Convert CourseSection → CourseDetail for UI compatibility
      final sections = filtered
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

  void toggleCourseType(String type) {
    final updated = Set<String>.from(state.courseTypes);
    if (!updated.remove(type)) updated.add(type);
    state = state.copyWith(courseTypes: updated);
    searchWithFilters();
  }

  void clearCourseTypes() {
    state = state.copyWith(courseTypes: const {});
    searchWithFilters();
  }

  void setElearning(bool? value) {
    state = state.copyWith(isElearning: value);
    searchWithFilters();
  }

  void toggleYearLevel(int level) {
    final updated = Set<int>.from(state.yearLevels);
    if (!updated.remove(level)) updated.add(level);
    state = state.copyWith(yearLevels: updated);
    searchWithFilters();
  }

  void clearYearLevels() {
    state = state.copyWith(yearLevels: const {});
    searchWithFilters();
  }

  void toggleCollege(int collegeId) {
    final updated = Set<int>.from(state.selectedCollegeIds);
    if (updated.remove(collegeId)) {
      // 해제된 단과대의 학과도 제거
      final removedCollegeDepts = state.departments
          .where((d) => d.college == collegeId)
          .map((d) => d.code)
          .toSet();
      final updatedDepts = Set<String>.from(state.departments_)
        ..removeAll(removedCollegeDepts);
      state = state.copyWith(
        selectedCollegeIds: updated,
        departments_: updatedDepts,
      );
    } else {
      updated.add(collegeId);
      state = state.copyWith(selectedCollegeIds: updated);
    }
    searchWithFilters();
  }

  void clearColleges() {
    state = state.copyWith(
      selectedCollegeIds: const {},
      departments_: const {},
    );
    searchWithFilters();
  }

  void toggleDepartment(String code) {
    final updated = Set<String>.from(state.departments_);
    if (!updated.remove(code)) updated.add(code);
    state = state.copyWith(departments_: updated);
    searchWithFilters();
  }

  void clearDepartments() {
    state = state.copyWith(departments_: const {});
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
