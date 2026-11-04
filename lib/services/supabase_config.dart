/// Supabase project config for SciLens AR mobile (migration M1).
///
/// The **anon** key is safe to ship in the app when RLS is enabled.
/// Never put the **service_role** key in Flutter.
///
/// Override at build time if needed:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nvgbfiavbgupbwhsliqr.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52Z2JmaWF2Ymd1cGJ3aHNsaXFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI3Mjc1MzEsImV4cCI6MjEwODMwMzUzMX0.T1-16uIZsMPfzejOhFnKy9RkAqSNLaBXy_WpxoM5rig',
  );

  static bool get isConfigured =>
      url.isNotEmpty && anonKey.isNotEmpty && url.startsWith('https://');
}
