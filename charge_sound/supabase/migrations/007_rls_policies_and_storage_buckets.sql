alter table public.profiles enable row level security;
alter table public.sounds enable row level security;
alter table public.trim_overrides enable row level security;
alter table public.favorites enable row level security;
alter table public.tags enable row level security;
alter table public.sound_tags enable row level security;
alter table public.folders enable row level security;
alter table public.folder_sounds enable row level security;
alter table public.event_assignments enable row level security;
alter table public.device_settings enable row level security;
alter table public.preset_packs enable row level security;
alter table public.preset_sounds enable row level security;

drop policy if exists profiles_owner on public.profiles;
create policy profiles_owner on public.profiles
for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists sounds_owner on public.sounds;
create policy sounds_owner on public.sounds
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists trim_overrides_owner on public.trim_overrides;
create policy trim_overrides_owner on public.trim_overrides
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists favorites_owner on public.favorites;
create policy favorites_owner on public.favorites
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists tags_owner on public.tags;
create policy tags_owner on public.tags
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists folders_owner on public.folders;
create policy folders_owner on public.folders
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists event_assignments_owner on public.event_assignments;
create policy event_assignments_owner on public.event_assignments
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists device_settings_owner on public.device_settings;
create policy device_settings_owner on public.device_settings
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists preset_packs_public_read on public.preset_packs;
create policy preset_packs_public_read on public.preset_packs
for select using (is_active = true);

drop policy if exists preset_sounds_public_read on public.preset_sounds;
create policy preset_sounds_public_read on public.preset_sounds
for select using (true);

insert into storage.buckets (id, name, public)
values ('recordings', 'recordings', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('user-files', 'user-files', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('meme-sounds', 'meme-sounds', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('preset-packs', 'preset-packs', true)
on conflict (id) do nothing;

drop policy if exists recordings_owner_rw on storage.objects;
create policy recordings_owner_rw on storage.objects
for all to authenticated
using (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists user_files_owner_rw on storage.objects;
create policy user_files_owner_rw on storage.objects
for all to authenticated
using (bucket_id = 'user-files' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'user-files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists meme_sounds_public_read on storage.objects;
create policy meme_sounds_public_read on storage.objects
for select to anon, authenticated
using (bucket_id = 'meme-sounds');

drop policy if exists preset_packs_public_read on storage.objects;
create policy preset_packs_public_read on storage.objects
for select to anon, authenticated
using (bucket_id = 'preset-packs');
