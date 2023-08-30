import 'dart:async';
import 'dart:math' as math;
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/mySpaces.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/bioassembly_provider.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/widgets/beaker_painter.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
import 'package:yuvaan_gui/widgets/syringe_painter.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';

enum Syringe { Left, Right }

enum FunnelRotation { Clockwise, AntiClockwise }

class Bioassembly extends StatefulWidget {
  @override
  State<Bioassembly> createState() => _BioassemblyState();
}

class _BioassemblyState extends State<Bioassembly>
    with SingleTickerProviderStateMixin {
  PausableTimer timer;
  Timer ros_timer;
  double counter = 0;
  double current_angle = 0;

  double left_drill_pos = 0;
  final base_plate_width = SizeConfig.horizontalBlockSize * 18;
  final syringe_plate_width = SizeConfig.horizontalBlockSize * 11;
  final circle_offset_diagonal = SizeConfig.horizontalBlockSize * 2.75;
  final circle_offset_corner = 60;
  final circle_offset_diagonal_syringe = SizeConfig.horizontalBlockSize * 3.25;
  final circle_offset_corner_syringe = SizeConfig.verticalBlockSize * 11;
  // final circle_offset_corner_syringe = 97;
  List<Offset> emptyPoints = [];
  List<Offset> emptyPoints_left = [];
  List<Offset> filledPoints_left = [];
  List<Offset> emptyPoints_right = [];
  List<Offset> filledPoints_right = [];
  List<String> point_keys = ["L1", "L2", "L3", "R3", "R2", "R1"];
  bool isLoading = false;
  bool left_syringe_selected = false;
  bool right_syringe_selected = false;
  bool left_drill_selected = false;
  bool right_drill_selected = false;
  double throttleVal = 0;
  double steeringVal = 0;
  bool rightFlap = false;
  bool leftFlap = false;
  final _formKey = GlobalKey<FormState>();
  String fileName = '';

  double prev_throttle_val = 0;
  double prev_steering_val = 0;

  bool left_active = false;
  double funnel_angle = 0;
  bool isFeedEnabled = false;
  bool readingSensors = false;
  bool topicsInitialised = false;
  int duration = 1000;

  void rotateBasePlate(double angle) {
    current_angle += angle;

    setState(() {
      if (angle.abs() == 22.5) {
        duration = 500;
      } else if (angle.abs() == 45) {
        duration = 1000;
      }
      counter += (angle / 360);
    });

    final bioassembly_provider =
        Provider.of<BioassemblyProvider>(context, listen: false);
    bioassembly_provider.publishBeakerSteps(angle);
    bioassembly_provider.updateCounter(counter);
  }

  void waimt(int dur) async {
    timer.pause();
    await Future.delayed(Duration(milliseconds: dur)).then((_) {
      timer.start();
    });
  }

  Widget leftDrillRender(double pos) {
    left_drill_pos = pos;
    return Positioned(
      top: pos,
      left: SizeConfig.horizontalBlockSize * 3.5,
      child: Container(
        height: SizeConfig.verticalBlockSize * 22.4,
        child: Image.asset(
          'assets/images/drill.png',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    emptyPoints = [
      Offset(0, (-base_plate_width / 2) + circle_offset_corner),
      Offset(
        (base_plate_width / 2) - (circle_offset_diagonal * 2),
        (-base_plate_width / 2) + (circle_offset_diagonal * 2),
      ),
      Offset((base_plate_width / 2) - circle_offset_corner, 0),
      Offset(
        (base_plate_width / 2) - (circle_offset_diagonal * 2),
        (base_plate_width / 2) - (circle_offset_diagonal * 2),
      ),
      Offset(0, (base_plate_width / 2) - circle_offset_corner),
      Offset((-base_plate_width / 2) + (circle_offset_diagonal * 2),
          (base_plate_width / 2) - (circle_offset_diagonal * 2)),
      Offset((-base_plate_width / 2) + circle_offset_corner, 0),
      Offset((-base_plate_width / 2) + (circle_offset_diagonal * 2),
          (-base_plate_width / 2) + (circle_offset_diagonal * 2)),
    ];
    emptyPoints_left = [
      Offset((-base_plate_width / 2) + circle_offset_corner_syringe, 0),
      Offset((-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2),
          (-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2)),
      Offset(0, (-base_plate_width / 2) + circle_offset_corner_syringe),
      Offset(
        (base_plate_width / 2) - (circle_offset_diagonal_syringe * 2),
        (-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2),
      ),
      Offset((base_plate_width / 2) - circle_offset_corner_syringe, 0),
      Offset(
        (base_plate_width / 2) - (circle_offset_diagonal_syringe * 2),
        (base_plate_width / 2) - (circle_offset_diagonal_syringe * 2),
      ),
    ];

    emptyPoints_right = [
      Offset((-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2),
          (base_plate_width / 2) - (circle_offset_diagonal_syringe * 2)),
      Offset((-base_plate_width / 2) + circle_offset_corner_syringe, 0),
      Offset((-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2),
          (-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2)),
      Offset(0, (-base_plate_width / 2) + circle_offset_corner_syringe),
      Offset(
        (base_plate_width / 2) - (circle_offset_diagonal_syringe * 2),
        (-base_plate_width / 2) + (circle_offset_diagonal_syringe * 2),
      ),
      Offset((base_plate_width / 2) - circle_offset_corner_syringe, 0),
    ];

    ros_timer = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
      final bioassemblyProvider =
          Provider.of<BioassemblyProvider>(context, listen: false);
      if (bioassemblyProvider.connectionStatus == ConnectionStatus.CONNECTED) {
        await Provider.of<BioassemblyProvider>(context, listen: false)
            .initTopics();
        setState(() {
          topicsInitialised = true;
        });
        ros_timer.cancel();
      }
    });

    timer = PausableTimer(const Duration(milliseconds: 20), () async {
      final bioassemblyProvider =
          Provider.of<BioassemblyProvider>(context, listen: false);
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      timer
        ..reset()
        ..start();

      steeringVal = double.parse(state['Steering'].toStringAsFixed(2));
      throttleVal = double.parse(state['Throttle'].toStringAsFixed(2));

      if (state['Up'] == 1) {
        if (state['Right'] == 1) {
          rotateBasePlate(22.5);
          await waimt(1000);
        } else if (state['Left'] == 1) {
          rotateBasePlate(-22.5);
          await waimt(1000);
        }
      } else if (state['Up'] == 0) {
        if (state['Right'] == 1) {
          rotateBasePlate(45);
          await waimt(1000);
        } else if (state['Left'] == 1) {
          rotateBasePlate(-45);
          await waimt(1000);
        }
      }

      if (state['X'] == 1) {
        bioassemblyProvider.markCurrentBeaker(current_angle, emptyPoints,
            left_drill_selected, right_drill_selected);
      }

      // if (state['B'] == 1) {
      if (state['Y'] == 1) {
        if (!isFeedEnabled) {
          setState(() {
            isFeedEnabled = true;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Microscope Feed'),
                content: CameraFeed(
                  tile_width: SizeConfig.horizontalBlockSize * 50,
                  tile_height: SizeConfig.verticalBlockSize * 50,
                  topicName: 'microscope',
                  altText: "Could'nt get micrscope feed",
                ),
              );
            },
          ).then((_) {
            setState(() {
              isFeedEnabled = false;
            });
          });
        } else {
          Navigator.of(context).pop();
        }
        await waimt(500);
      }

      if (state['B'] == 1) {
        setState(() {
          if (right_syringe_selected)
            right_syringe_selected = !right_syringe_selected;
          left_syringe_selected = !left_syringe_selected;
        });
        await waimt(500);
      }
      if (state['A'] == 1) {
        setState(() {
          if (left_syringe_selected)
            left_syringe_selected = !left_syringe_selected;
          right_syringe_selected = !right_syringe_selected;
        });
        await waimt(500);
      }

      if (left_syringe_selected) {
        if (state['L1'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[0])) {
          bioassemblyProvider.rotLeftSyringe(0);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[0]);
          await waimt(1000);
        } else if (state['L2'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[1])) {
          bioassemblyProvider.rotLeftSyringe(28);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[1]);
          await waimt(1000);
        } else if (state['L3'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[2])) {
          bioassemblyProvider.rotLeftSyringe(56);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[2]);
          await waimt(1000);
        } else if (state['R3'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[3])) {
          bioassemblyProvider.rotLeftSyringe(85);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[3]);
          await waimt(1000);
        } else if (state['R2'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[4])) {
          bioassemblyProvider.rotLeftSyringe(113);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[4]);
          await waimt(1000);
        } else if (state['R1'] == 1 &&
            !bioassemblyProvider.checkPointLeft(emptyPoints_left[5])) {
          bioassemblyProvider.rotLeftSyringe(142);
          bioassemblyProvider.addPointsLeft(emptyPoints_left[5]);
          await waimt(1000);
        }
      } else if (right_syringe_selected) {
        if (state['L1'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[0])) {
          bioassemblyProvider.rotRightSyringe(0);
          bioassemblyProvider.addPointsRight(emptyPoints_right[0]);
          await waimt(1000);
        } else if (state['L2'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[1])) {
          bioassemblyProvider.rotRightSyringe(28);
          bioassemblyProvider.addPointsRight(emptyPoints_right[1]);
          await waimt(1000);
        } else if (state['L3'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[2])) {
          bioassemblyProvider.rotRightSyringe(56);
          bioassemblyProvider.addPointsRight(emptyPoints_right[2]);
          await waimt(1000);
        } else if (state['R3'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[3])) {
          bioassemblyProvider.rotRightSyringe(85);
          bioassemblyProvider.addPointsRight(emptyPoints_right[3]);
          await waimt(1000);
        } else if (state['R2'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[4])) {
          bioassemblyProvider.rotRightSyringe(113);
          bioassemblyProvider.addPointsRight(emptyPoints_right[4]);
          await waimt(1000);
        } else if (state['R1'] == 1 &&
            !bioassemblyProvider.checkPointRight(emptyPoints_right[5])) {
          bioassemblyProvider.rotRightSyringe(142);
          bioassemblyProvider.addPointsRight(emptyPoints_right[5]);
          await waimt(1000);
        }
      } else {
        if (state['L2'] == 1) {
          setState(() {
            left_drill_selected = !left_drill_selected;
            if (right_drill_selected)
              right_drill_selected = !right_drill_selected;
          });
          await waimt(350);
        }
        if (state['R2'] == 1) {
          setState(() {
            right_drill_selected = !right_drill_selected;
            if (left_drill_selected) left_drill_selected = !left_drill_selected;
          });
          await waimt(350);
        }
      }

      if (steeringVal != prev_steering_val) {
        setState(() {
          funnel_angle = steeringVal * 30;
        });
        bioassemblyProvider.publishFunnelSteps(funnel_angle ~/ 0.45);
        await waimt(100);
      }

      if (state['L3'] == 1) {
        leftFlap
            ? bioassemblyProvider.moveServo(0)
            : bioassemblyProvider.moveServo(1);
        setState(() {
          leftFlap = !leftFlap;
        });
        await waimt(1000);
      } else if (state['R3'] == 1) {
        rightFlap
            ? bioassemblyProvider.moveServo(2)
            : bioassemblyProvider.moveServo(3);
        setState(() {
          rightFlap = !rightFlap;
        });
        await waimt(1000);
      }

      if (state['Throttle'] != prev_throttle_val) {
        if (left_drill_selected) {
          bioassemblyProvider.moveLeftDrillAssembly(-1 * throttleVal * 180);
        } else if (right_drill_selected) {
          bioassemblyProvider.moveRightDrillAssembly(-1 * throttleVal * 180);
        }
        await waimt(100);
      }

      if (state['L1'] == 1) {
        if (left_drill_selected) {
          bioassemblyProvider.publishDrillSpeed(1);
          await waimt(500);
        } else if (right_drill_selected) {
          bioassemblyProvider.publishDrillSpeed(2);
          await waimt(500);
        }
      } else if (state['R1'] == 1) {
        if (left_drill_selected) {
          bioassemblyProvider.publishDrillSpeed(-1);
          await waimt(500);
        } else if (right_drill_selected) {
          bioassemblyProvider.publishDrillSpeed(-2);
          await waimt(500);
        }
      }

      prev_throttle_val = throttleVal;
      prev_steering_val = steeringVal;
    });

    timer.start();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bioassemblyProvider = Provider.of<BioassemblyProvider>(context);
    final homeControlProvider =
        Provider.of<HomeControlProvider>(context, listen: false);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 2,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CameraFeed(
                tile_height: SizeConfig.verticalBlockSize * 50,
                tile_width: SizeConfig.horizontalBlockSize * 45,
              ),
              Row(
                children: [
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 15,
                    height: SizeConfig.verticalBlockSize * 29,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MySpaces.hSmallestGapInBetween,
                        Text(
                          "Left Flap : ${leftFlap ? 'Open' : 'Closed'}",
                          style: MyFonts.medium.factor(1.25),
                        ),
                        MySpaces.hSmallGapInBetween,
                        Text(
                          "Right Flap : ${rightFlap ? 'Open' : 'Closed'}",
                          style: MyFonts.medium.factor(1.25),
                        ),
                        MySpaces.hSmallestGapInBetween,
                      ],
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: TileWidget(
                      width: SizeConfig.horizontalBlockSize * 28.5,
                      height: SizeConfig.verticalBlockSize * 29,
                      child: Container(
                        width: SizeConfig.horizontalBlockSize * 20,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              // height: 40,
                              child: TextFormField(
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "Enter a name";
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  fileName = homeControlProvider.lat_long +
                                      '_' +
                                      value;
                                },
                                decoration: InputDecoration(
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.75,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: selected_color,
                                  border: InputBorder.none,
                                  labelText: "File name",
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.75,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.75,
                                    ),
                                  ),
                                  hoverColor: selected_color,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.75,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            MySpaces.vSmallGapInBetween,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 15,
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        readingSensors = !readingSensors;
                                      });
                                    },
                                    child: Text(
                                      readingSensors
                                          ? "Stop Sensors"
                                          : "Start Sensor Reading",
                                      style: MyFonts.medium.factor(1),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.all(15),
                                      primary: Colors.white,
                                      elevation: 2,
                                      backgroundColor: readingSensors
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 15,
                                  ),
                                  child: TextButton(
                                    onPressed: (bioassemblyProvider
                                                .sensorReadings.isEmpty ||
                                            readingSensors)
                                        ? null
                                        : () {
                                            if (!_formKey.currentState
                                                .validate()) {
                                              return;
                                            }
                                            _formKey.currentState.save();
                                            bioassemblyProvider
                                                .generateCSV(fileName);
                                          },
                                    child: Text(
                                      'Save',
                                      style: MyFonts.medium.factor(1),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 5,
                                      ),
                                      primary: Colors.white,
                                      elevation: 2,
                                      backgroundColor: (bioassemblyProvider
                                                  .sensorReadings.isEmpty ||
                                              readingSensors)
                                          ? selected_color
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                print("reading");
                              },
                              child: Text(
                                'Get Reaction Readings',
                                style: MyFonts.medium.factor(1),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 5,
                                ),
                                primary: Colors.white,
                                elevation: 2,
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
          Row(
            children: [
              Column(
                children: [
                  // TileWidget(
                  //   height: SizeConfig.verticalBlockSize * 56,
                  //   width: SizeConfig.horizontalBlockSize * 11,
                  //   color: left_drill_selected
                  //       ? Color.fromARGB(186, 15, 142, 151)
                  //       : null,
                  //   child: Stack(
                  //     alignment: Alignment.center,
                  //     children: [
                  //       Positioned(
                  //         bottom: SizeConfig.verticalBlockSize * 20,
                  //         child: Container(
                  //           width: SizeConfig.horizontalBlockSize * 11,
                  //           child: Image.asset(
                  //             'assets/images/front.png',
                  //           ),
                  //         ),
                  //       ),
                  //       topicsInitialised
                  //           ? Consumer<BioassemblyProvider>(
                  //               builder: (ctx, bioassemblyProvider, _) {
                  //               return StreamBuilder<Object>(
                  //                 stream: bioassemblyProvider
                  //                     .leftDrillPos.subscription
                  //                     .where((message) =>
                  //                         message['topic'] ==
                  //                         '/drill_pos_left'),
                  //                 builder: (context, snapshot) {
                  //                   if (snapshot.hasData) {
                  //                     final topic =
                  //                         TopicData.fromJson(snapshot.data);
                  //                     return leftDrillRender(topic.msg['data']);
                  //                   } else {
                  //                     return leftDrillRender(left_drill_pos);
                  //                   }
                  //                 },
                  //               );
                  //             })
                  //           : leftDrillRender(left_drill_pos),
                  //       Positioned(
                  //         top: left_drill_pos,
                  //         left: SizeConfig.horizontalBlockSize * 3.5,
                  //         child: Container(
                  //           height: SizeConfig.verticalBlockSize * 22.4,
                  //           child: Image.asset(
                  //             'assets/images/drill.png',
                  //           ),
                  //         ),
                  //       ),
                  //       Positioned(
                  //         bottom: 0,
                  //         child: Text("Left"),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  TileWidget(
                    height: SizeConfig.verticalBlockSize * 56,
                    width: SizeConfig.horizontalBlockSize * 11,
                    color: left_drill_selected
                        ? Color.fromARGB(186, 15, 142, 151)
                        : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: SizeConfig.verticalBlockSize * 20,
                          child: Container(
                            width: SizeConfig.horizontalBlockSize * 11,
                            child: Image.asset(
                              'assets/images/front.png',
                            ),
                          ),
                        ),
                        Positioned(
                          top: left_drill_pos,
                          left: SizeConfig.horizontalBlockSize * 3.5,
                          child: Container(
                            height: SizeConfig.verticalBlockSize * 22.4,
                            child: Image.asset(
                              'assets/images/drill.png',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text("Left"),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TileWidget(
                        height: SizeConfig.verticalBlockSize * 22.5,
                        width: syringe_plate_width,
                        color: left_syringe_selected
                            ? Color.fromARGB(186, 15, 142, 151)
                            : null,
                        child: CustomPaint(
                          painter: SyringePainter(
                            width: syringe_plate_width,
                            emptyPoints: emptyPoints_left,
                            filledPoints: bioassemblyProvider.filledPoints_left,
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          ...point_keys.map((e) {
                            return Transform(
                              transform: Matrix4.translationValues(
                                emptyPoints_left[point_keys.indexOf(e)].dx,
                                emptyPoints_left[point_keys.indexOf(e)].dy,
                                0,
                              ),
                              child: Text(
                                e,
                                style: MyFonts.medium.tsFactor(12.5),
                              ),
                            );
                          }).toList()
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 18,
                    height: SizeConfig.horizontalBlockSize * 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Spacer(),
                            Container(
                              width: SizeConfig.horizontalBlockSize * 6,
                              child: Image.asset('assets/images/beaker.png'),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            SizedBox(height: SizeConfig.verticalBlockSize * 8),
                            AnimatedRotation(
                              duration: Duration(
                                // milliseconds:
                                //     (min_rotation_angle * 10).toInt()),
                                milliseconds: 50,
                              ),
                              turns: (funnel_angle / 360),
                              child: Container(
                                width: SizeConfig.horizontalBlockSize * 9,
                                child: Image.asset('assets/images/funnel.png'),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "Current Beaker",
                        style: MyFonts.medium.factor(1.25),
                      ),
                      Container(
                        height: SizeConfig.verticalBlockSize * 3,
                        child: Row(
                          children: [
                            left_drill_selected
                                ? Icon(
                                    Icons.arrow_downward,
                                    size: SizeConfig.horizontalBlockSize * 1.5,
                                  )
                                : Container(),
                            SizedBox(
                              width: SizeConfig.horizontalBlockSize * 5,
                            ),
                            right_drill_selected
                                ? Icon(
                                    Icons.arrow_downward,
                                    size: SizeConfig.horizontalBlockSize * 1.5,
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      TileWidget(
                        width: base_plate_width,
                        height: SizeConfig.verticalBlockSize * 34,
                        child: AnimatedRotation(
                          duration: Duration(milliseconds: duration),
                          turns: bioassemblyProvider.counter,
                          child: Transform(
                            transform: Matrix4.rotationZ(22.5 * math.pi / 180),
                            child: CustomPaint(
                              painter: BeakerPainter(
                                width: base_plate_width,
                                emptyPoints: emptyPoints,
                                filledPoints: bioassemblyProvider.filledPoints,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  TileWidget(
                    height: SizeConfig.verticalBlockSize * 56,
                    width: SizeConfig.horizontalBlockSize * 11,
                    color: right_drill_selected
                        ? Color.fromARGB(186, 15, 142, 151)
                        : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          bottom: SizeConfig.verticalBlockSize * 20,
                          child: Container(
                            width: SizeConfig.horizontalBlockSize * 11,
                            child: Image.asset(
                              'assets/images/front.png',
                            ),
                          ),
                        ),
                        Positioned(
                          top: left_drill_pos,
                          left: SizeConfig.horizontalBlockSize * 3.5,
                          child: Container(
                            height: SizeConfig.verticalBlockSize * 22.4,
                            child: Image.asset(
                              'assets/images/drill.png',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text("Right"),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TileWidget(
                        height: SizeConfig.verticalBlockSize * 22.5,
                        width: syringe_plate_width,
                        color: right_syringe_selected
                            ? Color.fromARGB(186, 15, 142, 151)
                            : null,
                        child: CustomPaint(
                          painter: SyringePainter(
                            width: syringe_plate_width,
                            emptyPoints: emptyPoints_right,
                            filledPoints:
                                bioassemblyProvider.filledPoints_right,
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          ...point_keys.map((e) {
                            return Transform(
                              transform: Matrix4.translationValues(
                                emptyPoints_right[point_keys.indexOf(e)].dx,
                                emptyPoints_right[point_keys.indexOf(e)].dy,
                                0,
                              ),
                              child: Text(
                                e,
                                style: MyFonts.medium.tsFactor(12.5),
                              ),
                            );
                          }).toList()
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
