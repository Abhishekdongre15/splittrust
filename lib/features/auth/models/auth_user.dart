import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.plan,
    required this.isInvitable,
  });

  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String plan;
  final bool isInvitable;

  AuthUser copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? plan,
    bool? isInvitable,
  }) {
    return AuthUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      plan: plan ?? this.plan,
      isInvitable: isInvitable ?? this.isInvitable,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, phone, plan, isInvitable];
}
