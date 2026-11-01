import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/providers/locale_provider.dart';
import 'package:health_tracker/ui/screens/home_shell.dart';
import 'package:health_tracker/ui/screens/dashboard_screen.dart';
import 'package:health_tracker/ui/screens/analytics_screen.dart';
import 'package:health_tracker/ui/screens/history_screen.dart';
import 'package:health_tracker/ui/screens/doctor_report_screen.dart';
import 'package:health_tracker/ui/screens/settings_screen.dart';

class FakeFamilyMembersNotifier extends FamilyMembersNotifier {
  final List<FamilyMember> _members;
  FakeFamilyMembersNotifier(this._members);
  @override
  Future<List<FamilyMember>> build() async => _members;
}

class FakeBpNotifier extends BpReadingsNotifier {
  @override
  Future<List<BpReading>> build() async => [];
}

class FakeGlucoseNotifier extends GlucoseReadingsNotifier {
  @override
  Future<List<GlucoseReading>> build() async => [];
}

class FakeGlucoseUnitNotifier extends GlucoseUnitNotifier {
  @override
  String build() => 'mg/dL';
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}

void main() {
  const testMember = FamilyMember(
    id: 'mem_1',
    name: 'Dad',
    relation: 'Father',
    colorValue: 0xFF2E7D32,
    avatarEmoji: '👨',
  );

  testWidgets('HomeShell navigates seamlessly across all 5 bottom destinations (CRIT-20)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          familyMembersProvider.overrideWith(() => FakeFamilyMembersNotifier([testMember])),
          activeMemberProvider.overrideWithValue(testMember),
          bpReadingsProvider.overrideWith(FakeBpNotifier.new),
          glucoseReadingsProvider.overrideWith(FakeGlucoseNotifier.new),
          glucoseUnitProvider.overrideWith(FakeGlucoseUnitNotifier.new),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Destination 0: DashboardScreen
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Navigate to Destination 1: Trends
    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    // Navigate to Destination 2: History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    // Navigate to Destination 3: Doctor PDF
    await tester.tap(find.text('Doctor PDF'));
    await tester.pumpAndSettle();
    expect(find.byType(DoctorReportScreen), findsOneWidget);

    // Navigate to Destination 4: Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
