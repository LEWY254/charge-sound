create table if not exists public.preset_packs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  cover_image_path text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_preset_packs_updated_at
before update on public.preset_packs
for each row
execute function public.set_updated_at();

create table if not exists public.preset_sounds (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.preset_packs(id) on delete cascade,
  slug text not null,
  name text not null,
  storage_bucket text not null default 'preset-packs',
  storage_path text not null,
  duration_ms integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (pack_id, slug)
);
