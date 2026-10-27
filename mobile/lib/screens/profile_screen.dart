import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// The Profile tab: the account's name and email with Log out, or, for
/// guests, buttons to log in or create an account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onLoggedOut});

  /// Called after logging out, e.g. to return to the map.
  final VoidCallback? onLoggedOut;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user == null) ...[
            Text('You are browsing as a guest', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Log in to report trail conditions. You can read every report '
              'without an account.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _open(context, const LoginScreen()),
              child: const Text('Log in'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _open(context, const RegisterScreen()),
              child: const Text('Create account'),
            ),
          ] else ...[
            Center(
              child: CircleAvatar(
                radius: 36,
                child: Text(
                  user.displayName.characters.first.toUpperCase(),
                  style: text.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              user.email,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                onLoggedOut?.call();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
