abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.sutandard.kr',
  );

  // Auth
  static const login = '/api/v1/auth/login/';
  static const register = '/api/v1/auth/register/';
  static const logout = '/api/v1/auth/logout/';
  static const me = '/api/v1/auth/me/';
  static const changePassword = '/api/v1/auth/change-password/';
  static const resetPassword = '/api/v1/auth/reset-password/';
  static const portalCheck = '/api/v1/auth/portal-check/';
  static const deleteAccount = '/api/v1/auth/me/';
  static const tokenRefresh = '/api/v1/auth/token/refresh/';

  // Courses
  static const courses = '/api/v1/courses/';
  static String courseDetail(int id) => '/api/v1/courses/$id/';
  static const coursesBatch = '/api/v1/courses/batch/';
  static const subjects = '/api/v1/courses/subjects/';
  static String subjectDetail(String courseCode) =>
      '/api/v1/courses/subjects/$courseCode/';
  static const semesters = '/api/v1/courses/semesters/';
  static const professors = '/api/v1/courses/professors/';
  static String professorDetail(int id) => '/api/v1/courses/professors/$id/';
  static String professorOfficeHours(int id) =>
      '/api/v1/courses/professors/$id/office-hours/';
  static String professorSchedule(int id) =>
      '/api/v1/courses/professors/$id/schedule/';
  static const departments = '/api/v1/courses/departments/';
  static const colleges = '/api/v1/courses/colleges/';
  static const classrooms = '/api/v1/courses/classrooms/';
  static const availableClassrooms = '/api/v1/courses/classrooms/available/';
  static String classroomSchedule(int id) =>
      '/api/v1/courses/classrooms/$id/schedule/';

  // Timetables
  static const timetables = '/api/v1/timetables/';
  static String timetableDetail(int id) => '/api/v1/timetables/$id/';
  static String timetableCourses(int id) => '/api/v1/timetables/$id/courses/';
  static String timetableCourseDetail(int timetableId, int courseId) =>
      '/api/v1/timetables/$timetableId/courses/$courseId/';
  static const currentClass = '/api/v1/timetables/now/';
  static const timetableImport = '/api/v1/timetables/import/';
  static const timetableWizard = '/api/v1/timetables/wizard/';

  // Reviews
  static const reviews = '/api/v1/reviews/';
  static String reviewDetail(int id) => '/api/v1/reviews/$id/';
  static String reviewsBySubject(String courseCode) =>
      '/api/v1/reviews/subject/$courseCode/';

  // Community
  static const communityPosts = '/api/v1/community/posts/';
  static String communityPostDetail(int id) =>
      '/api/v1/community/posts/$id/';
  static String communityPostLike(int id) =>
      '/api/v1/community/posts/$id/like/';
  static String communityPostComments(int postId) =>
      '/api/v1/community/posts/$postId/comments/';
  static String communityCommentDetail(int postId, int commentId) =>
      '/api/v1/community/posts/$postId/comments/$commentId/';

  // Home Widget
  static const homeQuickTimetable = '/api/v1/community/home/quick-timetable/';
  static const homeToday = '/api/v1/community/home/today/';

  // Timeouts
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
}
