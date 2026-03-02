import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  final BuildContext context;

  const Responsive(this.context);

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;

  bool get isMobile => width < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      width >= AppConstants.mobileBreakpoint &&
      width < AppConstants.tabletBreakpoint;
  bool get isDesktop => width >= AppConstants.tabletBreakpoint;

  DeviceType get deviceType {
    if (isMobile) return DeviceType.mobile;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 화면 크기에 따라 다른 값 반환
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return switch (deviceType) {
      DeviceType.desktop => desktop ?? tablet ?? mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.mobile => mobile,
    };
  }

  /// 시간표 그리드의 한 교시 높이
  double get timetablePeriodHeight => value(
        mobile: 52.0,
        tablet: 56.0,
        desktop: 60.0,
      );

  /// 시간표 좌측 시간 레이블 너비
  double get timetableTimeLabelWidth => value(
        mobile: 36.0,
        tablet: 44.0,
        desktop: 52.0,
      );

  /// 시간표 헤더 높이
  double get timetableHeaderHeight => value(
        mobile: 32.0,
        tablet: 36.0,
        desktop: 40.0,
      );
}
