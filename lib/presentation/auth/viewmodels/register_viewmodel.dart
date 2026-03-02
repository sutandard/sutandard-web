import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_handler.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

enum RegisterStep { terms, studentId, portalAuth, password }

class RegisterState {
  final RegisterStep step;
  final bool termsAgreed;
  final bool privacyAgreed;
  final String studentId;
  final String portalPassword;
  final bool portalVerified;
  final User? userInfo;
  final bool isLoading;
  final String? error;

  const RegisterState({
    this.step = RegisterStep.terms,
    this.termsAgreed = false,
    this.privacyAgreed = false,
    this.studentId = '',
    this.portalPassword = '',
    this.portalVerified = false,
    this.userInfo,
    this.isLoading = false,
    this.error,
  });

  bool get allTermsAgreed => termsAgreed && privacyAgreed;

  RegisterState copyWith({
    RegisterStep? step,
    bool? termsAgreed,
    bool? privacyAgreed,
    String? studentId,
    String? portalPassword,
    bool? portalVerified,
    User? userInfo,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUserInfo = false,
  }) {
    return RegisterState(
      step: step ?? this.step,
      termsAgreed: termsAgreed ?? this.termsAgreed,
      privacyAgreed: privacyAgreed ?? this.privacyAgreed,
      studentId: studentId ?? this.studentId,
      portalPassword: portalPassword ?? this.portalPassword,
      portalVerified: portalVerified ?? this.portalVerified,
      userInfo: clearUserInfo ? null : (userInfo ?? this.userInfo),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegisterViewModel extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  void setTermsAgreed(bool value) {
    state = state.copyWith(termsAgreed: value);
  }

  void setPrivacyAgreed(bool value) {
    state = state.copyWith(privacyAgreed: value);
  }

  void toggleAllTerms(bool value) {
    state = state.copyWith(termsAgreed: value, privacyAgreed: value);
  }

  void goToStudentId() {
    if (!state.allTermsAgreed) return;
    state = state.copyWith(step: RegisterStep.studentId, clearError: true);
  }

  void setStudentId(String value) {
    state = state.copyWith(studentId: value);
  }

  void goToPortalAuth() {
    if (state.studentId.isEmpty) {
      state = state.copyWith(error: '학번을 입력해주세요.');
      return;
    }
    state = state.copyWith(step: RegisterStep.portalAuth, clearError: true);
  }

  Future<void> verifyPortal(String portalPassword) async {
    state = state.copyWith(
        isLoading: true, clearError: true, portalPassword: portalPassword);

    try {
      final repo = ref.read(authRepositoryProvider);
      final isValid = await repo.portalCheck(PortalCheckRequest(
        studentId: state.studentId,
        portalPassword: portalPassword,
      ));

      if (isValid) {
        state = state.copyWith(
          isLoading: false,
          portalVerified: true,
          step: RegisterStep.password,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '포털 인증에 실패했습니다. 학번과 포털 비밀번호를 확인해주세요.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    }
  }

  Future<bool> completeRegistration(
      String password, String passwordConfirm) async {
    if (password.length < 8) {
      state = state.copyWith(error: '비밀번호는 8자 이상이어야 합니다.');
      return false;
    }

    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    if (!hasSpecialChar) {
      state = state.copyWith(error: '특수문자를 포함해야 합니다.');
      return false;
    }

    if (password != passwordConfirm) {
      state = state.copyWith(error: '비밀번호가 일치하지 않습니다.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(RegisterRequest(
        studentId: state.studentId,
        portalPassword: state.portalPassword,
        password: password,
        passwordConfirm: passwordConfirm,
      ));
      final user = await repo.getMe();
      state = state.copyWith(userInfo: user);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: extractErrorMessage(e));
      return false;
    }
  }

  void goBack() {
    final prevStep = switch (state.step) {
      RegisterStep.terms => RegisterStep.terms,
      RegisterStep.studentId => RegisterStep.terms,
      RegisterStep.portalAuth => RegisterStep.studentId,
      RegisterStep.password => RegisterStep.portalAuth,
    };
    state = state.copyWith(step: prevStep, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const RegisterState();
  }
}

final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(
  RegisterViewModel.new,
);
