import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_placeholders.dart';

/// Handles Supabase initialization at app startup.
class SupabaseInitializer {
  SupabaseInitializer._();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
      );
      _isInitialized = true;
    } on Object catch (error, stackTrace) {
      log(
        'Supabase initialization failed. '
        'Double-check SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY dart-defines.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
