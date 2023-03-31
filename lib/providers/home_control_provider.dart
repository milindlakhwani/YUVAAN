import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';
import 'package:latlong2/latlong.dart';

class HomeControlProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  HomeControlProvider(this.ros, this.connectionStatus);

  Topic cmd_vel;
  Topic lidar_angle_range;
  // Topic euler_angle;
  Topic gps_data;
  LatLng gps_cord;
  LatLng gps_marker;

  Future<void> initTopics() async {
    if (connectionStatus == ConnectionStatus.CONNECTED) {
      cmd_vel = Topic(
        ros: ros,
        name: '/cmd_vel',
        type: "geometry_msgs/Twist",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      lidar_angle_range = Topic(
        ros: ros,
        name: '/laser_scan',
        type: "yuvaan/Lidar",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      // euler_angle = Topic(
      //   ros: ros,
      //   name: '/imu/euler',
      //   type: "yuvaan/Euler",
      //   reconnectOnClose: true,
      //   queueLength: 10,
      //   queueSize: 10,
      // );

      gps_data = Topic(
        ros: ros,
        name: '/GPS',
        type: "geometry_msgs/Vector3",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      await Future.wait(
        [
          cmd_vel.advertise(),
          lidar_angle_range.subscribe(),
          // euler_angle.subscribe(),
          gps_data.subscribe(),
        ],
      );
    }
  }

  Future<void> publishVelocityCommands(double lin_vel, double ang_vel) async {
    print("Publishing");
    var linear = {
      'x': -double.parse((lin_vel * 0.57).toStringAsFixed(2)),
      'y': 0.0,
      'z': 0.0
    };
    var angular = {
      'x': 0.0,
      'y': 0.0,
      'z': -double.parse((ang_vel * 0.18).toStringAsFixed(2))
    };
    var twist = {'linear': linear, 'angular': angular};
    await cmd_vel.publish(twist);
    print('cmd published');
  }

  String get lat_long {
    return (gps_cord.latitude.toString() + '_' + gps_cord.longitude.toString());
  }

  void setCord(LatLng cord) {
    gps_cord = cord;
    // notifyListeners();
  }

  void setMarker(LatLng cord) {
    gps_marker = cord;
    notifyListeners();
  }

  Future<void> clearTopics() async {
    await cmd_vel.unadvertise();
    await lidar_angle_range.unsubscribe();
    // await euler_angle.unsubscribe();
    await gps_data.unsubscribe();
  }
}
