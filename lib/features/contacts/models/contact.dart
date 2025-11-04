import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  const Contact({
    required this.name,
    required this.phone,
    required this.isUser,
    required this.plan,
    this.invited = false,
  });

  final String name;
  final String phone;
  final bool isUser;
  final String plan;
  final bool invited;

  Contact copyWith({
    bool? invited,
  }) {
    return Contact(
      name: name,
      phone: phone,
      isUser: isUser,
      plan: plan,
      invited: invited ?? this.invited,
    );
  }

  @override
  List<Object?> get props => [name, phone, isUser, plan, invited];
}
