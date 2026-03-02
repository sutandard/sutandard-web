import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../core/network/token_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkExistingSession();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  Future<void> _checkExistingSession() async {
    final hasTokens = await _tokenStorage.hasTokens();
    if (hasTokens) {
      try {
        final user = await _repo.getMe();
        state = AuthState(user: user, isAuthenticated: true);
      } catch (_) {
        await _tokenStorage.clear();
      }
    }
  }

  Future<bool> login(String studentId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repo.login(LoginRequest(
        studentId: studentId,
        password: password,
      ));
      final user = await _repo.getMe();
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}
    state = const AuthState();
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteAccount();
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
      return false;
    }
  }

  void setAuthenticated(User user) {
    state = AuthState(user: user, isAuthenticated: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
