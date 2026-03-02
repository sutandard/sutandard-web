abstract final class AppConstants {
  static const appName = 'Sutandard';
  static const appNameKo = '수탠다드';
  static const appDescription = '수원대학교 시간표 관리 서비스';

  // Timetable grid
  static const timetableStartHour = 9;
  static const timetableEndHour = 21;
  static const timetableDays = ['월', '화', '수', '목', '금'];
  static const timetableDaysFull = ['월요일', '화요일', '수요일', '목요일', '금요일'];

  // Responsive breakpoints
  static const mobileBreakpoint = 600.0;
  static const tabletBreakpoint = 1024.0;
  static const desktopBreakpoint = 1440.0;

  // Animation durations
  static const animationFast = Duration(milliseconds: 200);
  static const animationNormal = Duration(milliseconds: 300);
  static const animationSlow = Duration(milliseconds: 500);
}
