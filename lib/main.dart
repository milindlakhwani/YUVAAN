import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/providers/bioassembly_provider.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/providers/manipulator_provider.dart';
import 'package:yuvaan_gui/providers/ros_provider.dart';
import 'package:yuvaan_gui/screens/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RosProvider(),
        ),
        ChangeNotifierProxyProvider<RosProvider, HomeControlProvider>(
          create: null,
          update: (ctx, ros, previous_val) => HomeControlProvider(
            ros.ros,
            ros.connected,
          ),
        ),
        ChangeNotifierProxyProvider<RosProvider, BioassemblyProvider>(
          create: null,
          update: (ctx, ros, previous_val) => BioassemblyProvider(
            ros.ros,
            ros.connected,
          ),
        ),
        ChangeNotifierProxyProvider<RosProvider, ManipulatorProvider>(
          create: null,
          update: (ctx, ros, previous_val) => ManipulatorProvider(
            ros.ros,
            ros.connected,
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        title: 'Yuvaan GUI',
        home: HomePage(),
      ),
    );
  }
}
