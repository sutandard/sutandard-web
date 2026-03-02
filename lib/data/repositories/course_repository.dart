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
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Semester.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => Semester.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Professor>> getProfessors({String? search}) async {
    final response = await _client.get(
      ApiConstants.professors,
      queryParameters: search != null ? {'search': search} : null,
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => Professor.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return (data as List<dynamic>)
        .map((e) => Professor.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => College.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => College.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Department>> getDepartments(
      {String? search, int? college}) async {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    if (college != null) params['college'] = college;
    final response = await _client.get(
      ApiConstants.departments,
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Department.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => Department.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Classroom>> getClassrooms() async {
    final response = await _client.get(ApiConstants.classrooms);
    return (response.data as List<dynamic>)
        .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Classroom>> getAvailableClassrooms() async {
    final response = await _client.get(ApiConstants.availableClassrooms);
    return (response.data as List<dynamic>)
        .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Subject>> getSubjects(SubjectSearchParams params) async {
    final response = await _client.get(
      ApiConstants.subjects,
      queryParameters: params.toQueryParameters(),
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
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
}

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return CourseRepositoryImpl(client);
});
