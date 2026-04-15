create table if not exists public.event_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  sound_data jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, event_type)
);

create trigger set_event_assignments_updated_at
before update on public.event_assignments
for each row
execute function public.set_updated_at();

create table if not exists public.device_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  battery_threshold double precision,
  service_enabled boolean,
  theme_mode text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_device_settings_updated_at
before update on public.device_settings
for each row
execute function public.set_updated_at();
