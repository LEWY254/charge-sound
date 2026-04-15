import {
  createPack as createDemoPack,
  createSound as createDemoSound,
  getDashboardOverview,
  listEntitlements,
  listIngestionItems,
  listPacks,
  listPaymentEvents,
  listProviders,
  listSounds,
  listStaffRoles,
  listSubscriptions,
  listUsers,
  publishImport as publishDemoImport,
  queueManualImport as queueDemoManualImport,
  setPackActive as setDemoPackActive,
  setUserOverride as setDemoUserOverride,
} from './admin-demo-store'
import { adminCommandFunction, isDemoMode, supabase } from './supabase'
import type {
  AdminCommandResult,
  AdminUserRecord,
  CatalogSoundRecord,
  DashboardOverview,
  EntitlementRecord,
  IngestionItemRecord,
  ManualImportDraft,
  MusicProviderRecord,
  PaymentEvent,
  PresetPackRecord,
  StaffRoleRecord,
  SubscriptionRecord,
} from '../types/admin'

async function invokeAdminCommand<TPayload>(
  action: string,
  payload: TPayload,
): Promise<AdminCommandResult> {
  if (!supabase) {
    return { ok: false, message: 'Supabase is not configured.' }
  }

  const { data, error } = await supabase.functions.invoke(adminCommandFunction, {
    body: { action, payload },
  })

  if (error) {
    return { ok: false, message: error.message }
  }

  return {
    ok: Boolean(data?.ok ?? true),
    message: String(data?.message ?? `${action} completed.`),
  }
}

export async function readDashboardOverview(): Promise<DashboardOverview> {
  if (isDemoMode || !supabase) {
    return getDashboardOverview()
  }

  const [metricsRes, seriesRes, alertsRes] = await Promise.all([
    supabase.from('admin_dashboard_metrics').select('*').order('sort_order'),
    supabase.from('admin_usage_series').select('*').order('period'),
    supabase.from('admin_alerts').select('*').order('severity', { ascending: false }),
  ])

  if (metricsRes.error) throw metricsRes.error
  if (seriesRes.error) throw seriesRes.error
  if (alertsRes.error) throw alertsRes.error

  return {
    metrics: (metricsRes.data ?? []).map((row) => ({
      id: row.id,
      label: row.label,
      value: row.value,
      delta: row.delta,
      tone: row.tone ?? 'default',
      helpText: row.help_text,
    })),
    series: (seriesRes.data ?? []).map((row) => ({
      period: row.period,
      users: row.users,
      proUsers: row.pro_users,
      revenue: row.revenue,
      imports: row.imports,
    })),
    alerts: (alertsRes.data ?? []).map((row) => ({
      id: row.id,
      title: row.title,
      description: row.description,
      severity: row.severity,
      actionLabel: row.action_label ?? undefined,
    })),
  }
}

export async function readUsers(): Promise<AdminUserRecord[]> {
  if (isDemoMode || !supabase) {
    return listUsers()
  }

  const { data, error } = await supabase
    .from('admin_user_overview')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) throw error

  return (data ?? []).map((row) => ({
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    planKey: row.plan_key,
    planStatus: row.plan_status,
    billingProvider: row.billing_provider,
    onboardingCompleted: row.onboarding_completed,
    soundsSynced: row.sounds_synced,
    recordingsCount: row.recordings_count,
    lastSeenAt: row.last_seen_at,
    createdAt: row.created_at,
    region: row.region,
    overrideActive: row.override_active,
  }))
}

export async function readSubscriptions(): Promise<SubscriptionRecord[]> {
  if (isDemoMode || !supabase) {
    return listSubscriptions()
  }

  const { data, error } = await supabase.from('subscriptions').select('*').order('started_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as SubscriptionRecord[]
}

export async function readPaymentEvents(): Promise<PaymentEvent[]> {
  if (isDemoMode || !supabase) {
    return listPaymentEvents()
  }

  const { data, error } = await supabase.from('payment_events').select('*').order('occurred_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map((row) => ({
    id: row.id,
    userId: row.user_id,
    provider: row.provider,
    kind: row.kind,
    amountCents: row.amount_cents,
    currency: row.currency,
    status: row.status,
    occurredAt: row.occurred_at,
    reference: row.reference,
  }))
}

export async function readEntitlements(): Promise<EntitlementRecord[]> {
  if (isDemoMode || !supabase) {
    return listEntitlements()
  }

  const { data, error } = await supabase.from('entitlements').select('*').order('starts_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map((row) => ({
    id: row.id,
    userId: row.user_id,
    source: row.source,
    planKey: row.plan_key,
    isPro: row.is_pro,
    status: row.status,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    reason: row.reason ?? undefined,
  }))
}

export async function readPacks(): Promise<PresetPackRecord[]> {
  if (isDemoMode || !supabase) {
    return listPacks()
  }

  const { data, error } = await supabase
    .from('admin_preset_packs')
    .select('*')
    .order('name')

  if (error) throw error

  return (data ?? []).map((row) => ({
    id: row.id,
    name: row.name,
    slug: row.slug,
    isActive: row.is_active,
    soundCount: row.sound_count ?? 0,
    visibility: row.visibility ?? (row.is_active ? 'public' : 'staged'),
  }))
}

export async function readSounds(): Promise<CatalogSoundRecord[]> {
  if (isDemoMode || !supabase) {
    return listSounds()
  }

  const { data, error } = await supabase
    .from('admin_catalog_sounds')
    .select('*')
    .order('name')

  if (error) throw error

  return (data ?? []).map((row) => ({
    id: row.id,
    name: row.name,
    slug: row.slug ?? row.name.toLowerCase().replaceAll(' ', '_'),
    packId: row.pack_id ?? '',
    packName: row.pack_name ?? 'Unknown pack',
    storagePath: row.storage_path,
    durationLabel: '0:03',
    licenseLabel: row.license_label ?? 'Unknown',
    sourceProvider: row.source_provider ?? 'Manual',
    status: row.status ?? 'approved',
  }))
}

export async function readProviders(): Promise<MusicProviderRecord[]> {
  if (isDemoMode || !supabase) {
    return listProviders()
  }

  const { data, error } = await supabase.from('music_providers').select('*').order('name')
  if (error) throw error
  return (data ?? []).map((row) => ({
    id: row.id,
    name: row.name,
    kind: row.kind,
    status: row.status,
    syncMode: row.sync_mode,
    attributionRequired: row.attribution_required,
    lastSyncAt: row.last_sync_at,
  }))
}

export async function readIngestionItems(): Promise<IngestionItemRecord[]> {
  if (isDemoMode || !supabase) {
    return listIngestionItems()
  }

  const { data, error } = await supabase
    .from('catalog_import_items')
    .select('*, music_providers:provider_id(name)')
    .order('created_at', { ascending: false })

  if (error) throw error

  return (data ?? []).map((row) => ({
    id: row.id,
    providerId: row.provider_id,
    providerName: row.music_providers?.name ?? 'Unknown provider',
    title: row.title,
    sourceUrl: row.source_url,
    licenseLabel: row.license_label,
    status: row.status,
    duplicateRisk: row.duplicate_risk,
    attributionRequired: row.attribution_required,
    previewUrl: row.preview_url ?? row.source_url,
    createdAt: row.created_at,
  }))
}

export async function readStaffRoles(): Promise<StaffRoleRecord[]> {
  if (isDemoMode || !supabase) {
    return listStaffRoles()
  }

  const { data, error } = await supabase.from('staff_roles').select('*').order('email')
  if (error) throw error

  return (data ?? []).map((row) => ({
    id: row.id,
    email: row.email,
    fullName: row.full_name,
    role: row.role,
    active: row.active,
  }))
}

export async function createPack(input: {
  name: string
  slug: string
}): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return createDemoPack(input.name, input.slug)
  }

  return invokeAdminCommand('create_pack', input)
}

export async function createSound(input: {
  name: string
  slug: string
  packId: string
  storagePath: string
  licenseLabel: string
  sourceProvider: string
}): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return createDemoSound(input)
  }

  return invokeAdminCommand('create_sound', input)
}

export async function setPackActive(input: {
  packId: string
  isActive: boolean
}): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return setDemoPackActive(input.packId, input.isActive)
  }

  return invokeAdminCommand('set_pack_active', input)
}

export async function setUserOverride(input: {
  userId: string
  enabled: boolean
}): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return setDemoUserOverride(input.userId, input.enabled)
  }

  return invokeAdminCommand('set_user_override', input)
}

export async function queueManualImport(input: ManualImportDraft): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return queueDemoManualImport(input)
  }

  return invokeAdminCommand('queue_manual_import', input)
}

export async function publishImport(input: {
  itemId: string
}): Promise<AdminCommandResult> {
  if (isDemoMode) {
    return publishDemoImport(input.itemId)
  }

  return invokeAdminCommand('publish_import', input)
}
