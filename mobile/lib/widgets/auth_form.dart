import 'package:flutter/material.dart';

/// Scrollable, padded form layout for the login and register screens.
class AuthForm extends StatelessWidget {
  const AuthForm({super.key, required this.formKey, required this.children});

  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Email field with the email keyboard and a basic format check.
class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller, this.serverError});

  final TextEditingController controller;

  /// The backend's message for this field from the last attempt, if any.
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      forceErrorText: serverError,
      validator: (value) {
        final email = (value ?? '').trim();
        if (email.isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(email)) {
          return 'Email is not valid';
        }
        return null;
      },
    );
  }
}

/// Password field with a button to show or hide what was typed.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.autofillHint,
    required this.validator,
    required this.onSubmitted,
    this.serverError,
    this.helperText,
  });

  final TextEditingController controller;

  /// AutofillHints.password to log in, AutofillHints.newPassword to register.
  final String autofillHint;
  final FormFieldValidator<String> validator;
  final VoidCallback onSubmitted;
  final String? serverError;
  final String? helperText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      decoration: InputDecoration(
        labelText: 'Password',
        helperText: widget.helperText,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [widget.autofillHint],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => widget.onSubmitted(),
      forceErrorText: widget.serverError,
      validator: widget.validator,
    );
  }
}

/// Full-width submit button that shows a spinner while busy.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// An error message for the whole form, such as a wrong email or password.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
