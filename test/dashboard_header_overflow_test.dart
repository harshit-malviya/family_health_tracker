import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_tracker/l10n/app_localizations.dart';
import 'package:health_tracker/models/family_member.dart';
import 'package:health_tracker/models/bp_reading.dart';
import 'package:health_tracker/models/glucose_reading.dart';
import 'package:health_tracker/providers/health_providers.dart';
import 'package:health_tracker/repositories/health_repository.dart';
import 'package:health_tracker/ui/screens/dashboard_screen.dart';

class MockHealthRepository extends HealthRepository {
  final List<FamilyMember> members;
  MockHealthRepository(this.members);

  @override
  Future<List<FamilyMember>> getFamilyMembers() async => members;

  @override
  Future<List<BpReading>> getBpReadings(String memberId) async => [];

  @override
  Future<List<GlucoseReading>> getGlucoseReadings(String memberId) async => [];
}

void main() {
  testWidgets('DashboardScreen header does not overflow with long member name on narrow 320dp screen (CRIT-08)', (WidgetTester tester) async {
    // 1. Constrain viewport to a narrow phone width (320dp)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const longNamedMember = FamilyMember(
      id: 'mem_long',
      name: 'Grandmother Elizabeth Alexandra Mary',
      relation: 'Grandmother',
      age: 89,
      colorValue: 0xFF9C27B0,
      avatarEmoji: '👵',
    );

    final mockRepo = MockHealthRepository([longNamedMember]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          healthRepositoryProvider.overrideWithValue(mockRepo),
          activeMemberProvider.overrideWithValue(longNamedMember),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 2. Assert no RenderFlex overflow exception was caught
    expect(tester.takeException(), isNull);

    // 3. Find the header text widget and assert proper ellipsis and maxLines
    final headerFinder = find.text('👵 Grandmother Elizabeth Alexandra Mary');
    expect(headerFinder, findsOneWidget);

    final Text headerText = tester.widget(headerFinder);
    expect(headerText.overflow, equals(TextOverflow.ellipsis));
    expect(headerText.maxLines, equals(1));

    // 4. Assert the header age badge is rendered
    expect(find.text('89 yrs'), findsOneWidget);

    // 5. Assert the refresh button remains rendered
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
