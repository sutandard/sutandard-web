import 'dart:ui';
import 'course_model.dart';

class Timetable {
  final int id;
  final int semester;
  final String semesterStr;
  final String name;
  final bool isMain;
  final DateTime createdAt;
  final List<TimetableCourse> courses;

  const Timetable({
    required this.id,
    required this.semester,
    required this.semesterStr,
    required this.name,
    this.isMain = false,
    required this.createdAt,
    this.courses = const [],
  });

  int get totalCredits =>
      courses.fold(0, (sum, c) => sum + (c.courseDetail?.credits ?? 0));

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'] as int,
      semester: json['semester'] as int,
      semesterStr: json['semester_str'] as String,
      name: json['name'] as String? ?? '',
      isMain: json['is_main'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      courses: (json['courses'] as List<dynamic>?)
              ?.map(
                  (e) => TimetableCourse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TimetableCourse {
  final int id;
  final int course;
  final CourseList? courseDetail;
  final List<CourseSchedule> schedules;
  final String color;

  const TimetableCourse({
    required this.id,
    required this.course,
    this.courseDetail,
    this.schedules = const [],
    this.color = '#4F46E5',
  });

  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }

  String get name => courseDetail?.name ?? '';
  String get professorName => courseDetail?.professorName ?? '';
  int get credits => courseDetail?.credits ?? 0;

  factory TimetableCourse.fromJson(Map<String, dynamic> json) {
    return TimetableCourse(
      id: json['id'] as int,
      course: json['course'] as int,
      courseDetail: json['course_detail'] != null
          ? CourseList.fromJson(json['course_detail'] as Map<String, dynamic>)
          : null,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map(
                  (e) => CourseSchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      color: json['color'] as String? ?? '#4F46E5',
    );
  }
}

class TimetableCreate {
  final int semester;
  final String? name;
  final bool? isMain;

  const TimetableCreate({
    required this.semester,
    this.name,
    this.isMain,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'semester': semester};
    if (name != null) json['name'] = name;
    if (isMain != null) json['is_main'] = isMain;
    return json;
  }
}

class AddCourseRequest {
  final int courseId;
  final String color;

  const AddCourseRequest({
    required this.courseId,
    this.color = '#4F46E5',
  });

  Map<String, dynamic> toJson() => {
        'course_id': courseId,
        'color': color,
      };
}
