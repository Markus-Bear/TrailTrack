import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trail_search_result.dart';
import '../services/location_service.dart';
import '../services/trail_api.dart';
import '../view_models/search_view_model.dart';
import 'trail_detail_screen.dart';

/// Search trails by name, or near the phone's position with "Near me".
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.api, this.location});

  final TrailApi? api;
  final LocationService? location;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(
        api: api ?? TrailApi(),
        location: location ?? const DeviceLocationService(),
      )..search(),
      child: _SearchView(api: api),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView({this.api});

  final TrailApi? api;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SearchViewModel>();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Search trails')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: model.setQuery,
            onSubmitted: (_) => model.search(),
            decoration: const InputDecoration(
              hintText: 'Search by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Near me'),
            subtitle: const Text('Uses your location'),
            value: model.nearMe,
            onChanged: model.setNearMe,
          ),
          if (model.locationMessage != null)
            Text(
              model.locationMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (model.nearMe)
            Wrap(
              spacing: 8,
              children: [
                for (final km in SearchViewModel.radiusOptions)
                  ChoiceChip(
                    label: Text('${km.round()} km'),
                    selected: model.radiusKm == km,
                    onSelected: (_) => model.setRadius(km),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          // Shown over the previous results while a new search runs.
          if (model.loading && model.results.isNotEmpty)
            const LinearProgressIndicator(),
          if (model.loading && model.results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (model.error != null)
            _Message(message: model.error!, onRetry: model.search)
          else if (model.results.isEmpty)
            _Message(
              message: model.nearMe
                  ? 'No trails found. Try a wider radius.'
                  : 'No trails found.',
            )
          else ...[
            Text(
              '${model.results.length} '
              '${model.results.length == 1 ? 'trail' : 'trails'}, '
              '${model.resultsAreNearby ? 'nearest first' : 'A to Z'}',
              style: text.bodySmall,
            ),
            for (final result in model.results)
              _ResultRow(
                result: result,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrailDetailScreen(
                      trailId: result.id,
                      trailName: result.name,
                      api: api,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.onTap});

  final TrailSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = result.latestReport;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(result.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.summary),
          const SizedBox(height: 4),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(latest == null ? 'No recent reports' : latest.summary),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
