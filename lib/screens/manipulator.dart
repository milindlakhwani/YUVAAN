import 'dart:async';
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/manipulator_provider.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';

class Manipulator extends StatefulWidget {
  @override
  State<Manipulator> createState() => _ManipulatorState();
}

class _ManipulatorState extends State<Manipulator> {
  Timer ros_timer;
  bool topicsInitialised = false;
  Timer timer;
  String currentImage = "arm";
  bool gripperSelected = false;
  double steering_prev_value = 0;
  double throttle_prev_value = 0;
  int gripper_rpm = 0;
  int base_motor_rpm = 0;
  double steeringVal = 0.0;
  double throttleVal = 0.0;

  @override
  void initState() {
    super.initState();

    ros_timer = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
      final bioassemblyProvider =
          Provider.of<ManipulatorProvider>(context, listen: false);
      if (bioassemblyProvider.connectionStatus == ConnectionStatus.CONNECTED) {
        await Provider.of<ManipulatorProvider>(context, listen: false)
            .initTopics();
        setState(() {
          topicsInitialised = true;
        });
        ros_timer.cancel();
      }
    });

    // timer = Timer.periodic(const Duration(milliseconds: 50), (Timer t) {
    //   var state = js.JsObject.fromBrowserObject(js.context['state']);
    //   final manipulatorProvider =
    //       Provider.of<ManipulatorProvider>(context, listen: false);

    //   if (state['R2'] == 1) {
    //     gripperSelected = true;
    //     if (currentImage != "arm_gripper") {
    //       setState(() {
    //         currentImage = "arm_gripper";
    //       });
    //     }
    //   }

    //   if (state['L2'] == 1) {
    //     gripperSelected = false;
    //     if (currentImage != "arm") {
    //       setState(() {
    //         currentImage = "arm";
    //       });
    //     }
    //   }

    //   if (state['L1'] == 1) {
    //     gripperSelected = true;
    //     if (currentImage != "arm_gripper") {
    //       setState(() {
    //         currentImage = "arm_gripper";
    //       });
    //     }
    //     manipulatorProvider.rotate_gripper(true);
    //   } else if (state['R1'] == 1) {
    //     gripperSelected = true;
    //     if (currentImage != "arm_gripper") {
    //       setState(() {
    //         currentImage = "arm_gripper";
    //       });
    //     }
    //     manipulatorProvider.rotate_gripper(false);
    //   }

    //   if (state['B'] == 1) {
    //     if (currentImage != "arm_link_1") {
    //       setState(() {
    //         currentImage = "arm_link_1";
    //       });
    //     }
    //     manipulatorProvider.move_actuator_1(false);
    //   } else if (state['Y'] == 1) {
    //     if (currentImage != "arm_link_1") {
    //       setState(() {
    //         currentImage = "arm_link_1";
    //       });
    //     }
    //     manipulatorProvider.move_actuator_1(true);
    //   }

    //   if (state['A'] == 1) {
    //     if (currentImage != "arm_link_2") {
    //       setState(() {
    //         currentImage = "arm_link_2";
    //       });
    //     }
    //     manipulatorProvider.move_actuator_2(true);
    //   } else if (state['X'] == 1) {
    //     if (currentImage != "arm_link_2") {
    //       setState(() {
    //         currentImage = "arm_link_2";
    //       });
    //     }
    //     manipulatorProvider.move_actuator_2(false);
    //   }

    //   setState(() {
    //     steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
    //     throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));
    //   });

    //   if (throttleVal != throttle_prev_value) {
    //     gripperSelected = true;
    //     if (currentImage != "arm_gripper") {
    //       setState(() {
    //         currentImage = "arm_gripper";
    //       });
    //     }
    //     manipulatorProvider.move_gripper((throttleVal * 30).toInt(), 0);
    //   }

    //   if (!gripperSelected) {
    //     if (steeringVal != steering_prev_value) {
    //       if (currentImage != "arm_base") {
    //         setState(() {
    //           currentImage = "arm_base";
    //         });
    //       }
    //       setState(() {
    //         base_motor_rpm = (steeringVal * 30).toInt();
    //       });
    //       manipulatorProvider.rotate_base_motor((steeringVal * 255).toInt());
    //     }
    //   } else {
    //     if (steeringVal != steering_prev_value) {
    //       gripperSelected = true;
    //       if (currentImage != "arm_gripper") {
    //         setState(() {
    //           currentImage = "arm_gripper";
    //         });
    //       }
    //       manipulatorProvider.move_gripper(0, (steeringVal * 30).toInt());
    //     }
    //   }

    //   steering_prev_value = steeringVal;
    //   throttle_prev_value = throttleVal;
    // });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 2,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Row(
        children: [
          Column(
            children: [
              CameraFeed(
                tile_height: SizeConfig.verticalBlockSize * 40,
                tile_width: SizeConfig.horizontalBlockSize * 40,
              ),
              CameraFeed(
                tile_height: SizeConfig.verticalBlockSize * 37,
                tile_width: SizeConfig.horizontalBlockSize * 40,
                topicName: 'arm_camera',
                altText: "Arm camera feed not enabled",
              ),
            ],
          ),
          TileWidget(
            width: SizeConfig.horizontalBlockSize * 48,
            height: SizeConfig.verticalBlockSize * 80,
            isCenter: false,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Topics Initialized : $topicsInitialised"),
                  Center(
                    child: Image.asset(
                      'assets/images/$currentImage.png',
                      fit: BoxFit.cover,
                      height: SizeConfig.verticalBlockSize * 60,
                    ),
                  ),
                  Text("Base motor Rpm = $base_motor_rpm"),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Steering Value = ${steeringVal.toStringAsFixed(2)}"),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Throttle Value = ${throttleVal.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
