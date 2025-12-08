import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Contacts/model/contact_history_model.dart';

class FavouriteProvider  extends ChangeNotifier{

  final Box<ContactModel> _favouriteBox = Hive.box<ContactModel>('favourites');
    Box<ContactModel> get favouriteBox => _favouriteBox;

 
void addToFavourite(List<ContactModel> favContact) {
  for (var fav in favContact) {
    final exists = _favouriteBox.values.any((e) => e.number == fav.number);

    if (!exists) {
      final newFav = ContactModel(
        name: fav.name,
        number: fav.number,
        profile: fav.profile,
      );
      _favouriteBox.add(newFav);
    }
  }

  
}


void deleteFavourite(ContactModel contact) {
  final favBox = Hive.box<ContactModel>('favourites');

 
  final keyToDelete = favBox.keys.firstWhere(
    (key) => favBox.get(key)?.number == contact.number,
    orElse: () => null,
  );

  if (keyToDelete != null) {
    favBox.delete(keyToDelete);
  }
}




}