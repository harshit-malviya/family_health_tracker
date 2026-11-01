import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/health_providers.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FamilyHealthTrackerApp(),
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 54, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        l10n != null ? l10n.errorLoadingProfiles('$err') : 'Error loading profiles: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(familyMembersProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n?.retry ?? 'Retry'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
