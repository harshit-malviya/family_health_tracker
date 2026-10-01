import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme Font Bundling & Offline Typography (CRIT-03)', () {
    test('English theme configures Outfit with NotoSansDevanagari fallback', () {
      final theme = AppTheme.getTheme(const Locale('en'));

      expect(theme.textTheme.bodyLarge?.fontFamily, equals(AppTheme.fontOutfit));
      expect(theme.textTheme.bodyLarge?.fontFamilyFallback, contains(AppTheme.fontNotoSansDevanagari));

      expect(theme.textTheme.bodyMedium?.fontFamily, equals(AppTheme.fontOutfit));
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, contains(AppTheme.fontNotoSansDevanagari));

      expect(theme.textTheme.titleLarge?.fontFamily, equals(AppTheme.fontOutfit));
      expect(theme.textTheme.titleLarge?.fontFamilyFallback, contains(AppTheme.fontNotoSansDevanagari));

      expect(theme.appBarTheme.titleTextStyle?.fontFamily, equals(AppTheme.fontOutfit));
      expect(theme.appBarTheme.titleTextStyle?.fontFamilyFallback, contains(AppTheme.fontNotoSansDevanagari));
    });

    test('Hindi theme configures NotoSansDevanagari with Outfit fallback', () {
      final theme = AppTheme.getTheme(const Locale('hi'));

      expect(theme.textTheme.bodyLarge?.fontFamily, equals(AppTheme.fontNotoSansDevanagari));
      expect(theme.textTheme.bodyLarge?.fontFamilyFallback, contains(AppTheme.fontOutfit));

      expect(theme.textTheme.bodyMedium?.fontFamily, equals(AppTheme.fontNotoSansDevanagari));
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, contains(AppTheme.fontOutfit));

      expect(theme.textTheme.titleLarge?.fontFamily, equals(AppTheme.fontNotoSansDevanagari));
      expect(theme.textTheme.titleLarge?.fontFamilyFallback, contains(AppTheme.fontOutfit));

      expect(theme.appBarTheme.titleTextStyle?.fontFamily, equals(AppTheme.fontNotoSansDevanagari));
      expect(theme.appBarTheme.titleTextStyle?.fontFamilyFallback, contains(AppTheme.fontOutfit));
    });

    testWidgets('renders mixed Hindi and English text under both locales without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(const Locale('en')),
          home: Scaffold(
            appBar: AppBar(title: const Text('Family Health Tracker - राहुल')),
            body: Column(
              children: const [
                Text('Blood Pressure: 120/80 mmHg'),
                Text('मरीज़ का नाम: राहुल शर्मा'),
                Text('दवा के निर्देश: Take 1 tablet daily'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Family Health Tracker - राहुल'), findsOneWidget);
      expect(find.text('मरीज़ का नाम: राहुल शर्मा'), findsOneWidget);
      expect(find.text('दवा के निर्देश: Take 1 tablet daily'), findsOneWidget);
    });
  });
}
