import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/common_model.dart';
import '../models/course_model.dart';

abstract class CourseRepository {
  Future<PaginatedResponse<CourseList>> getCourses(CourseSearchParams params);
  Future<CourseDetail> getCourseDetail(int id);
  Future<List<CourseDetail>> getCoursesBatch(List<int> ids);
  Future<List<Semester>> getSemesters();
  Future<List<Professor>> getProfessors({String? search});
  Future<ProfessorDetail> getProfessorDetail(int id);
  Future<Map<String, dynamic>> getProfessorSchedule(int id, {int? semester});
  Future<List<College>> getColleges();
  Future<List<Department>> getDepartments({String? search, int? college});
  Future<List<Classroom>> getClassrooms();
  Future<List<Classroom>> getAvailableClassrooms();
  Future<List<Subject>> getSubjects(SubjectSearchParams params);
  Future<SubjectDetail> getSubjectDetail(String courseCode,
      {int? semester});
  Future<Map<String, dynamic>> getClassroomSchedule(int id,
      {int? semester});
}

class CourseRepositoryImpl implements CourseRepository {
  final ApiClient _client;

  CourseRepositoryImpl(this._client);

  @override
  Future<PaginatedResponse<CourseList>> getCourses(
      CourseSearchParams params) async {
    final response = await _client.get(
      ApiConstants.courses,
      queryParameters: params.toQueryParameters(),
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      CourseList.fromJson,
    );
  }

  @override
  Future<CourseDetail> getCourseDetail(int id) async {
    final response = await _client.get(ApiConstants.courseDetail(id));
    return CourseDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<CourseDetail>> getCoursesBatch(List<int> ids) async {
    final response = await _client.post(
      ApiConstants.coursesBatch,
      data: {'ids': ids},
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => CourseDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Semester>> getSemesters() async {
    final response = await _client.get(ApiConstants.semesters);
    return _parseList(response.data, Semester.fromJson);
  }

  @override
  Future<List<Professor>> getProfessors({String? search}) async {
    final params = <String, dynamic>{'page_size': 200};
    if (search != null) params['search'] = search;
    final response = await _client.get(
      ApiConstants.professors,
      queryParameters: params,
    );
    return _parseList(response.data, Professor.fromJson);
  }

  @override
  Future<ProfessorDetail> getProfessorDetail(int id) async {
    final response = await _client.get(ApiConstants.professorDetail(id));
    return ProfessorDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getProfessorSchedule(int id,
      {int? semester}) async {
    final response = await _client.get(
      ApiConstants.professorSchedule(id),
      queryParameters: semester != null ? {'semester': semester} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<College>> getColleges() async {
    final response = await _client.get(ApiConstants.colleges);
    return _parseList(response.data, College.fromJson);
  }

  @override
  Future<List<Department>> getDepartments(
      {String? search, int? college}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    if (college != null) params['college'] = college;
    final response = await _client.get(
      ApiConstants.departments,
      queryParameters: params.isNotEmpty ? params : null,
    );
    return _parseList(response.data, Department.fromJson);
  }

  @override
  Future<List<Classroom>> getClassrooms() async {
    final response = await _client.get(ApiConstants.classrooms);
    return _parseList(response.data, Classroom.fromJson);
  }

  @override
  Future<List<Classroom>> getAvailableClassrooms() async {
    final response = await _client.get(ApiConstants.availableClassrooms);
    return _parseList(response.data, Classroom.fromJson);
  }

  /// API가 배열 또는 paginated 응답({results: [...]}) 둘 다 반환할 수 있으므로 공통 처리
  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Subject>> getSubjects(SubjectSearchParams params) async {
    final queryParams = params.toQueryParameters();
    final response = await _client.get(
      ApiConstants.subjects,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return _parseList(response.data, Subject.fromJson);
  }

  @override
  Future<SubjectDetail> getSubjectDetail(String courseCode,
      {int? semester}) async {
    final response = await _client.get(
      ApiConstants.subjectDetail(courseCode),
      queryParameters: semester != null ? {'semester': semester} : null,
    );
    return SubjectDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getClassroomSchedule(int id,
      {int? semester}) async {
    final response = await _client.get(
      ApiConstants.classroomSchedule(id),
      queryParameters: semester != null ? {'semester': semester} : null,
    );
    return response.data as Map<String, dynamic>;
  }
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return CourseRepositoryImpl(client);
});
