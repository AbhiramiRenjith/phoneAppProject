import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Contacts/model/contacts_model.dart';

class ContactProvider extends ChangeNotifier {
  final Box<ContactModel> _contactBox = Hive.box<ContactModel>('contacts');

  Box<ContactModel> get contactBox => _contactBox;
  void addContact(ContactModel contact) {
    _contactBox.add(contact);
    notifyListeners();
  }

  void deleteContact(ContactModel contact) {
    contact.delete();
    notifyListeners();
  }



  Future<void> updateContact(ContactModel existingContact, {
  required String updatedName,
  required String updatedPhone,
  String? updatedImage,
}) async {

  final key = existingContact.key;  

  if (key != null) {
    final updated = ContactModel(
      name: updatedName,
      number: updatedPhone,
      profile: updatedImage ?? existingContact.profile,
    );

    await contactBox.put(key, updated);  
  }
  notifyListeners();
}


}
