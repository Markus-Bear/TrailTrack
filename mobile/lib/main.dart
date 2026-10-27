import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/auth_api.dart';
import 'services/session_store.dart';
import 'view_models/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthViewModel(api: AuthApi(), store: SecureSessionStore());
  // Restored before the first frame, so a logged-in user never briefly
  // sees the guest "Log in" button.
  await auth.restore();
  runApp(TrailTrackApp(auth: auth));
}

/// Root of the TrailTrack app: its title, colour theme and home screen, with
/// the login state available to every screen.
class TrailTrackApp extends StatelessWidget {
  const TrailTrackApp({super.key, required this.auth});

  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        title: 'TrailTrack',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32)),
        home: const HomeScreen(),
      ),
    );
  }
}
