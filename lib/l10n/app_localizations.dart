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
  /// **'Account created, but your username could not be saved.'**
  String get registrationProfileFailed;

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

  /// No description provided for @homeTiming.
  ///
  /// In en, this message translates to:
  /// **'Relocation timing'**
  String get homeTiming;

  /// No description provided for @homeCost.
  ///
  /// In en, this message translates to:
  /// **'Cost pressure'**
  String get homeCost;

  /// No description provided for @homeEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment stability'**
  String get homeEmployment;

  /// No description provided for @homeEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economic momentum'**
  String get homeEconomy;

  /// No description provided for @homeIncome.
  ///
  /// In en, this message translates to:
  /// **'Household median income'**
  String get homeIncome;

  /// No description provided for @homeNational.
  ///
  /// In en, this message translates to:
  /// **'Malaysia · National outlook'**
  String get homeNational;

  /// No description provided for @homeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'A relative recent-history index, not a government rating or a guarantee.'**
  String get homeDisclaimer;

  /// No description provided for @homeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeRefresh;

  /// No description provided for @homeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore map'**
  String get homeExplore;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading national outlook…'**
  String get homeLoading;

  /// No description provided for @homeNominal.
  ///
  /// In en, this message translates to:
  /// **'At current-year prices, not adjusted for inflation'**
  String get homeNominal;

  /// No description provided for @homeCostDirection.
  ///
  /// In en, this message translates to:
  /// **'Higher scores mean lower relative cost pressure.'**
  String get homeCostDirection;

  /// No description provided for @homeLaborCaveat.
  ///
  /// In en, this message translates to:
  /// **'Census benchmark changes may affect comparisons.'**
  String get homeLaborCaveat;

  /// No description provided for @homePartial.
  ///
  /// In en, this message translates to:
  /// **'Some indicators are unavailable; available results are retained.'**
  String get homePartial;

  /// No description provided for @homeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get homeUnavailable;

  /// No description provided for @homeCooling.
  ///
  /// In en, this message translates to:
  /// **'Refresh available in {seconds} seconds'**
  String homeCooling(int seconds);

  /// No description provided for @homeIncomeAmount.
  ///
  /// In en, this message translates to:
  /// **'RM {amount} / month · Survey {year}'**
  String homeIncomeAmount(String amount, String year);

  /// No description provided for @homeNavigation.
  ///
  /// In en, this message translates to:
  /// **'Map navigation unavailable: {reason}'**
  String homeNavigation(String reason);

  /// No description provided for @homeDirection.
  ///
  /// In en, this message translates to:
  /// **'{code, select, timing_favorable {More favorable} timing_wait {Consider waiting} timing_defer {Better to defer} cost_easing {Cost pressure is easing} cost_worsening {Cost pressure is increasing} cost_stable {Cost pressure is broadly stable} cost_lowerIsBetter {Higher scores mean lower relative pressure} employment_improving {Employment stability is improving} employment_weakening {Employment stability is weakening} employment_stable {Employment stability is broadly stable} employment_comparisonUnavailable {Employment trend comparison unavailable} economy_expanding {Recent economic trend: expansion} economy_weakening {Recent economic trend: weakening} economy_stable {Recent economic trend: broadly stable} other {Temporarily unavailable}}'**
  String homeDirection(String code);

  /// No description provided for @homeReason.
  ///
  /// In en, this message translates to:
  /// **'{code, select, sourceMissing {Source data missing} sourceSchemaChanged {Data temporarily unavailable; please retry} insufficientHistory {Insufficient valid historical observations} sourceDataUnverifiable {Source data cannot be verified} retryableUnavailable {Connection unavailable; please retry} noCachedResult {No available data; please retry} authenticationRequired {Sign in again} missingInput {Required input missing} staleInput {This request has expired} inapplicableDestination {Destination not available} scopeUnavailable {Account scope is closed} other {Temporarily unavailable}}'**
  String homeReason(String code);

  /// No description provided for @homeTrendSummary.
  ///
  /// In en, this message translates to:
  /// **'Recent trend · {count} observations'**
  String homeTrendSummary(int count);

  /// No description provided for @homeTrendApproximation.
  ///
  /// In en, this message translates to:
  /// **'Reconstructed from current observations; historical revisions may affect this comparison.'**
  String get homeTrendApproximation;

  /// No description provided for @homeTrendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Historical trend unavailable; see the direction summary above.'**
  String get homeTrendUnavailable;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan your next move?'**
  String get homeGreeting;

  /// No description provided for @homeIndicators.
  ///
  /// In en, this message translates to:
  /// **'Key indicators'**
  String get homeIndicators;

  /// No description provided for @mapEnterAValidWGS84LatitudeAnd.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid WGS84 latitude and longitude.'**
  String get mapEnterAValidWGS84LatitudeAnd;

  /// No description provided for @mapChooseAPointOnMalaysianLand.
  ///
  /// In en, this message translates to:
  /// **'Choose a point on Malaysian land.'**
  String get mapChooseAPointOnMalaysianLand;

  /// No description provided for @mapAAndBMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'A and B must be different locations.'**
  String get mapAAndBMustBeDifferent;

  /// No description provided for @mapNameMustContain1120Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must contain 1–120 characters.'**
  String get mapNameMustContain1120Characters;

  /// No description provided for @mapSelectAValidatedLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a validated location first.'**
  String get mapSelectAValidatedLocationFirst;

  /// No description provided for @mapDeletionRequiresAConnectionTheLocation.
  ///
  /// In en, this message translates to:
  /// **'Deletion requires a connection. The location is retained.'**
  String get mapDeletionRequiresAConnectionTheLocation;

  /// No description provided for @mapPermissionDeniedSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Sign in again.'**
  String get mapPermissionDeniedSignInAgain;

  /// No description provided for @mapTheLocationChangedOnAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'This location changed. Reload and retry.'**
  String get mapTheLocationChangedOnAnotherDevice;

  /// No description provided for @mapThisSavedLocationNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This saved location no longer exists.'**
  String get mapThisSavedLocationNoLongerExists;

  /// No description provided for @mapThisRequestIsOutdatedSelectOr.
  ///
  /// In en, this message translates to:
  /// **'This request is outdated. Select or refresh again.'**
  String get mapThisRequestIsOutdatedSelectOr;

  /// No description provided for @mapTemporarilyUnavailableTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable. Try again.'**
  String get mapTemporarilyUnavailableTryAgain;

  /// No description provided for @mapSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get mapSaveLocation;

  /// No description provided for @mapName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mapName;

  /// No description provided for @mapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get mapCancel;

  /// No description provided for @mapSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mapSave;

  /// No description provided for @mapSetCurrentLocationAs.
  ///
  /// In en, this message translates to:
  /// **'Set current location as'**
  String get mapSetCurrentLocationAs;

  /// No description provided for @mapLocationA.
  ///
  /// In en, this message translates to:
  /// **'Location A'**
  String get mapLocationA;

  /// No description provided for @mapLocationB.
  ///
  /// In en, this message translates to:
  /// **'Location B'**
  String get mapLocationB;

  /// No description provided for @mapSavedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved locations'**
  String get mapSavedLocations;

  /// No description provided for @mapNoSavedLocations.
  ///
  /// In en, this message translates to:
  /// **'No saved locations'**
  String get mapNoSavedLocations;

  /// No description provided for @mapDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mapDelete;

  /// No description provided for @mapSearchPlacesInMalaysia.
  ///
  /// In en, this message translates to:
  /// **'Search places in Malaysia'**
  String get mapSearchPlacesInMalaysia;

  /// No description provided for @mapEnterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates'**
  String get mapEnterCoordinates;

  /// No description provided for @mapSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get mapSingle;

  /// No description provided for @mapCompareLocations.
  ///
  /// In en, this message translates to:
  /// **'Compare locations'**
  String get mapCompareLocations;

  /// No description provided for @mapLayers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get mapLayers;

  /// No description provided for @mapSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mapSaved;

  /// No description provided for @mapRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get mapRefresh;

  /// No description provided for @mapClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapClear;

  /// No description provided for @mapSearchUnavailableTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable. Try again.'**
  String get mapSearchUnavailableTryAgain;

  /// No description provided for @mapNoPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get mapNoPlacesFound;

  /// No description provided for @mapSwapAB.
  ///
  /// In en, this message translates to:
  /// **'Swap A/B'**
  String get mapSwapAB;

  /// No description provided for @mapNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get mapNotSelected;

  /// No description provided for @mapViewComparison.
  ///
  /// In en, this message translates to:
  /// **'View comparison'**
  String get mapViewComparison;

  /// No description provided for @mapSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get mapSelectedLocation;

  /// No description provided for @mapSelectALocation.
  ///
  /// In en, this message translates to:
  /// **'Select a location'**
  String get mapSelectALocation;

  /// No description provided for @mapSelectedAnalysisLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected analysis location'**
  String get mapSelectedAnalysisLocation;

  /// No description provided for @mapViewFullAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View full analysis'**
  String get mapViewFullAnalysis;

  /// No description provided for @mapStartComparison.
  ///
  /// In en, this message translates to:
  /// **'Start comparison'**
  String get mapStartComparison;

  /// No description provided for @mapSafetyIndex.
  ///
  /// In en, this message translates to:
  /// **'Safety index'**
  String get mapSafetyIndex;

  /// No description provided for @crimeSafetyIndex.
  ///
  /// In en, this message translates to:
  /// **'Crime & safety index'**
  String get crimeSafetyIndex;

  /// No description provided for @crimeStateUnresolved.
  ///
  /// In en, this message translates to:
  /// **'State boundaries unresolved'**
  String get crimeStateUnresolved;

  /// No description provided for @crimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Crime data unavailable'**
  String get crimeUnavailable;

  /// No description provided for @crimeAnnualCases.
  ///
  /// In en, this message translates to:
  /// **'Annual cases'**
  String get crimeAnnualCases;

  /// No description provided for @crimePartialData.
  ///
  /// In en, this message translates to:
  /// **'Partial data — may be incomplete'**
  String get crimePartialData;

  /// No description provided for @crimeSourceYear.
  ///
  /// In en, this message translates to:
  /// **'Source year: {year}'**
  String crimeSourceYear(int year);

  /// No description provided for @crimeTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Crime trend'**
  String get crimeTrendTitle;

  /// No description provided for @crimeTrendNote.
  ///
  /// In en, this message translates to:
  /// **'Trend reconstructed from available observations.'**
  String get crimeTrendNote;

  /// No description provided for @crimeCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get crimeCategoryAll;

  /// No description provided for @crimeCategoryAssault.
  ///
  /// In en, this message translates to:
  /// **'Assault'**
  String get crimeCategoryAssault;

  /// No description provided for @crimeCategoryProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get crimeCategoryProperty;

  /// No description provided for @crimeViewPortfolio.
  ///
  /// In en, this message translates to:
  /// **'View property portfolio'**
  String get crimeViewPortfolio;

  /// No description provided for @crimeAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get crimeAddProperty;

  /// No description provided for @mapCostOfLivingIndex.
  ///
  /// In en, this message translates to:
  /// **'Cost of living index'**
  String get mapCostOfLivingIndex;

  /// No description provided for @mapNearbyFacilities2Km.
  ///
  /// In en, this message translates to:
  /// **'Nearby facilities · 2 km'**
  String get mapNearbyFacilities2Km;

  /// No description provided for @mapPublicTransportation15Km.
  ///
  /// In en, this message translates to:
  /// **'Public transportation · 1.5 km'**
  String get mapPublicTransportation15Km;

  /// No description provided for @mapInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get mapInfrastructure;

  /// No description provided for @mapLatitudeMustBeBetween90And.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between −90 and 90.'**
  String get mapLatitudeMustBeBetween90And;

  /// No description provided for @mapLongitudeMustBeBetween180And.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between −180 and 180.'**
  String get mapLongitudeMustBeBetween180And;

  /// No description provided for @mapLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get mapLatitude;

  /// No description provided for @mapLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get mapLongitude;

  /// No description provided for @mapSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get mapSelect;

  /// No description provided for @mapHideSummary.
  ///
  /// In en, this message translates to:
  /// **'Hide summary'**
  String get mapHideSummary;

  /// No description provided for @mapShowSummary.
  ///
  /// In en, this message translates to:
  /// **'Show summary'**
  String get mapShowSummary;

  /// No description provided for @mapPropertyLocation.
  ///
  /// In en, this message translates to:
  /// **'Property location'**
  String get mapPropertyLocation;

  /// No description provided for @mapNoLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Map: no location selected.'**
  String get mapNoLocationSelected;

  /// No description provided for @mapLocationSummary.
  ///
  /// In en, this message translates to:
  /// **'{role}: {name}. Latitude {latitude}, longitude {longitude}.'**
  String mapLocationSummary(
    String role,
    String name,
    String latitude,
    String longitude,
  );

  /// No description provided for @mapLayerPoint.
  ///
  /// In en, this message translates to:
  /// **'Layer point: latitude {latitude}, longitude {longitude}.'**
  String mapLayerPoint(String latitude, String longitude);

  /// No description provided for @mapFeatureNotConnected.
  ///
  /// In en, this message translates to:
  /// **'This feature is not connected yet'**
  String get mapFeatureNotConnected;

  /// No description provided for @mapLocationRetained.
  ///
  /// In en, this message translates to:
  /// **'The selected location is retained. Return to the map to continue.'**
  String get mapLocationRetained;

  /// No description provided for @mapFacilityLayer.
  ///
  /// In en, this message translates to:
  /// **'Nearby facilities'**
  String get mapFacilityLayer;

  /// No description provided for @mapHazardLayer.
  ///
  /// In en, this message translates to:
  /// **'Hazard reports'**
  String get mapHazardLayer;

  /// No description provided for @mapTransitLayer.
  ///
  /// In en, this message translates to:
  /// **'Public transportation'**
  String get mapTransitLayer;

  /// No description provided for @mapLayerCluster.
  ///
  /// In en, this message translates to:
  /// **'{layer}: {count} points. Tap to explore.'**
  String mapLayerCluster(String layer, int count);

  /// No description provided for @mapSavedOnline.
  ///
  /// In en, this message translates to:
  /// **'Saved online.'**
  String get mapSavedOnline;

  /// No description provided for @mapDeletedOnline.
  ///
  /// In en, this message translates to:
  /// **'Deleted online.'**
  String get mapDeletedOnline;

  /// No description provided for @mapSavedLocationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Saved locations unavailable. Retry loading.'**
  String get mapSavedLocationsUnavailable;

  /// No description provided for @mapRetryLoading.
  ///
  /// In en, this message translates to:
  /// **'Retry loading'**
  String get mapRetryLoading;

  /// No description provided for @mapAccountUnavailableSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to read the current account or location. Retry.'**
  String get mapAccountUnavailableSignInAgain;

  /// No description provided for @mapSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Summary unavailable. Open full analysis.'**
  String get mapSummaryUnavailable;
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
