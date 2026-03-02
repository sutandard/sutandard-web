import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sutandard_nav_bar.dart';

List<NavItem> buildMainNavItems(
    BuildContext context, String currentLocation) =>
    [
      NavItem(
        label: '나의 시간표',
        isActive: currentLocation == '/timetable',
        onTap: () => context.go('/timetable'),
      ),
      NavItem(
        label: '강의 목록',
        isActive: currentLocation.startsWith('/courses'),
        onTap: () => context.go('/courses'),
      ),
      NavItem(
        label: '강의 후기',
        isActive: currentLocation.startsWith('/reviews'),
        onTap: () => context.go('/reviews'),
      ),
      NavItem(
        label: '빈 강의실',
        isActive: currentLocation.startsWith('/classrooms'),
        onTap: () => context.go('/classrooms'),
      ),
    ];
