import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailtrack/services/trail_api.dart';

void main() {
  const body = {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'id': 1,
        'properties': {
          'name': 'Waterfall Loop',
          'difficulty': 'Easy',
          'lengthKm': 2.0,
        },
        'geometry': {
          'type': 'MultiLineString',
          'coordinates': [
            [
              [-7.5, 53.1],
              [-7.6, 53.2],
            ],
          ],
        },
      },
    ],
  };

  test('fetchTrails calls /api/trails and parses the response', () async {
    late Uri requested;
    final api = TrailApi(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(jsonEncode(body), 200);
      }),
    );

    final trails = await api.fetchTrails();

    expect(requested.toString(), 'http://example.test/api/trails');
    expect(trails.single.name, 'Waterfall Loop');
  });

  test('fetchTrails throws TrailApiException on a server error', () {
    final api = TrailApi(
      baseUrl: 'http://example.test',
      client: MockClient((_) async => http.Response('oops', 500)),
    );
    expect(api.fetchTrails(), throwsA(isA<TrailApiException>()));
  });

  test(
    'fetchTrails throws TrailApiException when the server is unreachable',
    () {
      final api = TrailApi(
        baseUrl: 'http://example.test',
        client: MockClient((_) async => throw http.ClientException('no route')),
      );
      expect(api.fetchTrails(), throwsA(isA<TrailApiException>()));
    },
  );

  test(
    'fetchTrailDetail calls /api/trails/{id} and parses the detail',
    () async {
      Uri? requested;
      final api = TrailApi(
        baseUrl: 'http://backend',
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'id': 9,
              'name': 'Glenbarrow - Waterfall Loop',
              'difficulty': 'Moderate',
              'currentConditions': [],
              'recentReports': [],
            }),
            200,
          );
        }),
      );

      final detail = await api.fetchTrailDetail(9);

      expect(requested.toString(), 'http://backend/api/trails/9');
      expect(detail.name, 'Glenbarrow - Waterfall Loop');
    },
  );

  test('fetchTrailDetail reports a trail that does not exist', () async {
    final api = TrailApi(
      baseUrl: 'http://backend',
      client: MockClient((_) async => http.Response('{}', 404)),
    );

    expect(
      api.fetchTrailDetail(999),
      throwsA(
        isA<TrailApiException>().having((e) => e.notFound, 'notFound', true),
      ),
    );
  });
}
