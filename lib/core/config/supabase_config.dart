import 'package:flutter/foundation.dart';

/// Configuration for Supabase backend.
/// Supports compile-time environment variables passed via `--dart-define`:
///   `--dart-define=SUPABASE_URL=https://xyz.supabase.co`
///   `--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...`
class SupabaseConfig {
  static const String _defaultUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _defaultKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  static String customUrl = '';
  static String customPublishableKey = '';

  /// The active Supabase project URL.
  static String get url => customUrl.isNotEmpty ? customUrl : _defaultUrl;

  /// The active Supabase publishable key (modern format sb_publishable_xxx).
  static String get publishableKey =>
      customPublishableKey.isNotEmpty ? customPublishableKey : _defaultKey;

  /// Whether Supabase credentials are configured.
  static bool get isConfigured => url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  /// Override credentials at runtime (useful for debug settings or in-app configuration).
  static void setCredentials({required String url, required String publishableKey}) {
    customUrl = url.trim();
    customPublishableKey = publishableKey.trim();
  }

  /// Reset to environment defaults.
  static void reset() {
    customUrl = '';
    customPublishableKey = '';
  }
}

