/// Runtime configuration for the Supabase client.
///
/// Instead of hard-coding publishable keys in the repository, pass the values
/// via `--dart-define` (e.g. `flutter run --dart-define=SUPABASE_URL=...`).
/// The defaults only exist to keep the UI working with mock data until you
/// provide actual credentials.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL (e.g. https://your-project.supabase.co).
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dcbfyjxuoxeufkprrkve.supabase.co',
  );

  /// Publishable key (formerly known as anon key) for public clients.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_-MoKSk4u5y5Lub7-CBtHuw_-P-eDFdH',
    ),
  );

  /// Backwards-compatible alias for consumers that still expect `anonKey`.
  static const String anonKey = publishableKey;

  /// Optional metadata to show inside the UI.
  static const String projectName = String.fromEnvironment(
    'SUPABASE_PROJECT_NAME',
    defaultValue: 'KazakhTree',
  );

  /// Optional project reference (handy when debugging Supabase logs).
  static const String projectRef = String.fromEnvironment(
    'SUPABASE_PROJECT_REF',
    defaultValue: 'dcbfyjxuoxeufkprrkve',
  );
}
