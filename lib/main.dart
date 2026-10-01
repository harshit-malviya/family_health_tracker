import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/health_providers.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: FamilyHealthTrackerApp(),
    ),
  );
}

class FamilyHealthTrackerApp extends ConsumerWidget {
  const FamilyHealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);
    final hasCompletedOnboarding = ref.watch(onboardingCompletedProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Family Health Tracker',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getTheme(locale),
      home: membersAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          body: Center(child: Text('Error loading profiles: $err')),
        ),
        data: (members) {
          if (members.isEmpty || !hasCompletedOnboarding) {
            return const OnboardingScreen();
          }
          return const HomeShell();
        },
      ),
    );
  }
}
