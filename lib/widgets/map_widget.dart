import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:latlong/latlong.dart';

class MapWidget extends StatelessWidget {
  final LatLng marker;

  const MapWidget({this.marker});
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        minZoom: 15.0,
        center: LatLng(26.1878, 91.6916),
      ),
      layers: [
        TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']),
        MarkerLayerOptions(markers: [
          Marker(
            point: marker,
            // point: LatLng(26.1878, 91.6916),
            builder: (ctx) {
              return Container(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
              );
            },
          )
        ]),
      ],
    );
  }
}
