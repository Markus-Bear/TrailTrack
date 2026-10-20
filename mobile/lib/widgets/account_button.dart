import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_screen.dart';
import '../view_models/auth_view_model.dart';

enum _AccountAction { logOut }

/// Map button for the account: "Log in" for guests, or the user's initial
/// with a menu to log out once logged in.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    if (user == null) {
      return FilledButton.tonalIcon(
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        icon: const Icon(Icons.person_outline),
        label: const Text('Log in'),
      );
    }
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account',
      onSelected: (_) => auth.logout(),
      itemBuilder: (_) => [
        PopupMenuItem<_AccountAction>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            // The item cannot be tapped, which would otherwise grey it out.
            title: Text(
              user.displayName,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(user.email),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _AccountAction.logOut,
          child: Text('Log out'),
        ),
      ],
      child: CircleAvatar(
        child: Text(user.displayName.characters.first.toUpperCase()),
      ),
    );
  }
}
