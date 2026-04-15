create extension if not exists pgcrypto;

create schema if not exists private;

create table if not exists public.staff_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null,
  role text not null check (role in ('owner', 'ops', 'support', 'catalog_manager', 'finance')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create or replace function private.is_admin_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.staff_roles sr
    where sr.user_id = auth.uid()
      and sr.active = true
  );
$$;

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name text not null,
  interval text not null check (interval in ('monthly', 'yearly', 'manual', 'lifetime')),
  provider_family text not null check (provider_family in ('stripe', 'app_store', 'google_play', 'manual')),
  amount_cents integer not null default 0,
  currency text not null default 'USD',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.customer_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('stripe', 'app_store', 'google_play')),
  provider_customer_id text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, provider, provider_customer_id)
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('stripe', 'app_store', 'google_play')),
  plan_key text not null,
  status text not null check (status in ('free', 'active', 'grace_period', 'past_due', 'canceled', 'manual')),
  amount_cents integer not null default 0,
  currency text not null default 'USD',
  started_at timestamptz not null default now(),
  renews_at timestamptz,
  source_reference text not null,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  provider text not null check (provider in ('stripe', 'app_store', 'google_play')),
  kind text not null,
  amount_cents integer not null default 0,
  currency text not null default 'USD',
  status text not null check (status in ('processed', 'pending', 'failed', 'refunded')),
  occurred_at timestamptz not null default now(),
  reference text not null,
  payload jsonb not null default '{}'::jsonb
);

create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null check (source in ('billing', 'manual_override')),
  plan_key text not null,
  is_pro boolean not null default false,
  status text not null check (status in ('free', 'active', 'grace_period', 'past_due', 'canceled', 'manual')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.manual_entitlement_overrides (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  enabled boolean not null,
  plan_key text not null default 'pro_support',
  reason text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.music_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  kind text not null check (kind in ('manual', 'api', 'feed')),
  status text not null default 'healthy' check (status in ('healthy', 'warning', 'error')),
  sync_mode text not null default 'manual' check (sync_mode in ('manual', 'assisted', 'automated')),
  attribution_required boolean not null default false,
  last_sync_at timestamptz,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.catalog_import_jobs (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.music_providers(id) on delete cascade,
  mode text not null check (mode in ('manual', 'assisted', 'automated')),
  status text not null check (status in ('queued', 'running', 'succeeded', 'failed')),
  started_at timestamptz,
  finished_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists public.catalog_import_items (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.music_providers(id) on delete cascade,
  job_id uuid references public.catalog_import_jobs(id) on delete set null,
  title text not null,
  source_url text not null,
  preview_url text,
  license_label text not null,
  duplicate_risk text not null default 'low' check (duplicate_risk in ('low', 'medium', 'high')),
  attribution_required boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'review', 'approved', 'rejected', 'archived')),
  raw_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.catalog_assets (
  id uuid primary key default gen_random_uuid(),
  import_item_id uuid references public.catalog_import_items(id) on delete set null,
  provider_id uuid not null references public.music_providers(id) on delete restrict,
  title text not null,
  slug text not null unique,
  duration_ms integer,
  waveform_json jsonb,
  storage_bucket text not null default 'preset-packs',
  storage_path text not null,
  source_url text not null,
  license_label text not null,
  attribution_required boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.staff_roles enable row level security;
alter table public.plans enable row level security;
alter table public.customer_accounts enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payment_events enable row level security;
alter table public.entitlements enable row level security;
alter table public.manual_entitlement_overrides enable row level security;
alter table public.music_providers enable row level security;
alter table public.catalog_import_jobs enable row level security;
alter table public.catalog_import_items enable row level security;
alter table public.catalog_assets enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "staff_roles_self_or_admin_select" on public.staff_roles;
create policy "staff_roles_self_or_admin_select"
on public.staff_roles
for select
using (user_id = auth.uid() or private.is_admin_staff());

drop policy if exists "admin_staff_read_plans" on public.plans;
create policy "admin_staff_read_plans" on public.plans for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_customer_accounts" on public.customer_accounts;
create policy "admin_staff_read_customer_accounts" on public.customer_accounts for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_subscriptions" on public.subscriptions;
create policy "admin_staff_read_subscriptions" on public.subscriptions for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_payment_events" on public.payment_events;
create policy "admin_staff_read_payment_events" on public.payment_events for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_entitlements" on public.entitlements;
create policy "admin_staff_read_entitlements" on public.entitlements for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_manual_overrides" on public.manual_entitlement_overrides;
create policy "admin_staff_read_manual_overrides" on public.manual_entitlement_overrides for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_music_providers" on public.music_providers;
create policy "admin_staff_read_music_providers" on public.music_providers for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_import_jobs" on public.catalog_import_jobs;
create policy "admin_staff_read_import_jobs" on public.catalog_import_jobs for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_import_items" on public.catalog_import_items;
create policy "admin_staff_read_import_items" on public.catalog_import_items for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_catalog_assets" on public.catalog_assets;
create policy "admin_staff_read_catalog_assets" on public.catalog_assets for select using (private.is_admin_staff());

drop policy if exists "admin_staff_read_audit_logs" on public.audit_logs;
create policy "admin_staff_read_audit_logs" on public.audit_logs for select using (private.is_admin_staff());

alter table if exists public.preset_packs
  add column if not exists visibility text not null default 'public';

alter table if exists public.preset_sounds
  add column if not exists status text not null default 'approved',
  add column if not exists license_label text,
  add column if not exists source_provider text;

create or replace view public.admin_preset_packs
with (security_invoker = true)
as
select
  p.id,
  p.name,
  p.slug,
  p.is_active,
  coalesce(p.visibility, case when p.is_active then 'public' else 'staged' end) as visibility,
  count(s.id)::int as sound_count
from public.preset_packs p
left join public.preset_sounds s on s.pack_id = p.id
group by p.id, p.name, p.slug, p.is_active, p.visibility;

create or replace view public.admin_catalog_sounds
with (security_invoker = true)
as
select
  s.id,
  s.name,
  coalesce(s.slug, replace(lower(s.name), ' ', '_')) as slug,
  s.pack_id,
  p.name as pack_name,
  s.storage_path,
  coalesce(s.status, 'approved') as status,
  coalesce(s.license_label, 'Unknown') as license_label,
  coalesce(s.source_provider, 'Manual') as source_provider
from public.preset_sounds s
left join public.preset_packs p on p.id = s.pack_id;

create or replace view public.admin_user_overview
with (security_invoker = true)
as
select
  p.id,
  coalesce(au.email, concat(p.id::text, '@anonymous.local')) as email,
  coalesce(p.display_name, split_part(coalesce(au.email, p.id::text), '@', 1)) as display_name,
  coalesce(e.plan_key, 'free') as plan_key,
  coalesce(e.status, 'free') as plan_status,
  coalesce(ca.provider, 'none') as billing_provider,
  coalesce(p.onboarding_completed, false) as onboarding_completed,
  coalesce(sound_counts.sounds_synced, 0) as sounds_synced,
  coalesce(sound_counts.recordings_count, 0) as recordings_count,
  coalesce(au.last_sign_in_at, au.created_at) as last_seen_at,
  au.created_at,
  coalesce(au.raw_user_meta_data ->> 'country', 'n/a') as region,
  exists (
    select 1
    from public.manual_entitlement_overrides mo
    where mo.user_id = p.id
      and mo.enabled = true
      and (mo.expires_at is null or mo.expires_at > now())
  ) as override_active
from public.profiles p
left join auth.users au on au.id = p.id
left join lateral (
  select
    count(*)::int as sounds_synced,
    count(*) filter (where source = 'recording')::int as recordings_count
  from public.sounds s
  where s.user_id = p.id
) sound_counts on true
left join lateral (
  select *
  from public.entitlements e
  where e.user_id = p.id
  order by e.starts_at desc
  limit 1
) e on true
left join lateral (
  select provider
  from public.customer_accounts ca
  where ca.user_id = p.id
  order by ca.created_at desc
  limit 1
) ca on true;

create or replace view public.admin_dashboard_metrics
with (security_invoker = true)
as
select * from (
  select
    'users'::text as id,
    'Total users'::text as label,
    count(*)::text as value,
    'live'::text as delta,
    'default'::text as tone,
    'Profiles known to the app and eligible for support workflows.'::text as help_text,
    1 as sort_order
  from public.admin_user_overview
  union all
  select
    'pro_users',
    'Active Pro users',
    count(*)::text,
    'live',
    'success',
    'Users whose latest entitlement currently grants Pro access.',
    2
  from public.entitlements
  where is_pro = true
    and (ends_at is null or ends_at > now())
  union all
  select
    'mrr',
    'MRR proxy',
    concat('$', coalesce(sum(amount_cents), 0) / 100.0)::text,
    'live',
    'success',
    'Active recurring revenue from normalized subscriptions.',
    3
  from public.subscriptions
  where status in ('active', 'grace_period')
  union all
  select
    'imports',
    'Pending imports',
    count(*)::text,
    'live',
    'warning',
    'Catalog imports that still require review or approval.',
    4
  from public.catalog_import_items
  where status in ('draft', 'review')
) metrics;

create or replace view public.admin_usage_series
with (security_invoker = true)
as
with months as (
  select generate_series(
    date_trunc('month', now()) - interval '5 months',
    date_trunc('month', now()),
    interval '1 month'
  ) as month_start
)
select
  to_char(month_start, 'Mon') as period,
  (
    select count(*)
    from auth.users au
    where au.created_at < month_start + interval '1 month'
  )::int as users,
  (
    select count(*)
    from public.entitlements e
    where e.is_pro = true
      and e.starts_at < month_start + interval '1 month'
      and (e.ends_at is null or e.ends_at >= month_start)
  )::int as pro_users,
  (
    select coalesce(sum(pe.amount_cents), 0) / 100
    from public.payment_events pe
    where date_trunc('month', pe.occurred_at) = month_start
      and pe.status = 'processed'
  )::int as revenue,
  (
    select count(*)
    from public.catalog_import_items ci
    where date_trunc('month', ci.created_at) = month_start
  )::int as imports
from months
order by month_start;

create or replace view public.admin_alerts
with (security_invoker = true)
as
select * from (
  select
    'billing_failures'::text as id,
    'Billing events need reconciliation'::text as title,
    'Recent payment events are still pending or failed and may leave users out of sync.'::text as description,
    'critical'::text as severity,
    'Open billing queue'::text as action_label,
    count(*) as rank_value
  from public.payment_events
  where status in ('pending', 'failed')
  union all
  select
    'provider_warnings',
    'Provider connectors need review',
    'One or more royalty-free providers are degraded or delayed.',
    'warning',
    'Review ingestion',
    count(*)
  from public.music_providers
  where status <> 'healthy'
  union all
  select
    'attribution_required',
    'Imports need attribution review',
    'Catalog items cannot be published until attribution requirements are resolved.',
    'info',
    'Review imports',
    count(*)
  from public.catalog_import_items
  where attribution_required = true
    and status in ('draft', 'review')
) alerts
where rank_value > 0;

comment on view public.admin_user_overview is
  'Safe client-facing admin view for user support workflows.';

comment on view public.admin_preset_packs is
  'Admin-facing pack view that preserves preset_packs as the app contract.';
