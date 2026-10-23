import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/condition_report.dart';

/// Thrown when a condition report cannot be submitted.
class ReportApiException implements Exception {
  const ReportApiException(this.message, {this.sessionExpired = false});

  /// A message that can be shown to the user.
  final String message;

  /// Whether the login token was missing or expired, so the user must log
  /// in again before reporting.
  final bool sessionExpired;

  @override
  String toString() => 'ReportApiException: $message';
}

/// Client for submitting condition reports.
class ReportApi {
  /// @param baseUrl backend base URL, defaults to [apiBaseUrl]
  ReportApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Submits a report. Sending the same [clientRef] again returns the report
  /// already stored instead of creating a second one.
  ///
  /// @param trailId the trail the report is about
  /// @param token the user's login token
  /// @param severity ignored for clear reports
  /// @param clientRef a UUID made once per report, see [newClientRef]
  /// @return the stored report
  /// @throws ReportApiException if the report is rejected, the session has
  ///         expired, or the server cannot be reached
  Future<ConditionReport> submit({
    required int trailId,
    required String token,
    required ConditionType conditionType,
    required Severity? severity,
    required String? note,
    required String clientRef,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/trails/$trailId/reports'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'conditionType': conditionType.apiName,
              if (conditionType != ConditionType.clear)
                'severity': severity?.apiName,
              if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
              'clientRef': clientRef,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ReportApiException('No connection, try again.');
    }
    switch (response.statusCode) {
      case 200 || 201:
        return ConditionReport.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      case 401:
        throw const ReportApiException(
          'Your login has expired. Please log in again.',
          sessionExpired: true,
        );
      case 404:
        throw const ReportApiException('This trail is no longer available.');
      default:
        throw const ReportApiException(
          'The report could not be sent. Please try again.',
        );
    }
  }
}

/// A random version 4 UUID, used as a report's clientRef.
String newClientRef([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
