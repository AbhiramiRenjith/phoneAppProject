import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

   part 'contact_history_model.g.dart';

@HiveType(typeId: 1)
class ContactModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String number;

  @HiveField(2)
  Uint8List? profile; 

  @HiveField(3)
  String? profilePath;
  @HiveField(4)
  String? deviceId; 

  ContactModel({
    required this.name,
    required this.number,
    this.profile,
    this.profilePath,
     this.deviceId,
  });
}
