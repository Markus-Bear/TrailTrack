import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/services/report_api.dart';

ReportApi _apiAnswering(int status, {List<http.Request>? sent}) => ReportApi(
  baseUrl: 'http://backend',
  client: MockClient((request) async {
    sent?.add(request);
    return http.Response(
      jsonEncode({
        'id': 50,
        'conditionType': 'MUD',
        'severity': 'HIGH',
        'reportedAt': '2026-10-23T10:00:00Z',
      }),
      status,
    );
  }),
);

Future<ReportApiException> _errorFrom(Future<void> call) async {
  try {
    await call;
  } on ReportApiException catch (e) {
    return e;
  }
  fail('Expected ReportApiException');
}

Future<ConditionReport> _submitMud(ReportApi api, {String? note}) => api.submit(
  trailId: 9,
  token: 'signed-token',
  conditionType: ConditionType.mud,
  severity: Severity.high,
  note: note,
  clientRef: 'ref-1',
);

void main() {
  test('submit posts the report with the login token', () async {
    final sent = <http.Request>[];
    final report = await _submitMud(
      _apiAnswering(201, sent: sent),
      note: ' Deep mud ',
    );

    final request = sent.single;
    expect(request.url.toString(), 'http://backend/api/trails/9/reports');
    expect(request.headers['Authorization'], 'Bearer signed-token');
    expect(jsonDecode(request.body), {
      'conditionType': 'MUD',
      'severity': 'HIGH',
      'note': 'Deep mud',
      'clientRef': 'ref-1',
    });
    expect(report.id, 50);
  });

  test('a clear report is sent without a severity', () async {
    final sent = <http.Request>[];
    await _apiAnswering(201, sent: sent).submit(
      trailId: 9,
      token: 'signed-token',
      conditionType: ConditionType.clear,
      severity: Severity.moderate,
      note: null,
      clientRef: 'ref-2',
    );

    expect(jsonDecode(sent.single.body), {
      'conditionType': 'CLEAR',
      'clientRef': 'ref-2',
    });
  });

  test('a retried report already stored (200) counts as sent', () async {
    final report = await _submitMud(_apiAnswering(200));
    expect(report.conditionType, ConditionType.mud);
  });

  test('an expired login is reported as a session problem', () async {
    final error = await _errorFrom(_submitMud(_apiAnswering(401)));
    expect(error.sessionExpired, isTrue);
  });

  test('no connection asks the user to try again', () async {
    final api = ReportApi(
      baseUrl: 'http://backend',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    final error = await _errorFrom(_submitMud(api));

    expect(error.message, 'No connection, try again.');
    expect(error.sessionExpired, isFalse);
  });

  test('newClientRef makes distinct version 4 UUIDs', () {
    final a = newClientRef();
    final b = newClientRef();

    expect(
      a,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(a, isNot(b));
  });
}
