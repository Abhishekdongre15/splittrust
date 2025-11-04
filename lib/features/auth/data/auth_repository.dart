import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  String? _verificationId;
  int? _resendToken;

  Future<AuthUser?> currentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    return AuthUser.fromFirebaseUser(user);
  }

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return AuthUser.fromFirebaseUser(user);
    });
  }

  Future<AuthUser> loginWithEmail(String email, String password) async {
    if (email.isEmpty) {
      throw const AuthException('Enter your email address');
    }
    if (password.isEmpty) {
      throw const AuthException('Enter your password to continue');
    }
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Login failed. Try again.');
      }
      return AuthUser.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (_) {
      throw const AuthException('Login failed. Try again.');
    }
  }

  Future<AuthUser> signUpWithEmail(String email, String password) async {
    if (email.isEmpty) {
      throw const AuthException('Enter your email address');
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters');
    }
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Could not create your account');
      }
      return AuthUser.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (_) {
      throw const AuthException('Could not create your account');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      throw const AuthException('Enter your email address');
    }
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (_) {
      throw const AuthException('We could not send a reset email right now');
    }
  }

  Future<({AuthUser user, bool isNewUser})?> sendOtp(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw const AuthException('Enter your mobile number');
    }
    final completer = Completer<({AuthUser user, bool isNewUser})?>();
    try {
      final verificationFuture = _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          try {
            final result = await _firebaseAuth.signInWithCredential(credential);
            final user = result.user;
            _verificationId = null;
            _resendToken = null;
            if (user != null && !completer.isCompleted) {
              completer.complete((
                user: AuthUser.fromFirebaseUser(user),
                isNewUser: result.additionalUserInfo?.isNewUser ?? false,
              ));
            } else if (!completer.isCompleted) {
              completer.complete(null);
            }
          } on FirebaseAuthException catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(AuthException(_mapFirebaseError(e)));
            }
          } catch (_) {
            if (!completer.isCompleted) {
              completer.completeError(
                const AuthException('Automatic verification failed. Try the OTP.'),
              );
            }
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException(_mapFirebaseError(error)));
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
      unawaited(verificationFuture.catchError((error) {
        if (!completer.isCompleted) {
          if (error is FirebaseAuthException) {
            completer.completeError(AuthException(_mapFirebaseError(error)));
          } else {
            completer.completeError(const AuthException('Could not send OTP'));
          }
        }
      }));
    } on FirebaseAuthException catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(AuthException(_mapFirebaseError(e)));
      }
    } catch (_) {
      if (!completer.isCompleted) {
        completer.completeError(const AuthException('Could not send OTP'));
      }
    }
    return completer.future;
  }

  Future<({AuthUser user, bool isNewUser})> verifyOtp(String? phoneNumber, String otp) async {
    if (_verificationId == null) {
      throw const AuthException('Request a new OTP to continue');
    }
    if (otp.isEmpty) {
      throw const AuthException('Enter the 6-digit code');
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      final user = result.user;
      _verificationId = null;
      _resendToken = null;
      if (user == null) {
        throw const AuthException('OTP verification failed');
      }
      return (
        user: AuthUser.fromFirebaseUser(user),
        isNewUser: result.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (_) {
      throw const AuthException('OTP verification failed');
    }
  }

  Future<void> logout() async {
    _verificationId = null;
    _resendToken = null;
    await _firebaseAuth.signOut();
  }

  String _mapFirebaseError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'We could not find an account for that email';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'missing-phone-number':
        return 'Enter your mobile number';
      case 'invalid-phone-number':
        return 'Enter a valid mobile number';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'session-expired':
        return 'The OTP expired. Request a new code';
      default:
        return exception.message ?? 'Something went wrong. Try again';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
