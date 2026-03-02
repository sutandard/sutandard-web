class CourseSchedule {
  final int id;
  final String dayOfWeek;
  final String dayDisplay;
  final String startTime;
  final String endTime;
  final int? classroom;
  final String classroomStr;

  const CourseSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.dayDisplay,
    required this.startTime,
    required this.endTime,
    this.classroom,
    required this.classroomStr,
  });

  int get dayIndex => switch (dayOfWeek) {
        'MON' => 0,
        'TUE' => 1,
        'WED' => 2,
        'THU' => 3,
        'FRI' => 4,
        'SAT' => 5,
        'SUN' => 6,
        _ => 0,
      };

  int get startHour => int.parse(startTime.split(':')[0]);
  int get startMinute => int.parse(startTime.split(':')[1]);
  int get endHour => int.parse(endTime.split(':')[0]);
  int get endMinute => int.parse(endTime.split(':')[1]);
  int get startInMinutes => startHour * 60 + startMinute;
  int get endInMinutes => endHour * 60 + endMinute;
  int get durationInMinutes => endInMinutes - startInMinutes;

  String get startTimeFormatted =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeFormatted =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  factory CourseSchedule.fromJson(Map<String, dynamic> json) {
    return CourseSchedule(
      id: json['id'] as int,
      dayOfWeek: json['day_of_week'] as String,
      dayDisplay: json['day_display'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      classroom: json['classroom'] as int?,
      classroomStr: json['classroom_str'] as String,
    );
  }
}

class CourseList {
  final int id;
  final String courseCode;
  final String name;
  final int? professor;
  final String professorName;
  final int semester;
  final String semesterStr;
  final int credits;
  final int? yearLevel;
  final String section;
  final String courseType;
  final String courseTypeDisplay;
  final bool isElearning;
  final int? department;
  final String departmentName;

  const CourseList({
    required this.id,
    required this.courseCode,
    required this.name,
    this.professor,
    required this.professorName,
    required this.semester,
    required this.semesterStr,
    required this.credits,
    this.yearLevel,
    required this.section,
    required this.courseType,
    required this.courseTypeDisplay,
    this.isElearning = false,
    this.department,
    this.departmentName = '',
  });

  factory CourseList.fromJson(Map<String, dynamic> json) {
    return CourseList(
      id: json['id'] as int,
      courseCode: json['course_code'] as String,
      name: json['name'] as String,
      professor: json['professor'] as int?,
      professorName: json['professor_name'] as String,
      semester: json['semester'] as int,
      semesterStr: json['semester_str'] as String,
      credits: json['credits'] as int,
      yearLevel: json['year_level'] as int?,
      section: json['section'] as String,
      courseType: json['course_type'] as String,
      courseTypeDisplay: json['course_type_display'] as String,
      isElearning: json['is_elearning'] as bool? ?? false,
      department: json['department'] as int?,
      departmentName: json['department_name'] as String? ?? '',
    );
  }
}

class CourseDetail extends CourseList {
  final List<CourseSchedule> schedules;
  final Map<String, dynamic>? reviewStats;
  final List<dynamic>? siblingSections;

  CourseDetail({
    required super.id,
    required super.courseCode,
    required super.name,
    super.professor,
    required super.professorName,
    required super.semester,
    required super.semesterStr,
    required super.credits,
    super.yearLevel,
    required super.section,
    required super.courseType,
    required super.courseTypeDisplay,
    super.isElearning,
    super.department,
    super.departmentName,
    required this.schedules,
    this.reviewStats,
    this.siblingSections,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    return CourseDetail(
      id: json['id'] as int,
      courseCode: json['course_code'] as String,
      name: json['name'] as String,
      professor: json['professor'] as int?,
      professorName: json['professor_name'] as String,
      semester: json['semester'] as int,
      semesterStr: json['semester_str'] as String,
      credits: json['credits'] as int,
      yearLevel: json['year_level'] as int?,
      section: json['section'] as String,
      courseType: json['course_type'] as String,
      courseTypeDisplay: json['course_type_display'] as String,
      isElearning: json['is_elearning'] as bool? ?? false,
      department: json['department'] as int?,
      departmentName: json['department_name'] as String? ?? '',
      schedules: (json['schedules'] as List<dynamic>)
          .map((e) => CourseSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviewStats: json['review_stats'] is Map
          ? json['review_stats'] as Map<String, dynamic>
          : null,
      siblingSections: json['sibling_sections'] is List
          ? json['sibling_sections'] as List<dynamic>
          : null,
    );
  }
}

class CourseSearchParams {
  final String? search;
  final int? semester;
  final String? courseType;
  final bool? isElearning;
  final int? yearLevel;
  final int? professor;
  final String? department;
  final String? period;
  final String? ordering;
  final int? page;
  final int? classroom;

  const CourseSearchParams({
    this.search,
    this.semester,
    this.courseType,
    this.isElearning,
    this.yearLevel,
    this.professor,
    this.department,
    this.period,
    this.ordering,
    this.page,
    this.classroom,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (semester != null) params['semester'] = semester;
    if (courseType != null) params['course_type'] = courseType;
    if (isElearning != null) params['is_elearning'] = isElearning;
    if (yearLevel != null) params['year_level'] = yearLevel;
    if (professor != null) params['professor'] = professor;
    if (department != null) params['department'] = department;
    if (period != null) params['period'] = period;
    if (ordering != null) params['ordering'] = ordering;
    if (page != null) params['page'] = page;
    if (classroom != null) params['classroom'] = classroom;
    return params;
  }
}

class Subject {
  final String courseCode;
  final String name;
  final int credits;
  final String courseType;
  final String courseTypeDisplay;
  final int? yearLevel;
  final String departmentName;
  final int sectionCount;
  final int? semester;
  final String? semesterStr;

  const Subject({
    required this.courseCode,
    required this.name,
    required this.credits,
    required this.courseType,
    required this.courseTypeDisplay,
    this.yearLevel,
    this.departmentName = '',
    required this.sectionCount,
    this.semester,
    this.semesterStr,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      courseCode: json['course_code'] as String,
      name: json['name'] as String,
      credits: json['credits'] as int? ?? 0,
      courseType: json['course_type'] as String? ?? '',
      courseTypeDisplay: json['course_type_display'] as String? ?? '',
      yearLevel: json['year_level'] as int?,
      departmentName: json['department_name'] as String? ?? '',
      sectionCount: json['section_count'] as int? ?? 1,
      semester: json['semester'] as int?,
      semesterStr: json['semester_str'] as String?,
    );
  }
}

class SubjectDetail {
  final String courseCode;
  final String name;
  final List<CourseDetail> sections;

  const SubjectDetail({
    required this.courseCode,
    required this.name,
    required this.sections,
  });

  factory SubjectDetail.fromJson(Map<String, dynamic> json) {
    return SubjectDetail(
      courseCode: json['course_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => CourseDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SubjectSearchParams {
  final String? search;
  final int? semester;
  final String? courseType;
  final String? college;
  final String? department;
  final int? yearLevel;
  final String? ordering;

  const SubjectSearchParams({
    this.search,
    this.semester,
    this.courseType,
    this.college,
    this.department,
    this.yearLevel,
    this.ordering,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (semester != null) params['semester'] = semester;
    if (courseType != null) params['course_type'] = courseType;
    if (college != null) params['college'] = college;
    if (department != null) params['department'] = department;
    if (yearLevel != null) params['year_level'] = yearLevel;
    if (ordering != null) params['ordering'] = ordering;
    return params;
  }
}
