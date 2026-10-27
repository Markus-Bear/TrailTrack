import 'package:latlong2/latlong.dart';

import 'trail.dart';

/// A place where one or more routes start from the same trailhead, e.g.
/// Oughaval Woods with its three loop walks.
class TrailSite {
  TrailSite({required this.id, required this.name, required this.routes});

  final String id;
  final String name;

  /// The site's routes, longest first.
  final List<Trail> routes;

  /// Whether the site has more than one route to choose between.
  bool get hasSeveralRoutes => routes.length > 1;

  /// Where the site is shown on the map: the official trailhead, or the
  /// start of the first route if none is recorded.
  LatLng get location =>
      routes.first.trailhead ?? routes.first.lines.first.first;

  /// Every point of every route, for fitting the map to the site.
  List<LatLng> get allPoints => [
    for (final r in routes)
      for (final l in r.lines) ...l,
  ];

  /// Groups trails into sites by their site id, keeping first-seen order.
  ///
  /// @param trails the trails to group
  /// @return one site per distinct site id
  static List<TrailSite> group(List<Trail> trails) {
    final bySite = <String, List<Trail>>{};
    for (final t in trails) {
      bySite.putIfAbsent(t.siteId, () => []).add(t);
    }
    return [
      for (final entry in bySite.entries)
        TrailSite(
          id: entry.key,
          name: entry.value.first.siteName,
          routes: [...entry.value]
            ..sort((a, b) => (b.lengthKm ?? 0).compareTo(a.lengthKm ?? 0)),
        ),
    ];
  }
}
