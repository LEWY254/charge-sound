export type Severity = 'info' | 'warning' | 'critical'
export type BillingProvider = 'stripe' | 'google_play' | 'app_store' | 'hybrid' | 'none'
export type PlanStatus = 'free' | 'active' | 'grace_period' | 'past_due' | 'canceled' | 'manual'
export type IngestionStatus = 'draft' | 'review' | 'approved' | 'rejected' | 'archived'
export type SyncMode = 'manual' | 'assisted' | 'automated'
export type ProviderStatus = 'healthy' | 'warning' | 'error'
export type DuplicateRisk = 'low' | 'medium' | 'high'
export type AdminRole = 'owner' | 'ops' | 'support' | 'catalog_manager' | 'finance'

export interface AdminMetric {
  id: string
  label: string
  value: string
  delta: string
  tone?: 'default' | 'success' | 'warning'
  helpText: string
}

export interface DashboardPoint {
  period: string
  users: number
  proUsers: number
  revenue: number
  imports: number
}

export interface AdminAlert {
  id: string
  title: string
  description: string
  severity: Severity
  actionLabel?: string
}

export interface DashboardOverview {
  metrics: AdminMetric[]
  series: DashboardPoint[]
  alerts: AdminAlert[]
}

export interface AdminUserRecord {
  id: string
  email: string
  displayName: string
  planKey: string
  planStatus: PlanStatus
  billingProvider: BillingProvider
  onboardingCompleted: boolean
  soundsSynced: number
  recordingsCount: number
  lastSeenAt: string
  createdAt: string
  region: string
  overrideActive: boolean
}

export interface SubscriptionRecord {
  id: string
  userId: string
  provider: Exclude<BillingProvider, 'none'>
  planKey: string
  status: PlanStatus
  amountCents: number
  currency: string
  startedAt: string
  renewsAt: string | null
  sourceReference: string
}

export interface PaymentEvent {
  id: string
  userId: string
  provider: Exclude<BillingProvider, 'none'>
  kind: string
  amountCents: number
  currency: string
  status: 'processed' | 'pending' | 'failed' | 'refunded'
  occurredAt: string
  reference: string
}

export interface EntitlementRecord {
  id: string
  userId: string
  source: 'billing' | 'manual_override'
  planKey: string
  isPro: boolean
  status: PlanStatus
  startsAt: string
  endsAt: string | null
  reason?: string
}

export interface PresetPackRecord {
  id: string
  name: string
  slug: string
  isActive: boolean
  soundCount: number
  visibility: 'public' | 'staged'
}

export interface CatalogSoundRecord {
  id: string
  name: string
  slug: string
  packId: string
  packName: string
  storagePath: string
  durationLabel: string
  licenseLabel: string
  sourceProvider: string
  status: 'draft' | 'approved'
}

export interface MusicProviderRecord {
  id: string
  name: string
  kind: 'manual' | 'api' | 'feed'
  status: ProviderStatus
  syncMode: SyncMode
  attributionRequired: boolean
  lastSyncAt: string
}

export interface IngestionItemRecord {
  id: string
  providerId: string
  providerName: string
  title: string
  sourceUrl: string
  licenseLabel: string
  status: IngestionStatus
  duplicateRisk: DuplicateRisk
  attributionRequired: boolean
  previewUrl: string
  createdAt: string
}

export interface ManualImportDraft {
  providerId: string
  title: string
  sourceUrl: string
  licenseLabel: string
  attributionRequired: boolean
}

export interface StaffRoleRecord {
  id: string
  email: string
  fullName: string
  role: AdminRole
  active: boolean
}

export interface AdminCommandResult {
  ok: boolean
  message: string
}
