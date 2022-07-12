import 'package:flutter/cupertino.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/ros/core.dart';

class ManipulatorProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  ManipulatorProvider(this.ros, this.connectionStatus);

  Topic actuator1;
  Topic actuator2;
  Topic base_motor;
  Topic gripper_motor;
  Topic cmd_vel_arm;

  Future<void> initTopics() async {
    if (connectionStatus == ConnectionStatus.CONNECTED) {
      actuator1 = Topic(
        ros: ros,
        name: '/actuator1',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      actuator2 = Topic(
        ros: ros,
        name: '/actuator2',
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
      gripper_motor = Topic(
        ros: ros,
        name: '/gripper_motor',
        type: "std_msgs/Bool",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      cmd_vel_arm = Topic(
        ros: ros,
        name: '/cmd_vel_arm',
        type: "geometry_msgs/Twist",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );

      await Future.wait(
        [
          actuator1.advertise(),
          actuator2.advertise(),
          base_motor.advertise(),
          gripper_motor.advertise(),
          cmd_vel_arm.advertise(),
        ],
      );
    }
  }

  Future<void> move_actuator_1(bool move_up) async {
    var msg = {
      'data': move_up,
    };
    await actuator1.publish(msg);
  }

  Future<void> move_actuator_2(bool move_up) async {
    var msg = {
      'data': move_up,
    };
    await actuator2.publish(msg);
  }

  Future<void> rotate_base_motor(int pwm) async {
    var msg = {
      'data': pwm,
    };
    await base_motor.publish(msg);
  }

  Future<void> rotate_gripper(bool clockwise) async {
    var msg = {
      'data': clockwise,
    };
    await gripper_motor.publish(msg);
  }

  Future<void> move_gripper(int lin_rpm, int ang_rpm) async {
    var linear = {
      'x': lin_rpm,
      'y': 0.0,
      'z': 0.0,
    };
    var angular = {
      'x': 0.0,
      'y': 0.0,
      'z': ang_rpm,
    };
    var twist = {'linear': linear, 'angular': angular};
    await cmd_vel_arm.publish(twist);
  }
}
