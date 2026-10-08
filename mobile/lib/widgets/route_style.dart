import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../models/trail_site.dart';

/// Neutral colours for routes whose sign colour is not recorded, so routes at
/// the same site can still be told apart without implying a sign colour.
const _fallbackColours = [
  Color(0xFF455A64),
  Color(0xFF6D4C41),
  Color(0xFF00838F),
];

/// Line colour for a route: the colour of its trail signs, or a neutral
/// fallback that differs from the site's other unrecorded routes.
///
/// @param trail the route
/// @param site the site the route belongs to
/// @return the colour to draw the route in
Color routeColour(Trail trail, TrailSite site) => switch (trail.waymarkColour) {
  WaymarkColour.green => const Color(0xFF2E7D32),
  WaymarkColour.blue => const Color(0xFF1565C0),
  WaymarkColour.red => const Color(0xFFC62828),
  WaymarkColour.purple => const Color(0xFF6A1B9A),
  WaymarkColour.orange => const Color(0xFFEF6C00),
  WaymarkColour.yellow => const Color(0xFFFBC02D),
  WaymarkColour.unknown => _fallbackColour(trail, site),
};

Color _fallbackColour(Trail trail, TrailSite site) {
  final unrecorded = site.routes
      .where((r) => r.waymarkColour == WaymarkColour.unknown)
      .toList();
  return _fallbackColours[unrecorded.indexOf(trail) % _fallbackColours.length];
}

/// National Waymarked Ways use a yellow arrow on black, so they are drawn
/// yellow with a black edge.
bool isNationalWay(Trail trail) => trail.waymarkColour == WaymarkColour.yellow;

/// One-line summary of a route, e.g. "Moderate | 2.8 km".
String routeSummary(Trail trail) => [
  trail.difficulty.label,
  if (trail.lengthKm != null) '${trail.lengthKm!.toStringAsFixed(1)} km',
].join(' | ');
