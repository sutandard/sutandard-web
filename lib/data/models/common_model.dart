class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
}

class Semester {
  final int id;
  final int year;
  final String term;
  final String termDisplay;

  const Semester({
    required this.id,
    required this.year,
    required this.term,
    required this.termDisplay,
  });

  String get label => '$year년 $termDisplay';

  String get shortLabel => '$year-$term';

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as int,
      year: json['year'] as int,
      term: json['term'] as String,
      termDisplay: json['term_display'] as String,
    );
  }
}

class Professor {
  final int id;
  final String name;
  final String? department;

  const Professor({
    required this.id,
    required this.name,
    this.department,
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'] as int,
      name: json['name'] as String,
      department: json['department'] as String?,
    );
  }
}

class ProfessorDetail {
  final int id;
  final String name;
  final String? department;
  final String? email;
  final String? phone;
  final String? officeLocation;
  final List<OfficeHour> officeHours;

  const ProfessorDetail({
    required this.id,
    required this.name,
    this.department,
    this.email,
    this.phone,
    this.officeLocation,
    required this.officeHours,
  });

  factory ProfessorDetail.fromJson(Map<String, dynamic> json) {
    return ProfessorDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      department: json['department'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      officeLocation: json['office_location'] as String?,
      officeHours: (json['office_hours'] as List<dynamic>?)
              ?.map((e) => OfficeHour.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OfficeHour {
  final int id;
  final String dayOfWeek;
  final String dayDisplay;
  final String startTime;
  final String endTime;
  final String? location;
  final String? note;

  const OfficeHour({
    required this.id,
    required this.dayOfWeek,
    required this.dayDisplay,
    required this.startTime,
    required this.endTime,
    this.location,
    this.note,
  });

  factory OfficeHour.fromJson(Map<String, dynamic> json) {
    return OfficeHour(
      id: json['id'] as int,
      dayOfWeek: json['day_of_week'] as String,
      dayDisplay: json['day_display'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      location: json['location'] as String?,
      note: json['note'] as String?,
    );
  }
}

class Classroom {
  final int id;
  final int building;
  final String buildingName;
  final String roomNumber;
  final String? name;

  const Classroom({
    required this.id,
    required this.building,
    required this.buildingName,
    required this.roomNumber,
    this.name,
  });

  String get displayName => name ?? '$buildingName $roomNumber';

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] as int,
      building: json['building'] as int,
      buildingName: json['building_name'] as String,
      roomNumber: json['room_number'] as String,
      name: json['name'] as String?,
    );
  }
}

class College {
  final int id;
  final String name;

  const College({required this.id, required this.name});

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Department {
  final int id;
  final String code;
  final String name;
  final int? college;
  final String collegeName;

  const Department({
    required this.id,
    required this.code,
    required this.name,
    this.college,
    this.collegeName = '',
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      college: json['college'] as int?,
      collegeName: json['college_name'] as String? ?? '',
    );
  }
}
