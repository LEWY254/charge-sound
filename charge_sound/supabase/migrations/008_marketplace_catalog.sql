alter table public.preset_packs
  add column if not exists is_marketplace_visible boolean not null default true;

alter table public.preset_sounds
  add column if not exists is_marketplace_visible boolean not null default true,
  add column if not exists is_free boolean not null default true,
  add column if not exists preview_path text,
  add column if not exists license_url text,
  add column if not exists creator_name text,
  add column if not exists source_attribution text,
  add column if not exists category text,
  add column if not exists tags text[] not null default '{}'::text[],
  add column if not exists featured_rank integer not null default 0;

create index if not exists idx_preset_sounds_marketplace_filters
  on public.preset_sounds (is_marketplace_visible, is_free, status, category, featured_rank);

create index if not exists idx_preset_sounds_tags_gin
  on public.preset_sounds using gin(tags);

drop policy if exists preset_packs_public_read on public.preset_packs;
create policy preset_packs_public_read on public.preset_packs
for select
using (is_active = true and is_marketplace_visible = true);

drop policy if exists preset_sounds_public_read on public.preset_sounds;
create policy preset_sounds_public_read on public.preset_sounds
for select
using (
  coalesce(is_marketplace_visible, true) = true
  and coalesce(is_free, true) = true
  and coalesce(status, 'approved') = 'approved'
  and exists (
    select 1
    from public.preset_packs p
    where p.id = preset_sounds.pack_id
      and p.is_active = true
      and coalesce(p.is_marketplace_visible, true) = true
  )
);

drop view if exists public.marketplace_sounds;
create view public.marketplace_sounds
with (security_invoker = true)
as
select
  s.id,
  s.name,
  coalesce(s.slug, replace(lower(s.name), ' ', '_')) as slug,
  s.pack_id,
  p.name as pack_name,
  p.slug as pack_slug,
  s.storage_bucket,
  s.storage_path,
  s.preview_path,
  coalesce(s.duration_ms, 0) as duration_ms,
  coalesce(s.category, 'general') as category,
  coalesce(s.tags, '{}'::text[]) as tags,
  coalesce(s.featured_rank, 0) as featured_rank,
  coalesce(s.license_label, 'Royalty Free') as license_label,
  coalesce(s.license_url, '') as license_url,
  coalesce(s.creator_name, '') as creator_name,
  coalesce(s.source_attribution, '') as source_attribution,
  coalesce(s.source_provider, 'Manual') as source_provider
from public.preset_sounds s
join public.preset_packs p on p.id = s.pack_id
where p.is_active = true
  and coalesce(p.is_marketplace_visible, true) = true
  and coalesce(s.is_marketplace_visible, true) = true
  and coalesce(s.is_free, true) = true
  and coalesce(s.status, 'approved') = 'approved'
order by coalesce(s.featured_rank, 0) desc, s.name asc;

comment on view public.marketplace_sounds is
  'App-facing royalty-free marketplace catalog view with only published free sounds.';
