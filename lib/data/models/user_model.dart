class User {
  final String studentId;
  final String name;
  final String major;
  final String email;
  final DateTime createdAt;

  const User({
    required this.studentId,
    required this.name,
    required this.major,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      studentId: json['student_id'] as String,
      name: json['name'] as String,
      major: json['major'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TokenPair {
  final String access;
  final String refresh;

  const TokenPair({required this.access, required this.refresh});

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }
}

class LoginRequest {
  final String studentId;
  final String password;

  const LoginRequest({required this.studentId, required this.password});

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'password': password,
      };
}

class RegisterRequest {
  final String studentId;
  final String portalPassword;
  final String password;
  final String passwordConfirm;

  const RegisterRequest({
    required this.studentId,
    required this.portalPassword,
    required this.password,
    required this.passwordConfirm,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'portal_password': portalPassword,
        'password': password,
        'password_confirm': passwordConfirm,
      };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirm;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirm,
  });

  Map<String, dynamic> toJson() => {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      };
}

class ResetPasswordRequest {
  final String studentId;
  final String portalPassword;
  final String newPassword;
  final String newPasswordConfirm;

  const ResetPasswordRequest({
    required this.studentId,
    required this.portalPassword,
    required this.newPassword,
    required this.newPasswordConfirm,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'portal_password': portalPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      };
}

class PortalCheckRequest {
  final String studentId;
  final String portalPassword;

  const PortalCheckRequest({
    required this.studentId,
    required this.portalPassword,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'portal_password': portalPassword,
      };
}
