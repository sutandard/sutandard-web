import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/timetable_model.dart';

abstract class TimetableRepository {
  Future<List<Timetable>> getTimetables();
  Future<Timetable> getTimetable(int id);
  Future<Timetable> createTimetable(TimetableCreate request);
  Future<Timetable> updateTimetable(int id, {String? name, bool? isMain});
  Future<void> deleteTimetable(int id);
  Future<TimetableCourse> addCourse(int timetableId, AddCourseRequest request);
  Future<void> removeCourse(int timetableId, int timetableCourseId);
  Future<Map<String, dynamic>?> getCurrentClass();
}

class TimetableRepositoryImpl implements TimetableRepository {
  final ApiClient _client;

  TimetableRepositoryImpl(this._client);

  @override
  Future<List<Timetable>> getTimetables() async {
    final response = await _client.get(ApiConstants.timetables);
    return (response.data as List<dynamic>)
        .map((e) => Timetable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Timetable> getTimetable(int id) async {
    final response = await _client.get(ApiConstants.timetableDetail(id));
    return Timetable.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Timetable> createTimetable(TimetableCreate request) async {
    final response = await _client.post(
      ApiConstants.timetables,
      data: request.toJson(),
    );
    return Timetable.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Timetable> updateTimetable(int id,
      {String? name, bool? isMain}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (isMain != null) data['is_main'] = isMain;
    final response = await _client.patch(
      ApiConstants.timetableDetail(id),
      data: data,
    );
    return Timetable.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTimetable(int id) async {
    await _client.delete(ApiConstants.timetableDetail(id));
  }

  @override
  Future<TimetableCourse> addCourse(
      int timetableId, AddCourseRequest request) async {
    final response = await _client.post(
      ApiConstants.timetableCourses(timetableId),
      data: request.toJson(),
    );
    return TimetableCourse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> removeCourse(int timetableId, int timetableCourseId) async {
    await _client.delete(
      ApiConstants.timetableCourseDetail(timetableId, timetableCourseId),
    );
  }

  @override
  Future<Map<String, dynamic>?> getCurrentClass() async {
    final response = await _client.get(ApiConstants.currentClass);
    return response.data as Map<String, dynamic>?;
  }
}

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return TimetableRepositoryImpl(client);
});
