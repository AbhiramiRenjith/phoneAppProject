import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoneapp/screen/Dial/model/call_history_model.dart';
class CallProvider extends ChangeNotifier {
 
final Box<CallModel> _box = Hive.box<CallModel>('call_log');
 Box<CallModel> get box => _box;


 void addCall(String number,int simSlot,int duration) {
    final now = DateTime.now();
    final call = CallModel(number: number, time: now,simSlot: simSlot,duration: duration);
    _box.add(call);
    notifyListeners();
   
    
  }

  void deleteCall(CallModel call) {
  call.delete(); 
  notifyListeners();
  
}
void updateCallsNumber({required String oldNumber, required String newNumber}) {
  final calls = box.values.where((c) => c.number == oldNumber);
  for (var call in calls) {
    call.number = newNumber;
    call.save();
  }
}

}




