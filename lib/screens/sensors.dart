import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/mySpaces.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/bioassembly_provider.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
import 'package:yuvaan_gui/widgets/map_widget.dart';
import 'package:yuvaan_gui/widgets/sensor_widget.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';
import 'package:latlong2/latlong.dart';

class Sensor extends StatefulWidget {
  @override
  State<Sensor> createState() => _SensorState();
}

class _SensorState extends State<Sensor> {
  @override
  Widget build(BuildContext context) {
    final bioassemblyProvider =
        Provider.of<BioassemblyProvider>(context, listen: false);
    final homeControlProvider =
        Provider.of<HomeControlProvider>(context, listen: false);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 1,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Column(
        children: [
          Row(
            children: [
              TileWidget(
                width: SizeConfig.horizontalBlockSize * 30,
                height: SizeConfig.verticalBlockSize * 25,
                child: Row(
                  children: [
                    SizedBox(
                      width: SizeConfig.horizontalBlockSize * 15,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: MapWidget(
                            marker:
                                homeControlProvider.gps_cord ?? LatLng(0, 0),
                          ),
                        ),
                      ),
                    ),
                    MySpaces.hGapInBetween,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Latitude : ",
                          style: MyFonts.medium.factor(1.25),
                        ),
                        // Text(
                        //   (homeControlProvider.gps_cord == null)
                        //       ? homeControlProvider.gps_cord.latitude.toString()
                        //       : 0,
                        //   style: MyFonts.light
                        //       .factor(1.25)
                        //       .setColor(kWhite.withOpacity(0.7)),
                        // ),
                        MySpaces.vGapInBetween,
                        Text(
                          "Longitude : ",
                          style: MyFonts.medium.factor(1.25),
                        ),
                        // Text(
                        //   (homeControlProvider.gps_cord == null)
                        //       ? homeControlProvider.gps_cord.longitude
                        //           .toString()
                        //       : 0,
                        //   style: MyFonts.light
                        //       .factor(1.25)
                        //       .setColor(kWhite.withOpacity(0.7)),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              TileWidget(
                height: SizeConfig.verticalBlockSize * 25,
                width: SizeConfig.horizontalBlockSize * 17,
                child: SensorWidget(
                  heading: "Temperature",
                  avg: bioassemblyProvider.avgValues.temperature,
                  min: bioassemblyProvider.minValues.temperature,
                  max: bioassemblyProvider.maxValues.temperature,
                  current: bioassemblyProvider.sensorReadings[0].temperature,
                  unit: "°C",
                ),
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 25,
                width: SizeConfig.horizontalBlockSize * 17,
                child: SensorWidget(
                  heading: "Pressure",
                  avg: bioassemblyProvider.avgValues.pressure,
                  min: bioassemblyProvider.minValues.pressure,
                  max: bioassemblyProvider.maxValues.pressure,
                  current: bioassemblyProvider.sensorReadings[0].pressure,
                  unit: "atm",
                ),
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 25,
                width: SizeConfig.horizontalBlockSize * 17,
                child: SensorWidget(
                  heading: "Humidity",
                  avg: bioassemblyProvider.avgValues.humidity,
                  min: bioassemblyProvider.minValues.humidity,
                  max: bioassemblyProvider.maxValues.humidity,
                  current: bioassemblyProvider.sensorReadings[0].humidity,
                  unit: "",
                ),
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 25,
                width: SizeConfig.horizontalBlockSize * 17,
                child: SensorWidget(
                  heading: "CO",
                  avg: bioassemblyProvider.avgValues.co,
                  min: bioassemblyProvider.minValues.co,
                  max: bioassemblyProvider.maxValues.co,
                  current: bioassemblyProvider.sensorReadings[0].co,
                  unit: "ppm",
                ),
              ),
              TileWidget(
                height: SizeConfig.verticalBlockSize * 25,
                width: SizeConfig.horizontalBlockSize * 17,
                child: SensorWidget(
                  heading: "CO2",
                  avg: bioassemblyProvider.avgValues.co2,
                  min: bioassemblyProvider.minValues.co2,
                  max: bioassemblyProvider.maxValues.co2,
                  current: bioassemblyProvider.sensorReadings[0].co2,
                  unit: "ppm",
                ),
              ),
            ],
          ),
          // Row(
          //   children: [
          //     TileWidget(
          //       height: SizeConfig.verticalBlockSize * 25,
          //       width: SizeConfig.horizontalBlockSize * 10,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
