import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/auth/viewmodels/auth_viewmodel.dart';
import 'presentation/auth/views/forgot_password_view.dart';
import 'presentation/auth/views/login_view.dart';
import 'presentation/auth/views/register_view.dart';
import 'presentation/classroom/views/available_classrooms_view.dart';
import 'presentation/community/views/community_feed_view.dart';
import 'presentation/community/views/post_create_view.dart';
import 'presentation/community/views/post_detail_view.dart';
import 'presentation/courses/views/course_list_view.dart';
import 'presentation/home/views/home_view.dart';
import 'presentation/professor/views/professor_schedule_view.dart';
import 'presentation/timetable/views/timetable_view.dart';
import 'presentation/timetable/views/wizard_view.dart';

// Uses ChangeNotifier + refreshListenable so the GoRouter is created once
// and auth state changes only trigger redirect re-evaluation, not router recreation.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authViewModelProvider, (_, __) {
      notifyListeners();
    });
    _ref = ref;
  }

  late final Ref _ref;

  bool get isAuthenticated => _ref.read(authViewModelProvider).isAuthenticated;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = notifier.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      final protectedRoutes = ['/wizard', '/community/create'];
      final isProtected = protectedRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/community');
      if (!isAuthenticated && isProtected) {
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
        pageBuilder: (context, state) =>
            _fadePage(state, const HomeView()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _fadePage(state, const LoginView()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            _fadePage(state, const RegisterView()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordView()),
      ),
      GoRoute(
        path: '/timetable',
        name: 'timetable',
        pageBuilder: (context, state) =>
            _fadePage(state, const TimetableView()),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        pageBuilder: (context, state) => _fadePage(
          state,
          CourseListView(
            initialQuery: state.uri.queryParameters['q'],
          ),
        ),
      ),
      GoRoute(
        path: '/wizard',
        name: 'wizard',
        pageBuilder: (context, state) =>
            _fadePage(state, const WizardView()),
      ),
      GoRoute(
        path: '/community',
        name: 'community',
        pageBuilder: (context, state) =>
            _fadePage(state, const CommunityFeedView()),
      ),
      GoRoute(
        path: '/community/create',
        name: 'community-create',
        pageBuilder: (context, state) =>
            _fadePage(state, const PostCreateView()),
      ),
      GoRoute(
        path: '/community/:id',
        name: 'community-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _fadePage(state, PostDetailView(postId: id));
        },
      ),
      GoRoute(
        path: '/classrooms',
        name: 'classrooms',
        pageBuilder: (context, state) =>
            _fadePage(state, const AvailableClassroomsView()),
      ),
      GoRoute(
        path: '/professor-schedule',
        name: 'professor-schedule',
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfessorScheduleView()),
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

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
