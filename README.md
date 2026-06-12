
# genealogy

Prototype front end for the Zhezhir genealogy tree.

## Supabase configuration

Provide Supabase credentials via `dart-define` flags instead of committing real
keys. Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://dcbfyjxuoxeufkprrkve.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_-MoKSk4u5y5Lub7-CBtHuw_-P-eDFdH \
  --dart-define=SUPABASE_PROJECT_NAME="Zhezhir Archive"
```

`SupabaseConfig` (see `lib/services/supabase_placeholders.dart`) exposes these
values, and `SupabaseInitializer` applies them before the Flutter app starts.
The repository already ships with the Genealogy project URL and publishable key
as defaults, so `flutter run` works without extra flags unless you want to point
at a different Supabase instance.
