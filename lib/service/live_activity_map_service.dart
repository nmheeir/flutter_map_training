import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_map_training/models/map_live_activity.dart';

class LiveActivityMapService {
  static const platform = MethodChannel(
    'com.example.flutter_map_training/map_live_activity',
  );

  Future<void> startLiveActivity({required MapLiveActivity data}) async {
    try {
      await platform.invokeMethod('startLiveActivity', data.toJson());
    } on PlatformException catch (e) {
      log("Failed to start live activity: '${e.message}'.");
    }
  }

  Future<void> updateLiveActivity({required MapLiveActivity data}) async {
    try {
      await platform.invokeMethod('updateLiveActivity', data.toJson());
    } on PlatformException catch (e) {
      log("Failed to start live activity: '${e.message}'.");
    }
  }

  Future<void> completeActivity() async {
    try {
      await platform.invokeMethod('completeActivity');
    } on PlatformException catch (e) {
      log("Failed to complete live activity: '${e.message}'.");
    }
  }

  Future<void> endLiveActivity() async {
    try {
      await platform.invokeMethod('endLiveActivity');
    } on PlatformException catch (e) {
      log("Failed to start live activity: '${e.message}'.");
    }
  }
}
