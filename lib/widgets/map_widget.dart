import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/providers/home_control_provider.dart';
// import 'package:latlong/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng marker;

  const MapWidget({this.marker});
  @override
  Widget build(BuildContext context) {
    final homeControlProvider =
        Provider.of<HomeControlProvider>(context, listen: false);
    return FlutterMap(
      options: MapOptions(
        maxZoom: 18.25,
        minZoom: 14.0,
        center: marker,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              point: (homeControlProvider.gps_marker == null)
                  ? LatLng(0.0, 0.0)
                  : homeControlProvider.gps_marker,
              builder: (ctx) {
                return Container(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: SizeConfig.horizontalBlockSize * 2,
                  ),
                );
              },
            ),
            Marker(
              point: marker,
              builder: (ctx) {
                return Container(
                  child: Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: SizeConfig.horizontalBlockSize * 2,
                  ),
                );
              },
            )
          ],
        ),
        // PolylineLayerOptions(polylines: [
        //   Polyline(
        //     color: kBlue,
        //     points: [
        //       LatLng(26.192733429350856, 91.69907713743616),
        //       LatLng(26.18632286499923, 91.69900156563799),
        //       // LatLng(25.1879, 91.6917),
        //     ],
        //   )
        // ]),
      ],
    );
  }
}
