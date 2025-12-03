import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';


import 'package:phoneapp/screen/Dial/model/call_history_model.dart';


class CallProvider extends ChangeNotifier {
 
final Box<CallModel> _box = Hive.box<CallModel>('call_log');
 Box<CallModel> get box => _box;


 void addCall(String number,int simSlot) {
    final now = DateTime.now();
    final call = CallModel(number: number, time: now,simSlot: simSlot);
    _box.add(call);
    notifyListeners();
   
    
  }

  void deleteCall(CallModel call) {
  // final keyToDelete = _box.keys.firstWhere(
  //   (key) => _box.get(key)?.number == call.number,
  //   orElse: () => null,
  // );

  // if (keyToDelete != null) {
  //   _box.delete(keyToDelete);
  // }
  call.delete(); 
  notifyListeners();
  
}

}




