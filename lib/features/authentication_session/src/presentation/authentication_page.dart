import 'package:locatemy/l10n/language_controller.dart';
import 'package:locatemy/l10n/app_localizations.dart';
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
  bool _hasValidated = false;
  Locale? _lastLocale;
  bool _showPassword = false;
  bool _showConfirmation = false;
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();

  bool _validate() {
    final errors = _formKey.currentState!.validateGranularly();
    if (errors.isEmpty) return true;
    final first = errors.first;
    first.context.visitChildElements((element) {
      void focusEditable(Element child) {
        if (child.widget is EditableText) {
          (child.widget as EditableText).focusNode.requestFocus();
        } else {
          child.visitChildElements(focusEditable);
        }
      }

      focusEditable(element);
    });
    Scrollable.ensureVisible(first.context);
    return false;
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale != null && _lastLocale != locale && _hasValidated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _formKey.currentState?.validate();
      });
    }
    _lastLocale = locale;
  }

  Future<void> _submitSignIn() async {
    _hasValidated = true;
    if (!_validate()) return;
    await widget.viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    _passwordController.clear();
  }

  Future<void> _submitRegistration() async {
    _hasValidated = true;
    if (!_validate()) return;
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
          title: state.isSigningOut
              ? AppLocalizations.of(context)!.signingOut
              : AppLocalizations.of(context)!.restoringSession,
          children: const [Center(child: CircularProgressIndicator())],
        );
      }
      if (state.signOutBlocked) {
        return _statusPage(
          title: AppLocalizations.of(context)!.signOutIncomplete,
          children: [
            if (state.messageKey != null)
              _FeedbackBanner(messageKey: state.messageKey!),
            FilledButton(
              onPressed: widget.onSignOut,
              child: Text(AppLocalizations.of(context)!.retrySignOut),
            ),
          ],
        );
      }
      final snapshot = state.session;
      if (snapshot is SessionUnavailable) {
        return _statusPage(
          title: AppLocalizations.of(context)!.sessionUnavailableTitle,
          children: [
            Text(switch (snapshot.failure) {
              SessionFailure.retryableUnavailable => AppLocalizations.of(
                context,
              )!.sessionRetryHint,
              SessionFailure.remoteRejected => AppLocalizations.of(
                context,
              )!.sessionRejectedHint,
              SessionFailure.unsupportedClient => AppLocalizations.of(
                context,
              )!.sessionUnsupportedHint,
            }),
            if (snapshot.failure == SessionFailure.retryableUnavailable)
              FilledButton(
                onPressed: widget.viewModel.retrySession,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            if (widget.onSignOut != null)
              TextButton(
                onPressed: _confirmSignOut,
                child: Text(AppLocalizations.of(context)!.signOutDevice),
              ),
          ],
        );
      }
      if (snapshot is AuthenticatedSession) {
        return _statusPage(
          title: AppLocalizations.of(context)!.signedIn,
          children: [
            const Icon(Icons.account_circle_outlined, size: 64),
            Text(snapshot.account.email, textAlign: TextAlign.center),
            Text(switch (snapshot.account.confirmation) {
              EmailConfirmation.confirmed => AppLocalizations.of(
                context,
              )!.emailConfirmed,
              EmailConfirmation.verificationRequired => AppLocalizations.of(
                context,
              )!.emailVerificationRequired,
              EmailConfirmation.unavailable => AppLocalizations.of(
                context,
              )!.emailConfirmationUnavailable,
            }, textAlign: TextAlign.center),
            if (state.messageKey != null)
              _FeedbackBanner(messageKey: state.messageKey!),
            if (widget.onRetryProfile != null)
              TextButton(
                onPressed:
                    state.actionStatus == AuthenticationActionStatus.submitting
                    ? null
                    : widget.onRetryProfile,
                child: Text(AppLocalizations.of(context)!.retryUsername),
              ),
            if (widget.onSignOut != null)
              FilledButton(
                onPressed: _confirmSignOut,
                child: Text(AppLocalizations.of(context)!.signOutDevice),
              ),
          ],
        );
      }
      final isRegister = state.mode == AuthenticationMode.register;
      final isSubmitting =
          state.actionStatus == AuthenticationActionStatus.submitting;
      return Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: 56),
                      Text(
                        isRegister
                            ? AppLocalizations.of(context)!.createAccount
                            : AppLocalizations.of(context)!.welcomeBack,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? AppLocalizations.of(context)!.registrationSubtitle
                            : AppLocalizations.of(context)!.signInSubtitle,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (isRegister) ...[
                        _FieldLabel(
                          AppLocalizations.of(context)!.optionalUsername,
                        ),
                        Semantics(
                          label: AppLocalizations.of(context)!.optionalUsername,
                          child: TextFormField(
                            controller: _usernameController,
                            enabled: !isSubmitting,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .usernameHint,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _FieldLabel(AppLocalizations.of(context)!.email),
                      Semantics(
                        label: AppLocalizations.of(context)!.email,
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: 'name@example.com',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? AppLocalizations.of(context)!.emailRequired
                              : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value.trim())
                              ? AppLocalizations.of(context)!.emailInvalid
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel(AppLocalizations.of(context)!.password),
                      Semantics(
                        label: AppLocalizations.of(context)!.password,
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          enabled: !isSubmitting,
                          obscureText: !_showPassword,
                          autofillHints: isRegister
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!
                                .passwordHint,
                            suffixIcon: TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                              child: Text(
                                _showPassword
                                    ? AppLocalizations.of(context)!.hide
                                    : AppLocalizations.of(context)!.show,
                              ),
                            ),
                          ),
                          textInputAction: isRegister
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: isSubmitting || isRegister
                              ? null
                              : (_) => _submitSignIn(),
                          validator: (value) => value == null || value.isEmpty
                              ? AppLocalizations.of(context)!.passwordRequired
                              : null,
                        ),
                      ),
                      if (isRegister) ...[
                        const SizedBox(height: 24),
                        _FieldLabel(
                          AppLocalizations.of(context)!.confirmPassword,
                        ),
                        Semantics(
                          label: AppLocalizations.of(context)!.confirmPassword,
                          child: TextFormField(
                            controller: _confirmationController,
                            focusNode: _confirmationFocus,
                            enabled: !isSubmitting,
                            obscureText: !_showConfirmation,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .confirmPasswordHint,
                              suffixIcon: TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _showConfirmation =
                                            !_showConfirmation,
                                      ),
                                child: Text(
                                  _showConfirmation
                                      ? AppLocalizations.of(context)!.hide
                                      : AppLocalizations.of(context)!.show,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: isSubmitting
                                ? null
                                : (_) => _submitRegistration(),
                            validator: (value) =>
                                value != _passwordController.text
                                ? AppLocalizations.of(context)!.passwordMismatch
                                : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
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
                            : Text(
                                isRegister
                                    ? AppLocalizations.of(context)!
                                          .createAccount
                                    : AppLocalizations.of(context)!.signIn,
                              ),
                      ),
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : isRegister
                            ? () => _switchMode(false)
                            : () => _switchMode(true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                        ),
                        child: Text(
                          isRegister
                              ? AppLocalizations.of(context)!.switchToSignIn
                              : AppLocalizations.of(context)!
                                    .switchToRegistration,
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 40),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
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
    _hasValidated = false;
    setState(() {
      _showPassword = false;
      _showConfirmation = false;
    });
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
        title: Text(AppLocalizations.of(context)!.confirmSignOut),
        content: Text(AppLocalizations.of(context)!.confirmSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.signOut),
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
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
  Widget build(BuildContext context) {
    final isSuccess =
        messageKey.contains('succeeded') ||
        messageKey.startsWith('verification_') ||
        messageKey.startsWith('registration_authenticated');
    final color = isSuccess ? const Color(0xFF16865C) : const Color(0xFFC9362B);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _messageFor(context, messageKey),
          style: TextStyle(color: color, fontSize: 14),
        ),
      ),
    );
  }

  String _messageFor(BuildContext context, String key) => switch (key) {
    'sign_in_succeeded' => AppLocalizations.of(context)!.signInSucceeded,
    'sign_in_invalid_input' => AppLocalizations.of(context)!.signInInvalidInput,
    'sign_in_invalid_credentials' => AppLocalizations.of(
      context,
    )!.signInInvalidCredentials,
    'sign_in_retryable_unavailable' => AppLocalizations.of(
      context,
    )!.serviceUnavailable,
    'sign_in_unsupported_client' => AppLocalizations.of(
      context,
    )!.signInUnsupportedClient,
    'registration_authenticated' => AppLocalizations.of(
      context,
    )!.registrationAuthenticated,
    'registration_authenticated_profile_failed' => AppLocalizations.of(
      context,
    )!.registrationProfileFailed,
    'verification_email_sent' => AppLocalizations.of(
      context,
    )!.verificationEmailSent,
    'verification_email_sent_profile_retry_needed' => AppLocalizations.of(
      context,
    )!.verificationProfileRetryNeeded,
    'registration_invalid_input' => AppLocalizations.of(
      context,
    )!.registrationInvalidInput,
    'registration_account_exists' => AppLocalizations.of(
      context,
    )!.registrationAccountExists,
    'registration_retryable_unavailable' => AppLocalizations.of(
      context,
    )!.serviceUnavailable,
    'registration_unsupported_client' => AppLocalizations.of(
      context,
    )!.registrationUnsupportedClient,
    'profile_retry_succeeded' => AppLocalizations.of(
      context,
    )!.profileRetrySucceeded,
    'profile_retry_failed' => AppLocalizations.of(context)!.profileRetryFailed,
    'profile_retry_skipped' => AppLocalizations.of(
      context,
    )!.profileRetrySkipped,
    'sign_out_retryable_unavailable' => AppLocalizations.of(
      context,
    )!.signOutRetryableUnavailable,
    'sign_out_remote_rejected' => AppLocalizations.of(
      context,
    )!.signOutRemoteRejected,
    'sign_out_unsupported_client' => AppLocalizations.of(
      context,
    )!.signOutUnsupportedClient,
    'session_unavailable' => AppLocalizations.of(context)!.sessionUnavailable,
    _ => AppLocalizations.of(context)!.unknownError,
  };
}

final class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

final class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF155EEF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.my_location, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LocateMY',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              AppLocalizations.of(context)!.brandTagline,
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
      const LanguageButton(),
    ],
  );
}
