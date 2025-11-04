import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/auth_user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState());

  final AuthRepository _repository;

  Timer? _splashTimer;

  void initialize() {
    emit(const AuthState(status: AuthStatus.splash));
    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 2), () async {
      final user = await _repository.currentUser();
      if (user != null) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    });
  }

  void sendOtp(String phoneNumber) async {
    emit(AuthState(status: AuthStatus.sendingOtp, phoneNumber: phoneNumber));
    try {
      await _repository.sendOtp(phoneNumber);
      emit(AuthState(status: AuthStatus.otpSent, phoneNumber: phoneNumber));
    } on AuthException catch (e) {
      emit(AuthState(status: AuthStatus.failure, phoneNumber: phoneNumber, errorMessage: e.message));
      emit(AuthState(status: AuthStatus.unauthenticated, phoneNumber: phoneNumber, errorMessage: e.message));
    } catch (e) {
      emit(AuthState(status: AuthStatus.failure, phoneNumber: phoneNumber, errorMessage: 'Could not send OTP'));
      emit(AuthState(status: AuthStatus.unauthenticated, phoneNumber: phoneNumber));
    }
  }

  void verifyOtp(String otp) async {
    emit(AuthState(status: AuthStatus.verifyingOtp, phoneNumber: state.phoneNumber));
    try {
      final result = await _repository.verifyOtp(state.phoneNumber, otp);
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        phoneNumber: state.phoneNumber,
        isNewUser: result.isNewUser,
      ));
    } on AuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.failure,
        phoneNumber: state.phoneNumber,
        errorMessage: e.message,
      ));
      emit(AuthState(
        status: AuthStatus.otpSent,
        phoneNumber: state.phoneNumber,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(AuthState(
        status: AuthStatus.failure,
        phoneNumber: state.phoneNumber,
        errorMessage: 'OTP verification failed',
      ));
      emit(AuthState(status: AuthStatus.otpSent, phoneNumber: state.phoneNumber));
    }
  }

  void loginWithEmail(String email, String password) async {
    emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final user = await _repository.loginWithEmail(email, password);
      if (user == null) {
        emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Unknown account'));
        emit(const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Unknown account'));
        return;
      }
      emit(AuthState(status: AuthStatus.authenticated, user: user, isNewUser: false));
    } on AuthException catch (e) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: e.message));
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Login failed. Try again.'));
      emit(const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Login failed. Try again.'));
    }
  }

  void logout() {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _splashTimer?.cancel();
    return super.close();
  }
}
