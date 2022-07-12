import 'dart:async';
import 'dart:math' as math;
import 'dart:js' as js;
import 'dart:io';

import 'package:animated_widgets/widgets/rotation_animated.dart';
import 'package:flutter/material.dart';
import 'package:pausable_timer/pausable_timer.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/mySpaces.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/bioassembly_provider.dart';
import 'package:yuvaan_gui/widgets/beaker_painter.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
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
  // Timer timer;
  Timer ros_timer;
  double counter = 0;
  double current_angle = 0;
  final base_plate_width = SizeConfig.horizontalBlockSize * 20;
  final circle_offset_diagonal = 40;
  final circle_offset_corner = 50;
  List<Offset> emptyPoints = [];
  List<Offset> filledPoints = [];
  bool moveDown = true;
  double leftHeight = SizeConfig.verticalBlockSize * 23;
  double rightHeight = SizeConfig.verticalBlockSize * 23;
  bool _enabled = false;
  List<Rotation> _rotationValues = [
    Rotation.deg(),
    Rotation.deg(x: 90),
  ];
  int func_calls = 0;
  double prev_throttle_val = 0;
  double prev_steering_val = 0;
  int drill_rpm = 180;
  int drill_speed = 0;
  double percent_height = SizeConfig.verticalBlockSize * 80;
  bool left_active = false;
  double min_rotation_angle = 45;
  double funnel_angle = 0;
  bool isFeedEnabled = false;
  bool readingSensors = false;
  bool topicsInitialised = false;
  int duration = 1000;
  double encoder_motor_speed = 0;
  bool drill_moving = false;

  void rotateBasePlate(double angle) {
    current_angle += angle;

    setState(() {
      if (angle.abs() == 22.5) {
        duration = 500;
      } else if (angle.abs() == 45) {
        duration = 1000;
      }
      counter += (angle * math.pi / 180) / (2 * math.pi);
    });

    Provider.of<BioassemblyProvider>(context, listen: false)
        .publishBeakerAngle(angle);
  }

  void markCurrentBeaker() {
    print("Marking");
    if (current_angle % 45 == 0) {
      final multiple = current_angle / 45;
      double index = multiple % 8;
      index = (emptyPoints.length) - index;
      index = index % 8;
      if (left_active) {
        if (index == 0) {
          index = 7;
        } else {
          index = index - 1;
        }
      }
      print(index);
      final Offset offset = emptyPoints[(index.toInt())];
      setState(() {
        filledPoints.add(offset);
      });
    }
  }

  void moveSyringe(Syringe syringe) {
    double height;
    if (syringe == Syringe.Left) {
      height = leftHeight;
    } else {
      height = rightHeight;
    }

    if (moveDown && height >= SizeConfig.verticalBlockSize * 1) {
      height -= SizeConfig.verticalBlockSize * 0.5;
      setState(() {
        Syringe.Left == syringe ? leftHeight = height : rightHeight = height;
      });
    } else if (!moveDown && height <= SizeConfig.verticalBlockSize * 23) {
      height += SizeConfig.verticalBlockSize * 0.5;
      setState(() {
        Syringe.Left == syringe ? leftHeight = height : rightHeight = height;
      });
    }

    final bioProvider =
        Provider.of<BioassemblyProvider>(context, listen: false);

    syringe == Syringe.Left
        ? bioProvider.rotLeftSyringe(moveDown)
        : bioProvider.rotRightSyringe(moveDown);
  }

  void change_drill_state() {
    Provider.of<BioassemblyProvider>(context, listen: false).toggleDrillState();
    setState(() {
      _enabled = !_enabled;
    });
  }

  void rotate_drill(double val) {
    double speemd = -val * drill_rpm;
    setState(() {
      drill_speed = speemd.toInt();
    });
    Provider.of<BioassemblyProvider>(context, listen: false)
        .publishDrillSpeed((-val * 255).toInt());
  }

  void change_drill_pos({int moveDir}) {
    final bioProvider =
        Provider.of<BioassemblyProvider>(context, listen: false);

    int pwmVal = (encoder_motor_speed.abs() * 255).toInt() * (moveDir);

    bioProvider.moveDrillAssembly(pwmVal);

    if (moveDir == 1 && percent_height <= SizeConfig.verticalBlockSize * 79.5) {
      setState(() {
        percent_height += 5;
      });
    } else if (moveDir == -1 &&
        percent_height >= SizeConfig.verticalBlockSize * 1) {
      setState(() {
        percent_height -= 5;
      });
    }
  }

  void rotate_funnel(FunnelRotation rotation) {
    if (rotation == FunnelRotation.Clockwise) {
      setState(() {
        funnel_angle += min_rotation_angle;
      });
    } else {
      setState(() {
        funnel_angle -= min_rotation_angle;
      });
    }
    Provider.of<BioassemblyProvider>(context, listen: false).publishFunnelAngle(
        min_rotation_angle * ((rotation == FunnelRotation.Clockwise) ? 1 : -1));
  }

  void waimt(int dur) {
    timer.pause();
    Future.delayed(Duration(milliseconds: dur)).then((_) {
      timer.start();
    });
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

    timer = PausableTimer(const Duration(milliseconds: 20), () {
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      timer
        ..reset()
        ..start();

      if (state['Up'] == 1) {
        if (state['Right'] == 1) {
          rotateBasePlate(22.5);
          waimt(1000);
        } else if (state['Left'] == 1) {
          rotateBasePlate(-22.5);
          waimt(1000);
        }
      } else if (state['Up'] == 0) {
        if (state['Right'] == 1) {
          rotateBasePlate(45);
          waimt(1000);
        } else if (state['Left'] == 1) {
          rotateBasePlate(-45);
          waimt(1000);
        }
      }

      if (state['Y'] == 1) {
        setState(() {
          moveDown = !moveDown;
        });
        waimt(500);
      }

      if (state['Up'] == 1) {
        setState(() {
          min_rotation_angle += 0.9;
        });
        waimt(500);
      }

      if (state['Down'] == 1) {
        if (double.parse(min_rotation_angle.toStringAsFixed(2)) > 0.9) {
          setState(() {
            min_rotation_angle -= 0.9;
          });
          waimt(500);
        }
      }

      if (state['X'] == 1) {
        markCurrentBeaker();
      }
      if (state['A'] == 1) {
        change_drill_state();
        waimt(1000);
      }

      if (state['B'] == 1) {
        if (!isFeedEnabled) {
          waimt(1000);
          setState(() {
            isFeedEnabled = true;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Microscope Feed'),
                content: CameraFeed(
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
          waimt(1000);
          Navigator.of(context).pop();
        }
      }

      if (state['R1'] == 1 &&
          double.parse(state['Steering'].toStringAsFixed(1)) != 0.0) {
        drill_moving = true;
        change_drill_pos(moveDir: -1);
        waimt(40);
      } else if (state['L1'] == 1 &&
          double.parse(state['Steering'].toStringAsFixed(1)) != 0.0) {
        drill_moving = true;
        change_drill_pos(moveDir: 1);
        waimt(40);
      } else {
        if (drill_moving) {
          change_drill_pos(moveDir: 0);
          drill_moving = false;
        }
        // waimt(40);
      }

      if (state['R2'] == 1) {
        moveSyringe(Syringe.Right);
        waimt(100);
      }
      if (state['L2'] == 1) {
        moveSyringe(Syringe.Left);
        waimt(100);
      }

      if (state['R3'] == 1) {
        rotate_funnel(FunnelRotation.Clockwise);
        waimt(1000);
      }
      if (state['L3'] == 1) {
        rotate_funnel(FunnelRotation.AntiClockwise);
        waimt(1000);
      }
      if (state['Throttle'] != prev_throttle_val) {
        rotate_drill(state['Throttle']);
        waimt(100);
      }
      if (state['Steering'] != prev_steering_val) {
        setState(() {
          encoder_motor_speed = state['Steering'];
        });
        waimt(100);
      }

      prev_throttle_val = state['Throttle'];
      prev_steering_val = state['Steering'];
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
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 2,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CameraFeed(
                  tile_height: SizeConfig.verticalBlockSize * 40,
                  tile_width: SizeConfig.horizontalBlockSize * 40),
              Row(
                children: [
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 15,
                    height: SizeConfig.horizontalBlockSize * 18,
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Transform(
                          transform: Matrix4.rotationZ(0)
                            ..translate(0.0,
                                SizeConfig.verticalBlockSize * 13 / 2, 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              RotationAnimatedWidget(
                                values: _rotationValues,
                                enabled: _enabled,
                                curve: Curves.linear,
                                duration: Duration(seconds: 1),
                                child: Transform(
                                  transform: Matrix4.rotationZ(0)
                                    ..translate(
                                        0.0,
                                        -SizeConfig.verticalBlockSize * 13 / 2,
                                        0.0),
                                  child: Container(
                                    height: SizeConfig.verticalBlockSize * 13,
                                    width: SizeConfig.horizontalBlockSize * 3,
                                    child:
                                        Image.asset('assets/images/drill.png'),
                                  ),
                                ),
                              ),
                              RotationAnimatedWidget(
                                values: _rotationValues.reversed.toList(),
                                enabled: _enabled,
                                curve: Curves.linear,
                                duration: Duration(seconds: 1),
                                animationFinished: (finished) {
                                  func_calls += 1;
                                  if (func_calls % 2 == 0) {
                                    setState(() {
                                      left_active = !left_active;
                                      _enabled = !_enabled;
                                      _rotationValues =
                                          _rotationValues.reversed.toList();
                                    });
                                  }
                                },
                                child: Transform(
                                  transform: Matrix4.rotationZ(0)
                                    ..translate(
                                        0.0,
                                        -SizeConfig.verticalBlockSize * 13 / 2,
                                        0.0),
                                  child: Container(
                                    height: SizeConfig.verticalBlockSize * 13,
                                    width: SizeConfig.horizontalBlockSize * 3,
                                    child:
                                        Image.asset('assets/images/drill.png'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: SizeConfig.horizontalBlockSize * 9,
                          child: Image.asset(
                            'assets/images/top.png',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 23.5,
                    height: SizeConfig.horizontalBlockSize * 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            AnimatedRotation(
                              duration: Duration(
                                  milliseconds:
                                      (min_rotation_angle * 10).toInt()),
                              turns: (funnel_angle / 180) / 2,
                              child: Container(
                                width: SizeConfig.horizontalBlockSize * 9,
                                child: Image.asset('assets/images/funnel.png'),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        Column(
                          children: [
                            Spacer(),
                            Container(
                              width: SizeConfig.horizontalBlockSize * 8,
                              child: Image.asset('assets/images/beaker.png'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          TileWidget(
            width: SizeConfig.horizontalBlockSize * 2,
            height: SizeConfig.verticalBlockSize * 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: percent_height,
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TileWidget(
                width: SizeConfig.horizontalBlockSize * 45,
                height: SizeConfig.horizontalBlockSize * 13,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      MySpaces.vSmallGapInBetween,
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Syringe Motion : ${moveDown ? "Down" : "Up"}",
                                style: MyFonts.medium.factor(1),
                              ),
                              Text(
                                "Current drill speemd : $drill_speed",
                                style: MyFonts.medium.factor(1),
                              ),
                              Text(
                                "Current drill assembly speemd : ${encoder_motor_speed.abs().toStringAsFixed(2)}",
                                style: MyFonts.medium.factor(1),
                              ),
                              Text(
                                "Funnel minimum rotation angle : ${min_rotation_angle.toStringAsFixed(1)}",
                                style: MyFonts.medium.factor(1),
                              ),
                              Text(
                                "Topics initialized : $topicsInitialised",
                                style: MyFonts.medium.factor(1),
                              ),
                            ],
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                readingSensors = !readingSensors;
                              });
                            },
                            child: Text(
                              readingSensors
                                  ? "Reading Sensors Data"
                                  : "Start Sensor Reading",
                              style: MyFonts.medium.factor(1.25),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(15),
                              primary: Colors.white,
                              elevation: 2,
                              backgroundColor:
                                  readingSensors ? Colors.green : kBlue,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "B - Mark current beaker",
                                style: MyFonts.medium.factor(1),
                              ),
                              Text(
                                "A - Change drill state",
                                style: MyFonts.medium.factor(1),
                              ),
                            ],
                          ),
                          Text(
                            "X - View microscope feed",
                            style: MyFonts.medium.factor(1),
                          ),
                        ],
                      ),
                      MySpaces.vGapInBetween,
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 10,
                    height: SizeConfig.verticalBlockSize * 50,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(child: Image.asset('assets/images/syringe.png')),
                        Container(
                          margin: EdgeInsets.only(
                              bottom: SizeConfig.verticalBlockSize * 15),
                          color: Color.fromRGBO(74, 78, 86, 1),
                          width: SizeConfig.horizontalBlockSize * 2,
                          height: leftHeight,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "Current Beaker",
                        style: MyFonts.bold.factor(1.5),
                      ),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          left_active
                              ? Icon(
                                  Icons.arrow_downward,
                                  size: SizeConfig.horizontalBlockSize * 2,
                                )
                              : Container(),
                          SizedBox(
                            width: SizeConfig.horizontalBlockSize * 5,
                          ),
                          !left_active
                              ? Icon(
                                  Icons.arrow_downward,
                                  size: SizeConfig.horizontalBlockSize * 2,
                                )
                              : Container(),
                        ],
                      ),
                      TileWidget(
                        width: SizeConfig.horizontalBlockSize * 21,
                        height: SizeConfig.verticalBlockSize * 40,
                        child: AnimatedRotation(
                          duration: Duration(milliseconds: duration),
                          turns: counter,
                          child: Transform(
                            transform: Matrix4.rotationZ(22.5 * math.pi / 180),
                            child: CustomPaint(
                              painter: BeakerPainter(
                                width: base_plate_width,
                                emptyPoints: emptyPoints,
                                filledPoints: filledPoints,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 10,
                    height: SizeConfig.verticalBlockSize * 50,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(child: Image.asset('assets/images/syringe.png')),
                        Container(
                          margin: EdgeInsets.only(
                              bottom: SizeConfig.verticalBlockSize * 15),
                          color: Color.fromRGBO(74, 78, 86, 1),
                          width: SizeConfig.horizontalBlockSize * 2,
                          height: rightHeight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
