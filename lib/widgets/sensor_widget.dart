import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/mySpaces.dart';

class SensorWidget extends StatelessWidget {
  final String heading;
  final double avg;
  final double min;
  final double max;
  final double current;
  final String unit;

  const SensorWidget({
    @required this.heading,
    @required this.avg,
    @required this.min,
    @required this.max,
    @required this.current,
    @required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: MyFonts.medium.factor(1.5).setColor(
                  kWhite.withOpacity(0.6),
                ),
          ),
          // MySpaces.vSmallGapInBetween,
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CircleAvatar(
                  backgroundColor: selected_color,
                  child: Icon(
                    CupertinoIcons.arrow_right_circle,
                    color: Colors.green,
                  ),
                ),
              ),
              MySpaces.hSmallGapInBetween,
              Text(
                current.toString() + ' ' + unit,
                style: MyFonts.medium
                    .factor(3)
                    .setColor(Colors.lightBlueAccent[100]),
              ),
            ],
          ),
          Text(
            "Avg : $avg $unit",
            style: MyFonts.medium.setColor(Colors.blue).factor(1.25),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Max : $max $unit",
                style: MyFonts.medium.setColor(Colors.green),
              ),
              Spacer(),
              Text(
                "Min : $min $unit",
                style: MyFonts.medium.setColor(Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
