import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/config/config.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/ros_provider.dart';

class Navbar extends StatefulWidget {
  final String heading;

  const Navbar({this.heading});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final TextEditingController addressController = TextEditingController();
  @override
  void initState() {
    super.initState();
    addressController.text = 'ws://' + url + ':' + port;
  }

  Widget connection_button(Function onclick, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ElevatedButton(
        child: Text(text),
        style: ElevatedButton.styleFrom(
          textStyle: MyFonts.medium.factor(1).setColor(text_color),
          fixedSize: Size(SizeConfig.horizontalBlockSize * 10,
              SizeConfig.verticalBlockSize * 5.5),
          primary: color,
        ),
        onPressed: onclick,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 2.5,
          vertical: SizeConfig.verticalBlockSize * 2.5),
      child: Form(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(widget.heading,
                style: MyFonts.medium.factor(2.5).setColor(text_color)),
            SizedBox(
              width: SizeConfig.horizontalBlockSize * 30,
            ),
            SizedBox(
              width: SizeConfig.horizontalBlockSize * 17,
              child: TextField(
                controller: addressController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: navbar_color,
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(
                      SizeConfig.horizontalBlockSize * 1,
                    ),
                  ),
                  hoverColor: navbar_color,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(
                      SizeConfig.horizontalBlockSize * 1,
                    ),
                  ),
                ),
              ),
            ),
            Consumer<RosProvider>(builder: (ctx, ros, _) {
              if (ros.ros != null) {
                if (ros.connected == ConnectionStatus.CONNECTED) {
                  return connection_button(() {
                    ros.disconnect();
                  }, 'Connected', Colors.green);
                } else if (ros.connected == ConnectionStatus.CONNECTING) {
                  return connection_button(
                      () => ros.initConnection(addressController.text),
                      'Connecting...',
                      Colors.greenAccent);
                } else if (ros.connected == ConnectionStatus.ERRORED) {
                  return connection_button(
                      null, 'Error connecting...', Colors.greenAccent);
                } else {
                  return connection_button(
                      () => ros.initConnection(addressController.text),
                      'Disconnected',
                      Colors.red);
                }
              } else {
                return connection_button(
                  () {
                    ros.initConnection(addressController.text);
                  },
                  'Connect',
                  Colors.green,
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
