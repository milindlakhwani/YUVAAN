import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';

class SyringePainter extends CustomPainter {
  final List<Offset> emptyPoints;
  final List<Offset> filledPoints;
  final double width;
  // final double height;

  SyringePainter({this.emptyPoints, this.filledPoints, this.width});

  final strokeWidth = SizeConfig.horizontalBlockSize * 2;

  @override
  void paint(Canvas canvas, Size size) {
    var base_plate = Paint()
      ..color = kWhite.withOpacity(0.8)
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 50;
    var emptyPaint = Paint()
      ..color = widget_bg
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    ;
    var filledPaint = Paint()
      ..color = Color.fromARGB(255, 109, 160, 175)
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset.zero, (width / 2) - 10, base_plate);

    //draw points on canvas
    canvas.drawPoints(PointMode.points, emptyPoints, emptyPaint);
    canvas.drawPoints(PointMode.points, filledPoints, filledPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}








// import 'package:flutter/material.dart';
// import 'package:yuvaan_gui/globals/sizeConfig.dart';

// class BeakerPainter extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     Widget bigCircle = new Container(
//       width: SizeConfig.horizontalBlockSize * 19,
//       height: SizeConfig.verticalBlockSize * 39,
//       decoration: new BoxDecoration(
//         color: Colors.orange,
//         shape: BoxShape.circle,
//       ),
//     );

//     return new Material(
//       color: Colors.transparent,
//       child: new Center(
//         child: new Stack(
//           children: <Widget>[
//             bigCircle,
//             Positioned(
//               child: new CircleButton(
//                   onTap: () => print("Cool"), iconData: Icons.favorite_border),
//               top: 10.0,
//               left: (SizeConfig.horizontalBlockSize * 15.5) / 2,
//             ),
//             Positioned(
//               child: new CircleButton(
//                   onTap: () => print("Cool"), iconData: Icons.add),
//               bottom: 10.0,
//               left: (SizeConfig.horizontalBlockSize * 15.5) / 2,
//             ),
//             Positioned(
//               child: new CircleButton(
//                   onTap: () => print("Cool"),
//                   iconData: Icons.remove_from_queue_outlined),
//               left: 10.0,
//               top: (SizeConfig.verticalBlockSize * 32) / 2,
//             ),
//             Positioned(
//               child: new CircleButton(
//                   onTap: () => print("Cool"),
//                   iconData: Icons.replay_10_rounded),
//               right: 10.0,
//               top: (SizeConfig.verticalBlockSize * 32) / 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class CircleButton extends StatelessWidget {
//   final GestureTapCallback onTap;
//   final IconData iconData;

//   const CircleButton({Key key, this.onTap, this.iconData}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     double size = 50.0;

//     return new InkResponse(
//       onTap: onTap,
//       child: new Container(
//         width: size,
//         height: size,
//         decoration: new BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//         ),
//         child: new Icon(
//           iconData,
//           color: Colors.black,
//         ),
//       ),
//     );
//   }
// }
