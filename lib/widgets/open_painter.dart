import 'dart:ui';
import 'package:flutter/material.dart';

class OpenPainter extends CustomPainter {
  List<Offset> allCords;

  OpenPainter({this.allCords});

  List<Offset> allPoints = [];

  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint()
      ..color = Color(0xff63aa65)
      ..strokeCap = StrokeCap.butt //rounded points
      ..strokeWidth = 2;
    //list of points
    // var points = [
    // Offset(0, 0),
    // Offset(1000, 0),
    // Offset(50, 50),
    // Offset(80, 70),
    // Offset(380, 175),
    // Offset(200, 175),
    // Offset(150, 105),
    // Offset(300, 75),
    // Offset(320, 200),
    // Offset(89, 125)
    // ];

    //draw points on canvas
    // print(allCords);
    canvas.drawPoints(PointMode.points, allCords, paint1);
    // print("Drawing");
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
