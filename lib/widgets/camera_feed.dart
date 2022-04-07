import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';
import 'package:yuvaan_gui/config/config.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/widgets/tile_widget.dart';

// ignore: must_be_immutable
class CameraFeed extends StatelessWidget {
  final String topicName;
  final String altText;
  final double height;

  CameraFeed({
    this.topicName = "usb_cam",
    this.altText = "Live feed not enabled",
    this.height,
  });

  WebViewXController webviewController;

  String get initialContent {
    return '''<img src= "${"http://" + url + ":8080/stream?topic=/" + topicName + "/image_raw&type=mjpeg&quality=80"}" width=${SizeConfig.horizontalBlockSize * 38} height=${height ?? SizeConfig.verticalBlockSize * 36} alt="${"Ummffffff....... " + altText}" style="color: #FFFFFF;font-weght: bolder;
  font-size:20px;">''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TileWidget(
          isCenter: true,
          width: SizeConfig.horizontalBlockSize * 40,
          height: SizeConfig.verticalBlockSize * 40,
          child: WebViewX(
            initialContent: initialContent,
            initialSourceType: SourceType.html,
            onWebViewCreated: (controller) => webviewController = controller,
            width: SizeConfig.horizontalBlockSize * 39,
            height: SizeConfig.verticalBlockSize * 39,
          ),
        ),
        Positioned(
          right: 5,
          child: Container(
            margin: const EdgeInsets.all(15),
            child: IconButton(
              padding: const EdgeInsets.all(2),
              onPressed: () {
                webviewController.reload();
              },
              icon: Icon(Icons.refresh),
            ),
            decoration: BoxDecoration(
              color: kBlue,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
