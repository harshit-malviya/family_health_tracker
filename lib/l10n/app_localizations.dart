import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi'),
  ];

  /// Title of the application
  ///
  /// In en, this message translates to:
  /// **'Family Health Tracker'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get navTrends;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navDoctorPdf.
  ///
  /// In en, this message translates to:
  /// **'Doctor PDF'**
  String get navDoctorPdf;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @familyHealth.
  ///
  /// In en, this message translates to:
  /// **'Family Health'**
  String get familyHealth;

  /// No description provided for @dailyRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily BP & Blood Sugar records'**
  String get dailyRecordsSubtitle;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String yearsOld(int age);

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @bloodSugar.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar / Glucose'**
  String get bloodSugar;

  /// No description provided for @pulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get pulse;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpm;

  /// No description provided for @overviewAndAverages.
  ///
  /// In en, this message translates to:
  /// **'Overview & Averages'**
  String get overviewAndAverages;

  /// No description provided for @avgBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Avg Blood Pressure'**
  String get avgBloodPressure;

  /// No description provided for @avgBloodGlucose.
  ///
  /// In en, this message translates to:
  /// **'Avg Blood Glucose'**
  String get avgBloodGlucose;

  /// No description provided for @normalPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% normal'**
  String normalPercent(String percent);

  /// No description provided for @inTargetRange.
  ///
  /// In en, this message translates to:
  /// **'{inRange}/{total} in target'**
  String inTargetRange(int inRange, int total);

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New Reading'**
  String get newReading;

  /// No description provided for @whatMeasuring.
  ///
  /// In en, this message translates to:
  /// **'What are you measuring?'**
  String get whatMeasuring;

  /// No description provided for @bpAndPulse.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure & Pulse'**
  String get bpAndPulse;

  /// No description provided for @bpAndPulseDesc.
  ///
  /// In en, this message translates to:
  /// **'Systolic, Diastolic, Heart rate'**
  String get bpAndPulseDesc;

  /// No description provided for @bloodSugarDesc.
  ///
  /// In en, this message translates to:
  /// **'Fasting, Post-meal, Bedtime'**
  String get bloodSugarDesc;

  /// No description provided for @readingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Readings History'**
  String get readingsHistory;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterBp.
  ///
  /// In en, this message translates to:
  /// **'BP'**
  String get filterBp;

  /// No description provided for @filterGlucose.
  ///
  /// In en, this message translates to:
  /// **'Glucose'**
  String get filterGlucose;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No {filter} records for {name} yet.'**
  String noRecordsYet(String filter, String name);

  /// No description provided for @deleteReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading?'**
  String get deleteReadingTitle;

  /// No description provided for @deleteReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this reading?'**
  String get deleteReadingConfirm;

  /// No description provided for @readingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reading deleted.'**
  String get readingDeleted;

  /// No description provided for @editReading.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading'**
  String get editReading;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @trendsAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Trends & Analytics'**
  String get trendsAndAnalytics;

  /// No description provided for @tabBp.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get tabBp;

  /// No description provided for @tabGlucose.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose'**
  String get tabGlucose;

  /// No description provided for @noBpLogs.
  ///
  /// In en, this message translates to:
  /// **'No blood pressure logs yet for this member.'**
  String get noBpLogs;

  /// No description provided for @noGlucoseLogs.
  ///
  /// In en, this message translates to:
  /// **'No blood glucose logs yet for this member.'**
  String get noGlucoseLogs;

  /// No description provided for @systolicTrend.
  ///
  /// In en, this message translates to:
  /// **'Systolic & Diastolic Trend'**
  String get systolicTrend;

  /// No description provided for @morningAvg.
  ///
  /// In en, this message translates to:
  /// **'Morning Avg'**
  String get morningAvg;

  /// No description provided for @eveningAvg.
  ///
  /// In en, this message translates to:
  /// **'Evening Avg'**
  String get eveningAvg;

  /// No description provided for @latestTrend.
  ///
  /// In en, this message translates to:
  /// **'Latest Trend'**
  String get latestTrend;

  /// No description provided for @days7Avg.
  ///
  /// In en, this message translates to:
  /// **'7-Day Avg'**
  String get days7Avg;

  /// No description provided for @days30Avg.
  ///
  /// In en, this message translates to:
  /// **'30-Day Avg'**
  String get days30Avg;

  /// No description provided for @timeInRange.
  ///
  /// In en, this message translates to:
  /// **'Time in Target Range'**
  String get timeInRange;

  /// No description provided for @targetRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Target: 70 - 180 mg/dL'**
  String get targetRangeHint;

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} readings logged'**
  String readingsCount(int count);

  /// No description provided for @doctorReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Consultation Report'**
  String get doctorReportTitle;

  /// No description provided for @physicianSummaryPdf.
  ///
  /// In en, this message translates to:
  /// **'Physician Summary PDF'**
  String get physicianSummaryPdf;

  /// No description provided for @readyToPrintFor.
  ///
  /// In en, this message translates to:
  /// **'Ready to print or share for {name}'**
  String readyToPrintFor(String name);

  /// No description provided for @selectFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Select a family member'**
  String get selectFamilyMember;

  /// No description provided for @selectTimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Time Period:'**
  String get selectTimePeriod;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get days30;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get days90;

  /// No description provided for @days365.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get days365;

  /// No description provided for @includeInReport.
  ///
  /// In en, this message translates to:
  /// **'Include in Report:'**
  String get includeInReport;

  /// No description provided for @includeBpLogs.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure logs & averages'**
  String get includeBpLogs;

  /// No description provided for @includeGlucoseLogs.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose logs & meal context'**
  String get includeGlucoseLogs;

  /// No description provided for @printOrSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Print / Share PDF Report'**
  String get printOrSharePdf;

  /// No description provided for @previewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview Doctor PDF'**
  String get previewPdf;

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get generatingPdf;

  /// No description provided for @noRecordsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No records found for the selected time period.'**
  String get noRecordsPeriod;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Backup'**
  String get settingsTitle;

  /// No description provided for @clinicalPreferences.
  ///
  /// In en, this message translates to:
  /// **'Clinical Preferences'**
  String get clinicalPreferences;

  /// No description provided for @glucoseUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Glucose Unit'**
  String get glucoseUnitTitle;

  /// No description provided for @glucoseUnitUsIndia.
  ///
  /// In en, this message translates to:
  /// **'US / India standard (mg/dL)'**
  String get glucoseUnitUsIndia;

  /// No description provided for @glucoseUnitIntl.
  ///
  /// In en, this message translates to:
  /// **'International standard (mmol/L)'**
  String get glucoseUnitIntl;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language / भाषा'**
  String get languageSectionTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App display language (ऐप की भाषा)'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get languageHindi;

  /// No description provided for @dataBackupPortability.
  ///
  /// In en, this message translates to:
  /// **'Data Backup & Portability'**
  String get dataBackupPortability;

  /// No description provided for @exportHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'Export Health Records'**
  String get exportHealthRecords;

  /// No description provided for @exportHealthRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save JSON backup file or share to Google Drive / WhatsApp'**
  String get exportHealthRecordsSubtitle;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// No description provided for @restoreFromBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup by selecting a .json file'**
  String get restoreFromBackupSubtitle;

  /// No description provided for @familyProfiles.
  ///
  /// In en, this message translates to:
  /// **'Family Profiles'**
  String get familyProfiles;

  /// No description provided for @addNewMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addNewMember;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? All associated health readings will be permanently removed.'**
  String deleteProfileConfirm(String name);

  /// No description provided for @cannotDeleteLast.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the only family profile.'**
  String get cannotDeleteLast;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile created!'**
  String get profileCreated;

  /// No description provided for @profileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted.'**
  String get profileDeleted;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully!'**
  String get backupSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get restoreSuccess;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Health Tracker'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track blood pressure and blood sugar for you and your family in one private, secure place.'**
  String get welcomeSubtitle;

  /// No description provided for @setupFirstProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Profile'**
  String get setupFirstProfile;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get memberName;

  /// No description provided for @memberNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Papa, Maa, Rahul, Self'**
  String get memberNameHint;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @chooseColorAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar & Theme Color'**
  String get chooseColorAvatar;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @orRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Already have a backup? Restore here'**
  String get orRestoreBackup;

  /// No description provided for @logBpTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Blood Pressure'**
  String get logBpTitle;

  /// No description provided for @editBpTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Blood Pressure'**
  String get editBpTitle;

  /// No description provided for @forMember.
  ///
  /// In en, this message translates to:
  /// **'For {name} ({relation})'**
  String forMember(String name, String relation);

  /// No description provided for @recordReading.
  ///
  /// In en, this message translates to:
  /// **'Record reading'**
  String get recordReading;

  /// No description provided for @dateTimeOfReading.
  ///
  /// In en, this message translates to:
  /// **'Date & Time of Reading'**
  String get dateTimeOfReading;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @systolicUpper.
  ///
  /// In en, this message translates to:
  /// **'Systolic (Upper)'**
  String get systolicUpper;

  /// No description provided for @diastolicLower.
  ///
  /// In en, this message translates to:
  /// **'Diastolic (Lower)'**
  String get diastolicLower;

  /// No description provided for @pulseBpm.
  ///
  /// In en, this message translates to:
  /// **'Pulse (bpm)'**
  String get pulseBpm;

  /// No description provided for @armMeasured.
  ///
  /// In en, this message translates to:
  /// **'Arm Measured'**
  String get armMeasured;

  /// No description provided for @armLeft.
  ///
  /// In en, this message translates to:
  /// **'Left Arm'**
  String get armLeft;

  /// No description provided for @armRight.
  ///
  /// In en, this message translates to:
  /// **'Right Arm'**
  String get armRight;

  /// No description provided for @bodyPosture.
  ///
  /// In en, this message translates to:
  /// **'Body Posture'**
  String get bodyPosture;

  /// No description provided for @postureSitting.
  ///
  /// In en, this message translates to:
  /// **'Sitting'**
  String get postureSitting;

  /// No description provided for @postureLying.
  ///
  /// In en, this message translates to:
  /// **'Lying down'**
  String get postureLying;

  /// No description provided for @postureStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get postureStanding;

  /// No description provided for @irregularHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'Irregular Heartbeat detected'**
  String get irregularHeartbeat;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @notesHintBp.
  ///
  /// In en, this message translates to:
  /// **'e.g. after 10 min rest, felt dizzy, morning'**
  String get notesHintBp;

  /// No description provided for @saveBpReading.
  ///
  /// In en, this message translates to:
  /// **'Save BP Reading'**
  String get saveBpReading;

  /// No description provided for @updateBpReading.
  ///
  /// In en, this message translates to:
  /// **'Update BP Reading'**
  String get updateBpReading;

  /// No description provided for @logGlucoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Blood Sugar'**
  String get logGlucoseTitle;

  /// No description provided for @editGlucoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Blood Sugar'**
  String get editGlucoseTitle;

  /// No description provided for @glucoseValue.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar Value'**
  String get glucoseValue;

  /// No description provided for @timingMealContext.
  ///
  /// In en, this message translates to:
  /// **'Timing / Meal Context'**
  String get timingMealContext;

  /// No description provided for @saveGlucoseReading.
  ///
  /// In en, this message translates to:
  /// **'Save Sugar Reading'**
  String get saveGlucoseReading;

  /// No description provided for @updateGlucoseReading.
  ///
  /// In en, this message translates to:
  /// **'Update Sugar Reading'**
  String get updateGlucoseReading;

  /// No description provided for @notesHintGlucose.
  ///
  /// In en, this message translates to:
  /// **'e.g. after festive meal, took medicine'**
  String get notesHintGlucose;

  /// No description provided for @mealFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get mealFasting;

  /// No description provided for @mealBeforeMeal.
  ///
  /// In en, this message translates to:
  /// **'Before Meal'**
  String get mealBeforeMeal;

  /// No description provided for @mealPostMeal.
  ///
  /// In en, this message translates to:
  /// **'After Meal (2h)'**
  String get mealPostMeal;

  /// No description provided for @mealBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get mealBedtime;

  /// No description provided for @mealRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get mealRandom;

  /// No description provided for @mealFastingHint.
  ///
  /// In en, this message translates to:
  /// **'Before any morning food'**
  String get mealFastingHint;

  /// No description provided for @mealBeforeMealHint.
  ///
  /// In en, this message translates to:
  /// **'Pre-lunch or dinner'**
  String get mealBeforeMealHint;

  /// No description provided for @mealPostMealHint.
  ///
  /// In en, this message translates to:
  /// **'2 hours after eating'**
  String get mealPostMealHint;

  /// No description provided for @mealBedtimeHint.
  ///
  /// In en, this message translates to:
  /// **'Before going to sleep'**
  String get mealBedtimeHint;

  /// No description provided for @mealRandomHint.
  ///
  /// In en, this message translates to:
  /// **'Any other time'**
  String get mealRandomHint;

  /// No description provided for @bpNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bpNormal;

  /// No description provided for @bpNormalHint.
  ///
  /// In en, this message translates to:
  /// **'Under 120/80 mmHg'**
  String get bpNormalHint;

  /// No description provided for @bpElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get bpElevated;

  /// No description provided for @bpElevatedHint.
  ///
  /// In en, this message translates to:
  /// **'120-129 / <80 mmHg'**
  String get bpElevatedHint;

  /// No description provided for @bpStage1.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Stage 1'**
  String get bpStage1;

  /// No description provided for @bpStage1Hint.
  ///
  /// In en, this message translates to:
  /// **'130-139 / 80-89 mmHg'**
  String get bpStage1Hint;

  /// No description provided for @bpStage2.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Stage 2'**
  String get bpStage2;

  /// No description provided for @bpStage2Hint.
  ///
  /// In en, this message translates to:
  /// **'140+ / 90+ mmHg'**
  String get bpStage2Hint;

  /// No description provided for @bpCrisis.
  ///
  /// In en, this message translates to:
  /// **'Hypertensive Crisis'**
  String get bpCrisis;

  /// No description provided for @bpCrisisHint.
  ///
  /// In en, this message translates to:
  /// **'Higher than 180 and/or 120'**
  String get bpCrisisHint;

  /// No description provided for @glucoseLow.
  ///
  /// In en, this message translates to:
  /// **'Low (Hypo)'**
  String get glucoseLow;

  /// No description provided for @glucoseLowHint.
  ///
  /// In en, this message translates to:
  /// **'Under 70 mg/dL'**
  String get glucoseLowHint;

  /// No description provided for @glucoseNormal.
  ///
  /// In en, this message translates to:
  /// **'Target Range'**
  String get glucoseNormal;

  /// No description provided for @glucoseNormalHint.
  ///
  /// In en, this message translates to:
  /// **'70-130 mg/dL fasting, <180 post-meal'**
  String get glucoseNormalHint;

  /// No description provided for @glucoseElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get glucoseElevated;

  /// No description provided for @glucoseElevatedHint.
  ///
  /// In en, this message translates to:
  /// **'131-180 mg/dL fasting'**
  String get glucoseElevatedHint;

  /// No description provided for @glucoseHigh.
  ///
  /// In en, this message translates to:
  /// **'High (Hyper)'**
  String get glucoseHigh;

  /// No description provided for @glucoseHighHint.
  ///
  /// In en, this message translates to:
  /// **'Above 180 mg/dL'**
  String get glucoseHighHint;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @switchMember.
  ///
  /// In en, this message translates to:
  /// **'Switch Member'**
  String get switchMember;

  /// No description provided for @manageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage Profiles'**
  String get manageProfiles;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
