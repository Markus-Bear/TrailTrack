import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/auth_form.dart';

/// Create an account. On success the user is signed in straight away and
/// returns to the map.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
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
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    final ok = await auth.register(
      displayName: _displayName.text,
      email: _email.text,
      password: _password.text,
    );
    if (ok && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: AuthForm(
        formKey: _formKey,
        children: [
          TextFormField(
            controller: _displayName,
            decoration: const InputDecoration(
              labelText: 'Display name',
              helperText: 'Shown to other walkers',
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            maxLength: 50,
            forceErrorText: auth.fieldErrors['displayName'],
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Display name is required'
                : null,
          ),
          EmailField(
            controller: _email,
            serverError: auth.fieldErrors['email'],
          ),
          PasswordField(
            controller: _password,
            serverError: auth.fieldErrors['password'],
            autofillHint: AutofillHints.newPassword,
            helperText: 'At least 8 characters',
            validator: (value) => (value ?? '').length < 8
                ? 'Password must be at least 8 characters'
                : null,
            onSubmitted: _submit,
          ),
          SubmitButton(
            label: 'Create account',
            busy: auth.busy,
            onPressed: _submit,
          ),
          if (auth.error != null && auth.fieldErrors.isEmpty)
            FormError(auth.error!),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
