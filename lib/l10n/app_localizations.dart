import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';






















































abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  
  
  
  
  
  
  
  
  
  
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  
  
  
  
  String get signingOut;

  
  
  
  
  String get restoringSession;

  
  
  
  
  String get retry;

  
  
  
  
  String get signOutDevice;

  
  
  
  
  String get signedIn;

  
  
  
  
  String get createAccount;

  
  
  
  
  String get welcomeBack;

  
  
  
  
  String get registrationSubtitle;

  
  
  
  
  String get signInSubtitle;

  
  
  
  
  String get optionalUsername;

  
  
  
  
  String get usernameHint;

  
  
  
  
  String get email;

  
  
  
  
  String get password;

  
  
  
  
  String get emailRequired;

  
  
  
  
  String get emailInvalid;

  
  
  
  
  String get passwordHint;

  
  
  
  
  String get hide;

  
  
  
  
  String get show;

  
  
  
  
  String get passwordRequired;

  
  
  
  
  String get confirmPassword;

  
  
  
  
  String get confirmPasswordHint;

  
  
  
  
  String get passwordMismatch;

  
  
  
  
  String get signIn;

  
  
  
  
  String get switchToSignIn;

  
  
  
  
  String get switchToRegistration;

  
  
  
  
  String get confirmSignOut;

  
  
  
  
  String get confirmSignOutBody;

  
  
  
  
  String get cancel;

  
  
  
  
  String get signOut;

  
  
  
  
  String get signInSucceeded;

  
  
  
  
  String get signInInvalidInput;

  
  
  
  
  String get signInInvalidCredentials;

  
  
  
  
  String get serviceUnavailable;

  
  
  
  
  String get signInUnsupportedClient;

  
  
  
  
  String get registrationAuthenticated;

  
  
  
  
  String get registrationProfileFailed;

  
  
  
  
  String get registrationInvalidInput;

  
  
  
  
  String get registrationAccountExists;

  
  
  
  
  String get registrationUnsupportedClient;

  
  
  
  
  String get signOutRetryableUnavailable;

  
  
  
  
  String get signOutRemoteRejected;

  
  
  
  
  String get signOutUnsupportedClient;

  
  
  
  
  String get sessionUnavailable;

  
  
  
  
  String get unknownError;

  
  
  
  
  String get brandTagline;

  
  
  
  
  String get language;

  
  
  
  
  String get languageSaveFailed;

  
  
  
  
  String get configurationMissing;

  
  
  
  
  String get shellHome;

  
  
  
  
  String get shellMap;

  
  
  
  
  String get shellAccount;

  
  
  
  
  String get homeTiming;

  
  
  
  
  String get homeCost;

  
  
  
  
  String get homeEmployment;

  
  
  
  
  String get homeEconomy;

  
  
  
  
  String get homeIncome;

  
  
  
  
  String get homeNational;

  
  
  
  
  String get homeRefresh;

  
  
  
  
  String get homeExplore;

  
  
  
  
  String get homeLoading;

  
  
  
  
  String get homeCostDirection;

  
  
  
  
  String get homeLaborCaveat;

  
  
  
  
  String get homePartial;

  
  
  
  
  String get homeUnavailable;

  
  
  
  
  String homeCooling(int seconds);

  
  
  
  
  String get crimeSafetyIndex;

  
  
  
  
  String get crimeAnnualCases;

  
  
  
  
  String get crimeTrendTitle;

  
  
  
  
  String get crimeCategoryAll;

  
  
  
  
  String get crimeCategoryAssault;

  
  
  
  
  String get crimeCategoryProperty;

  
  
  
  
  String get crimeTrendNote;

  
  
  
  
  String crimeSourceYear(int year);

  
  
  
  
  String get crimeUnavailable;

  
  
  
  
  String get crimeStateUnresolved;

  
  
  
  
  String get crimePartialData;

  
  
  
  
  String get crimeViewPortfolio;

  
  
  
  
  String get crimeAddProperty;

  
  
  
  
  String get crimeBackToMap;

  
  
  
  
  String homeIncomeAmount(String amount, String year);

  
  
  
  
  String homeNavigation(String reason);

  
  
  
  
  String homeDirection(String code);

  
  
  
  
  String homeReason(String code);

  
  
  
  
  String homeTrendSummary(int count);

  
  
  
  
  String get homeTrendUnavailable;

  
  
  
  
  String get homeGreeting;

  
  
  
  
  String get homeIndicators;

  
  
  
  
  String get mapEnterAValidWGS84LatitudeAnd;

  
  
  
  
  String get mapChooseAPointOnMalaysianLand;

  
  
  
  
  String get mapAAndBMustBeDifferent;

  
  
  
  
  String get mapNameMustContain1120Characters;

  
  
  
  
  String get mapSelectAValidatedLocationFirst;

  
  
  
  
  String get mapDeletionRequiresAConnectionTheLocation;

  
  
  
  
  String get mapPermissionDeniedSignInAgain;

  
  
  
  
  String get mapTheLocationChangedOnAnotherDevice;

  
  
  
  
  String get mapThisSavedLocationNoLongerExists;

  
  
  
  
  String get mapThisRequestIsOutdatedSelectOr;

  
  
  
  
  String get mapTemporarilyUnavailableTryAgain;

  
  
  
  
  String get mapSaveLocation;

  
  
  
  
  String get mapName;

  
  
  
  
  String get mapCancel;

  
  
  
  
  String get mapSave;

  
  
  
  
  String get mapSetCurrentLocationAs;

  
  
  
  
  String get mapLocationA;

  
  
  
  
  String get mapLocationB;

  
  
  
  
  String get mapSavedLocations;

  
  
  
  
  String get mapNoSavedLocations;

  
  
  
  
  String get mapDelete;

  
  
  
  
  String get mapSearchPlacesInMalaysia;

  
  
  
  
  String get mapEnterCoordinates;

  
  
  
  
  String get mapSingle;

  
  
  
  
  String get mapCompareLocations;

  
  
  
  
  String get mapLayers;

  
  
  
  
  String get mapSaved;

  
  
  
  
  String get mapRefresh;

  
  
  
  
  String get mapClear;

  
  
  
  
  String get mapSearchUnavailableTryAgain;

  
  
  
  
  String get mapNoPlacesFound;

  
  
  
  
  String get mapSwapAB;

  
  
  
  
  String get mapNotSelected;

  
  
  
  
  String get mapViewComparison;

  
  
  
  
  String get mapSelectedLocation;

  
  
  
  
  String get mapSelectALocation;

  
  
  
  
  String get mapSelectedAnalysisLocation;

  
  
  
  
  String get mapViewFullAnalysis;

  
  
  
  
  String get mapStartComparison;

  
  
  
  
  String get mapSafetyIndex;

  
  
  
  
  String get mapCostOfLivingIndex;

  
  
  
  
  String get mapNearbyFacilities2Km;

  
  
  
  
  String get mapPublicTransportation15Km;

  
  
  
  
  String get mapInfrastructure;

  
  
  
  
  String get mapLatitudeMustBeBetween90And;

  
  
  
  
  String get mapLongitudeMustBeBetween180And;

  
  
  
  
  String get mapLatitude;

  
  
  
  
  String get mapLongitude;

  
  
  
  
  String get mapSelect;

  
  
  
  
  String get mapHideSummary;

  
  
  
  
  String get mapShowSummary;

  
  
  
  
  String get mapPropertyLocation;

  
  
  
  
  String get mapNoLocationSelected;

  
  
  
  
  String mapLocationSummary(
    String role,
    String name,
    String latitude,
    String longitude,
  );

  
  
  
  
  String mapLayerPoint(String latitude, String longitude);

  
  
  
  
  String get mapFeatureNotConnected;

  
  
  
  
  String get mapLocationRetained;

  
  
  
  
  String get mapFacilityLayer;

  
  
  
  
  String get mapHazardLayer;

  
  
  
  
  String get mapTransitLayer;

  
  
  
  
  String mapLayerCluster(String layer, int count);

  
  
  
  
  String get mapSavedOnline;

  
  
  
  
  String get mapDeletedOnline;

  
  
  
  
  String get mapSavedLocationsUnavailable;

  
  
  
  
  String get mapRetryLoading;

  
  
  
  
  String get mapAccountUnavailableSignInAgain;

  
  
  
  
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
