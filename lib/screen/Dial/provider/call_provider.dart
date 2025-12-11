
import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/call_log_model.dart';
import '../helper/call_helper.dart';

class CallProvider extends ChangeNotifier {
  final Box<CallModel> _box = Hive.box<CallModel>('call_log');
  Box<CallModel> get box => _box;

  Future<void> addCall(
      String number, int simSlot, int duration, String callType) async {
    final now = DateTime.now();
    final call = CallModel(
      number: number,
      time: now,
      simSlot: simSlot,
      duration: duration,
      callType: callType,
    );
    await _box.add(call);
    notifyListeners();
  }

  Future<void> deleteCall(CallModel call) async {
    await call.delete();
    await CallHelper.deleteCallLog(call.number, call.time.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> fetchDeviceCalls() async {
    if (!await Permission.phone.request().isGranted) return;

    Iterable<CallLogEntry> entries = await CallLog.get();

    for (var entry in entries) {
      String type;
      switch (entry.callType) {
        case CallType.incoming:
          type = "incoming";
          break;
        case CallType.outgoing:
          type = "outgoing";
          break;
        case CallType.missed:
          type = "missed";
          break;
        default:
          type = "incoming";
      }

      final timestamp = entry.timestamp ?? 0;
      bool exists = _box.values.any(
          (c) => c.number == (entry.number ?? '') && c.time.millisecondsSinceEpoch == timestamp);

      if (!exists) {
        await _box.add(
          CallModel(
            number: entry.number ?? '',
            time: DateTime.fromMillisecondsSinceEpoch(timestamp),
            simSlot: 0,
            duration: entry.duration ?? 0,
            callType: type,
          ),
        );
      }
    }

    notifyListeners();
  }
}
