create table if not exists public.sounds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  source text not null check (source in ('recording','file','meme','preset')),
  storage_bucket text,
  storage_path text,
  local_path text,
  duration_ms integer not null default 0,
  category text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists sounds_user_id_idx on public.sounds(user_id);
create index if not exists sounds_source_idx on public.sounds(source);

create trigger set_sounds_updated_at
before update on public.sounds
for each row
execute function public.set_updated_at();

create table if not exists public.trim_overrides (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sound_id uuid not null references public.sounds(id) on delete cascade,
  trim_start_ms integer,
  trim_end_ms integer,
  fade_in_ms integer not null default 0,
  fade_out_ms integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, sound_id)
);

create trigger set_trim_overrides_updated_at
before update on public.trim_overrides
for each row
execute function public.set_updated_at();

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  sound_id uuid not null references public.sounds(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, sound_id)
);
