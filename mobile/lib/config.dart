/// Base URL of the TrailTrack backend.
///
/// Defaults to the host machine as seen from the Android emulator. Override
/// with `flutter run --dart-define=API_BASE_URL=http://<host>:8080`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
