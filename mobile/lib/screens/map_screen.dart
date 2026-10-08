import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trail.dart';
import '../services/trail_api.dart';
import '../widgets/map_overlays.dart';

/// Home screen: an OpenStreetMap base map with every trail drawn on top.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.api});

  final TrailApi? api;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Centre of County Laois, used until the trails have loaded.
  static const _laois = LatLng(53.0, -7.4);

  static const _trailColour = Color(0xFF2E7D32);

  late final TrailApi _api = widget.api ?? TrailApi();
  final MapController _mapController = MapController();

  List<Trail> _trails = const [];
  bool _loading = true;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrails();
  }

  Future<void> _loadTrails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trails = await _api.fetchTrails();
      if (!mounted) return;
      setState(() {
        _trails = trails;
        _loading = false;
      });
      _fitToTrails();
    } on TrailApiException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load trails. Check your connection and try again.';
      });
    }
  }

  /// Zooms to show every trail. Waits until the map has been laid out, since
  /// fitting before then calculates the zoom from a zero-size view.
  void _fitToTrails() {
    if (!_mapReady) return;
    final points = [
      for (final t in _trails)
        for (final l in t.lines) ...l,
    ];
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _laois,
              initialZoom: 9,
              onMapReady: () {
                _mapReady = true;
                _fitToTrails();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.github.markusbear.trailtrack',
              ),
              PolylineLayer(
                polylines: [
                  for (final trail in _trails)
                    for (final line in trail.lines)
                      Polyline(
                        points: line,
                        strokeWidth: 4,
                        color: _trailColour,
                      ),
                ],
              ),
              const AttributionBar(),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ErrorBanner(message: _error!, onRetry: _loadTrails),
              ),
            ),
        ],
      ),
    );
  }
}
