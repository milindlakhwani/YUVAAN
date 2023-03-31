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
  bool steering = false;
  bool throttle = false;

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

    timer = Timer.periodic(const Duration(milliseconds: 50), (Timer t) {
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      final manipulatorProvider =
          Provider.of<ManipulatorProvider>(context, listen: false);

      if (state['L1'] == 1) {
        manipulatorProvider.grip(true);
      } else if (state['R1'] == 1) {
        manipulatorProvider.grip(false);
      }

      if (state['A'] == 1) {
        manipulatorProvider.move_actuator_up(true);
      } else if (state['X'] == 1) {
        manipulatorProvider.move_actuator_up(false);
      }

      if (state['B'] == 1) {
        manipulatorProvider.move_actuator_bottom(false);
      } else if (state['Y'] == 1) {
        manipulatorProvider.move_actuator_bottom(true);
      }

      if (steeringVal != steering_prev_value) {
        steering = true;
        manipulatorProvider.rotate_base_motor((steeringVal * 255).toInt());
      } else {
        if (steering) {
          manipulatorProvider.rotate_base_motor((0).toInt());
          steering = false;
        }
      }

      if (state['R2'] == 1) {
        steering = true;
        if (steeringVal != steering_prev_value) {
          manipulatorProvider.gripper_rotate((steeringVal * 255).toInt());
        }
      } else {
        if (steering) {
          manipulatorProvider.gripper_rotate((0));
          steering = false;
        }
      }

      if (throttleVal != 0) {
        throttle = true;
        manipulatorProvider.gripper_up_down((throttleVal * 255).toInt());
      } else {
        if (throttle) {
          manipulatorProvider.gripper_up_down((0));
          throttle = false;
        }
      }

      setState(() {
        steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
        throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));
      });

      steering_prev_value = steeringVal;
      throttle_prev_value = throttleVal;
    });
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
