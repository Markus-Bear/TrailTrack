import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trail.dart';
import '../models/trail_site.dart';
import '../services/trail_api.dart';
import '../widgets/account_button.dart';
import '../widgets/map_overlays.dart';
import '../widgets/route_style.dart';

/// Home screen: an OpenStreetMap base map with every trail drawn on top.
///
/// Routes are drawn in the colour of their trail signs. Routes that share a
/// trailhead form a site, shown as a numbered pin when zoomed out. Tapping a
/// pin selects the site; tapping a route selects it, asking which route was
/// meant when several share the path. Tapping elsewhere clears the selection.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.api});

  final TrailApi? api;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Centre of County Laois, used until the trails have loaded.
  static const _laois = LatLng(53.0, -7.4);

  /// Zoom from which individual routes are drawn at full width and site
  /// pins are hidden.
  static const _detailZoom = 12.5;

  late final TrailApi _api = widget.api ?? TrailApi();
  final MapController _mapController = MapController();
  final LayerHitNotifier<Trail> _hitNotifier = ValueNotifier(null);

  List<Trail> _trails = const [];
  List<TrailSite> _sites = const [];
  Map<String, TrailSite> _siteById = const {};
  TrailSite? _selectedSite;
  Trail? _selectedTrail;
  bool _loading = true;
  bool _mapReady = false;
  bool _zoomedIn = false;
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
      final sites = TrailSite.group(trails);
      setState(() {
        _trails = trails;
        _sites = sites;
        _siteById = {for (final s in sites) s.id: s};
        _selectedSite = null;
        _selectedTrail = null;
        _loading = false;
      });
      _fitTo(_allPoints());
    } on TrailApiException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load trails. Check your connection and try again.';
      });
    }
  }

  List<LatLng> _allPoints() => [
    for (final t in _trails)
      for (final l in t.lines) ...l,
  ];

  /// Zooms to show the given points, leaving room for the legend and the
  /// bottom card. Waits until the map has been laid out, since fitting before
  /// then calculates the zoom from a zero-size view.
  void _fitTo(List<LatLng> points) {
    if (!_mapReady || points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 110, 40, 220),
      ),
    );
  }

  TrailSite _siteOf(Trail trail) => _siteById[trail.siteId]!;

  void _selectSite(TrailSite site) {
    setState(() {
      _selectedSite = site;
      _selectedTrail = site.hasSeveralRoutes ? null : site.routes.single;
    });
    _fitTo(site.allPoints);
  }

  void _selectTrail(Trail trail) {
    setState(() {
      _selectedSite = _siteOf(trail);
      _selectedTrail = trail;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSite = null;
      _selectedTrail = null;
    });
  }

  Future<void> _onRouteTapped() async {
    final hit = _hitNotifier.value;
    if (hit == null || hit.hitValues.isEmpty) return;
    // A route split into several sections can be hit more than once.
    final routes = hit.hitValues.toSet().toList();
    if (routes.length == 1) {
      _selectTrail(routes.single);
      return;
    }
    final chosen = await chooseRoute(context, routes, _siteOf);
    if (chosen != null && mounted) _selectTrail(chosen);
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
                _fitTo(_allPoints());
              },
              onPositionChanged: (camera, _) {
                final zoomedIn = camera.zoom >= _detailZoom;
                if (zoomedIn != _zoomedIn) setState(() => _zoomedIn = zoomedIn);
              },
              onTap: (_, _) => _clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.github.markusbear.trailtrack',
              ),
              GestureDetector(
                onTap: _onRouteTapped,
                child: PolylineLayer<Trail>(
                  hitNotifier: _hitNotifier,
                  polylines: _buildPolylines(),
                ),
              ),
              if (!_zoomedIn && _selectedSite == null)
                MarkerLayer(
                  markers: [
                    // National Waymarked Ways are already visible as long
                    // yellow lines, so they get no pin.
                    for (final site in _sites.where(
                      (s) => !isNationalWay(s.routes.first),
                    ))
                      Marker(
                        point: site.location,
                        width: 28,
                        height: 28,
                        child: SitePin(
                          site: site,
                          onTap: () => _selectSite(site),
                        ),
                      ),
                  ],
                ),
              const AttributionBar(),
            ],
          ),
          if (_trails.isNotEmpty)
            const Align(alignment: Alignment.topLeft, child: RouteLegend()),
          const SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: AccountButton(),
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                // Starts below the account button so the two never overlap.
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: ErrorBanner(message: _error!, onRetry: _loadTrails),
                ),
              ),
            ),
          if (_selectedSite != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SelectionCard(
                site: _selectedSite!,
                selected: _selectedTrail,
                onSelectRoute: _selectTrail,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the route lines. Within a site, longer routes are drawn first and
  /// wider, so where routes share a path each one stays visible as a band of
  /// its own colour.
  List<Polyline<Trail>> _buildPolylines() {
    final polylines = <Polyline<Trail>>[];
    final selectedSite = _selectedSite;
    final selectedTrail = _selectedTrail;
    final orderedSites = [
      for (final site in _sites)
        if (site != selectedSite) site,
      ?selectedSite,
    ];
    for (final site in orderedSites) {
      final routes = [
        for (final r in site.routes)
          if (r != selectedTrail) r,
        if (selectedTrail != null && selectedSite == site) selectedTrail,
      ];
      for (final trail in routes) {
        final bandWidth =
            3.0 * (site.routes.length - site.routes.indexOf(trail));
        final double width;
        final double opacity;
        if (trail == selectedTrail) {
          width = 7;
          opacity = 1;
        } else if (site == selectedSite) {
          width = bandWidth;
          opacity = selectedTrail == null ? 1 : 0.35;
        } else {
          width = _zoomedIn ? bandWidth : 2.5;
          opacity = selectedSite == null ? 1 : 0.2;
        }
        final national = isNationalWay(trail);
        for (final line in trail.lines) {
          polylines.add(
            Polyline<Trail>(
              points: line,
              hitValue: trail,
              strokeWidth: width,
              color: routeColour(trail, site).withValues(alpha: opacity),
              borderStrokeWidth: national ? 1.2 : 0,
              borderColor: Colors.black.withValues(alpha: opacity),
            ),
          );
        }
      }
    }
    return polylines;
  }
}
