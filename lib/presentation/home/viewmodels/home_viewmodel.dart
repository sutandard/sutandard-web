import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/home_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class HomeWidgetState {
  final TodayScheduleResponse? todaySchedule;
  final QuickTimetableResponse? quickTimetable;
  final bool isLoading;
  final String? error;

  const HomeWidgetState({
    this.todaySchedule,
    this.quickTimetable,
    this.isLoading = false,
    this.error,
  });

  HomeWidgetState copyWith({
    TodayScheduleResponse? todaySchedule,
    QuickTimetableResponse? quickTimetable,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeWidgetState(
      todaySchedule: todaySchedule ?? this.todaySchedule,
      quickTimetable: quickTimetable ?? this.quickTimetable,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeWidgetViewModel extends Notifier<HomeWidgetState> {
  @override
  HomeWidgetState build() {
    final authState = ref.watch(authViewModelProvider);
    if (authState.isAuthenticated) {
      Future.microtask(() => loadDashboard());
      return const HomeWidgetState(isLoading: true);
    }
    return const HomeWidgetState();
  }

  HomeRepository get _repo => ref.read(homeRepositoryProvider);

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repo.getTodaySchedule(),
        _repo.getQuickTimetable(),
      ]);

      state = HomeWidgetState(
        todaySchedule: results[0] as TodayScheduleResponse,
        quickTimetable: results[1] as QuickTimetableResponse,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
    }
  }

  Future<void> refresh() => loadDashboard();
}

final homeWidgetViewModelProvider =
    NotifierProvider<HomeWidgetViewModel, HomeWidgetState>(
        HomeWidgetViewModel.new);
