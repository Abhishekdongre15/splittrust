import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  const Contact({
    required this.name,
    this.phone,         // optional
    this.email,         // optional
    required this.isUser,
    required this.plan,
    this.invited = false,
  });

  final String name;
  final String? phone;
  final String? email;
  final bool isUser;
  final String plan;
  final bool invited;

  Contact copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isUser,
    String? plan,
    bool? invited,
  }) {
    return Contact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isUser: isUser ?? this.isUser,
      plan: plan ?? this.plan,
      invited: invited ?? this.invited,
    );
  }

  /// A loose identity used for local list updates.
  /// Prefers phone, then email, finally name as last resort.
  String get identity => phone ?? email ?? name;

  @override
  List<Object?> get props => [name, phone, email, isUser, plan, invited];
}
