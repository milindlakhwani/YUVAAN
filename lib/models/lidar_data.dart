import 'package:flutter/widgets.dart';

class LidarData {
  List<Offset> allCords;
  double frontDist;
  double backDist;

  LidarData({
    this.allCords,
    this.frontDist,
    this.backDist,
  });
}
