import 'package:flutter/services.dart';

class SimHelper {
  static const _channel = MethodChannel('sim_channel');

 static Future<List<Map<String, String>>> getSimInfo() async {

  try {
    final List sims = await _channel.invokeMethod('getSimInfo');
    return sims.map<Map<String, String>>((sim) {
      final map = Map<String, String>.from(
        sim.map((key, value) => MapEntry(key.toString(), value.toString())),
      );
      return map;
    }).toList();
  } on PlatformException {
    return [];
  }
}
}

