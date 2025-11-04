import 'dart:async';

import '../models/auth_user.dart';

class AuthRepository {
  AuthRepository();

  static const _otpCode = '123456';

  final _users = <AuthUser>[
    const AuthUser(
      id: 'u1',
      displayName: 'Aisha Sharma',
      email: 'aisha@splittrust.app',
      phone: '+919876543210',
      plan: 'gold',
      isInvitable: false,
    ),
    const AuthUser(
      id: 'u2',
      displayName: 'Rahul Verma',
      email: 'rahul@splittrust.app',
      phone: '+919812345678',
      plan: 'silver',
      isInvitable: false,
    ),
    const AuthUser(
      id: 'u3',
      displayName: 'Emily Tan',
      email: 'emily@splittrust.app',
      phone: '+6598765432',
      plan: 'diamond',
      isInvitable: false,
    ),
  ];

  Future<AuthUser?> loginWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (password.trim().isEmpty) {
      throw const AuthException('Enter your password to continue');
    }
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => const AuthUser(
        id: '',
        displayName: '',
        email: '',
        phone: '',
        plan: '',
        isInvitable: true,
      ),
    );
    if (user.id.isEmpty) {
      throw const AuthException('We could not find an account for that email');
    }
    return user;
  }

  Future<void> sendOtp(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (phoneNumber.isEmpty) {
      throw const AuthException('Enter your mobile number');
    }
  }

  Future<({AuthUser user, bool isNewUser})> verifyOtp(String phoneNumber, String otp) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (otp != _otpCode) {
      throw const AuthException('Invalid OTP. Try 123456');
    }
    final existing = _users.where((user) => user.phone == phoneNumber).toList();
    if (existing.isNotEmpty) {
      return (user: existing.first, isNewUser: false);
    }
    final newUser = AuthUser(
      id: 'u${_users.length + 1}',
      displayName: 'New SplitTrust user',
      email: '',
      phone: phoneNumber,
      plan: 'silver',
      isInvitable: false,
    );
    _users.add(newUser);
    return (user: newUser, isNewUser: true);
  }

  Future<AuthUser?> currentUser() async {
    return null;
  }

  List<AuthUser> registeredUsers() => List<AuthUser>.unmodifiable(_users);
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
