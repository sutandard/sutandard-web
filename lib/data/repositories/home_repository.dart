import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/home_model.dart';

abstract class HomeRepository {
  Future<TodayScheduleResponse> getTodaySchedule();
  Future<QuickTimetableResponse> getQuickTimetable();
}

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient _client;

  HomeRepositoryImpl(this._client);

  @override
  Future<TodayScheduleResponse> getTodaySchedule() async {
    final response = await _client.get(ApiConstants.homeToday);
    return TodayScheduleResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<QuickTimetableResponse> getQuickTimetable() async {
    final response = await _client.get(ApiConstants.homeQuickTimetable);
    return QuickTimetableResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return HomeRepositoryImpl(client);
});
