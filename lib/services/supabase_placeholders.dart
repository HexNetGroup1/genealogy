/// Runtime configuration for the Supabase client.
///
/// Instead of hard-coding publishable keys in the repository, pass the values
/// via `--dart-define` (e.g. `flutter run --dart-define=SUPABASE_URL=...`).
/// The defaults only exist to keep the UI working with mock data until you
/// provide actual credentials.
class SupabaseConfig {
  SupabaseConfig._();

  static const bool useLocal = bool.fromEnvironment('USE_LOCAL_SUPABASE', defaultValue: false);

  /// Supabase project URL (e.g. https://your-project.supabase.co).
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: useLocal ? 'http://127.0.0.1:54321' : 'https://genealogy.projectmanager.kz',
  );

  /// Publishable key (formerly known as anon key) for public clients.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: useLocal
      ? 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzgyMzkxNzc2LCJleHAiOjE5NDAwNzE3NzZ9.ki0DQpx_wfMcCEAfHaYxkGH-t8aZiPFd61-sYPYt1LI',
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
