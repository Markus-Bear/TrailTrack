import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/auth_form.dart';
import 'register_screen.dart';

/// Log in with an email and password. Never forced: "Continue as guest"
/// goes back to the map.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Errors from an earlier attempt belong to that attempt. Cleared after
    // the first frame, since listeners cannot be notified during a build.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthViewModel>().clearErrors(),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.login(email: _email.text, password: _password.text);
    if (ok && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: AuthForm(
        formKey: _formKey,
        children: [
          EmailField(
            controller: _email,
            serverError: auth.fieldErrors['email'],
          ),
          PasswordField(
            controller: _password,
            serverError: auth.fieldErrors['password'],
            autofillHint: AutofillHints.password,
            validator: (value) =>
                (value ?? '').isEmpty ? 'Password is required' : null,
            onSubmitted: _submit,
          ),
          SubmitButton(label: 'Log in', busy: auth.busy, onPressed: _submit),
          if (auth.error != null && auth.fieldErrors.isEmpty)
            FormError(auth.error!),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('Create an account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue as guest'),
          ),
        ],
      ),
    );
  }
}
