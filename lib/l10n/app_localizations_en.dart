// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Health Tracker';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTrends => 'Trends';

  @override
  String get navHistory => 'History';

  @override
  String get navDoctorPdf => 'Doctor PDF';

  @override
  String get navSettings => 'Settings';

  @override
  String get familyHealth => 'Family Health';

  @override
  String get dailyRecordsSubtitle => 'Daily BP & Blood Sugar records';

  @override
  String yearsOld(int age) {
    return '$age yrs';
  }

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String get bloodSugar => 'Blood Sugar / Glucose';

  @override
  String get pulse => 'Pulse';

  @override
  String get bpm => 'bpm';

  @override
  String get overviewAndAverages => 'Overview & Averages';

  @override
  String get avgBloodPressure => 'Avg Blood Pressure';

  @override
  String get avgBloodGlucose => 'Avg Blood Glucose';

  @override
  String normalPercent(String percent) {
    return '$percent% normal';
  }

  @override
  String inTargetRange(int inRange, int total) {
    return '$inRange/$total in target';
  }

  @override
  String get newReading => 'New Reading';

  @override
  String get whatMeasuring => 'What are you measuring?';

  @override
  String get bpAndPulse => 'Blood Pressure & Pulse';

  @override
  String get bpAndPulseDesc => 'Systolic, Diastolic, Heart rate';

  @override
  String get bloodSugarDesc => 'Fasting, Post-meal, Bedtime';

  @override
  String get readingsHistory => 'Readings History';

  @override
  String get filterAll => 'All';

  @override
  String get filterBp => 'BP';

  @override
  String get filterGlucose => 'Glucose';

  @override
  String noRecordsYet(String filter, String name) {
    return 'No $filter records for $name yet.';
  }

  @override
  String get deleteReadingTitle => 'Delete Reading?';

  @override
  String get deleteReadingConfirm =>
      'Are you sure you want to permanently delete this reading?';

  @override
  String get readingDeleted => 'Reading deleted.';

  @override
  String get undo => 'Undo';

  @override
  String get longPressOptionsHint => 'Long press card to edit or delete.';

  @override
  String get editReading => 'Edit Reading';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get trendsAndAnalytics => 'Trends & Analytics';

  @override
  String get tabBp => 'Blood Pressure';

  @override
  String get tabGlucose => 'Blood Glucose';

  @override
  String get noBpLogs => 'No blood pressure logs yet for this member.';

  @override
  String get noGlucoseLogs => 'No blood glucose logs yet for this member.';

  @override
  String get systolicTrend => 'Systolic & Diastolic Trend';

  @override
  String get morningAvg => 'Morning Avg';

  @override
  String get eveningAvg => 'Evening Avg';

  @override
  String get latestTrend => 'Latest Trend';

  @override
  String get days7Avg => '7-Day Avg';

  @override
  String get days30Avg => '30-Day Avg';

  @override
  String get timeInRange => 'Time in Target Range';

  @override
  String get targetRangeHint => 'Target: 70 - 180 mg/dL';

  @override
  String readingsCount(int count) {
    return '$count readings logged';
  }

  @override
  String get doctorReportTitle => 'Doctor Consultation Report';

  @override
  String get physicianSummaryPdf => 'Physician Summary PDF';

  @override
  String readyToPrintFor(String name) {
    return 'Ready to print or share for $name';
  }

  @override
  String get selectFamilyMember => 'Select a family member';

  @override
  String get selectTimePeriod => 'Select Time Period:';

  @override
  String get days7 => 'Last 7 Days';

  @override
  String get days30 => 'Last 30 Days';

  @override
  String get days90 => 'Last 90 Days';

  @override
  String get days365 => '1 Year';

  @override
  String get includeInReport => 'Include in Report:';

  @override
  String get includeBpLogs => 'Blood Pressure logs & averages';

  @override
  String get includeGlucoseLogs => 'Blood Glucose logs & meal context';

  @override
  String get printOrSharePdf => 'Print / Share PDF Report';

  @override
  String get previewPdf => 'Preview Doctor PDF';

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get noRecordsPeriod =>
      'No records found for the selected time period.';

  @override
  String get settingsTitle => 'Settings & Backup';

  @override
  String get clinicalPreferences => 'Clinical Preferences';

  @override
  String get glucoseUnitTitle => 'Blood Glucose Unit';

  @override
  String get glucoseUnitUsIndia => 'US / India standard (mg/dL)';

  @override
  String get glucoseUnitIntl => 'International standard (mmol/L)';

  @override
  String get languageSectionTitle => 'Language / भाषा';

  @override
  String get languageSubtitle => 'App display language (ऐप की भाषा)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी (Hindi)';

  @override
  String get dataBackupPortability => 'Data Backup & Portability';

  @override
  String get exportHealthRecords => 'Export Health Records';

  @override
  String get exportHealthRecordsSubtitle =>
      'Save JSON backup file or share to Google Drive / WhatsApp';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get restoreFromBackupSubtitle =>
      'Import backup by selecting a .json file';

  @override
  String get familyProfiles => 'Family Profiles';

  @override
  String get addNewMember => 'Add Family Member';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileConfirm(String name) {
    return 'Are you sure you want to delete $name? All associated health readings will be permanently removed.';
  }

  @override
  String get cannotDeleteLast => 'Cannot delete the only family profile.';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get profileCreated => 'Profile created!';

  @override
  String get profileDeleted => 'Profile deleted.';

  @override
  String get backupSuccess => 'Backup exported successfully!';

  @override
  String get restoreSuccess => 'Data restored successfully!';

  @override
  String get welcomeTitle => 'Family Health Tracker';

  @override
  String get welcomeSubtitle =>
      'Track blood pressure and blood sugar for you and your family in one private, secure place.';

  @override
  String get setupFirstProfile => 'Create Your First Profile';

  @override
  String get memberName => 'Member Name';

  @override
  String get memberNameHint => 'e.g. Papa, Maa, Rahul, Self';

  @override
  String get relationship => 'Relationship';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get chooseColorAvatar => 'Choose Avatar & Theme Color';

  @override
  String get getStarted => 'Get Started';

  @override
  String get orRestoreBackup => 'Already have a backup? Restore here';

  @override
  String get logBpTitle => 'Log Blood Pressure';

  @override
  String get editBpTitle => 'Edit Blood Pressure';

  @override
  String forMember(String name, String relation) {
    return 'For $name ($relation)';
  }

  @override
  String get recordReading => 'Record reading';

  @override
  String get dateTimeOfReading => 'Date & Time of Reading';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get systolicUpper => 'Systolic (Upper)';

  @override
  String get diastolicLower => 'Diastolic (Lower)';

  @override
  String get pulseBpm => 'Pulse (bpm)';

  @override
  String get armMeasured => 'Arm Measured';

  @override
  String get armLeft => 'Left Arm';

  @override
  String get armRight => 'Right Arm';

  @override
  String get bodyPosture => 'Body Posture';

  @override
  String get postureSitting => 'Sitting';

  @override
  String get postureLying => 'Lying down';

  @override
  String get postureStanding => 'Standing';

  @override
  String get irregularHeartbeat => 'Irregular Heartbeat detected';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get notesHintBp => 'e.g. after 10 min rest, felt dizzy, morning';

  @override
  String get saveBpReading => 'Save BP Reading';

  @override
  String get updateBpReading => 'Update BP Reading';

  @override
  String get logGlucoseTitle => 'Log Blood Sugar';

  @override
  String get editGlucoseTitle => 'Edit Blood Sugar';

  @override
  String get glucoseValue => 'Blood Sugar Value';

  @override
  String get timingMealContext => 'Timing / Meal Context';

  @override
  String get saveGlucoseReading => 'Save Sugar Reading';

  @override
  String get updateGlucoseReading => 'Update Sugar Reading';

  @override
  String get notesHintGlucose => 'e.g. after festive meal, took medicine';

  @override
  String get mealFasting => 'Fasting';

  @override
  String get mealBeforeMeal => 'Before Meal';

  @override
  String get mealPostMeal => 'After Meal (2h)';

  @override
  String get mealBedtime => 'Bedtime';

  @override
  String get mealRandom => 'Random';

  @override
  String get mealFastingHint => 'Before any morning food';

  @override
  String get mealBeforeMealHint => 'Pre-lunch or dinner';

  @override
  String get mealPostMealHint => '2 hours after eating';

  @override
  String get mealBedtimeHint => 'Before going to sleep';

  @override
  String get mealRandomHint => 'Any other time';

  @override
  String get bpNormal => 'Normal';

  @override
  String get bpNormalHint => 'Under 120/80 mmHg';

  @override
  String get bpElevated => 'Elevated';

  @override
  String get bpElevatedHint => '120-129 / <80 mmHg';

  @override
  String get bpStage1 => 'Hypertension Stage 1';

  @override
  String get bpStage1Hint => '130-139 / 80-89 mmHg';

  @override
  String get bpStage2 => 'Hypertension Stage 2';

  @override
  String get bpStage2Hint => '140+ / 90+ mmHg';

  @override
  String get bpCrisis => 'Hypertensive Crisis';

  @override
  String get bpCrisisHint => 'Higher than 180 and/or 120';

  @override
  String get glucoseLow => 'Low (Hypo)';

  @override
  String get glucoseLowHint => 'Under 70 mg/dL';

  @override
  String get glucoseNormal => 'Target Range';

  @override
  String get glucoseNormalHint => '70-130 mg/dL fasting, <180 post-meal';

  @override
  String get glucoseElevated => 'Elevated';

  @override
  String get glucoseElevatedHint => '131-180 mg/dL fasting';

  @override
  String get glucoseHigh => 'High (Hyper)';

  @override
  String get glucoseHighHint => 'Above 180 mg/dL';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get now => 'Now';

  @override
  String get switchMember => 'Switch Member';

  @override
  String get manageProfiles => 'Manage Profiles';

  @override
  String get errorInvalidSystolic => 'Systolic must be between 40 and 300 mmHg';

  @override
  String get errorInvalidDiastolic =>
      'Diastolic must be between 30 and 200 mmHg';

  @override
  String get errorSystolicMustExceedDiastolic =>
      'Systolic must be at least 10 mmHg higher than Diastolic';

  @override
  String get errorInvalidPulse => 'Pulse must be between 30 and 250 bpm';

  @override
  String get errorInvalidGlucoseMgDl =>
      'Glucose must be between 20 and 600 mg/dL';

  @override
  String get errorInvalidGlucoseMmol =>
      'Glucose must be between 1.1 and 33.3 mmol/L';

  @override
  String get errorSaveFailed => 'Failed to save reading. Please try again.';

  @override
  String get directPrintReport => 'Direct Print Report';

  @override
  String get errorGeneratePdf =>
      'Failed to generate PDF report. Please try again.';

  @override
  String get errorPrintPdf =>
      'Failed to print report. Please check printer settings.';
}
