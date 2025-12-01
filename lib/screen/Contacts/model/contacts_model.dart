import 'package:hive_flutter/hive_flutter.dart';

part 'contacts_model.g.dart';

@HiveType(typeId: 1)
class ContactModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String number;

  @HiveField(2)
  String profile; 

  ContactModel({
    required this.name,
    required this.number,
    required this.profile,
  });
}
