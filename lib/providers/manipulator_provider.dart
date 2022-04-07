import 'package:flutter/cupertino.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';

class ManipulatorProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  ManipulatorProvider(this.ros, this.connectionStatus);
}
