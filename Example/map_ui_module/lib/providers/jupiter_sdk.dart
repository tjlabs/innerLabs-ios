import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_ui_module/models/flt_result.dart';

class JupiterSDK extends ChangeNotifier {
  bool isAutoMode = false;
  StreamSubscription? _subscription;

  FLTResult fltResult = FLTResult(index: 0, x: 0, y: 0, absoluteHeading: 0.0);

  static const EventChannel fltResultChannel = EventChannel('com.tjlabscorp.flutter.mapuimodule/fltResult');

  void getFLTResult() async {
    try {
      _subscription = fltResultChannel.receiveBroadcastStream().listen((event) {
        var newFLTResult = FLTResult.fromMap(Map<String, dynamic>.from(event));
        if (fltResult != newFLTResult) {
          fltResult = newFLTResult;
          notifyListeners();
        }
      });
    } catch (e) {
      log('error: $e');
    }
  }

  void closeSubscription() {
    _subscription?.cancel();
  }
}
