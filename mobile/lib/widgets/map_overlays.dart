import 'package:flutter/material.dart';

import '../models/trail.dart';
import '../models/trail_site.dart';
import 'route_style.dart';

/// Required credits for the map tiles (ODbL) and trail data (CC BY 4.0).
class AttributionBar extends StatelessWidget {
  const AttributionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          color: Colors.white.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            '© OpenStreetMap contributors | Trail data: Sport Ireland (CC BY 4.0)',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

/// Error message with a Retry button.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Map pin for a site, showing how many routes start there.
class SitePin extends StatelessWidget {
  const SitePin({super.key, required this.site, required this.onTap});

  final TrailSite site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: Text(
          '${site.routes.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Bottom card for the selected site or route. Lists the site's routes as
/// chips so the user can switch between them.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.site,
    required this.selected,
    required this.onSelectRoute,
    this.onViewDetails,
  });

  final TrailSite site;

  /// The selected route, or null when the whole site is selected.
  final Trail? selected;
  final ValueChanged<Trail> onSelectRoute;

  /// Opens the selected route's detail page. No button is shown without it.
  final ValueChanged<Trail>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final route = selected;
    // The bottom margin keeps the attribution bar visible below the card.
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (route == null) ...[
                Text(site.name, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${site.routes.length} routes from this trailhead',
                  style: text.bodyMedium,
                ),
              ] else ...[
                if (site.hasSeveralRoutes)
                  Text(site.name, style: text.labelMedium),
                Text(route.shortName, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(routeSummary(route), style: text.bodyMedium),
              ],
              if (site.hasSeveralRoutes) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final r in site.routes)
                      ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: routeColour(r, site),
                          radius: 6,
                        ),
                        label: Text(r.shortName),
                        selected: r == route,
                        onSelected: (_) => onSelectRoute(r),
                      ),
                  ],
                ),
              ],
              if (route != null && onViewDetails != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => onViewDetails!(route),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('View details'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks which route was meant when a tap lands on a path shared by several.
///
/// @param routes the routes under the tap
/// @param siteOf finds a route's site, which its colour depends on
/// @return the chosen route, or null if dismissed
Future<Trail?> chooseRoute(
  BuildContext context,
  List<Trail> routes,
  TrailSite Function(Trail) siteOf,
) {
  return showModalBottomSheet<Trail>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Which route?')),
          for (final r in routes)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: routeColour(r, siteOf(r)),
                radius: 8,
              ),
              title: Text(r.shortName),
              subtitle: Text(routeSummary(r)),
              onTap: () => Navigator.pop(context, r),
            ),
        ],
      ),
    ),
  );
}

/// Explains the line colours: loop walks use the colour of their trail
/// signs, and National Waymarked Ways are yellow on black.
class RouteLegend extends StatelessWidget {
  const RouteLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget swatch(List<Color> colours, {bool edged = false}) => SizedBox(
      width: 28,
      height: 10,
      child: Row(
        children: [
          for (final c in colours)
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: c,
                  border: edged
                      ? Border.all(color: Colors.black, width: 1)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatch(const [
                    Color(0xFF2E7D32),
                    Color(0xFF1565C0),
                    Color(0xFFC62828),
                  ]),
                  const SizedBox(width: 8),
                  Text('Colour of the trail signs', style: style),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatch(const [Color(0xFFFBC02D)], edged: true),
                  const SizedBox(width: 8),
                  Text('National Waymarked Way', style: style),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
