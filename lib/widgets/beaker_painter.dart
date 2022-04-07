import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yuvaan_gui/globals/myColors.dart';

class BeakerPainter extends CustomPainter {
  final List<Offset> emptyPoints;
  final List<Offset> filledPoints;
  final double width;
  // final double height;

  BeakerPainter({this.emptyPoints, this.filledPoints, this.width});

  final strokeWidth = 60.0;

  final circle_offset_diagonal = 40;
  final circle_offset_corner = 50;

  @override
  void paint(Canvas canvas, Size size) {
    var base_plate = Paint()
      ..color = Color.fromRGBO(160, 20, 20, 1)
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = 50;
    var emptyPaint = Paint()
      ..color = kWhite
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    ;
    var filledPaint = Paint()
      ..color = Color.fromRGBO(124, 94, 66, 1)
      ..strokeCap = StrokeCap.round //rounded points
      ..strokeWidth = strokeWidth;

    //list of points
    // var points = [
    //   Offset(0, (width / 2) - circle_offset_corner),
    //   Offset(0, (-width / 2) + circle_offset_corner),
    //   Offset((-width / 2) + circle_offset_corner, 0),
    //   Offset((width / 2) - circle_offset_corner, 0),
    //   Offset((width / 2) - (circle_offset_diagonal * 2),
    //       (width / 2) - (circle_offset_diagonal * 2)),
    //   Offset((-width / 2) + (circle_offset_diagonal * 2),
    //       (-width / 2) + (circle_offset_diagonal * 2)),
    //   Offset((-width / 2) + (circle_offset_diagonal * 2),
    //       (width / 2) - (circle_offset_diagonal * 2)),
    //   Offset((width / 2) - (circle_offset_diagonal * 2),
    //       (-width / 2) + (circle_offset_diagonal * 2)),
    // ];
    // var points2 = [
    //   Offset((width / 2) - (circle_offset_diagonal * 2),
    //       (width / 2) - (circle_offset_diagonal * 2)),
    //   Offset((-width / 2) + (circle_offset_diagonal * 2),
    //       (-width / 2) + (circle_offset_diagonal * 2)),
    //   Offset((-width / 2) + (circle_offset_diagonal * 2),
    //       (width / 2) - (circle_offset_diagonal * 2)),
    //   Offset((width / 2) - (circle_offset_diagonal * 2),
    //       (-width / 2) + (circle_offset_diagonal * 2)),
    // ];

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
