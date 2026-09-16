import 'package:flutter/material.dart';

import '../domain/authentication_models.dart';
import 'authentication_view_model.dart';
import 'authentication_view_state.dart';

final class AuthenticationPage extends StatefulWidget {
  final AuthenticationViewModel viewModel;
  final Future<void> Function()? onSignOut;
  final Future<void> Function()? onRetryProfile;
  const AuthenticationPage({
    required this.viewModel,
    this.onSignOut,
    this.onRetryProfile,
    super.key,
  });

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

final class _AuthenticationPageState extends State<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  Future<void> _submitSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    _passwordController.clear();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.viewModel.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmationController.text,
    );
    if (!mounted) return;
    _passwordController.clear();
    _confirmationController.clear();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.viewModel,
    builder: (context, _) {
      final state = widget.viewModel.state;
      if (state.isRestoring || state.isSigningOut) {
        return _statusPage(
          title: state.isSigningOut ? 'Signing out' : 'Checking session',
          children: const [Center(child: CircularProgressIndicator())],
        );
      }
      if (state.signOutBlocked) {
        return _statusPage(
          title: 'Sign out incomplete',
          children: [
            if (state.messageKey != null)
              _FeedbackBanner(messageKey: state.messageKey!),
            FilledButton(
              onPressed: widget.onSignOut,
              child: const Text('Retry sign out'),
            ),
          ],
        );
      }
      final snapshot = state.session;
      if (snapshot is SessionUnavailable) {
        return _statusPage(
          title: 'Session unavailable',
          children: [
            Text(switch (snapshot.failure) {
              SessionFailure.retryableUnavailable =>
                'Connect to the internet and retry to confirm your session.',
              SessionFailure.remoteRejected => 'Your session was rejected. Sign out on this device, then sign in again.',
              SessionFailure.unsupportedClient => 'Session support is unavailable. Check your app configuration or contact support.',
            }),
            if (snapshot.failure == SessionFailure.retryableUnavailable)
              FilledButton(
                onPressed: widget.viewModel.retrySession,
                child: const Text('Retry session'),
              ),
            if (widget.onSignOut != null)
              TextButton(
                onPressed: _confirmSignOut,
                child: const Text('Sign out on this device'),
              ),
          ],
        );
      }
      if (snapshot is AuthenticatedSession) {
        return _statusPage(
          title: 'Signed in',
          children: [
            const Icon(Icons.account_circle_outlined, size: 64),
            Text(snapshot.account.email, textAlign: TextAlign.center),
            Text(switch (snapshot.account.confirmation) {
              EmailConfirmation.confirmed => 'Email verified',
              EmailConfirmation.verificationRequired =>
                'Email verification required',
              EmailConfirmation.unavailable =>
                'Email verification status unavailable',
            }, textAlign: TextAlign.center),
            if (state.messageKey != null)
              _FeedbackBanner(messageKey: state.messageKey!),
            if (widget.onRetryProfile != null)
              TextButton(
                onPressed:
                    state.actionStatus == AuthenticationActionStatus.submitting
                    ? null
                    : widget.onRetryProfile,
                child: const Text('Retry username setup'),
              ),
            if (widget.onSignOut != null)
              FilledButton(
                onPressed: _confirmSignOut,
                child: const Text('Sign out on this device'),
              ),
          ],
        );
      }
      final isRegister = state.mode == AuthenticationMode.register;
      final isSubmitting =
          state.actionStatus == AuthenticationActionStatus.submitting;
      return Scaffold(
        appBar: AppBar(title: Text(isRegister ? 'Create account' : 'Sign in')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isRegister) ...[
                        TextFormField(
                          controller: _usernameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Username (optional)',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Email is required.'
                            : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())
                            ? 'Enter a valid email address.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !isSubmitting,
                        obscureText: true,
                        autofillHints: isRegister
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password is required.'
                            : null,
                      ),
                      if (isRegister) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmationController,
                          enabled: !isSubmitting,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match.'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (state.messageKey != null)
                        _FeedbackBanner(messageKey: state.messageKey!),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : isRegister
                            ? _submitRegistration
                            : _submitSignIn,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isRegister ? 'Create account' : 'Sign in'),
                      ),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : isRegister
                            ? () => _switchMode(false)
                            : () => _switchMode(true),
                        child: Text(
                          isRegister
                              ? 'Already have an account? Sign in'
                              : 'Need an account? Register',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _statusPage({required String title, required List<Widget> children}) =>
      Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in children) ...[
                      child,
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _switchMode(bool register) {
    _passwordController.clear();
    _confirmationController.clear();
    _formKey.currentState?.reset();
    register
        ? widget.viewModel.showRegistration()
        : widget.viewModel.showSignIn();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('End your session on this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _passwordController.clear();
      _confirmationController.clear();
      await widget.onSignOut?.call();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}

final class _FeedbackBanner extends StatelessWidget {
  final String messageKey;
  const _FeedbackBanner({required this.messageKey});

  @override
  Widget build(BuildContext context) => Text(
    _messageFor(messageKey),
    style: TextStyle(
      color:
          messageKey.contains('succeeded') ||
              messageKey.startsWith('verification_') ||
              messageKey.startsWith('registration_authenticated')
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.error,
    ),
  );

  String _messageFor(String key) => switch (key) {
    'sign_in_succeeded' => 'Signed in successfully.',
    'sign_in_invalid_input' => 'Enter both email and password.',
    'sign_in_invalid_credentials' => 'Email or password is incorrect.',
    'sign_in_retryable_unavailable' =>
      'The service is unavailable. Please try again.',
    'sign_in_unsupported_client' => 'This device cannot sign in right now.',
    'registration_authenticated' => 'Account created successfully.',
    'registration_authenticated_profile_failed' =>
      'Account created, but username setup can be retried later.',
    'verification_email_sent' =>
      'Check your email and verify your account before signing in.',
    'verification_email_sent_profile_retry_needed' =>
      'Verify your email, then sign in to finish username setup.',
    'registration_invalid_input' =>
      'Check the required fields and password confirmation.',
    'registration_account_exists' => 'An account with this email exists.',
    'registration_retryable_unavailable' =>
      'The service is unavailable. Please try again.',
    'registration_unsupported_client' =>
      'This device cannot register right now.',
    'profile_retry_succeeded' => 'Username saved.',
    'profile_retry_failed' =>
      'Username was not saved. Check its format or try again.',
    'profile_retry_skipped' => 'No username setup is pending on this device.',
    'sign_out_retryable_unavailable' =>
      'Sign out could not finish. Connect to the internet and retry.',
    'sign_out_remote_rejected' =>
      'Sign out was rejected. Retry or contact support.',
    'sign_out_unsupported_client' =>
      'This device could not finish signing out. Check your app configuration.',
    'session_unavailable' =>
      'We cannot safely confirm your session. Please retry.',
    _ => 'Something went wrong.',
  };
}
