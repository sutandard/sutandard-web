import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final isRefreshCall =
        err.requestOptions.path == ApiConstants.tokenRefresh;
    if (isRefreshCall) {
      await _tokenStorage.clear();
      handler.next(err);
      return;
    }

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String;
      final newRefresh =
          response.data['refresh'] as String? ?? refreshToken;

      await _tokenStorage.saveTokens(
        access: newAccess,
        refresh: newRefresh,
      );

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';

      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      await _tokenStorage.clear();
      handler.next(err);
    }
  }
}
