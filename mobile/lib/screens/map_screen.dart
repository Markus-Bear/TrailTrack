import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trail.dart';
import '../services/trail_api.dart';
import '../widgets/difficulty_style.dart';
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

  late final TrailApi _api = widget.api ?? TrailApi();
  final MapController _mapController = MapController();
  final LayerHitNotifier<Trail> _hitNotifier = ValueNotifier(null);

  List<Trail> _trails = const [];
  Trail? _selected;
  bool _loading = true;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrails();
  }

  @override
  void dispose() {
    _hitNotifier.dispose();
    super.dispose();
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
        _selected = null;
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

  void _onTrailTapped() {
    final hit = _hitNotifier.value;
    if (hit == null || hit.hitValues.isEmpty) return;
    setState(() => _selected = hit.hitValues.first);
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
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.github.markusbear.trailtrack',
              ),
              GestureDetector(
                onTap: _onTrailTapped,
                child: PolylineLayer<Trail>(
                  hitNotifier: _hitNotifier,
                  polylines: _buildPolylines(),
                ),
              ),
              const AttributionBar(),
            ],
          ),
          if (_trails.isNotEmpty)
            const Align(
              alignment: Alignment.topLeft,
              child: DifficultyLegend(),
            ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ErrorBanner(message: _error!, onRetry: _loadTrails),
              ),
            ),
          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: TrailCard(trail: _selected!),
            ),
        ],
      ),
    );
  }

  /// One polyline per trail section, coloured and patterned by difficulty.
  /// When a trail is selected it is drawn
  /// wider and last, so it sits on top of any trail it overlaps, and the
  /// other trails fade.
  List<Polyline<Trail>> _buildPolylines() {
    final selected = _selected;
    final ordered = [
      for (final t in _trails)
        if (t != selected) t,
      ?selected,
    ];
    return [
      for (final trail in ordered)
        for (final line in trail.lines)
          Polyline<Trail>(
            points: line,
            hitValue: trail,
            strokeWidth: trail == selected ? 7 : 4,
            pattern: difficultyPattern(trail.difficulty),
            color: difficultyColour(trail.difficulty).withValues(
              alpha: selected == null || trail == selected ? 1 : 0.35,
            ),
          ),
    ];
  }
}
