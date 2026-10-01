// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'फैमिली हेल्थ ट्रैकर';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navTrends => 'ट्रेंड्स';

  @override
  String get navHistory => 'इतिहास';

  @override
  String get navDoctorPdf => 'डॉक्टर PDF';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get familyHealth => 'पारिवारिक स्वास्थ्य';

  @override
  String get dailyRecordsSubtitle => 'दैनिक बीपी और ब्लड शुगर रिकॉर्ड';

  @override
  String yearsOld(int age) {
    return '$age वर्ष';
  }

  @override
  String get bloodPressure => 'रक्तचाप (BP)';

  @override
  String get bloodSugar => 'ब्लड शुगर (ग्लूकोज)';

  @override
  String get pulse => 'नाड़ी दर (Pulse)';

  @override
  String get bpm => 'bpm';

  @override
  String get overviewAndAverages => 'समीक्षा और औसत';

  @override
  String get avgBloodPressure => 'औसत रक्तचाप';

  @override
  String get avgBloodGlucose => 'औसत ब्लड शुगर';

  @override
  String normalPercent(String percent) {
    return '$percent% सामान्य';
  }

  @override
  String inTargetRange(int inRange, int total) {
    return '$inRange/$total लक्ष्य में';
  }

  @override
  String get newReading => 'नया रिकॉर्ड जोड़ें';

  @override
  String get whatMeasuring => 'आप क्या माप रहे हैं?';

  @override
  String get bpAndPulse => 'रक्तचाप और पल्स (BP & Pulse)';

  @override
  String get bpAndPulseDesc => 'सिस्टोलिक, डायस्टोलिक, दिल की धड़कन';

  @override
  String get bloodSugarDesc => 'खाली पेट, खाने के बाद, सोते समय';

  @override
  String get readingsHistory => 'रीडिंग्स का इतिहास';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterBp => 'बीपी (BP)';

  @override
  String get filterGlucose => 'शुगर';

  @override
  String noRecordsYet(String filter, String name) {
    return '$name के लिए अभी कोई $filter रिकॉर्ड नहीं है।';
  }

  @override
  String get deleteReadingTitle => 'रीडिंग हटाएं?';

  @override
  String get deleteReadingConfirm =>
      'क्या आप वाकई इस रीडिंग को हमेशा के लिए हटाना चाहते हैं?';

  @override
  String get readingDeleted => 'रीडिंग हटा दी गई।';

  @override
  String get undo => 'वापस करें';

  @override
  String get longPressOptionsHint => 'विकल्पों के लिए कार्ड को दबाकर रखें।';

  @override
  String get editReading => 'रीडिंग संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सुरक्षित करें';

  @override
  String get trendsAndAnalytics => 'ट्रेंड्स और विश्लेषण';

  @override
  String get tabBp => 'रक्तचाप (BP)';

  @override
  String get tabGlucose => 'ब्लड शुगर';

  @override
  String get noBpLogs => 'इस सदस्य के लिए अभी कोई बीपी रिकॉर्ड नहीं है।';

  @override
  String get noGlucoseLogs =>
      'इस सदस्य के लिए अभी कोई ब्लड शुगर रिकॉर्ड नहीं है।';

  @override
  String get systolicTrend => 'सिस्टोलिक और डायस्टोलिक ट्रेंड';

  @override
  String get morningAvg => 'सुबह का औसत';

  @override
  String get eveningAvg => 'शाम का औसत';

  @override
  String get latestTrend => 'हालिया रुझान';

  @override
  String get days7Avg => '7 दिनों का औसत';

  @override
  String get days30Avg => '30 दिनों का औसत';

  @override
  String get timeInRange => 'लक्ष्य सीमा में समय';

  @override
  String get targetRangeHint => 'लक्ष्य: 70 - 180 mg/dL';

  @override
  String readingsCount(int count) {
    return '$count रीडिंग दर्ज';
  }

  @override
  String get doctorReportTitle => 'डॉक्टर परामर्श रिपोर्ट';

  @override
  String get physicianSummaryPdf => 'डॉक्टर सारांश PDF';

  @override
  String readyToPrintFor(String name) {
    return '$name के लिए प्रिंट या शेयर करने हेतु तैयार';
  }

  @override
  String get selectFamilyMember => 'परिवार का सदस्य चुनें';

  @override
  String get selectTimePeriod => 'समय अवधि चुनें:';

  @override
  String get days7 => 'पिछले 7 दिन';

  @override
  String get days30 => 'पिछले 30 दिन';

  @override
  String get days90 => 'पिछले 90 दिन';

  @override
  String get days365 => '1 वर्ष';

  @override
  String get includeInReport => 'रिपोर्ट में शामिल करें:';

  @override
  String get includeBpLogs => 'रक्तचाप लॉग और औसत';

  @override
  String get includeGlucoseLogs => 'ब्लड शुगर लॉग और भोजन संदर्भ';

  @override
  String get printOrSharePdf => 'PDF रिपोर्ट प्रिंट / शेयर करें';

  @override
  String get previewPdf => 'डॉक्टर PDF देखें';

  @override
  String get generatingPdf => 'PDF तैयार हो रहा है...';

  @override
  String get noRecordsPeriod =>
      'चुनी गई समय अवधि के लिए कोई रिकॉर्ड नहीं मिला।';

  @override
  String get settingsTitle => 'सेटिंग्स और बैकअप';

  @override
  String get clinicalPreferences => 'क्लिनिकल प्राथमिकताएं';

  @override
  String get glucoseUnitTitle => 'ब्लड शुगर इकाई (Unit)';

  @override
  String get glucoseUnitUsIndia => 'भारत / अमेरिका मानक (mg/dL)';

  @override
  String get glucoseUnitIntl => 'अंतर्राष्ट्रीय मानक (mmol/L)';

  @override
  String get languageSectionTitle => 'भाषा / Language';

  @override
  String get languageSubtitle => 'ऐप की भाषा चुनें (App display language)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी (Hindi)';

  @override
  String get dataBackupPortability => 'डेटा बैकअप और सुरक्षा';

  @override
  String get exportHealthRecords => 'स्वास्थ्य रिकॉर्ड निर्यात करें';

  @override
  String get exportHealthRecordsSubtitle =>
      'JSON बैकअप फाइल सहेजें या Google Drive / WhatsApp पर शेयर करें';

  @override
  String get restoreFromBackup => 'बैकअप से पुनर्स्थापित करें';

  @override
  String get restoreFromBackupSubtitle => '.json फाइल चुनकर डेटा वापस लाएं';

  @override
  String get familyProfiles => 'परिवार के सदस्य';

  @override
  String get addNewMember => 'नया सदस्य जोड़ें';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get deleteProfile => 'प्रोफ़ाइल हटाएं';

  @override
  String deleteProfileConfirm(String name) {
    return 'क्या आप वाकई $name की प्रोफ़ाइल हटाना चाहते हैं? उनसे संबंधित सभी स्वास्थ्य रिकॉर्ड हटा दिए जाएंगे।';
  }

  @override
  String get cannotDeleteLast =>
      'एकमात्र पारिवारिक प्रोफ़ाइल को हटाया नहीं जा सकता।';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हो गई!';

  @override
  String get profileCreated => 'प्रोफ़ाइल तैयार हो गई!';

  @override
  String get profileDeleted => 'प्रोफ़ाइल हटा दी गई।';

  @override
  String get backupSuccess => 'बैकअप सफलतापूर्वक निर्यात किया गया!';

  @override
  String get restoreSuccess => 'डेटा सफलतापूर्वक पुनर्स्थापित हो गया!';

  @override
  String get welcomeTitle => 'फैमिली हेल्थ ट्रैकर';

  @override
  String get welcomeSubtitle =>
      'अपने और अपने परिवार के रक्तचाप और ब्लड शुगर को एक सुरक्षित और निजी स्थान पर ट्रैक करें।';

  @override
  String get setupFirstProfile => 'अपनी पहली पारिवारिक प्रोफ़ाइल बनाएं';

  @override
  String get memberName => 'सदस्य का नाम';

  @override
  String get memberNameHint => 'जैसे पापा, माँ, राहुल, स्वयं';

  @override
  String get relationship => 'संबंध (Relationship)';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get chooseColorAvatar => 'अवतार और थीम रंग चुनें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get orRestoreBackup =>
      'क्या आपके पास बैकअप है? यहाँ पुनर्स्थापित करें';

  @override
  String get logBpTitle => 'रक्तचाप (BP) दर्ज करें';

  @override
  String get editBpTitle => 'रक्तचाप संपादित करें';

  @override
  String forMember(String name, String relation) {
    return '$name ($relation) के लिए';
  }

  @override
  String get recordReading => 'रीडिंग रिकॉर्ड करें';

  @override
  String get dateTimeOfReading => 'रीडिंग की तारीख और समय';

  @override
  String get systolic => 'सिस्टोलिक';

  @override
  String get diastolic => 'डायस्टोलिक';

  @override
  String get systolicUpper => 'सिस्टोलिक (ऊपरी)';

  @override
  String get diastolicLower => 'डायस्टोलिक (निचला)';

  @override
  String get pulseBpm => 'नाड़ी दर (Pulse bpm)';

  @override
  String get armMeasured => 'मापी गई बांह';

  @override
  String get armLeft => 'बाईं बांह';

  @override
  String get armRight => 'दाहिनी बांह';

  @override
  String get bodyPosture => 'शरीर की मुद्रा (Posture)';

  @override
  String get postureSitting => 'बैठकर';

  @override
  String get postureLying => 'लेटकर';

  @override
  String get postureStanding => 'खड़े होकर';

  @override
  String get irregularHeartbeat => 'अनियमित दिल की धड़कन पाई गई';

  @override
  String get notesOptional => 'टिप्पणी / नोट्स (वैकल्पिक)';

  @override
  String get notesHintBp => 'जैसे 10 मिनट आराम के बाद, चक्कर महसूस हुआ, सुबह';

  @override
  String get saveBpReading => 'बीपी रीडिंग सुरक्षित करें';

  @override
  String get updateBpReading => 'बीपी रीडिंग अपडेट करें';

  @override
  String get logGlucoseTitle => 'ब्लड शुगर दर्ज करें';

  @override
  String get editGlucoseTitle => 'ब्लड शुगर संपादित करें';

  @override
  String get glucoseValue => 'ब्लड शुगर का मान';

  @override
  String get timingMealContext => 'भोजन का समय / संदर्भ';

  @override
  String get saveGlucoseReading => 'शुगर रीडिंग सुरक्षित करें';

  @override
  String get updateGlucoseReading => 'शुगर रीडिंग अपडेट करें';

  @override
  String get notesHintGlucose => 'जैसे दावत के बाद, दवा लेने के बाद';

  @override
  String get mealFasting => 'खाली पेट (Fasting)';

  @override
  String get mealBeforeMeal => 'भोजन से पहले (Pre-meal)';

  @override
  String get mealPostMeal => 'भोजन के 2 घंटे बाद (Post-meal)';

  @override
  String get mealBedtime => 'सोते समय (Bedtime)';

  @override
  String get mealRandom => 'सामान्य (Random)';

  @override
  String get mealFastingHint => 'सुबह के भोजन से पहले';

  @override
  String get mealBeforeMealHint => 'दोपहर या रात के खाने से पहले';

  @override
  String get mealPostMealHint => 'भोजन करने के 2 घंटे बाद';

  @override
  String get mealBedtimeHint => 'रात को सोने से पहले';

  @override
  String get mealRandomHint => 'दिन में किसी भी समय';

  @override
  String get bpNormal => 'सामान्य';

  @override
  String get bpNormalHint => '120/80 mmHg से कम';

  @override
  String get bpElevated => 'बढ़ा हुआ';

  @override
  String get bpElevatedHint => '120-129 / <80 mmHg';

  @override
  String get bpStage1 => 'उच्च रक्तचाप स्टेज 1';

  @override
  String get bpStage1Hint => '130-139 / 80-89 mmHg';

  @override
  String get bpStage2 => 'उच्च रक्तचाप स्टेज 2';

  @override
  String get bpStage2Hint => '140+ / 90+ mmHg';

  @override
  String get bpCrisis => 'अति गंभीर';

  @override
  String get bpCrisisHint => '180 और/या 120 से अधिक';

  @override
  String get glucoseLow => 'कम / हाइपो';

  @override
  String get glucoseLowHint => '70 mg/dL से कम';

  @override
  String get glucoseNormal => 'लक्ष्य सीमा';

  @override
  String get glucoseNormalHint => '70-130 mg/dL खाली पेट, <180 भोजन बाद';

  @override
  String get glucoseElevated => 'बढ़ा हुआ';

  @override
  String get glucoseElevatedHint => '131-180 mg/dL खाली पेट';

  @override
  String get glucoseHigh => 'उच्च / हाइपर';

  @override
  String get glucoseHighHint => '180 mg/dL से अधिक';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get now => 'अभी';

  @override
  String get switchMember => 'सदस्य बदलें';

  @override
  String get manageProfiles => 'प्रोफ़ाइल प्रबंधित करें';

  @override
  String get errorInvalidSystolic =>
      'सिस्टोलिक 40 और 300 mmHg के बीच होना चाहिए';

  @override
  String get errorInvalidDiastolic =>
      'डायस्टोलिक 30 और 200 mmHg के बीच होना चाहिए';

  @override
  String get errorSystolicMustExceedDiastolic =>
      'सिस्टोलिक डायस्टोलिक से कम से कम 10 mmHg अधिक होना चाहिए';

  @override
  String get errorInvalidPulse => 'पल्स 30 और 250 bpm के बीच होनी चाहिए';

  @override
  String get errorInvalidGlucoseMgDl =>
      'ग्लूकोज 20 और 600 mg/dL के बीच होना चाहिए';

  @override
  String get errorInvalidGlucoseMmol =>
      'ग्लूकोज 1.1 और 33.3 mmol/L के बीच होना चाहिए';

  @override
  String get errorSaveFailed =>
      'रीडिंग सहेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get directPrintReport => 'सीधे रिपोर्ट प्रिंट करें';

  @override
  String get errorGeneratePdf =>
      'PDF रिपोर्ट जनरेट करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get errorPrintPdf =>
      'रिपोर्ट प्रिंट करने में विफल। कृपया प्रिंटर सेटिंग्स जांचें।';
}
