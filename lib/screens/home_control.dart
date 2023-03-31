import 'dart:async';
import 'dart:math';
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/config/config.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/models/lidar_data.dart';
import 'package:yuvaan_gui/models/topic_data.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/providers/manipulator_provider.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
import 'package:yuvaan_gui/widgets/lidar.dart';
import 'package:yuvaan_gui/widgets/map_widget.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';
import 'package:latlong2/latlong.dart';

class HomeControl extends StatefulWidget {
  @override
  State<HomeControl> createState() => _HomeControlState();
}

class _HomeControlState extends State<HomeControl> {
  final int rangeLength = 560;
  final int rangeLengthHalf = 280;
  Timer timer;
  Timer ros_timer;
  bool topicsInitialised = false;
  List<Offset> allCords = [];
  final latController = TextEditingController();
  final longController = TextEditingController();
  double throttlePrev = 0;
  double steeringPrev = 0;
  double throttleVal = 0;
  double steeringVal = 0;
  double frontDist = 0;
  double backDist = 0;
  bool steering = false;
  bool throttle = false;
  bool rot = false;

  Map<String, double> controller_values = {
    'A': 0,
    'B': 0,
    'X': 0,
    'Y': 0,
    'L1': 0,
    'R1': 0,
    'L2': 0,
    'R2': 0,
    'L3': 0,
    'R3': 0,
    'Up': 0,
    'Down': 0,
    'Left': 0,
    'Right': 0,
    'Steering': 0.0,
    'Throttle': 0.0,
  };

  double map(
      double x, double in_min, double in_max, double out_min, double out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
  }

  LidarData addCord(
      Map<String, dynamic> topicData, double width, double height) {
    List<dynamic> ranges = topicData['ranges'];

    double angle_diff = 0.01124004554;
    double curr_angle = 0;
    double x, y;
    List<Offset> allCords = [];

    List<double> frontRange = [
      ...ranges.sublist(0, 20),
      ...ranges.sublist(rangeLength - 20, rangeLength)
    ]..removeWhere((element) => element == null);

    frontDist = frontRange.fold(
            0, (previousValue, element) => previousValue + element) /
        frontRange.length;

    List<double> backRange = [
      ...ranges.sublist((rangeLength ~/ 2) - 20, 20),
      ...ranges.sublist(rangeLength - 20, rangeLength)
    ]..removeWhere((element) => element == null);

    backDist =
        backRange.fold(0, (previousValue, element) => previousValue + element) /
            backRange.length;

    ranges.forEach((e) {
      if (e == null) {
        e = 0;
      }
      x = 1 * e * sin(curr_angle);
      y = 1 * e * cos(curr_angle);

      x = map(x, -lidar_max_dist, lidar_max_dist, (-1 * width) / 2, width / 2);
      y = map(
          y, -lidar_max_dist, lidar_max_dist, (-1 * height) / 2, height / 2);

      curr_angle += angle_diff;
      allCords.add(Offset(x, y));
    });

    final LidarData lidar_data = LidarData(
      allCords: allCords,
      frontDist: frontDist,
      backDist: backDist,
    );

    return lidar_data;
  }

  @override
  void initState() {
    super.initState();
    ros_timer = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
      final homeControlProvider =
          Provider.of<HomeControlProvider>(context, listen: false);
      if (homeControlProvider.connectionStatus == ConnectionStatus.CONNECTED) {
        await Provider.of<HomeControlProvider>(context, listen: false)
            .initTopics();
        if (mounted) {
          setState(() {
            topicsInitialised = true;
          });
        }

        ros_timer.cancel();
      }
    });

    timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
      final manipulatorProvider =
          Provider.of<ManipulatorProvider>(context, listen: false);
      final homeControlProvider =
          Provider.of<HomeControlProvider>(context, listen: false);
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      if (mounted) {
        setState(() {
          steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
          throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));
        });
      }

      // if (controller_values['Share'] == 1) {
      //   await manipulatorProvider.clearTopics();
      //   manipulatorProvider.changeStatus();
      // } else if (controller_values['Options'] == 1) {
      //   await Provider.of<ManipulatorProvider>(context, listen: false)
      //       .initTopics();
      //   manipulatorProvider.changeStatus();
      // }

      if (manipulatorProvider.topicsInitialised) {
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

        if (state['R2'] == 1) {
          rot = true;
          steering = true;
          if (steeringVal != steeringPrev) {
            manipulatorProvider.gripper_rotate((steeringVal * 100).toInt());
          }
        } else {
          manipulatorProvider.gripper_rotate((0));
          steering = false;
          rot = false;
        }
        if (!rot) {
          if (steeringVal != steeringPrev) {
            print("test");
            steering = true;
            manipulatorProvider.rotate_base_motor((steeringVal * 150).toInt());
          } else {
            if (steering) {
              manipulatorProvider.rotate_base_motor((0).toInt());
              steering = false;
            }
          }
        }

        if (state['L2'] == 1) {
          throttle = true;
          if (throttleVal != throttlePrev) {
            manipulatorProvider.gripper_up_down((throttleVal * 100).toInt());
          }
        } else {
          manipulatorProvider.gripper_up_down((0));
          throttle = false;
        }

        // if (throttleVal != 0) {
        //   throttle = true;
        //   if (throttleVal != throttlePrev) {
        //     manipulatorProvider.gripper_up_down((throttleVal * 255).toInt());
        //   }
        // } else {
        //   if (throttle) {
        //     manipulatorProvider.gripper_up_down((0));
        //     throttle = false;
        //   }
        // }
      } else {
        if (throttleVal != throttlePrev || steeringVal != steeringPrev) {
          homeControlProvider.publishVelocityCommands(throttleVal, steeringVal);
        }
      }

      throttlePrev = throttleVal;
      steeringPrev = steeringVal;
    });
    // final manipulatorProvider =
    //     Provider.of<ManipulatorProvider>(context, listen: false);
    // final homeControlProvider =
    //     Provider.of<HomeControlProvider>(context, listen: false);
    // timer = Timer.periodic(const Duration(milliseconds: 20), (Timer t) {
    //   var state = js.JsObject.fromBrowserObject(js.context['state']);
    //   if (mounted) {}
    //   setState(() {
    //     steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
    //     throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));
    //   });

    //   homeControlProvider.publishVelocityCommands(
    //     throttleVal, steeringVal,
    //     // controller_values['Throttle'],
    //     // controller_values['Steering'],
    //   );
    //   // if (throttleVal != throttlePrev || steeringVal != steeringPrev) {
    //   // }

    //   // Manipulator Controls
    //   if (manipulatorProvider.topicsInitialised) {
    //     print("Umfff");
    //     // if (state['L1'] == 1) {
    //     //   manipulatorProvider.grip(true);
    //     // } else if (state['R1'] == 1) {
    //     //   manipulatorProvider.grip(false);
    //     // }

    //     // if (state['A'] == 1) {
    //     //   manipulatorProvider.move_actuator_up(true);
    //     // } else if (state['X'] == 1) {
    //     //   manipulatorProvider.move_actuator_up(false);
    //     // }

    //     // if (state['B'] == 1) {
    //     //   manipulatorProvider.move_actuator_bottom(false);
    //     // } else if (state['Y'] == 1) {
    //     //   manipulatorProvider.move_actuator_bottom(true);
    //     // }

    //     // if (steeringVal != steeringPrev) {
    //     //   steering = true;
    //     //   manipulatorProvider.rotate_base_motor((steeringVal * 255).toInt());
    //     // } else {
    //     //   if (steering) {
    //     //     manipulatorProvider.rotate_base_motor((0).toInt());
    //     //     steering = false;
    //     //   }
    //     // }

    //     // if (state['R2'] == 1) {
    //     //   steering = true;
    //     //   if (steeringVal != steeringPrev) {
    //     //     manipulatorProvider.gripper_rotate((steeringVal * 255).toInt());
    //     //   }
    //     // } else {
    //     //   if (steering) {
    //     //     manipulatorProvider.gripper_rotate((0));
    //     //     steering = false;
    //     //   }
    //     // }

    //     // if (throttleVal != 0) {
    //     //   throttle = true;
    //     //   if (throttleVal != throttlePrev) {
    //     //     manipulatorProvider.gripper_up_down((throttleVal * 255).toInt());
    //     //   }
    //     // } else {
    //     //   if (throttle) {
    //     //     manipulatorProvider.gripper_up_down((0));
    //     //     throttle = false;
    //     //   }
    //     // }
    //   }

    //   throttlePrev = throttleVal;
    //   steeringPrev = steeringVal;
    // });
  }

  @override
  void dispose() {
    Provider.of<HomeControlProvider>(context, listen: false).clearTopics();
    timer.cancel();
    super.dispose();
  }

  Widget renderOrientationState(TopicData topic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TileWidget(
          height: SizeConfig.verticalBlockSize * 25.5,
          width: SizeConfig.horizontalBlockSize * 21,
          child: Transform.rotate(
            angle: (topic.msg['yaw'] ?? 0),
            child: Image.asset('assets/images/top.png'),
            alignment: Alignment.center,
          ),
        ),
        TileWidget(
          height: SizeConfig.verticalBlockSize * 25.5,
          width: SizeConfig.horizontalBlockSize * 12,
          child: Transform.rotate(
            angle: (topic.msg['roll'] ?? 0),
            child: Image.asset('assets/images/side.png'),
            alignment: Alignment.center,
          ),
        ),
        TileWidget(
          height: SizeConfig.verticalBlockSize * 25.5,
          width: SizeConfig.horizontalBlockSize * 12,
          child: Transform.rotate(
            angle: topic.msg['pitch'] ?? 0,
            child: Image.asset('assets/images/front.png'),
            alignment: Alignment.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 1,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CameraFeed(
                    tile_height: SizeConfig.verticalBlockSize * 55,
                    tile_width: SizeConfig.horizontalBlockSize * 60,
                  ),
                  Row(
                    children: [
                      TileWidget(
                        isCenter: false,
                        width: SizeConfig.horizontalBlockSize * 11,
                        height: SizeConfig.verticalBlockSize * 25.5,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "State :",
                                style: MyFonts.medium
                                    .setColor(text_color)
                                    .factor(1),
                              ),
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 4,
                              ),
                              Text(
                                "Throttle : ${(throttleVal * 0.57).toStringAsFixed(2)} m/s",
                                style: MyFonts.medium
                                    .setColor(text_color)
                                    .factor(0.9),
                              ),
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 2,
                              ),
                              Text(
                                "Steering : ${(steeringVal * 0.18).toStringAsFixed(2)} rad/s",
                                style: MyFonts.medium
                                    .setColor(text_color)
                                    .factor(0.9),
                              ),
                              Text(
                                "Gripper PWM : ${(steeringVal * 65).toStringAsFixed(2)}    ",
                                style: MyFonts.medium
                                    .setColor(text_color)
                                    .factor(0.8),
                              ),
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 1,
                              ),
                              Text(
                                topicsInitialised
                                    ? "Topics Initialized"
                                    : "Not Initialized",
                                style: MyFonts.bold
                                    .setColor(text_color)
                                    .factor(0.9),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TileWidget(
                        height: SizeConfig.verticalBlockSize * 25.5,
                        width: SizeConfig.horizontalBlockSize * 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...[
                                  "Move bottom actuator up          - A",
                                  "Move bottom actuator down    - B",
                                  "Move above actuator up             - Y",
                                  "Move above actuator down       - X",
                                ].map((e) {
                                  return Text(
                                    e,
                                    style: MyFonts.medium
                                        .factor(1.1)
                                        .setColor(kWhite.withOpacity(0.6)),
                                  );
                                }),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...[
                                  "Grip                                  - L1",
                                  "UnGrip                            - R1",
                                  "End Effector rotate      - R2 + Steering",
                                  "End Effector up/down - L2 + Throttle"
                                ].map((e) {
                                  return Text(
                                    e,
                                    style: MyFonts.medium.factor(1.1).setColor(
                                          kWhite.withOpacity(0.6),
                                        ),
                                  );
                                }),
                              ],
                            )
                          ],
                        ),
                      ),
                      // topicsInitialised
                      //     ? Consumer<HomeControlProvider>(
                      //         builder: (ctx, homeControlProvider, _) {
                      //         return StreamBuilder<Object>(
                      //           stream: homeControlProvider
                      //               .euler_angle.subscription
                      //               .where((message) =>
                      //                   message['topic'] == '/imu/euler'),
                      //           builder: (context, snapshot) {
                      //             if (snapshot.hasData) {
                      //               final topic =
                      //                   TopicData.fromJson(snapshot.data);
                      //               return renderOrientationState(topic);
                      //             } else {
                      //               // print(snapshot.data);
                      //               return TileWidget(
                      //                 height:
                      //                     SizeConfig.verticalBlockSize * 25.5,
                      //                 width:
                      //                     SizeConfig.horizontalBlockSize * 21,
                      //                 child: CircularProgressIndicator(),
                      //               );
                      //             }
                      //           },
                      //         );
                      //       })
                      //     : Stack(
                      //         children: [
                      //           renderOrientationState(TopicData("", {})),
                      //           Container(
                      //             width:
                      //                 SizeConfig.horizontalBlockSize * 45 + 40,
                      //             height: SizeConfig.verticalBlockSize * 25.5,
                      //             child: Text("Waiting for IMU data"),
                      //             margin: const EdgeInsets.all(10),
                      //             decoration: BoxDecoration(
                      //                 color: Colors.black.withOpacity(0.5),
                      //                 borderRadius: BorderRadius.circular(15)),
                      //             alignment: Alignment.center,
                      //           ),
                      //         ],
                      //       ),
                    ],
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TileWidget(
                    height: SizeConfig.verticalBlockSize * 68,
                    width: SizeConfig.horizontalBlockSize * 30,
                    child: topicsInitialised
                        ? Consumer<HomeControlProvider>(
                            builder: (ctx, homeControlProvider, _) {
                            return StreamBuilder<Object>(
                              stream: homeControlProvider.gps_data.subscription
                                  .where(
                                      (message) => message['topic'] == '/GPS'),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final topic =
                                      TopicData.fromJson(snapshot.data);
                                  homeControlProvider.setCord(
                                    LatLng(
                                      topic.msg['x'],
                                      topic.msg['y'],
                                    ),
                                  );
                                  // print(topic.msg['x']);
                                  // print(topic.msg['y']);
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: MapWidget(
                                      marker: LatLng(
                                        topic.msg['x'],
                                        topic.msg['y'],
                                      ),
                                    ),
                                  );
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            );
                          })
                        : Text("Waiting for GPS data to be intialized"),
                    // child: ClipRRect(
                    //   borderRadius: BorderRadius.circular(15),
                    //   child: MapWidget(
                    //     marker: LatLng(
                    //       double.parse("26.1878"),
                    //       double.parse('91.6916'),
                    //     ),
                    //   ),
                    // ),
                  ),
                  TileWidget(
                    height: SizeConfig.verticalBlockSize * 12,
                    width: SizeConfig.horizontalBlockSize * 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 4,
                                width: SizeConfig.horizontalBlockSize * 13,
                                child: TextField(
                                  controller: latController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    hintText: "Latitude",
                                    fillColor: selected_color,
                                    border: InputBorder.none,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.4,
                                      ),
                                    ),
                                    hoverColor: selected_color,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 4,
                                width: SizeConfig.horizontalBlockSize * 13,
                                child: TextField(
                                  controller: longController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    hintText: "Longitude",
                                    fillColor: selected_color,
                                    border: InputBorder.none,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.4,
                                      ),
                                    ),
                                    hoverColor: selected_color,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                child: Text("Add Marker"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.4,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(0.9)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                    SizeConfig.horizontalBlockSize * 9,
                                    SizeConfig.verticalBlockSize * 3,
                                  ),
                                  primary: kBlue,
                                ),
                                onPressed: () {
                                  Provider.of<HomeControlProvider>(context,
                                          listen: false)
                                      .setMarker(
                                    LatLng(
                                      double.parse(latController.text),
                                      double.parse(longController.text),
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton(
                                child: Text("Start Tracking"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.4,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(0.9)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                    SizeConfig.horizontalBlockSize * 9,
                                    SizeConfig.verticalBlockSize * 3,
                                  ),
                                  primary: kBlue,
                                ),
                                onPressed: () {},
                              ),
                              ElevatedButton(
                                child: Text("Clear"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.4,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(0.9)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                    SizeConfig.horizontalBlockSize * 9,
                                    SizeConfig.verticalBlockSize * 3,
                                  ),
                                  primary: kBlue,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  // TileWidget(
                  //   height: SizeConfig.verticalBlockSize * 36,
                  //   width: SizeConfig.horizontalBlockSize * 30,
                  //   child: topicsInitialised
                  //       ? Consumer<HomeControlProvider>(
                  //           builder: (ctx, homeControlProvider, _) {
                  //           return StreamBuilder<Object>(
                  //             stream: homeControlProvider
                  //                 .lidar_angle_range.subscription
                  //                 .where((message) =>
                  //                     message['topic'] == '/laser_scan'),
                  //             builder: (context, snapshot) {
                  //               if (snapshot.hasData) {
                  //                 final topic = TopicData.fromJson(snapshot.data);
                  //                 return Lidar(
                  //                   lidar_data: addCord(
                  //                     topic.msg,
                  //                     SizeConfig.horizontalBlockSize * 30,
                  //                     SizeConfig.verticalBlockSize * 36,
                  //                   ),
                  //                 );
                  //               } else {
                  //                 return CircularProgressIndicator();
                  //               }
                  //             },
                  //           );
                  //         })
                  //       : Text("Waiting for lidar topic to be intialized"),
                  // ),
                  // TileWidget(
                  //   height: SizeConfig.verticalBlockSize * 36,
                  //   width: SizeConfig.horizontalBlockSize * 30,
                  //   child: topicsInitialised
                  //       ? Consumer<HomeControlProvider>(
                  //           builder: (ctx, homeControlProvider, _) {
                  //           return StreamBuilder<Object>(
                  //             stream: homeControlProvider
                  //                 .lidar_angle_range.subscription
                  //                 .where((message) =>
                  //                     message['topic'] == '/laser_scan'),
                  //             builder: (context, snapshot) {
                  //               if (snapshot.hasData) {
                  //                 final topic = TopicData.fromJson(snapshot.data);
                  //                 return Column(
                  //                   children: [
                  //                     Container(
                  //                       height: SizeConfig.verticalBlockSize * 30,
                  //                       child: Stack(
                  //                         children: [
                  //                           Center(
                  //                             child: Image.asset(
                  //                               'assets/images/top.png',
                  //                               height:
                  //                                   SizeConfig.verticalBlockSize *
                  //                                       3,
                  //                             ),
                  //                           ),
                  //                           Center(
                  //                             child: CustomPaint(
                  //                               painter: OpenPainter(
                  //                                 allCords: addCord(
                  //                                   topic.msg,
                  //                                   SizeConfig.horizontalBlockSize *
                  //                                       30,
                  //                                   SizeConfig.verticalBlockSize *
                  //                                       36,
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     ),
                  //                     Container(
                  //                       height: SizeConfig.verticalBlockSize * 6,
                  //                       child: Text("test"),
                  //                       decoration:
                  //                           BoxDecoration(color: Colors.amber),
                  //                     )
                  //                   ],
                  //                 );
                  //               } else {
                  //                 return CircularProgressIndicator();
                  //               }
                  //             },
                  //           );
                  //         })
                  //       : Text("Waiting for lidar topic to be intialized"),
                  // ),
                ],
              ),
            ],
          ),
          // TileWidget(
          //   height: SizeConfig.verticalBlockSize * 60,
          //   width: SizeConfig.screenWidth,
          //   child: topicsInitialised
          //       ? Consumer<HomeControlProvider>(
          //           builder: (ctx, homeControlProvider, _) {
          //           return StreamBuilder<Object>(
          //             stream: homeControlProvider.lidar_angle_range.subscription
          //                 .where(
          //                     (message) => message['topic'] == '/laser_scan'),
          //             builder: (context, snapshot) {
          //               if (snapshot.hasData) {
          //                 final topic = TopicData.fromJson(snapshot.data);
          //                 return Lidar(
          //                   lidar_data: addCord(
          //                     topic.msg,
          //                     SizeConfig.screenWidth,
          //                     SizeConfig.verticalBlockSize * 60,
          //                   ),
          //                 );
          //               } else {
          //                 return CircularProgressIndicator();
          //               }
          //             },
          //           );
          //         })
          //       : Text("Waiting for lidar topic to be intialized"),
          // ),
        ],
      ),
    );
  }
}
