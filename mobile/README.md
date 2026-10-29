# TrailTrack app

The Flutter Android app for TrailTrack: trail conditions and community walks
for Ireland.

## Structure

| Folder | Contents |
|---|---|
| `lib/models` | Data classes parsed from the backend's JSON |
| `lib/services` | Backend API clients, the saved login session and the phone's location |
| `lib/view_models` | Screen state and logic (MVVM, with `provider`) |
| `lib/screens` | One file per screen |
| `lib/widgets` | Widgets shared between screens, and the map's overlays and route styles |

The map screen keeps its own state for now; newer screens use a view model.

See the [main README](../README.md) for setup, running the app and the
backend API.
