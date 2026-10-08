import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/map_overlays.dart';

/// Home screen: an OpenStreetMap base map centred on County Laois.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const _laois = LatLng(53.0, -7.4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(initialCenter: _laois, initialZoom: 9),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.github.markusbear.trailtrack',
          ),
          const AttributionBar(),
        ],
      ),
    );
  }
}
