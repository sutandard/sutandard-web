class TodayClassItem {
  final int courseId;
  final String courseName;
  final String? professor;
  final String startTime;
  final String endTime;
  final String? classroom;
  final String color;
  final String status; // 'done', 'in_progress', 'upcoming'

  const TodayClassItem({
    required this.courseId,
    required this.courseName,
    this.professor,
    required this.startTime,
    required this.endTime,
    this.classroom,
    required this.color,
    required this.status,
  });

  factory TodayClassItem.fromJson(Map<String, dynamic> json) {
    return TodayClassItem(
      courseId: json['course_id'] as int,
      courseName: json['course_name'] as String,
      professor: json['professor'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      classroom: json['classroom'] as String?,
      color: json['color'] as String? ?? '#4F46E5',
      status: json['status'] as String,
    );
  }

  bool get isDone => status == 'done';
  bool get isInProgress => status == 'in_progress';
  bool get isUpcoming => status == 'upcoming';
}

class TodayScheduleResponse {
  final String date;
  final String dayOfWeek;
  final List<TodayClassItem> classes;

  const TodayScheduleResponse({
    required this.date,
    required this.dayOfWeek,
    required this.classes,
  });

  factory TodayScheduleResponse.fromJson(Map<String, dynamic> json) {
    return TodayScheduleResponse(
      date: json['date'] as String,
      dayOfWeek: json['day_of_week'] as String,
      classes: (json['classes'] as List<dynamic>)
          .map((e) => TodayClassItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuickTimetableResponse {
  final String timetableName;
  final String semester;
  final Map<String, dynamic> days;

  const QuickTimetableResponse({
    required this.timetableName,
    required this.semester,
    required this.days,
  });

  factory QuickTimetableResponse.fromJson(Map<String, dynamic> json) {
    return QuickTimetableResponse(
      timetableName: json['timetable_name'] as String,
      semester: json['semester'] as String,
      days: json['days'] as Map<String, dynamic>,
    );
  }
}
