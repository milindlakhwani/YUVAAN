import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/models/sensor_data.dart';
import 'package:yuvaan_gui/ros/core.dart';

class BioassemblyProvider with ChangeNotifier {
  Ros ros;
  ConnectionStatus connectionStatus;
  BioassemblyProvider(this.ros, this.connectionStatus);

  Topic beaker_stepper;
  Topic funnel_stepper;
  Topic left_syringe;
  Topic right_syringe;
  Topic rotateDrill;
  Topic moveLeftDrill;
  Topic moveRightDrill;
  Topic leftDrillPos;
  Topic rightDrillPos;
  Topic servos;

  List<Offset> filledPoints = [];
  List<Offset> filledPoints_left = [];
  List<Offset> filledPoints_right = [];
  double counter = 0;

  List<SensorData> sensorReadings = [
    SensorData(
      co2: 12,
      co: 13,
      humidity: 10,
      methane: 12,
      pressure: 1,
      temperature: 12,
      wind_speed: 21,
    ),
  ];

  List<Map<String, Object>> reactionReadings = [];

  SensorData minValues = SensorData(
    co2: 12,
    co: 13,
    humidity: 10,
    methane: 12,
    pressure: 1,
    temperature: 12,
    wind_speed: 21,
  );
  SensorData maxValues = SensorData(
    co2: 12,
    co: 13,
    humidity: 10,
    methane: 12,
    pressure: 1,
    temperature: 12,
    wind_speed: 21,
  );
  SensorData avgValues = SensorData(
    co2: 12,
    co: 13,
    humidity: 10,
    methane: 12,
    pressure: 10,
    temperature: 12,
    wind_speed: 21,
  );

  Future<void> initTopics() async {
    if (connectionStatus == ConnectionStatus.CONNECTED) {
      beaker_stepper = Topic(
        ros: ros,
        name: '/change_beaker_pos',
        type: "std_msgs/Int8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      funnel_stepper = Topic(
        ros: ros,
        name: '/rotate_funnel',
        type: "std_msgs/Int8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      left_syringe = Topic(
        ros: ros,
        name: '/left_syringe',
        type: "std_msgs/UInt8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      right_syringe = Topic(
        ros: ros,
        name: '/right_syringe',
        type: "std_msgs/UInt8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      rotateDrill = Topic(
        ros: ros,
        name: '/rotate_drill',
        type: "std_msgs/Int8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      moveLeftDrill = Topic(
        ros: ros,
        name: '/change_drill_pos_left',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      moveRightDrill = Topic(
        ros: ros,
        name: '/change_drill_pos_right',
        type: "std_msgs/Int16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      leftDrillPos = Topic(
        ros: ros,
        name: '/drill_pos_left',
        type: "std_msgs/UInt16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      rightDrillPos = Topic(
        ros: ros,
        name: '/drill_pos_right',
        type: "std_msgs/UInt16",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      servos = Topic(
        ros: ros,
        name: '/servos',
        type: "std_msgs/UInt8",
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
      await Future.wait(
        [
          beaker_stepper.advertise(),
          funnel_stepper.advertise(),
          left_syringe.advertise(),
          right_syringe.advertise(),
          rotateDrill.advertise(),
          moveLeftDrill.advertise(),
          moveRightDrill.advertise(),
          leftDrillPos.subscribe(),
          rightDrillPos.subscribe(),
          servos.subscribe(),
        ],
      );
    }
  }

  Future<void> publishBeakerSteps(double angle) async {
    var msg = {
      'data': (angle ~/ 0.9).toInt(),
    };
    await beaker_stepper.publish(msg);
  }

  Future<void> publishFunnelSteps(int steps) async {
    var msg = {
      'data': steps,
    };
    await funnel_stepper.publish(msg);
  }

  Future<void> rotLeftSyringe(int angle) async {
    var msg = {
      'data': angle,
    };
    await left_syringe.publish(msg);
  }

  Future<void> rotRightSyringe(int angle) async {
    var msg = {
      'data': angle,
    };
    await right_syringe.publish(msg);
  }

  Future<void> publishDrillSpeed(int value) async {
    var msg = {
      'data': value,
    };
    await rotateDrill.publish(msg);
  }

  Future<void> moveLeftDrillAssembly(double pwmVal) async {
    var msg = {
      'data': pwmVal.toInt(),
    };
    await moveLeftDrill.publish(msg);
  }

  Future<void> moveRightDrillAssembly(double pwmVal) async {
    var msg = {
      'data': pwmVal.toInt(),
    };
    await moveRightDrill.publish(msg);
  }

  Future<void> moveServo(int val) async {
    var msg = {
      'data': val,
    };
    await servos.publish(msg);
  }

  Future<void> clearTopics() async {
    await beaker_stepper.unadvertise();
    await funnel_stepper.unadvertise();
    await left_syringe.unadvertise();
    await right_syringe.unadvertise();
    await rotateDrill.unadvertise();
    await moveLeftDrill.unadvertise();
    await moveRightDrill.unadvertise();
    await leftDrillPos.unsubscribe();
    await rightDrillPos.unsubscribe();
  }

  void updateCounter(double count) {
    counter = count;
    notifyListeners();
  }

  void markCurrentBeaker(double current_angle, List<Offset> emptyPoints,
      bool left_active, bool right_active) {
    if (current_angle % 45 == 0 && (left_active || right_active)) {
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
      filledPoints.add(offset);
      notifyListeners();
    }
  }

  void addPointsLeft(Offset point) {
    filledPoints_left.add(point);
    notifyListeners();
  }

  bool checkPointLeft(Offset point) {
    return filledPoints_left.contains(point);
  }

  bool checkPointRight(Offset point) {
    return filledPoints_right.contains(point);
  }

  void addPointsRight(Offset point) {
    filledPoints_right.add(point);
    notifyListeners();
  }

  void populateSensorData(List<SensorData> data) {
    sensorReadings.clear();
    sensorReadings = data;
  }

  SensorData getAvg() {
    SensorData data = SensorData(
      temperature: 0,
      humidity: 0,
      co2: 0,
      co: 0,
      methane: 0,
      pressure: 0,
      wind_speed: 0,
      alcohol: 0,
      hydrogen: 0,
      lpg: 0,
      propane: 0,
    );
    final int n = sensorReadings.length;
    sensorReadings.forEach((element) {
      data.temperature += element.temperature;
      data.co += element.co;
      data.co2 += element.co2;
      data.humidity += element.humidity;
      data.methane += element.methane;
      data.pressure += element.pressure;
      data.wind_speed += element.wind_speed;
      data.alcohol += element.alcohol;
      data.hydrogen += element.hydrogen;
      data.lpg += element.lpg;
      data.propane += element.propane;
    });
    data.temperature = data.temperature / n;
    data.co = data.co / n;
    data.co2 = data.co2 / n;
    data.humidity = data.humidity / n;
    data.methane = data.methane / n;
    data.pressure = data.pressure / n;
    data.wind_speed = data.wind_speed / n;
    data.alcohol = data.alcohol / n;
    data.hydrogen = data.hydrogen / n;
    data.lpg = data.lpg / n;
    data.propane = data.propane / n;
    return data;
  }

  SensorData getMax() {
    SensorData data = SensorData(
      temperature: 0,
      humidity: 0,
      co2: 0,
      co: 0,
      methane: 0,
      pressure: 0,
      wind_speed: 0,
      alcohol: 0,
      hydrogen: 0,
      lpg: 0,
      propane: 0,
    );
    sensorReadings.forEach((element) {
      data.temperature = max(data.temperature, element.temperature);
      data.co = max(data.co, element.co);
      data.co2 = max(data.co2, element.co2);
      data.humidity = max(data.co2, element.humidity);
      data.methane = max(data.co2, element.methane);
      data.pressure = max(data.co2, element.pressure);
      data.wind_speed = max(data.co2, element.wind_speed);
      data.alcohol = max(data.alcohol, element.alcohol);
      data.hydrogen = max(data.alcohol, element.hydrogen);
      data.lpg = max(data.alcohol, element.lpg);
      data.propane = max(data.alcohol, element.propane);
    });
    return data;
  }

  SensorData getMin() {
    SensorData data = SensorData(
      temperature: 0,
      humidity: 0,
      co2: 0,
      co: 0,
      methane: 0,
      pressure: 0,
      wind_speed: 0,
      alcohol: 0,
      hydrogen: 0,
      lpg: 0,
      propane: 0,
    );
    sensorReadings.forEach((element) {
      data.temperature = min(data.temperature, element.temperature);
      data.co = min(data.co, element.co);
      data.co2 = min(data.co2, element.co2);
      data.humidity = min(data.co2, element.humidity);
      data.methane = min(data.co2, element.methane);
      data.pressure = min(data.co2, element.pressure);
      data.wind_speed = min(data.co2, element.wind_speed);
      data.alcohol = min(data.co2, element.alcohol);
      data.hydrogen = min(data.co2, element.hydrogen);
      data.lpg = min(data.co2, element.lpg);
      data.propane = min(data.co2, element.propane);
    });
    return data;
  }

  void generateCSV(String text) {
    print(text);
    const List<String> rowHeader = [
      "Temperature",
      "Humidity",
      "Pressure",
      "CO",
      "CO2",
      "Methane",
      "Wind Speed",
      "Alcohol",
      "Hydrogen",
      "Lpg",
      "Propane",
    ];

    List<List<dynamic>> rows = [];

    rows.add(rowHeader);

    sensorReadings.forEach((element) {
      List<dynamic> dataRow = [];
      dataRow.add(element.temperature);
      dataRow.add(element.humidity);
      dataRow.add(element.pressure);
      dataRow.add(element.co);
      dataRow.add(element.co2);
      dataRow.add(element.methane);
      dataRow.add(element.wind_speed);
      rows.add(dataRow);
    });

    //now convert our 2d array into the csvlist using the plugin of csv
    String csv = const ListToCsvConverter().convert(rows);
    //this csv variable holds entire csv data
    //Now Convert or encode this csv string into utf8
    final bytes = utf8.encode(csv);
    //NOTE THAT HERE WE USED HTML PACKAGE
    final blob = html.Blob([bytes]);
    //It will create downloadable object
    final url = html.Url.createObjectUrlFromBlob(blob);
    //It will create anchor to download the file
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = text + '.csv';
    //finally add the csv anchor to body
    html.document.body.children.add(anchor);
    // Cause download by calling this function
    anchor.click();
    //revoke the object
    html.Url.revokeObjectUrl(url);
    sensorReadings.clear();
  }
}
