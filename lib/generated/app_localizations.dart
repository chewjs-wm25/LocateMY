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
/// import 'generated/app_localizations.dart';
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

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'UI Prototype Show'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get navCost;

  /// No description provided for @navSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get navSecurity;

  /// No description provided for @navSocioEconomic.
  ///
  /// In en, this message translates to:
  /// **'Socio-Economic'**
  String get navSocioEconomic;

  /// No description provided for @navInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get navInfrastructure;

  /// No description provided for @navTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get navTransport;

  /// No description provided for @titleHome.
  ///
  /// In en, this message translates to:
  /// **'LocateMY'**
  String get titleHome;

  /// No description provided for @titleMap.
  ///
  /// In en, this message translates to:
  /// **'Location Exploration'**
  String get titleMap;

  /// No description provided for @titleCost.
  ///
  /// In en, this message translates to:
  /// **'Cost of Living Analysis'**
  String get titleCost;

  /// No description provided for @titleSecurity.
  ///
  /// In en, this message translates to:
  /// **'Crime & Security Risk'**
  String get titleSecurity;

  /// No description provided for @titleSocioEconomic.
  ///
  /// In en, this message translates to:
  /// **'Socio-Economic Analysis'**
  String get titleSocioEconomic;

  /// No description provided for @titleInfrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure Assessment'**
  String get titleInfrastructure;

  /// No description provided for @titleTransport.
  ///
  /// In en, this message translates to:
  /// **'Public Transport & Commute'**
  String get titleTransport;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @comparisonMode.
  ///
  /// In en, this message translates to:
  /// **'Comparison Mode'**
  String get comparisonMode;

  /// No description provided for @currentAddress.
  ///
  /// In en, this message translates to:
  /// **'Origin Address'**
  String get currentAddress;

  /// No description provided for @newAddress.
  ///
  /// In en, this message translates to:
  /// **'New Address'**
  String get newAddress;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @selectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select on Map'**
  String get selectOnMap;

  /// No description provided for @costOfLiving.
  ///
  /// In en, this message translates to:
  /// **'Cost of Living'**
  String get costOfLiving;

  /// No description provided for @crimeSecurity.
  ///
  /// In en, this message translates to:
  /// **'Crime & Security'**
  String get crimeSecurity;

  /// No description provided for @socioEconomic.
  ///
  /// In en, this message translates to:
  /// **'Socio-Economic'**
  String get socioEconomic;

  /// No description provided for @infrastructure.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get infrastructure;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @unemployment.
  ///
  /// In en, this message translates to:
  /// **'Unemployment'**
  String get unemployment;

  /// No description provided for @medianIncome.
  ///
  /// In en, this message translates to:
  /// **'Median Income'**
  String get medianIncome;

  /// No description provided for @economicGrowth.
  ///
  /// In en, this message translates to:
  /// **'Economic Growth (GDP %)'**
  String get economicGrowth;

  /// No description provided for @cpiInflation.
  ///
  /// In en, this message translates to:
  /// **'CPI Inflation'**
  String get cpiInflation;

  /// No description provided for @oprRate.
  ///
  /// In en, this message translates to:
  /// **'OPR Rate'**
  String get oprRate;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring Locations'**
  String get startExploring;

  /// No description provided for @favorablePeriod.
  ///
  /// In en, this message translates to:
  /// **'Favorable Period'**
  String get favorablePeriod;

  /// No description provided for @goodTimeToRelocate.
  ///
  /// In en, this message translates to:
  /// **'Good time to relocate'**
  String get goodTimeToRelocate;

  /// No description provided for @stableInflationInfo.
  ///
  /// In en, this message translates to:
  /// **'Stable inflation and dry season makes it ideal.'**
  String get stableInflationInfo;

  /// No description provided for @indexLabel.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get indexLabel;

  /// No description provided for @interMonsoon.
  ///
  /// In en, this message translates to:
  /// **'Inter-monsoon'**
  String get interMonsoon;

  /// No description provided for @lowFloodRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Flood Risk'**
  String get lowFloodRisk;

  /// No description provided for @idealForMoving.
  ///
  /// In en, this message translates to:
  /// **'Ideal for moving house now.'**
  String get idealForMoving;

  /// No description provided for @nextPeak.
  ///
  /// In en, this message translates to:
  /// **'Next peak: Nov'**
  String get nextPeak;

  /// No description provided for @locationSelection.
  ///
  /// In en, this message translates to:
  /// **'Location Selection'**
  String get locationSelection;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @kl.
  ///
  /// In en, this message translates to:
  /// **'Kuala Lumpur'**
  String get kl;

  /// No description provided for @pg.
  ///
  /// In en, this message translates to:
  /// **'Penang'**
  String get pg;

  /// No description provided for @jb.
  ///
  /// In en, this message translates to:
  /// **'Johor Bahru'**
  String get jb;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'Ipoh'**
  String get ip;

  /// No description provided for @purchasingPower.
  ///
  /// In en, this message translates to:
  /// **'Purchasing Power Forecast'**
  String get purchasingPower;

  /// No description provided for @significantImprovement.
  ///
  /// In en, this message translates to:
  /// **'Significant Improvement'**
  String get significantImprovement;

  /// No description provided for @expectedQualityImprovement.
  ///
  /// In en, this message translates to:
  /// **'Expected quality of life improvement'**
  String get expectedQualityImprovement;

  /// No description provided for @housingExpenditure.
  ///
  /// In en, this message translates to:
  /// **'Housing Expenditure'**
  String get housingExpenditure;

  /// No description provided for @foodPrices.
  ///
  /// In en, this message translates to:
  /// **'Food Prices'**
  String get foodPrices;

  /// No description provided for @monthlySaving.
  ///
  /// In en, this message translates to:
  /// **'Monthly saving approx. RM {value}'**
  String monthlySaving(Object value);

  /// No description provided for @priceCatcherData.
  ///
  /// In en, this message translates to:
  /// **'PriceCatcher real-time data'**
  String get priceCatcherData;

  /// No description provided for @expenditureComparison.
  ///
  /// In en, this message translates to:
  /// **'Expenditure Comparison'**
  String get expenditureComparison;

  /// No description provided for @weightAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Weight Adjustment (Personalized)'**
  String get weightAdjustment;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @safetyMapLayer.
  ///
  /// In en, this message translates to:
  /// **'Safety Map Layer'**
  String get safetyMapLayer;

  /// No description provided for @cherasArea.
  ///
  /// In en, this message translates to:
  /// **'KL - Cheras Area'**
  String get cherasArea;

  /// No description provided for @overallSafetyIndex.
  ///
  /// In en, this message translates to:
  /// **'Overall Safety Index'**
  String get overallSafetyIndex;

  /// No description provided for @betterThanNational.
  ///
  /// In en, this message translates to:
  /// **'Better than {percent}% of national areas'**
  String betterThanNational(Object percent);

  /// No description provided for @floodRiskLevel.
  ///
  /// In en, this message translates to:
  /// **'Flood Risk Level'**
  String get floodRiskLevel;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @noFloodHistory.
  ///
  /// In en, this message translates to:
  /// **'No flood records in last 5 years'**
  String get noFloodHistory;

  /// No description provided for @crimeTypeFocus.
  ///
  /// In en, this message translates to:
  /// **'Crime Type Focus'**
  String get crimeTypeFocus;

  /// No description provided for @violentCrime.
  ///
  /// In en, this message translates to:
  /// **'Violent Crime'**
  String get violentCrime;

  /// No description provided for @propertyCrime.
  ///
  /// In en, this message translates to:
  /// **'Property Crime'**
  String get propertyCrime;

  /// No description provided for @cyberFraud.
  ///
  /// In en, this message translates to:
  /// **'Cyber Fraud'**
  String get cyberFraud;

  /// No description provided for @crimeTrend.
  ///
  /// In en, this message translates to:
  /// **'Crime Rate Trend'**
  String get crimeTrend;

  /// No description provided for @warningBanner.
  ///
  /// In en, this message translates to:
  /// **'Note: Current Northeast Monsoon season, potential flood risk in low-lying areas.'**
  String get warningBanner;

  /// No description provided for @incomeClassDistribution.
  ///
  /// In en, this message translates to:
  /// **'Income Class Distribution (2024)'**
  String get incomeClassDistribution;

  /// No description provided for @dosmOfficialData.
  ///
  /// In en, this message translates to:
  /// **'DOSM Official Data'**
  String get dosmOfficialData;

  /// No description provided for @lowIncome.
  ///
  /// In en, this message translates to:
  /// **'Low Income'**
  String get lowIncome;

  /// No description provided for @middleClass.
  ///
  /// In en, this message translates to:
  /// **'Middle Class'**
  String get middleClass;

  /// No description provided for @highIncome.
  ///
  /// In en, this message translates to:
  /// **'High Income'**
  String get highIncome;

  /// No description provided for @m40HigherThanAverage.
  ///
  /// In en, this message translates to:
  /// **'M40 group in this area is higher than national average ({percent}%)'**
  String m40HigherThanAverage(Object percent);

  /// No description provided for @developmentRanking.
  ///
  /// In en, this message translates to:
  /// **'Development Ranking'**
  String get developmentRanking;

  /// No description provided for @rankNumber.
  ///
  /// In en, this message translates to:
  /// **'No. {rank}'**
  String rankNumber(Object rank);

  /// No description provided for @totalConstituencies.
  ///
  /// In en, this message translates to:
  /// **'Out of {total} constituencies'**
  String totalConstituencies(Object total);

  /// No description provided for @giniCoefficient.
  ///
  /// In en, this message translates to:
  /// **'Gini Coefficient (Inequality)'**
  String get giniCoefficient;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @incomeDistributionCurve.
  ///
  /// In en, this message translates to:
  /// **'Monthly Household Income Distribution'**
  String get incomeDistributionCurve;

  /// No description provided for @yourIncomePosition.
  ///
  /// In en, this message translates to:
  /// **'Your Income Position'**
  String get yourIncomePosition;

  /// No description provided for @monthlyHouseholdIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Household Income (RM)'**
  String get monthlyHouseholdIncome;

  /// No description provided for @incomeBetterThan.
  ///
  /// In en, this message translates to:
  /// **'Your income is better than {percent}% of households in this area, in the M40 high-end range.'**
  String incomeBetterThan(Object percent);

  /// No description provided for @infrastructureCoverage.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure Coverage (ICI)'**
  String get infrastructureCoverage;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @iciDescription.
  ///
  /// In en, this message translates to:
  /// **'This index aggregates water, electricity, communication, and public service coverage'**
  String get iciDescription;

  /// No description provided for @waterSupply.
  ///
  /// In en, this message translates to:
  /// **'Water Supply'**
  String get waterSupply;

  /// No description provided for @electricNetwork.
  ///
  /// In en, this message translates to:
  /// **'Electric Network'**
  String get electricNetwork;

  /// No description provided for @medicalDensity.
  ///
  /// In en, this message translates to:
  /// **'Medical Density'**
  String get medicalDensity;

  /// No description provided for @educationalResources.
  ///
  /// In en, this message translates to:
  /// **'Education Resources'**
  String get educationalResources;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @sufficient.
  ///
  /// In en, this message translates to:
  /// **'Sufficient'**
  String get sufficient;

  /// No description provided for @iciRadarChart.
  ///
  /// In en, this message translates to:
  /// **'ICI Dimension Balance Radar Chart'**
  String get iciRadarChart;

  /// No description provided for @personalizedWeight.
  ///
  /// In en, this message translates to:
  /// **'Personalized Demand Weights'**
  String get personalizedWeight;

  /// No description provided for @medicalImportance.
  ///
  /// In en, this message translates to:
  /// **'Medical Service Importance'**
  String get medicalImportance;

  /// No description provided for @educationPriority.
  ///
  /// In en, this message translates to:
  /// **'Education Resource Priority'**
  String get educationPriority;

  /// No description provided for @commercialConvenience.
  ///
  /// In en, this message translates to:
  /// **'Commercial Convenience'**
  String get commercialConvenience;

  /// No description provided for @connectivityScore.
  ///
  /// In en, this message translates to:
  /// **'Connectivity Overall Score'**
  String get connectivityScore;

  /// No description provided for @highlyConvenient.
  ///
  /// In en, this message translates to:
  /// **'Highly Convenient'**
  String get highlyConvenient;

  /// No description provided for @betterThanKL.
  ///
  /// In en, this message translates to:
  /// **'Better than {percent}% of areas in Klang Valley'**
  String betterThanKL(Object percent);

  /// No description provided for @nearbyStations.
  ///
  /// In en, this message translates to:
  /// **'Nearby Stations (within 500m)'**
  String get nearbyStations;

  /// No description provided for @walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get walking;

  /// No description provided for @pedestrianBridge.
  ///
  /// In en, this message translates to:
  /// **'Pedestrian Bridge Link'**
  String get pedestrianBridge;

  /// No description provided for @trafficDensityHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Traffic Network Density Heatmap'**
  String get trafficDensityHeatmap;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @commuteModeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Commute Mode Distribution'**
  String get commuteModeDistribution;

  /// No description provided for @accountCenter.
  ///
  /// In en, this message translates to:
  /// **'Account Center'**
  String get accountCenter;

  /// No description provided for @verifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get verifiedUser;

  /// No description provided for @relocationHistory.
  ///
  /// In en, this message translates to:
  /// **'Relocation Assessment History'**
  String get relocationHistory;

  /// No description provided for @defaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Default Location'**
  String get defaultLocation;

  /// No description provided for @savedComparisons.
  ///
  /// In en, this message translates to:
  /// **'Saved Comparisons'**
  String get savedComparisons;

  /// No description provided for @assessmentDate.
  ///
  /// In en, this message translates to:
  /// **'Assessment Date: {date}'**
  String assessmentDate(Object date);

  /// No description provided for @myComments.
  ///
  /// In en, this message translates to:
  /// **'My Comments'**
  String get myComments;

  /// No description provided for @likedAreas.
  ///
  /// In en, this message translates to:
  /// **'Liked Areas'**
  String get likedAreas;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
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
