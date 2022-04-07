import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/widgets/camera_feed.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';

class Manipulator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.horizontalBlockSize * 2,
          vertical: SizeConfig.verticalBlockSize * 2),
      child: Row(
        children: [
          Column(
            children: [
              CameraFeed(),
              SizedBox(
                height: SizeConfig.verticalBlockSize * 40,
                child: CameraFeed(
                  height: SizeConfig.verticalBlockSize * 34,
                  topicName: 'arm_camera',
                  altText: "Arm camera feed not enabled",
                ),
              ),
            ],
          ),
          Column(
            children: [
              TileWidget(
                width: SizeConfig.horizontalBlockSize * 48,
                height: SizeConfig.verticalBlockSize * 40,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Image.asset('assets/images/arm.png'),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 23,
                    height: SizeConfig.verticalBlockSize * 37,
                  ),
                  TileWidget(
                    width: SizeConfig.horizontalBlockSize * 23,
                    height: SizeConfig.verticalBlockSize * 37,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
