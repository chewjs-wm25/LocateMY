import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out'**
  String get signingOut;

  /// No description provided for @restoringSession.
  ///
  /// In en, this message translates to:
  /// **'Checking sign-in status'**
  String get restoringSession;

  /// No description provided for @signOutIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Sign-out incomplete'**
  String get signOutIncomplete;

  /// No description provided for @retrySignOut.
  ///
  /// In en, this message translates to:
  /// **'Retry sign-out'**
  String get retrySignOut;

  /// No description provided for @sessionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in status unavailable'**
  String get sessionUnavailableTitle;

  /// No description provided for @sessionRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet and retry to check your sign-in status.'**
  String get sessionRetryHint;

  /// No description provided for @sessionRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign out of this device and sign in again.'**
  String get sessionRejectedHint;

  /// No description provided for @sessionUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is unavailable. Check the app configuration or contact support.'**
  String get sessionUnsupportedHint;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get signOutDevice;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @emailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailConfirmed;

  /// No description provided for @emailVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Email verification required'**
  String get emailVerificationRequired;

  /// No description provided for @emailConfirmationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email verification status unavailable'**
  String get emailConfirmationUnavailable;

  /// No description provided for @retryUsername.
  ///
  /// In en, this message translates to:
  /// **'Retry saving username'**
  String get retryUsername;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to plan a life that suits you.'**
  String get registrationSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to explore locations, budgets and property inspections.'**
  String get signInSubtitle;

  /// No description provided for @optionalUsername.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get optionalUsername;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get usernameHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password again'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @switchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToSignIn;

  /// No description provided for @switchToRegistration.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get switchToRegistration;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get confirmSignOut;

  /// No description provided for @confirmSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'End your session on this device?'**
  String get confirmSignOutBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully.'**
  String get signInSucceeded;

  /// No description provided for @signInInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password.'**
  String get signInInvalidInput;

  /// No description provided for @signInInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get signInInvalidCredentials;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable. Please retry.'**
  String get serviceUnavailable;

  /// No description provided for @signInUnsupportedClient.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is unavailable on this device.'**
  String get signInUnsupportedClient;

  /// No description provided for @registrationAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get registrationAuthenticated;

  /// No description provided for @registrationProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Account created, but your username could not be saved. Retry later.'**
  String get registrationProfileFailed;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email and verify your address before signing in.'**
  String get verificationEmailSent;

  /// No description provided for @verificationProfileRetryNeeded.
  ///
  /// In en, this message translates to:
  /// **'Verify your email, then sign in to finish setting your username.'**
  String get verificationProfileRetryNeeded;

  /// No description provided for @registrationInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Check the required fields and confirm your password.'**
  String get registrationInvalidInput;

  /// No description provided for @registrationAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get registrationAccountExists;

  /// No description provided for @registrationUnsupportedClient.
  ///
  /// In en, this message translates to:
  /// **'Registration is unavailable on this device.'**
  String get registrationUnsupportedClient;

  /// No description provided for @profileRetrySucceeded.
  ///
  /// In en, this message translates to:
  /// **'Username saved.'**
  String get profileRetrySucceeded;

  /// No description provided for @profileRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Username not saved. Check the format or retry.'**
  String get profileRetryFailed;

  /// No description provided for @profileRetrySkipped.
  ///
  /// In en, this message translates to:
  /// **'There is no username to save on this device.'**
  String get profileRetrySkipped;

  /// No description provided for @signOutRetryableUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-out incomplete. Connect to the internet and retry.'**
  String get signOutRetryableUnavailable;

  /// No description provided for @signOutRemoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Sign-out rejected. Retry or contact support.'**
  String get signOutRemoteRejected;

  /// No description provided for @signOutUnsupportedClient.
  ///
  /// In en, this message translates to:
  /// **'Sign-out unavailable on this device. Check the app configuration.'**
  String get signOutUnsupportedClient;

  /// No description provided for @sessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to check your sign-in status. Please retry.'**
  String get sessionUnavailable;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please retry.'**
  String get unknownError;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Find a location that suits your life'**
  String get brandTagline;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Language preference could not be saved. Please retry.'**
  String get languageSaveFailed;

  /// No description provided for @configurationMissing.
  ///
  /// In en, this message translates to:
  /// **'LocateMY is not configured. Set the Supabase project URL and publishable key, then restart the app.'**
  String get configurationMissing;

  /// No description provided for @shellHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellHome;

  /// No description provided for @shellMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get shellMap;

  /// No description provided for @shellAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get shellAccount;

  /// No description provided for @shellTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get shellTask;

  /// No description provided for @shellPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the app. Please wait.'**
  String get shellPreparing;

  /// No description provided for @shellRecovery.
  ///
  /// In en, this message translates to:
  /// **'The app is temporarily unavailable. Please retry.'**
  String get shellRecovery;

  /// No description provided for @shellCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'Previous account cleanup is incomplete. Private content is closed. Retry to finish cleanup.'**
  String get shellCleanupPending;

  /// No description provided for @shellScopeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The account scope cannot be confirmed. Please retry.'**
  String get shellScopeUnavailable;

  /// No description provided for @shellFutureTask.
  ///
  /// In en, this message translates to:
  /// **'This feature will be connected in a later development wave.'**
  String get shellFutureTask;

  /// No description provided for @shellHomePending.
  ///
  /// In en, this message translates to:
  /// **'Home features are not connected yet.'**
  String get shellHomePending;

  /// No description provided for @shellMapPending.
  ///
  /// In en, this message translates to:
  /// **'Map features are not connected yet. No location is selected.'**
  String get shellMapPending;

  /// No description provided for @shellAccountPending.
  ///
  /// In en, this message translates to:
  /// **'Account Center is not connected yet. You can sign out of this device here.'**
  String get shellAccountPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
