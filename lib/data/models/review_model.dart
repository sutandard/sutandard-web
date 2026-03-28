class CourseReview {
  final int id;
  final int course;
  final String authorName;
  final bool isAnonymous;
  final int? semesterTaken;
  final String semesterTakenStr;
  final String content;
  final int gradeScore;
  final int assignmentScore;
  final int examScore;
  final double totalScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String courseName;
  final String professorName;
  final bool isMine;

  const CourseReview({
    required this.id,
    required this.course,
    required this.authorName,
    this.isAnonymous = false,
    this.semesterTaken,
    required this.semesterTakenStr,
    required this.content,
    required this.gradeScore,
    required this.assignmentScore,
    required this.examScore,
    required this.totalScore,
    required this.createdAt,
    required this.updatedAt,
    this.courseName = '',
    this.professorName = '',
    this.isMine = false,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      id: json['id'] as int,
      course: json['course_id'] as int? ?? json['course'] as int,
      authorName: json['author_name'] as String? ?? json['author_id'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      semesterTaken: json['semester_taken'] as int?,
      semesterTakenStr: json['semester_taken_str'] as String? ?? '',
      content: json['content'] as String,
      gradeScore: json['grade_score'] as int,
      assignmentScore: json['assignment_score'] as int,
      examScore: json['exam_score'] as int,
      totalScore: (json['total_score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      courseName: json['course_name'] as String? ?? '',
      professorName: json['professor_name'] as String? ?? '',
      isMine: json['is_mine'] as bool? ?? false,
    );
  }

  String scoreToGrade(int score) => switch (score) {
        5 => 'A+',
        4 => 'A',
        3 => 'B',
        2 => 'C',
        _ => 'D',
      };

  String get gradeGrade => scoreToGrade(gradeScore);
  String get assignmentGrade => scoreToGrade(assignmentScore);
  String get examGrade => scoreToGrade(examScore);

  int get starRating => totalScore.round().clamp(1, 5);
}

class CreateReviewRequest {
  final int course;
  final int? semesterTaken;
  final String content;
  final int gradeScore;
  final int assignmentScore;
  final int examScore;
  final bool isAnonymous;

  const CreateReviewRequest({
    required this.course,
    this.semesterTaken,
    required this.content,
    required this.gradeScore,
    required this.assignmentScore,
    required this.examScore,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'course': course,
        'semester_taken': semesterTaken ?? 0,
        'content': content,
        'grade_score': gradeScore,
        'assignment_score': assignmentScore,
        'exam_score': examScore,
        'is_anonymous': isAnonymous,
      };
}
