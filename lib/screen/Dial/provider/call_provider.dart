import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/screen/Dial/model/call_log_history_model.dart';


class CallProvider extends ChangeNotifier {
 
final Box<CallModel> _box = Hive.box<CallModel>('call_log');
 Box<CallModel> get box => _box;

 
 Future<void> addCall(String number,int simSlot,int duration,bool incoming) async {
    final now = DateTime.now();
    final call = CallModel(number: number, time: now,simSlot: simSlot,duration: duration,incoming: incoming);
    _box.add(call);
    notifyListeners(); 
  }


  Future<void> deleteCall(CallModel call) async {
  call.delete(); 
  notifyListeners();
  

}



  // Fetch device calls (incoming/outgoing/missed)
  Future<void> fetchDeviceCalls() async {
    if (!await Permission.phone.request().isGranted ||
        !await Permission.contacts.request().isGranted) return;

    Iterable<CallLogEntry> entries = await CallLog.get();

    for (var entry in entries) {
      // Avoid duplicates by checking timestamp & number
      bool exists = _box.values.any((c) =>
          c.number == entry.number &&
          c.time.millisecondsSinceEpoch ==
              (entry.timestamp ?? DateTime.now().millisecondsSinceEpoch));

      if (!exists) {
        _box.add(CallModel(
          number: entry.number ?? '',
          time: entry.timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(entry.timestamp!)
              : DateTime.now(),
          simSlot: 0, // or map to entry.simSlot if available
          duration: entry.duration ?? 0,
          incoming: entry.callType == CallType.incoming,
        ));
      }
    }
    notifyListeners();
  }




}


