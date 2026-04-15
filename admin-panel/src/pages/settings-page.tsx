import { useQuery } from '@tanstack/react-query'
import { readStaffRoles } from '../lib/admin-api'
import { hasSupabaseConfig, isDemoMode, adminCommandFunction } from '../lib/supabase'
import { useAdminAuth } from '../providers/admin-auth-provider'
import { Badge, LoadingState, SectionHeader, Surface } from '../components/ui'

export function SettingsPage() {
  const { identity } = useAdminAuth()
  const rolesQuery = useQuery({
    queryKey: ['staff-roles'],
    queryFn: readStaffRoles,
  })

  if (rolesQuery.isLoading) {
    return <LoadingState label="Loading admin settings…" />
  }

  if (rolesQuery.error) {
    throw rolesQuery.error
  }

  const roles = rolesQuery.data ?? []

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Settings and access model"
        subtitle="Review staff access, browser configuration, and the server-side command contract for privileged actions."
      />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
        <Surface className="p-5">
          <div className="mb-4">
            <h2 className="text-lg font-semibold text-[var(--color-text)]">Staff roles</h2>
            <p className="text-sm text-[var(--color-text-muted)]">
              Staff access is expected to be granted through `staff_roles`, not user-editable metadata.
            </p>
          </div>
          <div className="space-y-3">
            {roles.map((role) => (
              <div
                key={role.id}
                className="flex flex-col gap-3 rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4 md:flex-row md:items-center md:justify-between"
              >
                <div>
                  <div className="text-sm font-medium text-[var(--color-text)]">{role.fullName}</div>
                  <div className="text-sm text-[var(--color-text-muted)]">{role.email}</div>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Badge tone="default">{role.role}</Badge>
                  <Badge tone={role.active ? 'success' : 'critical'}>
                    {role.active ? 'active' : 'disabled'}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </Surface>

        <div className="space-y-6">
          <Surface className="p-5">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Security posture</h2>
            </div>
            <dl className="space-y-3 text-sm text-[var(--color-text-muted)]">
              <div className="flex items-center justify-between gap-4">
                <dt>Supabase browser client</dt>
                <dd>
                  <Badge tone={hasSupabaseConfig ? 'success' : 'warning'}>
                    {hasSupabaseConfig ? 'publishable key configured' : 'missing config'}
                  </Badge>
                </dd>
              </div>
              <div className="flex items-center justify-between gap-4">
                <dt>Privileged command channel</dt>
                <dd>
                  <Badge tone="default">{adminCommandFunction}</Badge>
                </dd>
              </div>
              <div className="flex items-center justify-between gap-4">
                <dt>Demo mode</dt>
                <dd>
                  <Badge tone={isDemoMode ? 'warning' : 'success'}>
                    {isDemoMode ? 'enabled' : 'disabled'}
                  </Badge>
                </dd>
              </div>
              <div className="flex items-center justify-between gap-4">
                <dt>Signed in staff role</dt>
                <dd>
                  <Badge tone="default">{identity?.role ?? 'none'}</Badge>
                </dd>
              </div>
            </dl>
          </Surface>

          <Surface className="p-5">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Implementation notes</h2>
            </div>
            <ul className="space-y-3 text-sm text-[var(--color-text-muted)]">
              <li>Direct table mutations were removed from the browser data flow.</li>
              <li>Privileged writes are expected to be handled by the server-side admin command function.</li>
              <li>Read surfaces use views and normalized tables for billing, entitlements, providers, and imports.</li>
              <li>The mobile app can continue reading preset catalog data from `preset_sounds` and `preset-packs`.</li>
            </ul>
          </Surface>
        </div>
      </div>
    </div>
  )
}
