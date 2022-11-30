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
import 'package:yuvaan_gui/models/topic_data.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
import 'package:yuvaan_gui/widgets/map_widget.dart';
import 'package:yuvaan_gui/widgets/open_painter.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';
import 'package:latlong2/latlong.dart';

class HomeControl extends StatefulWidget {
  @override
  State<HomeControl> createState() => _HomeControlState();
}

class _HomeControlState extends State<HomeControl> {
  final int rangeLength = 560;
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

  List<Offset> addCord(
      Map<String, dynamic> topicData, double width, double height) {
    List<dynamic> ranges = topicData['ranges'];

    double angle_diff = 0.01124004554;
    double curr_angle = 0;
    double x, y;
    List<Offset> allCords = [];

    // List<double> frontRange = [
    //   ...ranges.sublist(0, 20),
    //   ...ranges.sublist(rangeLength - 20, rangeLength)
    // ]..removeWhere((element) => element == null);

    // frontDist = frontRange.fold(
    //         0, (previousValue, element) => previousValue + element) /
    //     frontRange.length;

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

    return allCords;
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
        setState(() {
          topicsInitialised = true;
        });

        ros_timer.cancel();
      }
    });

    timer = Timer.periodic(const Duration(milliseconds: 10), (Timer t) {
      final homeControlProvider =
          Provider.of<HomeControlProvider>(context, listen: false);
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      setState(() {
        controller_values['A'] = state['A'];
        controller_values['B'] = state['B'];
        controller_values['X'] = state['X'];
        controller_values['Y'] = state['Y'];
        controller_values['L1'] = state['L1'];
        controller_values['R1'] = state['R1'];
        controller_values['L2'] = state['L2'];
        controller_values['R2'] = state['R2'];
        controller_values['L3'] = state['L3'];
        controller_values['R3'] = state['R3'];
        controller_values['Up'] = state['Up'];
        controller_values['Down'] = state['Down'];
        controller_values['Left'] = state['Left'];
        controller_values['Right'] = state['Right'];
        controller_values['Steering'] = state['Steering'];
        controller_values['Throttle'] = state['Throttle'];
      });

      throttleVal =
          double.parse(controller_values['Throttle'].toStringAsFixed(2));
      steeringVal =
          double.parse(controller_values['Steering'].toStringAsFixed(2));
      // print(steeringPrev);

      if (throttleVal != throttlePrev || steeringVal != steeringPrev) {
        homeControlProvider.publishVelocityCommands(
          controller_values['Throttle'],
          controller_values['Steering'],
        );
      }

      throttlePrev = throttleVal;
      steeringPrev = steeringVal;
    });
  }

  @override
  void dispose() {
    Provider.of<HomeControlProvider>(context).clearTopics();
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
      child: Row(
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
                            style:
                                MyFonts.medium.setColor(text_color).factor(1),
                          ),
                          SizedBox(
                            height: SizeConfig.verticalBlockSize * 4,
                          ),
                          Text(
                            "Throttle : ${(-controller_values['Throttle'] * 0.57).toStringAsFixed(2)} m/s",
                            style:
                                MyFonts.medium.setColor(text_color).factor(0.9),
                          ),
                          SizedBox(
                            height: SizeConfig.verticalBlockSize * 2,
                          ),
                          Text(
                            "Steering : ${(controller_values['Steering'] * 0.18).toStringAsFixed(2)} rad/s",
                            style:
                                MyFonts.medium.setColor(text_color).factor(0.9),
                          ),
                          SizedBox(
                            height: SizeConfig.verticalBlockSize * 2,
                          ),

                          // Text(
                          //   "Front Proximity : ${frontDist.toStringAsFixed(2)} m",
                          //   style:
                          //       MyFonts.medium.setColor(text_color).factor(0.7),
                          // ),
                          // Text(
                          //   "${frontDist <= 1 ? "Damger" : "Safe"} (dist < 1m)",
                          //   style:
                          //       MyFonts.medium.setColor(text_color).factor(0.6),
                          // ),
                          // SizedBox(
                          //   height: SizeConfig.verticalBlockSize * 2,
                          // ),
                          // Text(
                          //   "Back Proximity : ${backDist.toStringAsFixed(2)} m",
                          //   style:
                          //       MyFonts.medium.setColor(text_color).factor(0.7),
                          // ),
                          // Text(
                          //   "${backDist <= 1 ? "Damger" : "Safe"} (dist < 1m)",
                          //   style:
                          //       MyFonts.medium.setColor(text_color).factor(0.6),
                          // ),
                          // SizedBox(
                          //   height: SizeConfig.verticalBlockSize * 2,
                          // ),
                          Text(
                            topicsInitialised
                                ? "Topics Initialized"
                                : "Not Initialized",
                            style:
                                MyFonts.bold.setColor(text_color).factor(0.9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  topicsInitialised
                      ? Consumer<HomeControlProvider>(
                          builder: (ctx, homeControlProvider, _) {
                          return StreamBuilder<Object>(
                            stream: homeControlProvider.euler_angle.subscription
                                .where((message) =>
                                    message['topic'] == '/imu/euler'),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final topic = TopicData.fromJson(snapshot.data);
                                return renderOrientationState(topic);
                              } else {
                                // print(snapshot.data);
                                return TileWidget(
                                  height: SizeConfig.verticalBlockSize * 25.5,
                                  width: SizeConfig.horizontalBlockSize * 21,
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                        })
                      : Stack(
                          children: [
                            renderOrientationState(TopicData("", {})),
                            Container(
                              width: SizeConfig.horizontalBlockSize * 45 + 40,
                              height: SizeConfig.verticalBlockSize * 25.5,
                              child: Text("Waiting for IMU data"),
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(15)),
                              alignment: Alignment.center,
                            ),
                          ],
                        ),
                ],
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TileWidget(
                height: SizeConfig.verticalBlockSize * 30,
                width: SizeConfig.horizontalBlockSize * 30,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: MapWidget(
                    marker: LatLng(
                      double.parse("0.0"),
                      double.parse('0'),
                    ),
                  ),
                ),
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 12,
                width: SizeConfig.horizontalBlockSize * 30,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                            onPressed: () {},
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
              TileWidget(
                height: SizeConfig.verticalBlockSize * 36,
                width: SizeConfig.horizontalBlockSize * 30,
                child: topicsInitialised
                    ? Consumer<HomeControlProvider>(
                        builder: (ctx, homeControlProvider, _) {
                        return StreamBuilder<Object>(
                          stream: homeControlProvider
                              .lidar_angle_range.subscription
                              .where((message) =>
                                  message['topic'] == '/laser_scan'),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final topic = TopicData.fromJson(snapshot.data);

                              return Stack(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/top.png',
                                      height: SizeConfig.verticalBlockSize * 3,
                                    ),
                                  ),
                                  Center(
                                    child: CustomPaint(
                                      painter: OpenPainter(
                                        allCords: addCord(
                                          topic.msg,
                                          SizeConfig.horizontalBlockSize * 30,
                                          SizeConfig.verticalBlockSize * 36,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        );
                      })
                    : Text("Waiting for lidar topic to be intialized"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
