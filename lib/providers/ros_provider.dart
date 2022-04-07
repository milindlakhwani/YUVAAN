import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';

class RosProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connected = ConnectionStatus.NONE;

  void initConnection(String address) async {
    print("Trying to connect to $address");
    ros = Ros(url: address);
    ros.connect();
    connected = ConnectionStatus.CONNECTING;
    notifyListeners();
    await Future.delayed(Duration(seconds: 2));
    if (ros.status != Status.CLOSED) {
      connected = ConnectionStatus.CONNECTED;
      notifyListeners();
    }

    ros.statusStream.listen((status) async {
      if (status == Status.CLOSED) {
        connected = ConnectionStatus.CLOSED;
        notifyListeners();
        await Future.delayed(Duration(seconds: 3));
        initConnection(address);
      } else if (status == Status.ERRORED) {
        connected = ConnectionStatus.ERRORED;
        notifyListeners();
        await Future.delayed(Duration(seconds: 2));
        initConnection(address);
      } else {
        connected = ConnectionStatus.CONNECTING;
        notifyListeners();
      }
    });
  }

  void disconnect() {
    ros.close();
    ros = null;
    connected = ConnectionStatus.CLOSED;
    notifyListeners();
  }
}
