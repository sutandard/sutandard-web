class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromStatusCode(int statusCode, [dynamic data]) {
    final serverMessage = _extractMessage(data);
    final fallback = switch (statusCode) {
      400 => '잘못된 요청입니다.',
      401 => '인증이 필요합니다. 다시 로그인해 주세요.',
      403 => '접근 권한이 없습니다.',
      404 => '요청하신 정보를 찾을 수 없습니다.',
      409 => '이미 존재하는 데이터입니다.',
      422 => '입력값을 확인해 주세요.',
      429 => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.',
      500 => '서버 오류가 발생했습니다.',
      502 => '서버에 연결할 수 없습니다.',
      503 => '서비스 점검 중입니다.',
      _ => '알 수 없는 오류가 발생했습니다. ($statusCode)',
    };
    return ApiException(
      message: serverMessage ?? fallback,
      statusCode: statusCode,
      data: data,
    );
  }

  /// DRF 응답에서 사람이 읽을 수 있는 에러 메시지를 추출
  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      // { "detail": "..." }
      if (data['detail'] is String) return data['detail'] as String;

      // { "non_field_errors": ["..."] }
      if (data['non_field_errors'] is List) {
        return (data['non_field_errors'] as List).join(', ');
      }

      // { "field": ["error1", "error2"] } — 첫 번째 필드 에러 반환
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final fieldErrors = (entry.value as List).join(', ');
          return '${entry.key}: $fieldErrors';
        }
        if (entry.value is String) {
          return '${entry.key}: ${entry.value}';
        }
      }
    }

    return null;
  }

  factory ApiException.network() =>
      const ApiException(message: '네트워크 연결을 확인해 주세요.');

  factory ApiException.timeout() =>
      const ApiException(message: '요청 시간이 초과되었습니다. 다시 시도해 주세요.');

  factory ApiException.unknown([String? detail]) => ApiException(
        message: detail ?? '알 수 없는 오류가 발생했습니다.',
      );

  @override
  String toString() => message;
}
