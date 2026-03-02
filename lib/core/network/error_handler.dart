import 'package:dio/dio.dart';
import 'api_exception.dart';

/// DioException 내부의 ApiException 메시지를 추출하거나,
/// 일반 Exception의 message를 반환합니다.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner.message;
    return error.message ?? '알 수 없는 오류가 발생했습니다.';
  }
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
