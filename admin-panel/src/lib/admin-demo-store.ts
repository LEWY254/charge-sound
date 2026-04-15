import type {
  AdminAlert,
  AdminCommandResult,
  AdminMetric,
  AdminUserRecord,
  CatalogSoundRecord,
  DashboardOverview,
  DashboardPoint,
  EntitlementRecord,
  IngestionItemRecord,
  ManualImportDraft,
  MusicProviderRecord,
  PaymentEvent,
  PresetPackRecord,
  StaffRoleRecord,
  SubscriptionRecord,
} from '../types/admin'

const metrics: AdminMetric[] = [
  {
    id: 'users',
    label: 'Total users',
    value: '12,480',
    delta: '+8.2%',
    helpText: 'Signed in or anonymous profiles with sync history.',
  },
  {
    id: 'pro',
    label: 'Active Pro users',
    value: '2,431',
    delta: '+4.1%',
    tone: 'success',
    helpText: 'Unified entitlement state across Stripe and app stores.',
  },
  {
    id: 'revenue',
    label: 'MRR proxy',
    value: '$14.2k',
    delta: '+6.7%',
    tone: 'success',
    helpText: 'Normalized recurring revenue from live subscriptions.',
  },
  {
    id: 'imports',
    label: 'Pending imports',
    value: '18',
    delta: '-3',
    tone: 'warning',
    helpText: 'Catalog review items waiting for approval.',
  },
]

const series: DashboardPoint[] = [
  { period: 'Jan', users: 9200, proUsers: 1760, revenue: 9800, imports: 12 },
  { period: 'Feb', users: 10100, proUsers: 1940, revenue: 11050, imports: 16 },
  { period: 'Mar', users: 10890, proUsers: 2112, revenue: 12480, imports: 19 },
  { period: 'Apr', users: 11600, proUsers: 2268, revenue: 13200, imports: 24 },
  { period: 'May', users: 12040, proUsers: 2350, revenue: 13860, imports: 20 },
  { period: 'Jun', users: 12480, proUsers: 2431, revenue: 14230, imports: 18 },
]

const alerts: AdminAlert[] = [
  {
    id: 'stripe-fail',
    title: '2 Stripe webhook retries need review',
    description: 'Recent invoice.payment_failed events have not been reconciled into entitlements.',
    severity: 'critical',
    actionLabel: 'Open billing queue',
  },
  {
    id: 'sync-drift',
    title: 'Google Play receipt sync is 42 minutes behind',
    description: 'The last store receipt import completed, but the scheduled pull is delayed.',
    severity: 'warning',
    actionLabel: 'Inspect provider health',
  },
  {
    id: 'license-check',
    title: 'Three review items need attribution confirmation',
    description: 'The import queue includes tracks that cannot be published until attribution is set.',
    severity: 'info',
    actionLabel: 'Review imports',
  },
]

let users: AdminUserRecord[] = [
  {
    id: 'usr_01',
    email: 'maya@chargesound.app',
    displayName: 'Maya Wilson',
    planKey: 'pro_monthly',
    planStatus: 'active',
    billingProvider: 'stripe',
    onboardingCompleted: true,
    soundsSynced: 42,
    recordingsCount: 15,
    lastSeenAt: '2026-04-15T08:30:00Z',
    createdAt: '2026-01-03T10:12:00Z',
    region: 'GB',
    overrideActive: false,
  },
  {
    id: 'usr_02',
    email: 'leo@chargesound.app',
    displayName: 'Leo Carter',
    planKey: 'pro_yearly',
    planStatus: 'grace_period',
    billingProvider: 'app_store',
    onboardingCompleted: true,
    soundsSynced: 25,
    recordingsCount: 7,
    lastSeenAt: '2026-04-14T16:52:00Z',
    createdAt: '2025-12-21T11:00:00Z',
    region: 'US',
    overrideActive: false,
  },
  {
    id: 'usr_03',
    email: 'sana@chargesound.app',
    displayName: 'Sana Ali',
    planKey: 'free',
    planStatus: 'manual',
    billingProvider: 'none',
    onboardingCompleted: false,
    soundsSynced: 4,
    recordingsCount: 1,
    lastSeenAt: '2026-04-13T11:15:00Z',
    createdAt: '2026-04-09T08:42:00Z',
    region: 'AE',
    overrideActive: true,
  },
]

const subscriptions: SubscriptionRecord[] = [
  {
    id: 'sub_01',
    userId: 'usr_01',
    provider: 'stripe',
    planKey: 'pro_monthly',
    status: 'active',
    amountCents: 699,
    currency: 'USD',
    startedAt: '2026-02-01T00:00:00Z',
    renewsAt: '2026-05-01T00:00:00Z',
    sourceReference: 'sub_1Rc7ab8Example',
  },
  {
    id: 'sub_02',
    userId: 'usr_02',
    provider: 'app_store',
    planKey: 'pro_yearly',
    status: 'grace_period',
    amountCents: 3999,
    currency: 'USD',
    startedAt: '2025-04-01T00:00:00Z',
    renewsAt: '2026-04-20T00:00:00Z',
    sourceReference: 'appstore_txn_4488',
  },
]

const paymentEvents: PaymentEvent[] = [
  {
    id: 'evt_01',
    userId: 'usr_01',
    provider: 'stripe',
    kind: 'invoice.paid',
    amountCents: 699,
    currency: 'USD',
    status: 'processed',
    occurredAt: '2026-04-01T00:00:00Z',
    reference: 'in_001',
  },
  {
    id: 'evt_02',
    userId: 'usr_02',
    provider: 'app_store',
    kind: 'renewal_failed',
    amountCents: 3999,
    currency: 'USD',
    status: 'pending',
    occurredAt: '2026-04-14T10:00:00Z',
    reference: 'renewal_retry_4488',
  },
]

let entitlements: EntitlementRecord[] = [
  {
    id: 'ent_01',
    userId: 'usr_01',
    source: 'billing',
    planKey: 'pro_monthly',
    isPro: true,
    status: 'active',
    startsAt: '2026-02-01T00:00:00Z',
    endsAt: '2026-05-01T00:00:00Z',
  },
  {
    id: 'ent_02',
    userId: 'usr_02',
    source: 'billing',
    planKey: 'pro_yearly',
    isPro: true,
    status: 'grace_period',
    startsAt: '2025-04-01T00:00:00Z',
    endsAt: '2026-04-20T00:00:00Z',
  },
  {
    id: 'ent_03',
    userId: 'usr_03',
    source: 'manual_override',
    planKey: 'pro_support',
    isPro: true,
    status: 'manual',
    startsAt: '2026-04-12T00:00:00Z',
    endsAt: '2026-05-12T00:00:00Z',
    reason: 'Support courtesy extension while investigating Play receipt mismatch.',
  },
]

let packs: PresetPackRecord[] = [
  { id: 'pack_01', name: 'Anime Hits', slug: 'anime_hits', isActive: true, soundCount: 12, visibility: 'public' },
  { id: 'pack_02', name: 'Retro Alerts', slug: 'retro_alerts', isActive: true, soundCount: 9, visibility: 'public' },
  { id: 'pack_03', name: 'Cinematic Drops', slug: 'cinematic_drops', isActive: false, soundCount: 6, visibility: 'staged' },
]

let sounds: CatalogSoundRecord[] = [
  {
    id: 'snd_01',
    name: 'Sword Slash',
    slug: 'sword_slash',
    packId: 'pack_01',
    packName: 'Anime Hits',
    storagePath: 'anime_hits/sword_slash.mp3',
    durationLabel: '0:03',
    licenseLabel: 'CC BY 4.0',
    sourceProvider: 'Pixabay',
    status: 'approved',
  },
  {
    id: 'snd_02',
    name: 'Retro Coin',
    slug: 'retro_coin',
    packId: 'pack_02',
    packName: 'Retro Alerts',
    storagePath: 'retro_alerts/retro_coin.mp3',
    durationLabel: '0:02',
    licenseLabel: 'Pixabay License',
    sourceProvider: 'Pixabay',
    status: 'approved',
  },
  {
    id: 'snd_03',
    name: 'Deep Bass Drop',
    slug: 'deep_bass_drop',
    packId: 'pack_03',
    packName: 'Cinematic Drops',
    storagePath: 'cinematic_drops/deep_bass_drop.mp3',
    durationLabel: '0:04',
    licenseLabel: 'CC0',
    sourceProvider: 'Freesound',
    status: 'draft',
  },
]

const providers: MusicProviderRecord[] = [
  {
    id: 'provider_pixabay',
    name: 'Pixabay Music',
    kind: 'api',
    status: 'healthy',
    syncMode: 'assisted',
    attributionRequired: false,
    lastSyncAt: '2026-04-15T07:55:00Z',
  },
  {
    id: 'provider_freesound',
    name: 'Freesound',
    kind: 'api',
    status: 'warning',
    syncMode: 'manual',
    attributionRequired: true,
    lastSyncAt: '2026-04-15T06:20:00Z',
  },
  {
    id: 'provider_mixkit',
    name: 'Mixkit',
    kind: 'feed',
    status: 'healthy',
    syncMode: 'automated',
    attributionRequired: false,
    lastSyncAt: '2026-04-15T08:05:00Z',
  },
]

let ingestionItems: IngestionItemRecord[] = [
  {
    id: 'ing_01',
    providerId: 'provider_pixabay',
    providerName: 'Pixabay Music',
    title: 'Pixel Charge Chime',
    sourceUrl: 'https://example.com/pixel-charge-chime',
    licenseLabel: 'Pixabay License',
    status: 'review',
    duplicateRisk: 'low',
    attributionRequired: false,
    previewUrl: 'https://example.com/previews/pixel-charge-chime.mp3',
    createdAt: '2026-04-15T07:20:00Z',
  },
  {
    id: 'ing_02',
    providerId: 'provider_freesound',
    providerName: 'Freesound',
    title: 'Sci-Fi Plug In',
    sourceUrl: 'https://example.com/scifi-plug-in',
    licenseLabel: 'CC BY 4.0',
    status: 'review',
    duplicateRisk: 'medium',
    attributionRequired: true,
    previewUrl: 'https://example.com/previews/scifi-plug-in.mp3',
    createdAt: '2026-04-14T18:20:00Z',
  },
  {
    id: 'ing_03',
    providerId: 'provider_mixkit',
    providerName: 'Mixkit',
    title: 'Power Surge Stinger',
    sourceUrl: 'https://example.com/power-surge-stinger',
    licenseLabel: 'Mixkit Free License',
    status: 'draft',
    duplicateRisk: 'high',
    attributionRequired: false,
    previewUrl: 'https://example.com/previews/power-surge-stinger.mp3',
    createdAt: '2026-04-14T10:05:00Z',
  },
]

const staffRoles: StaffRoleRecord[] = [
  {
    id: 'staff_01',
    email: 'admin@chargesound.app',
    fullName: 'ChargeSound Admin',
    role: 'owner',
    active: true,
  },
]

export function getDashboardOverview(): DashboardOverview {
  return { metrics, series, alerts }
}

export function listUsers() {
  return [...users]
}

export function listSubscriptions() {
  return [...subscriptions]
}

export function listPaymentEvents() {
  return [...paymentEvents].sort((a, b) => b.occurredAt.localeCompare(a.occurredAt))
}

export function listEntitlements() {
  return [...entitlements]
}

export function listPacks() {
  return [...packs]
}

export function listSounds() {
  return [...sounds]
}

export function listProviders() {
  return [...providers]
}

export function listIngestionItems() {
  return [...ingestionItems].sort((a, b) => b.createdAt.localeCompare(a.createdAt))
}

export function listStaffRoles() {
  return [...staffRoles]
}

export function createPack(name: string, slug: string): AdminCommandResult {
  packs = [
    {
      id: `pack_${Date.now()}`,
      name,
      slug,
      isActive: false,
      soundCount: 0,
      visibility: 'staged',
    },
    ...packs,
  ]

  return { ok: true, message: `Created "${name}" in demo mode.` }
}

export function createSound(input: {
  name: string
  slug: string
  packId: string
  storagePath: string
  licenseLabel: string
  sourceProvider: string
}): AdminCommandResult {
  const pack = packs.find((item) => item.id === input.packId)
  if (!pack) {
    return { ok: false, message: 'Pack not found.' }
  }

  sounds = [
    {
      id: `snd_${Date.now()}`,
      name: input.name,
      slug: input.slug,
      packId: pack.id,
      packName: pack.name,
      storagePath: input.storagePath,
      durationLabel: '0:03',
      licenseLabel: input.licenseLabel,
      sourceProvider: input.sourceProvider,
      status: 'draft',
    },
    ...sounds,
  ]

  packs = packs.map((item) =>
    item.id === pack.id ? { ...item, soundCount: item.soundCount + 1 } : item,
  )

  return { ok: true, message: `Added "${input.name}" as a staged sound.` }
}

export function setPackActive(packId: string, isActive: boolean): AdminCommandResult {
  packs = packs.map((item) => (item.id === packId ? { ...item, isActive } : item))
  return { ok: true, message: isActive ? 'Pack published.' : 'Pack moved back to staged.' }
}

export function setUserOverride(userId: string, enabled: boolean): AdminCommandResult {
  users = users.map((item) =>
    item.id === userId
      ? {
          ...item,
          overrideActive: enabled,
          planStatus: enabled ? 'manual' : item.planKey === 'free' ? 'free' : item.planStatus,
        }
      : item,
  )

  if (enabled) {
    entitlements = [
      {
        id: `ent_${Date.now()}`,
        userId,
        source: 'manual_override',
        planKey: 'pro_support',
        isPro: true,
        status: 'manual',
        startsAt: new Date().toISOString(),
        endsAt: null,
        reason: 'Granted from admin panel demo mode.',
      },
      ...entitlements.filter((item) => !(item.userId === userId && item.source === 'manual_override')),
    ]
  } else {
    entitlements = entitlements.filter(
      (item) => !(item.userId === userId && item.source === 'manual_override'),
    )
  }

  return {
    ok: true,
    message: enabled ? 'Manual Pro override enabled.' : 'Manual Pro override removed.',
  }
}

export function queueManualImport(input: ManualImportDraft): AdminCommandResult {
  const provider = providers.find((item) => item.id === input.providerId)
  if (!provider) {
    return { ok: false, message: 'Select a valid provider.' }
  }

  ingestionItems = [
    {
      id: `ing_${Date.now()}`,
      providerId: provider.id,
      providerName: provider.name,
      title: input.title,
      sourceUrl: input.sourceUrl,
      licenseLabel: input.licenseLabel,
      status: 'draft',
      duplicateRisk: 'low',
      attributionRequired: input.attributionRequired,
      previewUrl: input.sourceUrl,
      createdAt: new Date().toISOString(),
    },
    ...ingestionItems,
  ]

  return { ok: true, message: 'Import queued for review.' }
}

export function publishImport(itemId: string): AdminCommandResult {
  const item = ingestionItems.find((entry) => entry.id === itemId)
  if (!item) {
    return { ok: false, message: 'Import item not found.' }
  }

  ingestionItems = ingestionItems.map((entry) =>
    entry.id === itemId ? { ...entry, status: 'approved' } : entry,
  )

  return { ok: true, message: `"${item.title}" approved for publishing.` }
}
