import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { readDashboardOverview, readProviders } from '../lib/admin-api'
import { Badge, Button, LoadingState, SectionHeader, StatCard, Surface } from '../components/ui'
import { cn } from '../lib/cn'

function alertTone(severity: 'info' | 'warning' | 'critical') {
  if (severity === 'critical') return 'critical'
  if (severity === 'warning') return 'warning'
  return 'default'
}

export function DashboardPage() {
  const dashboardQuery = useQuery({
    queryKey: ['dashboard'],
    queryFn: readDashboardOverview,
  })

  const providersQuery = useQuery({
    queryKey: ['providers'],
    queryFn: readProviders,
  })

  if (dashboardQuery.isLoading) {
    return <LoadingState label="Loading dashboard…" />
  }

  if (dashboardQuery.error) {
    throw dashboardQuery.error
  }

  const dashboard = dashboardQuery.data ?? {
    metrics: [],
    series: [],
    alerts: [],
  }
  const providers = providersQuery.data ?? []
  const linkClass =
    'inline-flex min-h-11 items-center justify-center rounded-[var(--radius-sm)] px-4 text-sm font-medium transition-opacity'

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Operations dashboard"
        subtitle="Track user growth, Pro entitlements, payment health, and music ingestion throughput."
        actions={
          <>
            <Link
              to="/billing"
              className={cn(
                linkClass,
                'border border-white/10 bg-[var(--color-surface-raised)] text-[var(--color-text)] hover:bg-white/5',
              )}
            >
              Billing queue
            </Link>
            <Link
              to="/ingestion"
              className={cn(linkClass, 'bg-[var(--color-primary)] text-white hover:opacity-90')}
            >
              Review imports
            </Link>
          </>
        }
      />

      <div className="grid gap-4 xl:grid-cols-4 md:grid-cols-2">
        {dashboard.metrics.map((metric) => (
          <StatCard
            key={metric.id}
            label={metric.label}
            value={metric.value}
            delta={metric.delta}
            tone={metric.tone}
            helpText={metric.helpText}
          />
        ))}
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.7fr)_minmax(320px,1fr)]">
        <Surface className="p-5">
          <div className="mb-4 space-y-1">
            <h2 className="text-balance text-lg font-semibold text-[var(--color-text)]">
              Growth and entitlement trend
            </h2>
            <p className="text-pretty text-sm text-[var(--color-text-muted)]">
              Compare total users, active Pro users, and normalized recurring revenue.
            </p>
          </div>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dashboard.series}>
                <defs>
                  <linearGradient id="usersGradient" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="5%" stopColor="#818cf8" stopOpacity={0.32} />
                    <stop offset="95%" stopColor="#818cf8" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="rgba(255,255,255,0.06)" vertical={false} />
                <XAxis dataKey="period" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#1a1d27',
                    borderColor: 'rgba(255,255,255,0.08)',
                    borderRadius: 12,
                    color: '#e2e8f0',
                  }}
                />
                <Area type="monotone" dataKey="users" stroke="#818cf8" fill="url(#usersGradient)" strokeWidth={2} />
                <Area type="monotone" dataKey="proUsers" stroke="#22c55e" fill="transparent" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Surface>

        <Surface className="p-5">
          <div className="mb-4 space-y-1">
            <h2 className="text-balance text-lg font-semibold text-[var(--color-text)]">
              Alert queue
            </h2>
            <p className="text-pretty text-sm text-[var(--color-text-muted)]">
              Prioritized issues that can affect billing, access, or catalog publishing.
            </p>
          </div>
          <div className="space-y-3">
            {dashboard.alerts.map((alert) => (
              <div key={alert.id} className="rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4">
                <div className="mb-2 flex flex-wrap items-center gap-2">
                  <Badge tone={alertTone(alert.severity)}>{alert.severity}</Badge>
                  <div className="text-sm font-medium text-[var(--color-text)]">{alert.title}</div>
                </div>
                <p className="text-pretty text-sm text-[var(--color-text-muted)]">
                  {alert.description}
                </p>
                {alert.actionLabel ? (
                  <div className="pt-3">
                    <Button variant="ghost">{alert.actionLabel}</Button>
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        </Surface>
      </div>

      <Surface className="p-5">
        <div className="mb-4 space-y-1">
          <h2 className="text-balance text-lg font-semibold text-[var(--color-text)]">
            Provider health snapshot
          </h2>
          <p className="text-pretty text-sm text-[var(--color-text-muted)]">
            Approved royalty-free sources and the current sync posture for each provider.
          </p>
        </div>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {providers.map((provider) => (
            <div
              key={provider.id}
              className="rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4"
            >
              <div className="mb-3 flex items-center justify-between gap-3">
                <div className="text-sm font-medium text-[var(--color-text)]">{provider.name}</div>
                <Badge
                  tone={
                    provider.status === 'healthy'
                      ? 'success'
                      : provider.status === 'warning'
                        ? 'warning'
                        : 'critical'
                  }
                >
                  {provider.status}
                </Badge>
              </div>
              <dl className="space-y-2 text-sm text-[var(--color-text-muted)]">
                <div className="flex items-center justify-between gap-4">
                  <dt>Sync mode</dt>
                  <dd className="tabular-nums text-[var(--color-text)]">{provider.syncMode}</dd>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <dt>Attribution</dt>
                  <dd className="tabular-nums text-[var(--color-text)]">
                    {provider.attributionRequired ? 'Required' : 'Optional'}
                  </dd>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <dt>Last sync</dt>
                  <dd className="tabular-nums text-[var(--color-text)]">
                    {new Date(provider.lastSyncAt).toLocaleString()}
                  </dd>
                </div>
              </dl>
            </div>
          ))}
        </div>
      </Surface>
    </div>
  )
}
