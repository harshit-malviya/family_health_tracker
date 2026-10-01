import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/repositories/health_repository.dart';
import 'package:health_tracker/ui/widgets/quick_bp_modal.dart';
import 'package:health_tracker/ui/widgets/quick_glucose_modal.dart';

class MockHealthRepository extends HealthRepository {
  final List<FamilyMember> members = [
    const FamilyMember(
      id: 'member_1',
      name: 'Dad',
      relation: 'Father',
      age: 60,
      colorValue: 0xFF1E88E5,
      avatarEmoji: '👨',
    ),
  ];

  final List<BpReading> bpList = [];
  final List<GlucoseReading> glucoseList = [];
  int addBpCallCount = 0;
  int addGlucoseCallCount = 0;
  Completer<void>? bpCompleter;
  Completer<void>? glucoseCompleter;

  @override
  Future<List<FamilyMember>> getFamilyMembers() async => members;

  @override
  Future<List<BpReading>> getBpReadings(String memberId) async => List.from(bpList);

  @override
  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async => List.from(glucoseList);

  @override
  Future<void> addBpReading(BpReading reading) async {
    addBpCallCount++;
    if (bpCompleter != null) {
      await bpCompleter!.future;
    }
    bpList.add(reading);
  }

  @override
  Future<void> addGlucoseReading(GlucoseReading reading) async {
    addGlucoseCallCount++;
    if (glucoseCompleter != null) {
      await glucoseCompleter!.future;
    }
    glucoseList.add(reading);
  }
}

void main() {
  group('ClinicalStandards Validation Unit Tests', () {
    test('validateBp accepts valid physiological values', () {
      final result = ClinicalStandards.validateBp(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
      );
      expect(result, isNull);
    });

    test('validateBp catches null and out-of-range systolic', () {
      expect(
        ClinicalStandards.validateBp(systolic: null, diastolic: 80, pulse: 72),
        BpValidationError.invalidSystolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 35, diastolic: 30, pulse: 72),
        BpValidationError.invalidSystolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 305, diastolic: 80, pulse: 72),
        BpValidationError.invalidSystolic,
      );
    });

    test('validateBp catches null and out-of-range diastolic', () {
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: null, pulse: 72),
        BpValidationError.invalidDiastolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: 25, pulse: 72),
        BpValidationError.invalidDiastolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: 205, pulse: 72),
        BpValidationError.invalidDiastolic,
      );
    });

    test('validateBp catches systolic <= diastolic and insufficient pulse pressure', () {
      expect(
        ClinicalStandards.validateBp(systolic: 80, diastolic: 120, pulse: 72),
        BpValidationError.systolicMustExceedDiastolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 100, diastolic: 100, pulse: 72),
        BpValidationError.systolicMustExceedDiastolic,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 105, diastolic: 100, pulse: 72),
        BpValidationError.systolicMustExceedDiastolic,
      );
    });

    test('validateBp catches out-of-range pulse', () {
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: 80, pulse: null),
        BpValidationError.invalidPulse,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: 80, pulse: 25),
        BpValidationError.invalidPulse,
      );
      expect(
        ClinicalStandards.validateBp(systolic: 120, diastolic: 80, pulse: 260),
        BpValidationError.invalidPulse,
      );
    });

    test('validateGlucose validates mg/dL boundaries', () {
      expect(
        ClinicalStandards.validateGlucose(value: 95.0, unit: 'mg/dL'),
        isNull,
      );
      expect(
        ClinicalStandards.validateGlucose(value: null, unit: 'mg/dL'),
        GlucoseValidationError.invalidMgDl,
      );
      expect(
        ClinicalStandards.validateGlucose(value: 15.0, unit: 'mg/dL'),
        GlucoseValidationError.invalidMgDl,
      );
      expect(
        ClinicalStandards.validateGlucose(value: 650.0, unit: 'mg/dL'),
        GlucoseValidationError.invalidMgDl,
      );
    });

    test('validateGlucose validates mmol/L boundaries', () {
      expect(
        ClinicalStandards.validateGlucose(value: 5.5, unit: 'mmol/L'),
        isNull,
      );
      expect(
        ClinicalStandards.validateGlucose(value: null, unit: 'mmol/L'),
        GlucoseValidationError.invalidMmol,
      );
      expect(
        ClinicalStandards.validateGlucose(value: 0.8, unit: 'mmol/L'),
        GlucoseValidationError.invalidMmol,
      );
      expect(
        ClinicalStandards.validateGlucose(value: 35.0, unit: 'mmol/L'),
        GlucoseValidationError.invalidMmol,
      );
    });
  });

  group('QuickBpModal Validation & Concurrency Widget Tests', () {
    testWidgets('Rejects diastolic >= systolic and shows inline error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockHealthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(mockRepo),
            activeMemberProvider.overrideWithValue(mockRepo.members.first),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: QuickBpModal()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter diastolic > systolic (e.g. Sys: 80, Dia: 120)
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '80');
      await tester.enterText(textFields.at(1), '120');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save BP Reading');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify inline error message is displayed
      expect(
        find.text('Systolic must be at least 10 mmHg higher than Diastolic'),
        findsOneWidget,
      );
      // Verify nothing was saved to repository
      expect(mockRepo.addBpCallCount, 0);
    });

    testWidgets('Rejects blank inputs without falling back to defaults', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockHealthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(mockRepo),
            activeMemberProvider.overrideWithValue(mockRepo.members.first),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: QuickBpModal()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear the systolic text field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save BP Reading');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify error is shown and nothing saved
      expect(
        find.text('Systolic must be between 40 and 300 mmHg'),
        findsOneWidget,
      );
      expect(mockRepo.addBpCallCount, 0);
    });

    testWidgets('Prevents duplicate submission on rapid double-tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockHealthRepository();
      mockRepo.bpCompleter = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(mockRepo),
            activeMemberProvider.overrideWithValue(mockRepo.members.first),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: QuickBpModal()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(ElevatedButton, 'Save BP Reading');
      await tester.ensureVisible(saveBtn);

      // First tap begins async submission
      await tester.tap(saveBtn);
      await tester.pump(); // Start execution

      // Spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt rapid second tap on the button area
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // Complete the async operation
      mockRepo.bpCompleter!.complete();
      await tester.pumpAndSettle();

      // Exactly 1 insert should have occurred
      expect(mockRepo.addBpCallCount, 1);
    });
  });

  group('QuickGlucoseModal Validation & Concurrency Widget Tests', () {
    testWidgets('Rejects invalid glucose range in mg/dL and shows inline error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockHealthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(mockRepo),
            activeMemberProvider.overrideWithValue(mockRepo.members.first),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: QuickGlucoseModal()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter value 10 (below 20 mg/dL minimum)
      final valueField = find.byType(TextField).first;
      await tester.enterText(valueField, '10');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Sugar Reading');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify inline error message
      expect(
        find.text('Glucose must be between 20 and 600 mg/dL'),
        findsOneWidget,
      );
      expect(mockRepo.addGlucoseCallCount, 0);
    });

    testWidgets('Prevents duplicate submission on rapid double tap in QuickGlucoseModal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockHealthRepository();
      mockRepo.glucoseCompleter = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            healthRepositoryProvider.overrideWithValue(mockRepo),
            activeMemberProvider.overrideWithValue(mockRepo.members.first),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: QuickGlucoseModal()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Sugar Reading');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Loading spinner displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attempt rapid second tap
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      mockRepo.glucoseCompleter!.complete();
      await tester.pumpAndSettle();

      expect(mockRepo.addGlucoseCallCount, 1);
    });
  });
}
