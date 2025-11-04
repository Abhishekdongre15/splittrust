import 'package:equatable/equatable.dart';
import '../models/contact.dart';

enum ContactsStatus { initial, loading, ready, failure }

class ContactsState extends Equatable {
  const ContactsState({
    this.status = ContactsStatus.initial,
    this.contacts = const [],
    this.errorMessage,
    this.lastInvited,
  });

  final ContactsStatus status;
  final List<Contact> contacts;
  final String? errorMessage;
  final Contact? lastInvited;

  ContactsState copyWith({
    ContactsStatus? status,
    List<Contact>? contacts,
    String? errorMessage,
    Contact? lastInvited,
    bool clearError = false,
  }) {
    return ContactsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastInvited: lastInvited ?? this.lastInvited,
    );
  }

  @override
  List<Object?> get props => [status, contacts, errorMessage, lastInvited];
}
