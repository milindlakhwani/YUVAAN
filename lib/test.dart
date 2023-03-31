// if (state['R2'] == 1) {
      //   gripperSelected = true;
      //   if (currentImage != "arm_gripper") {
      //     setState(() {
      //       currentImage = "arm_gripper";
      //     });
      //   }
      // }

      // if (state['L2'] == 1) {
      //   gripperSelected = false;
      //   if (currentImage != "arm") {
      //     setState(() {
      //       currentImage = "arm";
      //     });
      //   }
      // }

      // if (state['L1'] == 1) {
      //   gripperSelected = true;
      //   if (currentImage != "arm_gripper") {
      //     setState(() {
      //       currentImage = "arm_gripper";
      //     });
      //   }
      //   manipulatorProvider.rotate_gripper(true);
      // } else if (state['R1'] == 1) {
      //   gripperSelected = true;
      //   if (currentImage != "arm_gripper") {
      //     setState(() {
      //       currentImage = "arm_gripper";
      //     });
      //   }
      //   manipulatorProvider.rotate_gripper(false);
      // }

      // if (state['B'] == 1) {
      //   if (currentImage != "arm_link_1") {
      //     setState(() {
      //       currentImage = "arm_link_1";
      //     });
      //   }
      //   manipulatorProvider.move_actuator_1(false);
      // } else if (state['Y'] == 1) {
      //   if (currentImage != "arm_link_1") {
      //     setState(() {
      //       currentImage = "arm_link_1";
      //     });
      //   }
      //   manipulatorProvider.move_actuator_1(true);
      // }

      // if (state['A'] == 1) {
      //   if (currentImage != "arm_link_2") {
      //     setState(() {
      //       currentImage = "arm_link_2";
      //     });
      //   }
      //   manipulatorProvider.move_actuator_2(true);
      // } else if (state['X'] == 1) {
      //   if (currentImage != "arm_link_2") {
      //     setState(() {
      //       currentImage = "arm_link_2";
      //     });
      //   }
      //   manipulatorProvider.move_actuator_2(false);
      // }

      // setState(() {
      //   steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
      //   throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));
      // });

      // if (throttleVal != throttle_prev_value) {
      //   gripperSelected = true;
      //   if (currentImage != "arm_gripper") {
      //     setState(() {
      //       currentImage = "arm_gripper";
      //     });
      //   }
      //   manipulatorProvider.move_gripper((throttleVal * 30).toInt(), 0);
      // }

      // if (!gripperSelected) {
      //   if (steeringVal != steering_prev_value) {
      //     if (currentImage != "arm_base") {
      //       setState(() {
      //         currentImage = "arm_base";
      //       });
      //     }
      //     setState(() {
      //       base_motor_rpm = (steeringVal * 30).toInt();
      //     });
      //     manipulatorProvider.rotate_base_motor((steeringVal * 255).toInt());
      //   }
      // } else {
      //   if (steeringVal != steering_prev_value) {
      //     gripperSelected = true;
      //     if (currentImage != "arm_gripper") {
      //       setState(() {
      //         currentImage = "arm_gripper";
      //       });
      //     }
      //     manipulatorProvider.move_gripper(0, (steeringVal * 30).toInt());
      //   }
      // }

      // steering_prev_value = steeringVal;
      // throttle_prev_value = throttleVal;









// addcord function in home_control.dart


//       List<Offset> addCord(
//     Map<String, dynamic> topicData, double width, double height) {
//   List<dynamic> ranges = topicData['ranges'];

//   double angle_diff = 0.01124004554;
//   double curr_angle = 0;
//   double x, y;
//   List<Offset> allCords = [];

//   List<double> frontRange = [
//     ...ranges.sublist(0, 20),
//     ...ranges.sublist(rangeLength - 20, rangeLength)
//   ]..removeWhere((element) => element == null);

//   frontDist =
//       frontRange.fold(0, (previousValue, element) => previousValue + element) /
//           frontRange.length;

//   ranges.forEach((e) {
//     if (e == null) {
//       e = 0;
//     }
//     x = 1 * e * sin(curr_angle);
//     y = 1 * e * cos(curr_angle);

//     x = map(x, -lidar_max_dist, lidar_max_dist, (-1 * width) / 2, width / 2);
//     y = map(y, -lidar_max_dist, lidar_max_dist, (-1 * height) / 2, height / 2);

//     curr_angle += angle_diff;
//     allCords.add(Offset(x, y));
//   });

//   return allCords;
// }
