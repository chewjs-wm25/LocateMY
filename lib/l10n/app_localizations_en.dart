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
  String get retry => 'Retry';

  @override
  String get signOutDevice => 'Sign out of this device';

  @override
  String get signedIn => 'Signed in';

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
      'Account created, but your username could not be saved.';

  @override
  String get registrationInvalidInput =>
      'Check the required fields and confirm your password.';

  @override
  String get registrationAccountExists => 'This email is already registered.';

  @override
  String get registrationUnsupportedClient =>
      'Registration is unavailable on this device.';

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

  @override
  String get shellHome => 'Home';

  @override
  String get shellMap => 'Map';

  @override
  String get shellAccount => 'Account';

  @override
  String get homeTiming => 'Relocation timing';

  @override
  String get homeCost => 'Cost pressure';

  @override
  String get homeEmployment => 'Employment stability';

  @override
  String get homeEconomy => 'Economic momentum';

  @override
  String get homeIncome => 'Household median income';

  @override
  String get homeNational => 'Malaysia · National outlook';

  @override
  String get homeDisclaimer =>
      'A relative recent-history index, not a government rating or a guarantee.';

  @override
  String get homeRefresh => 'Refresh';

  @override
  String get homeExplore => 'Explore map';

  @override
  String get homeLoading => 'Loading national outlook…';

  @override
  String get homeNominal =>
      'At current-year prices, not adjusted for inflation';

  @override
  String get homeCostDirection =>
      'Higher scores mean lower relative cost pressure.';

  @override
  String get homeLaborCaveat =>
      'Census benchmark changes may affect comparisons.';

  @override
  String get homePartial =>
      'Some indicators are unavailable; available results are retained.';

  @override
  String get homeUnavailable => 'Temporarily unavailable';

  @override
  String homeCooling(int seconds) {
    return 'Refresh available in $seconds seconds';
  }

  @override
  String homeIncomeAmount(String amount, String year) {
    return 'RM $amount / month · Survey $year';
  }

  @override
  String homeNavigation(String reason) {
    return 'Map navigation unavailable: $reason';
  }

  @override
  String homeDirection(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'timing_favorable': 'More favorable',
      'timing_wait': 'Consider waiting',
      'timing_defer': 'Better to defer',
      'cost_easing': 'Cost pressure is easing',
      'cost_worsening': 'Cost pressure is increasing',
      'cost_stable': 'Cost pressure is broadly stable',
      'cost_lowerIsBetter': 'Higher scores mean lower relative pressure',
      'employment_improving': 'Employment stability is improving',
      'employment_weakening': 'Employment stability is weakening',
      'employment_stable': 'Employment stability is broadly stable',
      'employment_comparisonUnavailable':
          'Employment trend comparison unavailable',
      'economy_expanding': 'Recent economic trend: expansion',
      'economy_weakening': 'Recent economic trend: weakening',
      'economy_stable': 'Recent economic trend: broadly stable',
      'other': 'Temporarily unavailable',
    });
    return '$_temp0';
  }

  @override
  String homeReason(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'sourceMissing': 'Source data missing',
      'sourceSchemaChanged': 'Data temporarily unavailable; please retry',
      'insufficientHistory': 'Insufficient valid historical observations',
      'sourceDataUnverifiable': 'Source data cannot be verified',
      'retryableUnavailable': 'Connection unavailable; please retry',
      'noCachedResult': 'No available data; please retry',
      'authenticationRequired': 'Sign in again',
      'missingInput': 'Required input missing',
      'staleInput': 'This request has expired',
      'inapplicableDestination': 'Destination not available',
      'scopeUnavailable': 'Account scope is closed',
      'other': 'Temporarily unavailable',
    });
    return '$_temp0';
  }

  @override
  String homeTrendSummary(int count) {
    return 'Recent trend · $count observations';
  }

  @override
  String get homeTrendApproximation =>
      'Reconstructed from current observations; historical revisions may affect this comparison.';

  @override
  String get homeTrendUnavailable =>
      'Historical trend unavailable; see the direction summary above.';

  @override
  String get homeGreeting => 'Ready to plan your next move?';

  @override
  String get homeIndicators => 'Key indicators';

  @override
  String get mapEnterAValidWGS84LatitudeAnd =>
      'Enter a valid WGS84 latitude and longitude.';

  @override
  String get mapChooseAPointOnMalaysianLand =>
      'Choose a point on Malaysian land.';

  @override
  String get mapAAndBMustBeDifferent => 'A and B must be different locations.';

  @override
  String get mapNameMustContain1120Characters =>
      'Name must contain 1–120 characters.';

  @override
  String get mapSelectAValidatedLocationFirst =>
      'Select a validated location first.';

  @override
  String get mapDeletionRequiresAConnectionTheLocation =>
      'Deletion requires a connection. The location is retained.';

  @override
  String get mapPermissionDeniedSignInAgain =>
      'Permission denied. Sign in again.';

  @override
  String get mapTheLocationChangedOnAnotherDevice =>
      'This location changed. Reload and retry.';

  @override
  String get mapThisSavedLocationNoLongerExists =>
      'This saved location no longer exists.';

  @override
  String get mapThisRequestIsOutdatedSelectOr =>
      'This request is outdated. Select or refresh again.';

  @override
  String get mapTemporarilyUnavailableTryAgain =>
      'Temporarily unavailable. Try again.';

  @override
  String get mapSaveLocation => 'Save location';

  @override
  String get mapName => 'Name';

  @override
  String get mapCancel => 'Cancel';

  @override
  String get mapSave => 'Save';

  @override
  String get mapSetCurrentLocationAs => 'Set current location as';

  @override
  String get mapLocationA => 'Location A';

  @override
  String get mapLocationB => 'Location B';

  @override
  String get mapSavedLocations => 'Saved locations';

  @override
  String get mapNoSavedLocations => 'No saved locations';

  @override
  String get mapDelete => 'Delete';

  @override
  String get mapSearchPlacesInMalaysia => 'Search places in Malaysia';

  @override
  String get mapEnterCoordinates => 'Enter coordinates';

  @override
  String get mapSingle => 'Single';

  @override
  String get mapCompareLocations => 'Compare locations';

  @override
  String get mapLayers => 'Layers';

  @override
  String get mapSaved => 'Saved';

  @override
  String get mapRefresh => 'Refresh';

  @override
  String get mapClear => 'Clear';

  @override
  String get mapSearchUnavailableTryAgain => 'Search unavailable. Try again.';

  @override
  String get mapNoPlacesFound => 'No places found';

  @override
  String get mapSwapAB => 'Swap A/B';

  @override
  String get mapNotSelected => 'Not selected';

  @override
  String get mapViewComparison => 'View comparison';

  @override
  String get mapSelectedLocation => 'Selected location';

  @override
  String get mapSelectALocation => 'Select a location';

  @override
  String get mapSelectedAnalysisLocation => 'Selected analysis location';

  @override
  String get mapViewFullAnalysis => 'View full analysis';

  @override
  String get mapStartComparison => 'Start comparison';

  @override
  String get mapSafetyIndex => 'Safety index';

  @override
  String get mapCostOfLivingIndex => 'Cost of living index';

  @override
  String get mapNearbyFacilities2Km => 'Nearby facilities · 2 km';

  @override
  String get mapPublicTransportation15Km => 'Public transportation · 1.5 km';

  @override
  String get mapInfrastructure => 'Infrastructure';

  @override
  String get mapLatitudeMustBeBetween90And =>
      'Latitude must be between −90 and 90.';

  @override
  String get mapLongitudeMustBeBetween180And =>
      'Longitude must be between −180 and 180.';

  @override
  String get mapLatitude => 'Latitude';

  @override
  String get mapLongitude => 'Longitude';

  @override
  String get mapSelect => 'Select';

  @override
  String get mapHideSummary => 'Hide summary';

  @override
  String get mapShowSummary => 'Show summary';

  @override
  String get mapPropertyLocation => 'Property location';

  @override
  String get mapNoLocationSelected => 'Map: no location selected.';

  @override
  String mapLocationSummary(
    String role,
    String name,
    String latitude,
    String longitude,
  ) {
    return '$role: $name. Latitude $latitude, longitude $longitude.';
  }

  @override
  String mapLayerPoint(String latitude, String longitude) {
    return 'Layer point: latitude $latitude, longitude $longitude.';
  }

  @override
  String get mapFeatureNotConnected => 'This feature is not connected yet';

  @override
  String get mapLocationRetained =>
      'The selected location is retained. Return to the map to continue.';

  @override
  String get mapFacilityLayer => 'Nearby facilities';

  @override
  String get mapHazardLayer => 'Hazard reports';

  @override
  String get mapTransitLayer => 'Public transportation';

  @override
  String mapLayerCluster(String layer, int count) {
    return '$layer: $count points. Tap to explore.';
  }

  @override
  String get mapSavedOnline => 'Saved online.';

  @override
  String get mapDeletedOnline => 'Deleted online.';

  @override
  String get mapSavedLocationsUnavailable =>
      'Saved locations unavailable. Retry loading.';

  @override
  String get mapRetryLoading => 'Retry loading';

  @override
  String get mapAccountUnavailableSignInAgain =>
      'Unable to read the current account or location. Retry.';

  @override
  String get mapSummaryUnavailable =>
      'Summary unavailable. Open full analysis.';
}
