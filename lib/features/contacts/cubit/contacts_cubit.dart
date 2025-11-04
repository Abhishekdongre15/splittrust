import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/contact_repository.dart';
import '../models/contact.dart';
import 'contacts_state.dart';

class ContactsCubit extends Cubit<ContactsState> {
  ContactsCubit({required ContactRepository repository})
      : _repository = repository,
        super(const ContactsState());

  final ContactRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ContactsStatus.loading));
    try {
      final contacts = _repository.fetchContacts();
      emit(state.copyWith(status: ContactsStatus.ready, contacts: contacts));
    } catch (e) {
      emit(state.copyWith(status: ContactsStatus.failure, errorMessage: 'Unable to read contacts'));
    }
  }

  Future<void> invite(Contact contact) async {
    final invitedContact = contact.copyWith(invited: true);
    final updated = state.contacts.map((c) {
      if (c.phone == contact.phone) {
        return invitedContact;
      }
      return c;
    }).toList();
    emit(state.copyWith(contacts: updated, lastInvited: invitedContact));

    final uri = Uri.parse('sms:${contact.phone}?body=${Uri.encodeComponent(_downloadMessage(contact.name))}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // ignored; we already updated the UI state and will show the snackbar via listener
    }
  }

  String _downloadMessage(String name) {
    return 'Hi $name, join me on SplitTrust to track shared expenses. Download the app: https://splittrust.app/download';
  }
}
