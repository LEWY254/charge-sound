# Supabase Schema Source of Truth

This folder mirrors the SQL applied via MCP to the `sound-trigger-prod` project.

## Migrations

Ordered migrations are in `supabase/migrations/`:

1. `001_core_extensions_and_updated_at.sql`
2. `002_profiles_table.sql`
3. `003_sounds_trim_favorites.sql`
4. `004_tags_and_folders.sql`
5. `005_event_assignments_and_device_settings.sql`
6. `006_preset_tables.sql`
7. `007_rls_policies_and_storage_buckets.sql`

## Apply order

Apply files in numeric order against the target Supabase project.

## Runtime requirements

- Buckets expected by app:
  - `recordings`
  - `user-files`
  - `meme-sounds`
  - `preset-packs`
- RLS policies are defined in migration 007.
