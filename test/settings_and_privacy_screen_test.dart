import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/providers/locale_provider.dart';
import 'package:health_tracker/ui/screens/settings_screen.dart';
import 'package:health_tracker/core/constants/app_constants.dart';

class FakeFamilyMembersNotifier extends FamilyMembersNotifier {
  final List<FamilyMember> _members;
  FakeFamilyMembersNotifier(this._members);
  @override
  Future<List<FamilyMember>> build() async => _members;
}

class FakeGlucoseUnitNotifier extends GlucoseUnitNotifier {
  final String _unit;
  FakeGlucoseUnitNotifier(this._unit);
  @override
  String build() => _unit;
}

class FakeLocaleNotifier extends LocaleNotifier {
  final Locale _locale;
  FakeLocaleNotifier(this._locale);
  @override
  Locale build() => _locale;
}

void main() {
  const testMembers = [
    FamilyMember(
      id: 'mem_1',
      name: 'Dad',
      relation: 'Father',
      colorValue: 0xFF2E7D32,
      avatarEmoji: '👨',
    ),
    FamilyMember(
      id: 'mem_2',
      name: 'Mom',
      relation: 'Mother',
      colorValue: 0xFFC2185B,
      avatarEmoji: '👩',
    ),
  ];

  testWidgets('SettingsScreen displays profiles, version, and Privacy Policy modal (CRIT-18, CRIT-28)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          familyMembersProvider.overrideWith(() => FakeFamilyMembersNotifier(testMembers)),
          glucoseUnitProvider.overrideWith(() => FakeGlucoseUnitNotifier('mg/dL')),
          localeProvider.overrideWith(() => FakeLocaleNotifier(const Locale('en'))),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Profiles rendered
    expect(find.text('Dad'), findsOneWidget);
    expect(find.text('Mom'), findsOneWidget);

    // Verify App version from AppConstants (CRIT-28)
    expect(find.text(AppConstants.appDisplayVersion), findsOneWidget);

    // Verify Medical alignment title
    expect(find.text('Medical Standard Alignment'), findsOneWidget);

    // Verify Privacy Policy tile exists and tap it (CRIT-18)
    expect(find.text('Privacy & Data Ownership'), findsOneWidget);
    await tester.tap(find.text('Privacy & Data Ownership'));
    await tester.pumpAndSettle();

    // Verify Privacy Policy bottom sheet content
    expect(find.text('100% on-device local storage. No trackers, no clouds.'), findsOneWidget);
    expect(find.textContaining('Zero Telemetry'), findsOneWidget);
    expect(find.textContaining('Private SQLite Storage'), findsOneWidget);

    // Tap Close button
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify sheet closed
    expect(find.textContaining('Zero Telemetry'), findsNothing);
  });
}
