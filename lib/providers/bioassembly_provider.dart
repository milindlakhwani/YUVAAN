import 'package:flutter/widgets.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';

class BioassemblyProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  BioassemblyProvider(this.ros, this.connectionStatus);

  Topic beaker_stepper;
  Topic funnel_stepper;
  Topic left_syringe;
  Topic right_syringe;
  Topic rotateDrill;
  Topic changeDrillState;

  Future<void> initTopics() async {
    if (connectionStatus == ConnectionStatus.CONNECTED) {
      beaker_stepper = Topic(
        ros: ros,
        name: '/change_beaker_pos',
        type: "std_msgs/Int8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      funnel_stepper = Topic(
        ros: ros,
        name: '/rotate_funnel',
        type: "std_msgs/Float32",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      left_syringe = Topic(
        ros: ros,
        name: '/left_syringe',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      right_syringe = Topic(
        ros: ros,
        name: '/right_syringe',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      rotateDrill = Topic(
        ros: ros,
        name: '/rotate_drill',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      changeDrillState = Topic(
        ros: ros,
        name: '/change_drill_state',
        type: "std_msgs/Empty",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      await Future.wait(
        [
          beaker_stepper.advertise(),
          funnel_stepper.advertise(),
          left_syringe.advertise(),
          right_syringe.advertise(),
          rotateDrill.advertise(),
          changeDrillState.advertise(),
        ],
      );
    }
  }

  Future<void> publishBeakerAngle(double angle) async {
    var msg = {
      'data': (angle ~/ 0.9).toInt(),
    };
    await beaker_stepper.publish(msg);
  }

  Future<void> publishFunnelAngle(double angle) async {
    var msg = {
      'data': angle,
    };
    await funnel_stepper.publish(msg);
  }

  Future<void> rotLeftSyringe(bool clockwise) async {
    var msg = {
      'data': clockwise,
    };
    await left_syringe.publish(msg);
  }

  Future<void> rotRightSyringe(bool clockwise) async {
    var msg = {
      'data': clockwise,
    };
    await right_syringe.publish(msg);
  }

  Future<void> publishDrillSpeed(int pwm) async {
    var msg = {
      'data': pwm,
    };
    await rotateDrill.publish(msg);
  }

  Future<void> toggleDrillState() async {
    var msg = {};
    await changeDrillState.publish(msg);
  }

  Future<void> clearTopics() async {
    await beaker_stepper.unadvertise();
  }
}
