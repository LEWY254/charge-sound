create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

create table if not exists public.sound_tags (
  sound_id uuid not null references public.sounds(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (sound_id, tag_id)
);

create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  parent_folder_id uuid references public.folders(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, name, parent_folder_id)
);

create trigger set_folders_updated_at
before update on public.folders
for each row
execute function public.set_updated_at();

create table if not exists public.folder_sounds (
  folder_id uuid not null references public.folders(id) on delete cascade,
  sound_id uuid not null references public.sounds(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (folder_id, sound_id)
);
