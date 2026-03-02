import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/auth/viewmodels/auth_viewmodel.dart';
import 'presentation/auth/views/forgot_password_view.dart';
import 'presentation/auth/views/login_view.dart';
import 'presentation/auth/views/register_view.dart';
import 'presentation/classroom/views/available_classrooms_view.dart';
import 'presentation/home/views/home_view.dart';
import 'presentation/professor/views/professor_schedule_view.dart';
import 'presentation/review/views/review_write_view.dart';
import 'presentation/timetable/views/timetable_view.dart';
import 'presentation/timetable/views/wizard_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      final protectedRoutes = ['/review/write', '/wizard'];
      if (!isAuthenticated &&
          protectedRoutes.contains(state.matchedLocation)) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/timetable';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/timetable',
        name: 'timetable',
        builder: (context, state) => const TimetableView(),
      ),
      GoRoute(
        path: '/review/write',
        name: 'review-write',
        builder: (context, state) => const ReviewWriteView(),
      ),
      GoRoute(
        path: '/wizard',
        name: 'wizard',
        builder: (context, state) => const WizardView(),
      ),
      GoRoute(
        path: '/classrooms',
        name: 'classrooms',
        builder: (context, state) => const AvailableClassroomsView(),
      ),
      GoRoute(
        path: '/professor-schedule',
        name: 'professor-schedule',
        builder: (context, state) => const ProfessorScheduleView(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 32, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                '페이지를 찾을 수 없습니다',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
