import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';

class TileWidget extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final bool isCenter;
  final Color color;

  const TileWidget(
      {this.width, this.height, this.child, this.isCenter = true, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: isCenter ? Center(child: child) : child,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color ?? widget_bg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: const Color(0xFF000000),
            offset: Offset.zero,
            blurRadius: 5.0,
            spreadRadius: 2.0,
          )
        ],
      ),
    );
  }
}
