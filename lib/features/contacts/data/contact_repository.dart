import '../models/contact.dart';

class ContactRepository {
  ContactRepository();

  List<Contact> fetchContacts() {
    return const [
      Contact(name: 'Aisha Sharma', phone: '+919876543210', isUser: true, plan: 'Gold'),
      Contact(name: 'Rahul Verma', phone: '+919812345678', isUser: true, plan: 'Silver'),
      Contact(name: 'Karan Patel', phone: '+919765432189', isUser: false, plan: ''),
      Contact(name: 'Neha Gupta', phone: '+919998877665', isUser: false, plan: ''),
      Contact(name: 'Emily Tan', phone: '+6598765432', isUser: true, plan: 'Diamond'),
      Contact(name: 'Sophia Lee', phone: '+6599123456', isUser: false, plan: ''),
      Contact(name: 'Ravi Kumar', phone: '+919887766554', isUser: false, plan: ''),
    ];
  }
}
