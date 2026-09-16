// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signingOut => 'Signing out';

  @override
  String get restoringSession => 'Checking sign-in status';

  @override
  String get signOutIncomplete => 'Sign-out incomplete';

  @override
  String get retrySignOut => 'Retry sign-out';

  @override
  String get sessionUnavailableTitle => 'Sign-in status unavailable';

  @override
  String get sessionRetryHint =>
      'Connect to the internet and retry to check your sign-in status.';

  @override
  String get sessionRejectedHint =>
      'Your session has expired. Sign out of this device and sign in again.';

  @override
  String get sessionUnsupportedHint =>
      'Sign-in is unavailable. Check the app configuration or contact support.';

  @override
  String get retry => 'Retry';

  @override
  String get signOutDevice => 'Sign out of this device';

  @override
  String get signedIn => 'Signed in';

  @override
  String get emailConfirmed => 'Email verified';

  @override
  String get emailVerificationRequired => 'Email verification required';

  @override
  String get emailConfirmationUnavailable =>
      'Email verification status unavailable';

  @override
  String get retryUsername => 'Retry saving username';

  @override
  String get createAccount => 'Create account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get registrationSubtitle =>
      'Create an account to plan a life that suits you.';

  @override
  String get signInSubtitle =>
      'Sign in to explore locations, budgets and property inspections.';

  @override
  String get optionalUsername => 'Username (optional)';

  @override
  String get usernameHint => 'Enter username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get emailRequired => 'Enter your email.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Enter password again';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get signIn => 'Sign in';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get switchToRegistration => 'New here? Create an account';

  @override
  String get confirmSignOut => 'Sign out?';

  @override
  String get confirmSignOutBody => 'End your session on this device?';

  @override
  String get cancel => 'Cancel';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInSucceeded => 'Signed in successfully.';

  @override
  String get signInInvalidInput => 'Enter your email and password.';

  @override
  String get signInInvalidCredentials => 'Incorrect email or password.';

  @override
  String get serviceUnavailable => 'Service unavailable. Please retry.';

  @override
  String get signInUnsupportedClient =>
      'Sign-in is unavailable on this device.';

  @override
  String get registrationAuthenticated => 'Account created successfully.';

  @override
  String get registrationProfileFailed =>
      'Account created, but your username could not be saved. Retry later.';

  @override
  String get verificationEmailSent =>
      'Check your email and verify your address before signing in.';

  @override
  String get verificationProfileRetryNeeded =>
      'Verify your email, then sign in to finish setting your username.';

  @override
  String get registrationInvalidInput =>
      'Check the required fields and confirm your password.';

  @override
  String get registrationAccountExists => 'This email is already registered.';

  @override
  String get registrationUnsupportedClient =>
      'Registration is unavailable on this device.';

  @override
  String get profileRetrySucceeded => 'Username saved.';

  @override
  String get profileRetryFailed =>
      'Username not saved. Check the format or retry.';

  @override
  String get profileRetrySkipped =>
      'There is no username to save on this device.';

  @override
  String get signOutRetryableUnavailable =>
      'Sign-out incomplete. Connect to the internet and retry.';

  @override
  String get signOutRemoteRejected =>
      'Sign-out rejected. Retry or contact support.';

  @override
  String get signOutUnsupportedClient =>
      'Sign-out unavailable on this device. Check the app configuration.';

  @override
  String get sessionUnavailable =>
      'Unable to check your sign-in status. Please retry.';

  @override
  String get unknownError => 'Something went wrong. Please retry.';

  @override
  String get brandTagline => 'Find a location that suits your life';

  @override
  String get language => 'Language';

  @override
  String get languageSaveFailed =>
      'Language preference could not be saved. Please retry.';

  @override
  String get configurationMissing =>
      'LocateMY is not configured. Set the Supabase project URL and publishable key, then restart the app.';
}
