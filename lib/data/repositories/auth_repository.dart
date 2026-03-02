import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<TokenPair> login(LoginRequest request);
  Future<TokenPair> register(RegisterRequest request);
  Future<void> logout();
  Future<User> getMe();
  Future<void> changePassword(ChangePasswordRequest request);
  Future<void> resetPassword(ResetPasswordRequest request);
  Future<bool> portalCheck(PortalCheckRequest request);
  Future<TokenPair> refreshToken(String refreshToken);
  Future<void> deleteAccount();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._client, this._tokenStorage);

  @override
  Future<TokenPair> login(LoginRequest request) async {
    final response = await _client.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    final tokens = TokenPair.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
    return tokens;
  }

  @override
  Future<TokenPair> register(RegisterRequest request) async {
    final response = await _client.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    final tokens = TokenPair.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
    return tokens;
  }

  @override
  Future<void> logout() async {
    try {
      final refresh = await _tokenStorage.getRefreshToken();
      if (refresh != null) {
        await _client.post(ApiConstants.logout, data: {'refresh': refresh});
      }
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<User> getMe() async {
    final response = await _client.get(ApiConstants.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _client.post(ApiConstants.changePassword, data: request.toJson());
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _client.post(ApiConstants.resetPassword, data: request.toJson());
  }

  @override
  Future<bool> portalCheck(PortalCheckRequest request) async {
    final response = await _client.post(
      ApiConstants.portalCheck,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['valid'] == true;
  }

  @override
  Future<void> deleteAccount() async {
    await _client.delete(ApiConstants.deleteAccount);
    await _tokenStorage.clear();
  }

  @override
  Future<TokenPair> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiConstants.tokenRefresh,
      data: {'refresh': refreshToken},
    );
    final tokens = TokenPair.fromJson(response.data as Map<String, dynamic>);
    await _tokenStorage.saveTokens(
      access: tokens.access,
      refresh: tokens.refresh,
    );
    return tokens;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.read(apiClientProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthRepositoryImpl(client, tokenStorage);
});
