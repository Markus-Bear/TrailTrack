import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/services/location_service.dart';
import 'package:trailtrack/view_models/search_view_model.dart';

import '../helpers/fake_search.dart';

SearchViewModel _model(FakeSearchTrailApi api, [LocationService? location]) =>
    SearchViewModel(
      api: api,
      location:
          location ??
          FakeLocationService(const LocationFound(glenbarrowCarPark)),
      typingDelay: Duration.zero,
    );

void main() {
  test('the first search lists trails by name, without a position', () async {
    final api = FakeSearchTrailApi();
    final model = _model(api);

    await model.search();

    expect(model.results.single.name, 'Glenbarrow - Waterfall Loop');
    expect(api.searches.single.near, isNull);
  });

  test('typing searches once the user pauses', () async {
    final api = FakeSearchTrailApi();
    final model = _model(api);

    model.setQuery('gle');
    model.setQuery('glen');
    await Future<void>.delayed(Duration.zero);

    expect(api.searches, hasLength(1));
    expect(api.searches.single.query, 'glen');
  });

  test('near me sends the position and the chosen radius', () async {
    final api = FakeSearchTrailApi();
    final model = _model(api);

    await model.setNearMe(true);
    await model.setRadius(25);

    expect(model.nearMe, isTrue);
    expect(model.resultsAreNearby, isTrue);
    expect(api.searches.last.near, glenbarrowCarPark);
    expect(api.searches.last.radiusKm, 25);
  });

  test(
    'with location refused, near me turns off and the search is by name',
    () async {
      final api = FakeSearchTrailApi();
      final model = _model(
        api,
        FakeLocationService(
          const LocationUnavailable('Location permission was not given.'),
        ),
      );

      await model.setNearMe(true);

      expect(model.nearMe, isFalse);
      expect(
        model.locationMessage,
        'Location permission was not given. Searching by name only.',
      );
      expect(api.searches.last.near, isNull);
      expect(model.results, isNotEmpty);
      expect(model.resultsAreNearby, isFalse);
    },
  );

  test('turning near me off forgets the position', () async {
    final api = FakeSearchTrailApi();
    final model = _model(api);

    await model.setNearMe(true);
    await model.setNearMe(false);

    expect(api.searches.last.near, isNull);
  });

  test('a slow older search does not replace newer results', () async {
    final api = FakeSearchTrailApi([searchResult(1, 'Old result')]);
    final model = _model(api);

    api.hold = Completer<void>();
    final older = model.search();
    api.results = [searchResult(2, 'New result')];
    final newer = model.search();
    api.hold!.complete();
    await Future.wait([older, newer]);

    expect(model.results.single.name, 'New result');
  });
}
