import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/core/constants/clinical_standards.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/ui/screens/analytics_screen.dart';

class FakeFamilyMembersNotifier extends FamilyMembersNotifier {
  final List<FamilyMember> _members;
  FakeFamilyMembersNotifier(this._members);
  @override
  Future<List<FamilyMember>> build() async => _members;
}

class FakeBpNotifier extends BpReadingsNotifier {
  final List<BpReading> _readings;
  FakeBpNotifier(this._readings);
  @override
  Future<List<BpReading>> build() async => _readings;
}

class FakeGlucoseNotifier extends GlucoseReadingsNotifier {
  final List<GlucoseReading> _readings;
  FakeGlucoseNotifier(this._readings);
  @override
  Future<List<GlucoseReading>> build() async => _readings;
}

class FakeGlucoseUnitNotifier extends GlucoseUnitNotifier {
  final String _unit;
  FakeGlucoseUnitNotifier(this._unit);
  @override
  String build() => _unit;
}

void main() {
  const testMember = FamilyMember(
    id: 'mem_1',
    name: 'Dad',
    relation: 'Father',
    colorValue: 0xFF2E7D32,
    avatarEmoji: '👨',
  );

  Widget createWidget({
    required SharedPreferences prefs,
    required List<BpReading> bpReadings,
    required List<GlucoseReading> glucoseReadings,
    String unit = 'mg/dL',
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        familyMembersProvider.overrideWith(() => FakeFamilyMembersNotifier([testMember])),
        activeMemberProvider.overrideWithValue(testMember),
        bpReadingsProvider.overrideWith(() => FakeBpNotifier(bpReadings)),
        glucoseReadingsProvider.overrideWith(() => FakeGlucoseNotifier(glucoseReadings)),
        glucoseUnitProvider.overrideWith(() => FakeGlucoseUnitNotifier(unit)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: AnalyticsScreen(),
      ),
    );
  }

  testWidgets('AnalyticsScreen renders empty state when no readings exist', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createWidget(prefs: prefs, bpReadings: [], glucoseReadings: []));
    await tester.pumpAndSettle();

    expect(find.text('No blood pressure logs yet for this member.'), findsOneWidget);

    // Switch to Blood Glucose tab
    await tester.tap(find.text('Blood Glucose'));
    await tester.pumpAndSettle();

    expect(find.text('No blood glucose logs yet for this member.'), findsOneWidget);
  });

  testWidgets('AnalyticsScreen handles Hypertensive Crisis reading and computes circadian averages (CRIT-15)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final morningTime = DateTime(now.year, now.month, now.day, 8, 30);
    final eveningTime = DateTime(now.year, now.month, now.day, 19, 30);

    final readings = [
      BpReading(
        id: 'bp_1',
        memberId: 'mem_1',
        systolic: 205, // Hypertensive crisis (> 180 and > 190)
        diastolic: 115,
        pulse: 92,
        arm: 'Left',
        posture: 'Sitting',
        timestamp: morningTime,
      ),
      BpReading(
        id: 'bp_2',
        memberId: 'mem_1',
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        arm: 'Right',
        posture: 'Sitting',
        timestamp: eveningTime,
      ),
    ];

    await tester.pumpWidget(createWidget(prefs: prefs, bpReadings: readings, glucoseReadings: []));
    await tester.pumpAndSettle();

    // Verify trend card header and legend render
    expect(find.text('Systolic & Diastolic Trend'), findsOneWidget);
    expect(find.text('SYS'), findsOneWidget);
    expect(find.text('DIA'), findsOneWidget);

    // Verify Circadian pattern averages
    expect(find.text('Morning Avg'), findsOneWidget);
    expect(find.text('205'), findsOneWidget); // Morning Sys
    expect(find.text('Evening Avg'), findsOneWidget);
    expect(find.text('120'), findsOneWidget); // Evening Sys
  });

  testWidgets('AnalyticsScreen handles single glucose reading without bounds errors (CRIT-23)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final singleReading = [
      GlucoseReading(
        id: 'gl_1',
        memberId: 'mem_1',
        valueMgDl: 110.0,
        mealContext: MealContext.fasting,
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(createWidget(prefs: prefs, bpReadings: [], glucoseReadings: singleReading));
    await tester.pumpAndSettle();

    // Switch to Blood Glucose tab
    await tester.tap(find.text('Blood Glucose'));
    await tester.pumpAndSettle();

    expect(find.text('Blood Glucose (mg/dL)'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });
}
