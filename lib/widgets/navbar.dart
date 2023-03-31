import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/config/config.dart';
import 'package:yuvaan_gui/enum/connection_status.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/mySpaces.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/models/sensor_data.dart';
import 'package:yuvaan_gui/providers/bioassembly_provider.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/providers/manipulator_provider.dart';
import 'package:yuvaan_gui/providers/ros_provider.dart';
import 'package:yuvaan_gui/screens/home_control.dart';
import 'package:latlong2/latlong.dart';

class Navbar extends StatefulWidget {
  final String heading;

  const Navbar({this.heading});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final TextEditingController addressController = TextEditingController();
  bool manipulatorInitialised = false;
  bool isLoading = false;

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

  void importCSV() async {
    //Pick file
    FilePickerResult csvFile = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
      allowMultiple: false,
    );
    if (csvFile != null) {
      final String name = csvFile.files[0].name;
      final List<String> cord_string = name.split('_');
      final LatLng cord =
          LatLng(double.parse(cord_string[0]), double.parse(cord_string[1]));

      //decode bytes back to utf8
      final bytes = utf8.decode(csvFile.files[0].bytes);
      //from the csv plugin
      List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter().convert(bytes);
      final bioassemblyProvider =
          Provider.of<BioassemblyProvider>(context, listen: false);
      final homeControlProvider =
          Provider.of<HomeControlProvider>(context, listen: false);
      homeControlProvider.setCord(cord);
      rowsAsListOfValues.removeAt(0);

      List<SensorData> sensorData = [];
      rowsAsListOfValues.forEach((element) {
        sensorData.add(SensorData.fromList(element));
      });
      bioassemblyProvider.populateSensorData(sensorData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manipulatorProvider = Provider.of<ManipulatorProvider>(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.horizontalBlockSize * 2.5,
        vertical: SizeConfig.verticalBlockSize * 2.25,
      ),
      child: Form(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            (widget.heading == "Home")
                ? TextButton(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        // manipulatorProvider.manipulatorIntialised
                        //     ? 'Manipulator'
                        //     : 'Start Manipulator',
                        isLoading
                            ? 'Initialising'
                            : manipulatorInitialised
                                ? 'Manipulator'
                                : 'Start Manipulator',
                        style: MyFonts.medium.factor(1.5).setColor(text_color),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      primary: Colors.white,
                      backgroundColor: manipulatorInitialised
                          ? widget_bg.withOpacity(0.4)
                          : null,
                      onSurface: Colors.grey,
                    ),
                    onPressed: () async {
                      final manipulatorProvider =
                          Provider.of<ManipulatorProvider>(context,
                              listen: false);
                      if (!manipulatorInitialised) {
                        setState(() {
                          isLoading = true;
                        });
                        if (manipulatorProvider.connectionStatus ==
                            ConnectionStatus.CONNECTED) {
                          await Provider.of<ManipulatorProvider>(context,
                                  listen: false)
                              .initTopics();
                          manipulatorProvider.changeStatus();
                          setState(() {
                            manipulatorInitialised = true;
                            isLoading = false;
                          });
                        }
                      } else {
                        await manipulatorProvider.clearTopics();
                        setState(() {
                          manipulatorInitialised = false;
                        });
                      }
                    },
                  )
                : widget.heading != "Sensors"
                    ? Text(
                        widget.heading,
                        style: MyFonts.medium.factor(2.5).setColor(text_color),
                      )
                    : TextButton(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'Load CSV',
                            style:
                                MyFonts.medium.factor(1.5).setColor(text_color),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: const BeveledRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          primary: Colors.white,
                          backgroundColor: widget_bg.withOpacity(0.4),
                          onSurface: Colors.grey,
                        ),
                        onPressed: importCSV,
                      ),
            Row(
              children: [
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
                MySpaces.hLargeGapInBetween,
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
          ],
        ),
      ),
    );
  }
}
