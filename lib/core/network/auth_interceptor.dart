import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  bool _isRefreshing = false;
  final _pendingRequests =
      <({RequestOptions options, ErrorInterceptorHandler handler})>[];

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

    // refresh 엔드포인트 자체가 401 → 토큰 완전 만료, 로그아웃
    final isRefreshCall =
        err.requestOptions.path == ApiConstants.tokenRefresh;
    if (isRefreshCall) {
      await _tokenStorage.clear();
      handler.next(err);
      return;
    }

    // 이미 refresh 진행 중이면 큐에 대기
    if (_isRefreshing) {
      _pendingRequests
          .add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        handler.next(err);
        _rejectPending(err);
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

      // 원래 요청 재시도
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);

      // 대기 중인 요청들도 새 토큰으로 재시도
      _resolvePending(newAccess);
    } on DioException {
      await _tokenStorage.clear();
      handler.next(err);
      _rejectPending(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// 대기 중인 요청들을 새 토큰으로 재시도
  void _resolvePending(String newAccess) {
    final pending = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final req in pending) {
      req.options.headers['Authorization'] = 'Bearer $newAccess';
      _dio.fetch(req.options).then(
            (response) => req.handler.resolve(response),
            onError: (e) => req.handler.reject(
              e is DioException
                  ? e
                  : DioException(
                      requestOptions: req.options, error: e),
            ),
          );
    }
  }

  /// 대기 중인 요청들을 전부 실패 처리
  void _rejectPending(DioException err) {
    final pending = List.of(_pendingRequests);
    _pendingRequests.clear();
    for (final req in pending) {
      req.handler.next(DioException(
        requestOptions: req.options,
        error: err.error,
        type: err.type,
        response: err.response,
      ));
    }
  }
}
