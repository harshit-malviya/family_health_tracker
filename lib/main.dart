import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/health_providers.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/family_setup_screen.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
      );
    } catch (_) {}
  }

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
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Family Health Tracker',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getTheme(locale),
      home: _buildHome(context, ref),
    );
  }

  Widget _buildHome(BuildContext context, WidgetRef ref) {
    // If Supabase is configured, enforce Auth & Family setup
    if (SupabaseConfig.isConfigured) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return const AuthScreen();
      }

      final familyAsync = ref.watch(currentFamilyProvider);
      return familyAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 54, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Error connecting to family space: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => ref.read(currentFamilyProvider.notifier).reload(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => ref.read(currentFamilyProvider.notifier).signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (family) {
          if (family == null) {
            return const FamilySetupScreen();
          }
          return _buildPatientProfilesShell(context, ref);
        },
      );
    }

    // Fallback for local-only / non-Supabase mode
    return _buildPatientProfilesShell(context, ref);
  }

  Widget _buildPatientProfilesShell(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);
    final hasCompletedOnboarding = ref.watch(onboardingCompletedProvider);

    return membersAsync.when(
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
    );
  }
}
