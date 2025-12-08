import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Dial/model/callhistory_model.dart';

class CallProvider extends ChangeNotifier {
 
final Box<CallModel> _box = Hive.box<CallModel>('call_log');
 Box<CallModel> get box => _box;

 
 Future<void> addCall(String number,int simSlot,int duration) async {
    final now = DateTime.now();
    final call = CallModel(number: number, time: now,simSlot: simSlot,duration: duration);
    _box.add(call);
    notifyListeners(); 
  }


  Future<void> deleteCall(CallModel call) async {
  call.delete(); 
  notifyListeners();
  
}
}




