import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';

class ContactProvider extends ChangeNotifier {
  final Box<ContactModel> _contactBox = Hive.box<ContactModel>('contacts');

  Box<ContactModel> get contactBox => _contactBox;

  Future<void> loadDeviceContacts() async {
    if (!await FlutterContacts.requestPermission()) return;

    List<Contact> deviceContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
    );

    await _contactBox.clear();

    for (var c in deviceContacts) {
      final name = c.displayName;
      final number = c.phones.isNotEmpty ? c.phones.first.number : "";
      final Uint8List? profile = c.thumbnail;

      if (number.isEmpty) continue;

      _contactBox.add(
        ContactModel(
          name: name,
          number: number,
          profile: profile,
          deviceId: c.id,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> deleteContactFromDevice(ContactModel contact) async {
    if (!await FlutterContacts.requestPermission()) return;

    if (contact.deviceId != null && contact.deviceId!.isNotEmpty) {
      final deviceContact = await FlutterContacts.getContact(
        contact.deviceId!,
        withProperties: true,
        withThumbnail: true,
      );

      if (deviceContact != null) {
        try {
          await deviceContact.delete();
        } catch (e) {
          debugPrint('Failed to delete device contact: $e');
        }
      }
    }

    await _contactBox.delete(contact.key);
    notifyListeners();
  }

  Future<void> addContact(ContactModel contact) async {
    await _contactBox.add(contact);
    notifyListeners();

    if (!await FlutterContacts.requestPermission()) return;

    final newDeviceContact = Contact()
      ..name.first = contact.name
      ..phones = [Phone(contact.number)];

    if (contact.profile != null && contact.profile!.isNotEmpty) {
      newDeviceContact.photo = contact.profile;
    }

    try {
      await newDeviceContact.insert();

      contact.deviceId = newDeviceContact.id;
      await contact.save();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add contact to device: $e');
    }
  }

  Future<void> updateContact(
    ContactModel existingContact, {
    required String updatedName,
    required String updatedPhone,
    Uint8List? updatedImageBytes,
    String? updatedPath,
  }) async {
    existingContact.name = updatedName;
    existingContact.number = updatedPhone;
    existingContact.profile = updatedImageBytes;
    existingContact.profilePath = updatedPath;
    await existingContact.save();
    notifyListeners();

    if (!await FlutterContacts.requestPermission()) return;

    if (existingContact.deviceId != null &&
        existingContact.deviceId!.isNotEmpty) {
      final deviceContact = await FlutterContacts.getContact(
        existingContact.deviceId!,
        withProperties: true,
        withThumbnail: true,
        withAccounts: true,
      );

      if (deviceContact != null) {
        deviceContact.name.first = updatedName;
        deviceContact.phones = [Phone(updatedPhone)];

        if (updatedImageBytes != null) {
          deviceContact.photo = updatedImageBytes;
        }

        await deviceContact.update();
        return;
      }
    }

    final newDeviceContact = Contact()
      ..name.first = updatedName
      ..phones = [Phone(updatedPhone)];

    if (updatedImageBytes != null) {
      newDeviceContact.photo = updatedImageBytes;
    }

    await newDeviceContact.insert();

    existingContact.deviceId = newDeviceContact.id;
    await existingContact.save();
    notifyListeners();
  }
}
