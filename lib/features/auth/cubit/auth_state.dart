import 'package:equatable/equatable.dart';

import '../models/auth_user.dart';

enum AuthStatus {
  splash,
  unauthenticated,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticating,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.splash,
    this.user,
    this.phoneNumber = '',
    this.errorMessage,
    this.isNewUser = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String phoneNumber;
  final String? errorMessage;
  final bool isNewUser;

  bool get isSplash => status == AuthStatus.splash;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? phoneNumber,
    String? errorMessage,
    bool? isNewUser,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  List<Object?> get props => [status, user, phoneNumber, errorMessage, isNewUser];
}
