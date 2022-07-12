import 'dart:async';
import 'dart:js' as js;
import 'dart:math';

import 'package:flutter/gestures.dart';
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

  double mapOneRangeToAnother(double sourceNumber, double fromA, double fromB,
      double toA, double toB, int decimalPrecision) {
    double deltaA = fromB - fromA;
    double deltaB = toB - toA;
    double scale = deltaB / deltaA;
    double negA = -1 * fromA;
    double offset = (negA * scale) + toA;
    double finalNumber = (sourceNumber * scale) + offset;
    int calcScale = pow(10, decimalPrecision).toInt();

    return ((finalNumber * calcScale) / calcScale).roundToDouble();
  }

  void addCord(Map<String, dynamic> topicData, double width, double height) {
    double x = topicData['x'];
    double y = topicData['y'];
    final z = topicData['z'];
    // final dist = topicData['x'];
    // final step = topicData['y'];
    // final angle = 180 - (step * 0.45);
    // double x, y;

    // x = dist * cos(angle * pi / 180);
    // y = dist * sin(angle * pi / 180);

    x = mapOneRangeToAnother(
        x, -lidar_max_dist, lidar_max_dist, (-1 * width) / 2, width / 2, 2);
    y = mapOneRangeToAnother(y, 0, lidar_max_dist, 0, height, 2);

    y = height - (y + (height / 2));
    if (z == 1.0 || allCords.length == 400 || y >= ((height / 2) - 5)) {
      print("Clearing");
      allCords.clear();
    }
    allCords.add(Offset(x, y));
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

      if (throttleVal != throttlePrev || steeringVal != steeringPrev) {
        print("Publishing");
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
                tile_height: SizeConfig.verticalBlockSize * 40,
                tile_width: SizeConfig.horizontalBlockSize * 40,
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 38.5,
                width: SizeConfig.horizontalBlockSize * 40,
                child: topicsInitialised
                    ? Consumer<HomeControlProvider>(
                        builder: (ctx, homeControlProvider, _) {
                        return StreamBuilder<Object>(
                          stream: homeControlProvider
                              .lidar_angle_range.subscription
                              .where((message) =>
                                  message['topic'] == '/lidar_angle_range'),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final topic = TopicData.fromJson(snapshot.data);
                              addCord(
                                  topic.msg,
                                  SizeConfig.horizontalBlockSize * 40,
                                  SizeConfig.verticalBlockSize * 40);
                              return CustomPaint(
                                painter: OpenPainter(
                                  allCords: allCords,
                                ),
                              );
                            } else {
                              print(snapshot.data);
                              return CircularProgressIndicator();
                            }
                          },
                        );
                      })
                    : Text("Waiting for lidar topic to be intialized"),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TileWidget(
                    isCenter: false,
                    width: SizeConfig.horizontalBlockSize * 12.5,
                    height: SizeConfig.verticalBlockSize * 16,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            height: SizeConfig.verticalBlockSize * 3,
                          ),
                          Text(
                            topicsInitialised
                                ? "Topics Initialized"
                                : "Not Initialized",
                            style:
                                MyFonts.bold.setColor(text_color).factor(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TileWidget(
                    height: SizeConfig.verticalBlockSize * 16,
                    width: SizeConfig.horizontalBlockSize * 34,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 5,
                                width: SizeConfig.horizontalBlockSize * 15,
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
                                        SizeConfig.horizontalBlockSize * 0.5,
                                      ),
                                    ),
                                    hoverColor: selected_color,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 10),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: SizeConfig.verticalBlockSize * 5,
                                width: SizeConfig.horizontalBlockSize * 15,
                                child: TextField(
                                  controller: latController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: selected_color,
                                    hintText: "Longitude",
                                    border: InputBorder.none,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.5,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 10),
                                    hoverColor: selected_color,
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(
                                        SizeConfig.horizontalBlockSize * 0.5,
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
                                      SizeConfig.horizontalBlockSize * 0.5,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(1)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                      SizeConfig.horizontalBlockSize * 10,
                                      SizeConfig.verticalBlockSize * 5.5),
                                  primary: kBlue,
                                ),
                                onPressed: () {},
                              ),
                              ElevatedButton(
                                child: Text("Start Tracking"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.5,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(1)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                      SizeConfig.horizontalBlockSize * 10,
                                      SizeConfig.verticalBlockSize * 5.5),
                                  primary: kBlue,
                                ),
                                onPressed: () {},
                              ),
                              ElevatedButton(
                                child: Text("Clear"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.horizontalBlockSize * 0.5,
                                    ),
                                  ),
                                  textStyle: MyFonts.medium
                                      .factor(1)
                                      .setColor(text_color),
                                  fixedSize: Size(
                                      SizeConfig.horizontalBlockSize * 10,
                                      SizeConfig.verticalBlockSize * 5.5),
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
                ],
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 34,
                width: SizeConfig.horizontalBlockSize * 48,
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
              topicsInitialised
                  ? Consumer<HomeControlProvider>(
                      builder: (ctx, homeControlProvider, _) {
                      return StreamBuilder<Object>(
                        stream: homeControlProvider.euler_angle.subscription
                            .where(
                                (message) => message['topic'] == '/imu/euler'),
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
    );
  }
}



//  ScrollConfiguration(
//         behavior: ScrollConfiguration.of(context).copyWith(
//           dragDevices: {
//             PointerDeviceKind.touch,
//             PointerDeviceKind.mouse,
//             PointerDeviceKind.stylus,
//             PointerDeviceKind.invertedStylus,
//             PointerDeviceKind.unknown,
//           },
//         ),
//         child: SingleChildScrollView(




