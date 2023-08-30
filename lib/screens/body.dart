import 'package:flutter/material.dart';
import 'package:yuvaan_gui/screens/bioassembly.dart';
import 'package:yuvaan_gui/screens/home_control.dart';
import 'package:yuvaan_gui/screens/sensors.dart';
import 'package:yuvaan_gui/widgets/navbar.dart';

class Body extends StatelessWidget {
  final String currentPage;

  const Body({this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Navbar(
          heading: currentPage,
        ),
        if (currentPage == "Home")
          HomeControl()
        else if (currentPage == "Bioassembly")
          Bioassembly()
        else
          Sensor()
      ],
    );
  }
}
