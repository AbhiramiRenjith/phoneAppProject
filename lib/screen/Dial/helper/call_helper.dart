import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class CallHelper {
  static const platform = MethodChannel("sim_channel");
  static Future<void> makeCall(
      BuildContext context, String number, int simSlot) async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) return;
    }

    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      arguments: {"com.android.phone.extra.slot": simSlot},
    );
    await intent.launch();


    await platform.invokeMethod("startCallListener", {"number": number});

    platform.setMethodCallHandler((call) async {
      if (call.method == "callEnded") {
        if (!context.mounted) return;

   
        await Future.delayed(const Duration(seconds: 1));

  
        Iterable<CallLogEntry> entries = await CallLog.query();

   
        List<CallLogEntry> sorted = entries.toList()
          ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

        CallLogEntry? lastCall = sorted.firstWhereOrNull(
          (entry) => entry.number == number,
        );

        int duration = lastCall?.duration ?? 0;
        if (duration == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Call not connected")),
          );
        }

        
       final callProvider = Provider.of<CallProvider>(context, listen: false);
        callProvider.addCall(number, simSlot, duration,false);
        

      }
    });
  }
}
