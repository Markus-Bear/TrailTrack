import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/services/trail_api.dart';
import 'package:trailtrack/view_models/trail_detail_view_model.dart';

import '../helpers/fake_trail_detail.dart';

void main() {
  test('loading fetches the trail detail', () async {
    final model = TrailDetailViewModel(api: FakeDetailTrailApi(), trailId: 9);

    await model.load();

    expect(model.detail?.name, 'Glenbarrow - Waterfall Loop');
    expect(model.error, isNull);
    expect(model.loading, isFalse);
  });

  test('a trail that no longer exists is reported as not found', () async {
    final model = TrailDetailViewModel(
      api: FakeDetailTrailApi(
        error: const TrailApiException('No such trail', notFound: true),
      ),
      trailId: 999,
    );

    await model.load();

    expect(model.notFound, isTrue);
    expect(model.error, 'This trail is no longer available.');
  });

  test('a connection failure can be retried', () async {
    final api = FakeDetailTrailApi(error: const TrailApiException('offline'));
    final model = TrailDetailViewModel(api: api, trailId: 9);

    await model.load();
    expect(model.notFound, isFalse);
    expect(model.error, contains('Check your connection'));

    api.error = null;
    await model.load();
    expect(model.detail, isNotNull);
    expect(model.error, isNull);
  });
}
