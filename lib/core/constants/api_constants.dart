abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.sutandard.kr',
  );

  // Auth
  static const login = '/api/auth/login/';
  static const register = '/api/auth/register/';
  static const logout = '/api/auth/logout/';
  static const me = '/api/auth/me/';
  static const changePassword = '/api/auth/change-password/';
  static const resetPassword = '/api/auth/reset-password/';
  static const portalCheck = '/api/auth/portal-check/';
  static const deleteAccount = '/api/auth/me/';
  static const tokenRefresh = '/api/auth/token/refresh/';

  // Courses
  static const courses = '/api/courses/';
  static String courseDetail(int id) => '/api/courses/$id/';
  static const coursesBatch = '/api/courses/batch/';
  static const subjects = '/api/courses/subjects/';
  static String subjectDetail(String courseCode) =>
      '/api/courses/subjects/$courseCode/';
  static const semesters = '/api/courses/semesters/';
  static const professors = '/api/courses/professors/';
  static String professorDetail(int id) => '/api/courses/professors/$id/';
  static String professorOfficeHours(int id) =>
      '/api/courses/professors/$id/office-hours/';
  static String professorSchedule(int id) =>
      '/api/courses/professors/$id/schedule/';
  static const departments = '/api/courses/departments/';
  static const colleges = '/api/courses/colleges/';
  static const classrooms = '/api/courses/classrooms/';
  static const availableClassrooms = '/api/courses/classrooms/available/';
  static String classroomSchedule(int id) =>
      '/api/courses/classrooms/$id/schedule/';

  // Timetables
  static const timetables = '/api/timetables/';
  static String timetableDetail(int id) => '/api/timetables/$id/';
  static String timetableCourses(int id) => '/api/timetables/$id/courses/';
  static String timetableCourseDetail(int timetableId, int courseId) =>
      '/api/timetables/$timetableId/courses/$courseId/';
  static const currentClass = '/api/timetables/now/';

  // Reviews
  static const reviews = '/api/reviews/';
  static String reviewDetail(int id) => '/api/reviews/$id/';
  static String reviewsBySubject(String courseCode) =>
      '/api/reviews/subject/$courseCode/';

  // Timeouts
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
}
