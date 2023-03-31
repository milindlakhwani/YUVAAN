import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/models/lidar_data.dart';
import 'package:yuvaan_gui/widgets/open_painter.dart';

class Lidar extends StatelessWidget {
  final LidarData lidar_data;

  const Lidar({this.lidar_data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: SizeConfig.verticalBlockSize * 30,
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/top.png',
                  height: SizeConfig.verticalBlockSize * 3,
                ),
              ),
              Center(
                child: CustomPaint(
                  painter: OpenPainter(allCords: lidar_data.allCords),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: SizeConfig.verticalBlockSize * 6,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Front Proximity : ${lidar_data.frontDist.toStringAsFixed(2)} m",
                    style: MyFonts.medium.setColor(text_color).factor(0.7),
                  ),
                  Text(
                    "${lidar_data.frontDist <= 1 ? "Damger" : "Safe"} (dist < 1m)",
                    style: MyFonts.medium.setColor(text_color).factor(0.6),
                  ),
                ],
              ),
              SizedBox(
                height: SizeConfig.verticalBlockSize * 1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Back Proximity : ${lidar_data.backDist.toStringAsFixed(2)} m",
                    style: MyFonts.medium.setColor(text_color).factor(0.7),
                  ),
                  Text(
                    "${lidar_data.backDist <= 1 ? "Damger" : "Safe"} (dist < 1m)",
                    style: MyFonts.medium.setColor(text_color).factor(0.6),
                  ),
                ],
              ),
            ],
          ),
          decoration: BoxDecoration(color: Colors.amber),
        )
      ],
    );
  }
}
