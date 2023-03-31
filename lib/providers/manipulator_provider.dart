import 'package:flutter/cupertino.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';

class ManipulatorProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  ManipulatorProvider(this.ros, this.connectionStatus);
  bool topicsInitialised = false;
  bool manipulatorIntialised = false;

  Topic actuator_bottom;
  Topic actuator_up;
  Topic base_motor;
  Topic gripper_motor;
  Topic gripper_yaw;
  Topic gripper_motion;

  Future<void> initTopics() async {
    if (connectionStatus == ConnectionStatus.CONNECTED) {
      actuator_bottom = Topic(
        ros: ros,
        name: '/actuator_bottom',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      actuator_up = Topic(
        ros: ros,
        name: '/actuator_up',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      gripper_motor = Topic(
        ros: ros,
        name: '/gripper_motor',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      base_motor = Topic(
        ros: ros,
        name: '/base_motor',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      gripper_yaw = Topic(
        ros: ros,
        name: '/gripper_yaw',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      gripper_motion = Topic(
        ros: ros,
        name: '/gripper_motion',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      await Future.wait(
        [
          actuator_bottom.advertise(),
          actuator_up.advertise(),
          base_motor.advertise(),
          gripper_motor.advertise(),
          gripper_yaw.advertise(),
          gripper_motion.advertise(),
        ],
      );
    }
  }

  Future<void> move_actuator_bottom(bool move_up) async {
    var msg = {
      'data': move_up,
    };
    await actuator_bottom.publish(msg);
  }

  Future<void> move_actuator_up(bool move_up) async {
    var msg = {
      'data': move_up,
    };
    await actuator_up.publish(msg);
  }

  Future<void> grip(bool clockwise) async {
    var msg = {
      'data': clockwise,
    };
    await gripper_motor.publish(msg);
  }

  Future<void> rotate_base_motor(int pwm) async {
    var msg = {
      'data': pwm,
    };
    await base_motor.publish(msg);
  }

  Future<void> gripper_up_down(int pwm) async {
    var msg = {
      'data': pwm,
    };
    await gripper_motion.publish(msg);
  }

  Future<void> gripper_rotate(int pwm) async {
    var msg = {
      'data': pwm,
    };
    await gripper_yaw.publish(msg);
  }

  Future<void> clearTopics() async {
    await actuator_bottom.unadvertise();
    await actuator_up.unadvertise();
    await base_motor.unadvertise();
    await gripper_motor.unadvertise();
    await gripper_yaw.unadvertise();
    await gripper_motion.unadvertise();
    topicsInitialised = false;
  }

  void changeStatus() {
    topicsInitialised = true;
    // topicsInitialised = !topicsInitialised;
    // manipulatorIntialised = !manipulatorIntialised;
  }
}
