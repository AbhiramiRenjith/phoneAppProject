
// import 'dart:async';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:call_log/call_log.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:collection/collection.dart';

// class CallHelper {
//   static const platform = MethodChannel("sim_channel");
//   static const MethodChannel _channel = MethodChannel('call_helper');

//   static Future<void> makeCall(
//       BuildContext context, String number, int simSlot) async {
//     var status = await Permission.phone.status;
//     if (!status.isGranted) {
//       status = await Permission.phone.request();
//       if (!status.isGranted) return;
//     }

//     final intent = AndroidIntent(
//       action: 'android.intent.action.CALL',
//       data: 'tel:$number',
//       arguments: {"com.android.phone.extra.slot": simSlot},
//     );
//     await intent.launch();

//     await platform.invokeMethod("startCallListener", {"number": number});

//     platform.setMethodCallHandler((call) async {
//       if (call.method == "callEnded") {
//         if (!context.mounted) return;

//         await Future.delayed(const Duration(seconds: 1));

//         Iterable<CallLogEntry> entries = await CallLog.query();
//         List<CallLogEntry> sorted = entries.toList()
//           ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

//         CallLogEntry? lastCall = sorted.firstWhereOrNull(
//           (entry) => entry.number == number,
//         );

//         int duration = lastCall?.duration ?? 0;

//         if (duration == 0) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Call not connected")),
//           );
//         }

//         final callProvider = Provider.of<CallProvider>(context, listen: false);
//         await callProvider.addCall(number, simSlot, duration, "outgoing");
//       }
//     });
//   }

//   static Future<void> deleteCallLog(String number, int timestamp) async {
//     try {
//       await _channel.invokeMethod('deleteCall', {
//         'number': number,
//         'timestamp': timestamp,
//       });
//     } on PlatformException catch (e) {
//       print("Error deleting call log: ${e.message}");
//     }
//   }
// }



import 'package:android_intent_plus/android_intent.dart';
import 'package:call_log/call_log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phoneapp/screen/Dial/provider/call_provider.dart';
import 'package:provider/provider.dart';

class CallHelper {
  static const platform = MethodChannel("sim_channel");
  static const MethodChannel _channel = MethodChannel('call_helper');

  static bool _isInitialized = false;

  static void initialize(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    platform.setMethodCallHandler((call) async {
      if (call.method == "callEnded") {
        final number = call.arguments["number"];

        // Wait longer for accurate duration
        await Future.delayed(const Duration(milliseconds: 1800));

        Iterable<CallLogEntry> entries = await CallLog.query();
        List<CallLogEntry> sorted = entries.toList()
          ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

        // Get the latest matching call
        CallLogEntry? lastCall = sorted.firstWhereOrNull(
          (e) => e.number == number,
        );

        int duration = lastCall?.duration ?? 0;
        int simSlot = lastCall?.simDisplayName == "SIM 1" ? 0 : 1;

        final callProvider = Provider.of<CallProvider>(
            context, listen: false);

        await callProvider.addCall(
            number, simSlot, duration, "outgoing");
      }
    });
  }

  static Future<void> makeCall(
      BuildContext context, String number, int simSlot) async {
    initialize(context); // <-- CALL IT HERE ONE TIME ONLY

    if (!await Permission.phone.request().isGranted) return;

    final intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:$number',
      arguments: {"com.android.phone.extra.slot": simSlot},
    );
    await intent.launch();

    await platform.invokeMethod("startCallListener", {"number": number});
  }

    static Future<void> deleteCallLog(String number, int timestamp) async {
    try {
      await _channel.invokeMethod('deleteCall', {
        'number': number,
        'timestamp': timestamp,
      });
    } on PlatformException catch (e) {
      print("Error deleting call log: ${e.message}");
    }
  }
}
