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
  StreamSubscription<AuthUser?>? _authSubscription;
  bool _splashComplete = false;
  AuthUser? _pendingAuthUser;

  void initialize() {
    emit(const AuthState(status: AuthStatus.splash));
    _splashComplete = false;
    _pendingAuthUser = null;

    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges().listen((user) {
      if (!_splashComplete) {
        _pendingAuthUser = user;
        return;
      }
      _emitAuthState(user);
    });

    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 2), () async {
      _splashComplete = true;
      final current = _pendingAuthUser ?? await _repository.currentUser();
      _pendingAuthUser = null;
      _emitAuthState(current);
    });
  }

  void _emitAuthState(AuthUser? user) {
    if (user != null) {
      final sameIdentity = state.user?.id == user.id;
      final unchanged = sameIdentity && state.user == user && state.status == AuthStatus.authenticated;
      if (unchanged) {
        return;
      }
      final preserveNewFlag = state.isNewUser && sameIdentity;
      emit(AuthState(status: AuthStatus.authenticated, user: user, isNewUser: preserveNewFlag));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  void sendOtp(String phoneNumber) async {
    emit(AuthState(status: AuthStatus.sendingOtp, phoneNumber: phoneNumber));
    try {
      final result = await _repository.sendOtp(phoneNumber);
      if (result != null) {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
          phoneNumber: phoneNumber,
          isNewUser: result.isNewUser,
        ));
        return;
      }
      emit(AuthState(status: AuthStatus.otpSent, phoneNumber: phoneNumber));
    } on AuthException catch (e) {
      emit(AuthState(status: AuthStatus.failure, phoneNumber: phoneNumber, errorMessage: e.message));
      emit(AuthState(status: AuthStatus.unauthenticated, phoneNumber: phoneNumber, errorMessage: e.message));
    } catch (_) {
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
      emit(AuthState(status: AuthStatus.authenticated, user: user, isNewUser: false));
    } on AuthException catch (e) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: e.message));
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Login failed. Try again.'));
      emit(const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Login failed. Try again.'));
    }
  }

  void signUpWithEmail(String email, String password) async {
    emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final user = await _repository.signUpWithEmail(email, password);
      emit(AuthState(status: AuthStatus.authenticated, user: user, isNewUser: true));
    } on AuthException catch (e) {
      emit(AuthState(status: AuthStatus.failure, errorMessage: e.message));
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.failure, errorMessage: 'Sign up failed. Try again.'));
      emit(const AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Sign up failed. Try again.'));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const AuthException('We could not send a reset email right now');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _splashTimer?.cancel();
    _authSubscription?.cancel();
    return super.close();
  }
}
