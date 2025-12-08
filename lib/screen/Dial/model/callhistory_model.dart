import 'package:hive_flutter/hive_flutter.dart';
 part 'callhistory_model.g.dart';

@HiveType(typeId: 0)
class CallModel extends HiveObject {
  @HiveField(0)
  String number;
  @HiveField(1)
  DateTime time;
  @HiveField(2)
  int simSlot;
  @HiveField(3)
  int duration;
  CallModel({required this.number, required this.time, required this.simSlot,this.duration = 0});
}
