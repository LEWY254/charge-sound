import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { readEntitlements, readPaymentEvents, readSubscriptions, readUsers } from '../lib/admin-api'
import {
  Badge,
  EmptyState,
  LoadingState,
  SectionHeader,
  Surface,
  TableShell,
  TextInput,
} from '../components/ui'

function providerTone(provider: string) {
  if (provider === 'stripe') return 'default'
  if (provider === 'google_play' || provider === 'app_store') return 'warning'
  return 'muted'
}

function statusTone(status: string) {
  if (status === 'processed' || status === 'active') return 'success'
  if (status === 'pending' || status === 'grace_period') return 'warning'
  if (status === 'failed' || status === 'refunded' || status === 'canceled') return 'critical'
  return 'muted'
}

function formatMoney(amountCents: number, currency: string) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amountCents / 100)
}

export function BillingPage() {
  const [providerFilter, setProviderFilter] = useState('')
  const subscriptionsQuery = useQuery({
    queryKey: ['subscriptions'],
    queryFn: readSubscriptions,
  })
  const eventsQuery = useQuery({
    queryKey: ['payment-events'],
    queryFn: readPaymentEvents,
  })
  const entitlementsQuery = useQuery({
    queryKey: ['entitlements'],
    queryFn: readEntitlements,
  })
  const usersQuery = useQuery({
    queryKey: ['users'],
    queryFn: readUsers,
  })

  const filteredEvents = useMemo(() => {
    const allEvents = eventsQuery.data ?? []
    if (!providerFilter) return allEvents
    return allEvents.filter((item) => item.provider === providerFilter)
  }, [eventsQuery.data, providerFilter])

  const subscriptions = subscriptionsQuery.data ?? []
  const entitlements = entitlementsQuery.data ?? []
  const users = usersQuery.data ?? []
  const usersById = new Map(users.map((item) => [item.id, item]))

  if (
    subscriptionsQuery.isLoading ||
    eventsQuery.isLoading ||
    entitlementsQuery.isLoading ||
    usersQuery.isLoading
  ) {
    return <LoadingState label="Loading billing data…" />
  }

  const totalMrr = subscriptions
    .filter((item) => item.status === 'active' || item.status === 'grace_period')
    .reduce((sum, item) => sum + item.amountCents, 0)

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Billing and payment tracking"
        subtitle="Normalized subscriptions, payment events, and Pro entitlements across Stripe and app stores."
        actions={
          <TextInput
            value={providerFilter}
            onChange={(event) => setProviderFilter(event.target.value)}
            placeholder="Filter payment events by provider…"
            className="w-full md:w-72"
          />
        }
      />

      <div className="grid gap-4 md:grid-cols-3">
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">Live subscriptions</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">{subscriptions.length}</div>
        </Surface>
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">MRR proxy</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">{formatMoney(totalMrr, 'USD')}</div>
        </Surface>
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">Entitlement records</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">{entitlements.length}</div>
        </Surface>
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
        <TableShell>
          <div className="border-b border-white/8 px-4 py-4">
            <h2 className="text-lg font-semibold text-[var(--color-text)]">Subscriptions</h2>
            <p className="text-sm text-[var(--color-text-muted)]">
              Current billing contracts that feed the entitlement model.
            </p>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/8">
              <thead className="bg-white/[0.03]">
                <tr className="text-left text-xs uppercase text-[var(--color-text-muted)]">
                  <th className="px-4 py-3 font-medium">Customer</th>
                  <th className="px-4 py-3 font-medium">Provider</th>
                  <th className="px-4 py-3 font-medium">Plan</th>
                  <th className="px-4 py-3 font-medium">Renewal</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/8 text-sm">
                {subscriptions.map((subscription) => (
                  <tr key={subscription.id}>
                    <td className="px-4 py-4">
                      <div className="font-medium text-[var(--color-text)]">
                        {usersById.get(subscription.userId)?.displayName ?? subscription.userId}
                      </div>
                      <div className="text-[var(--color-text-muted)]">
                        {usersById.get(subscription.userId)?.email ?? 'Unknown'}
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex flex-wrap gap-2">
                        <Badge tone={providerTone(subscription.provider)}>{subscription.provider}</Badge>
                        <Badge tone={statusTone(subscription.status)}>{subscription.status}</Badge>
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="tabular-nums text-[var(--color-text)]">
                        {subscription.planKey}
                      </div>
                      <div className="text-[var(--color-text-muted)]">
                        {formatMoney(subscription.amountCents, subscription.currency)}
                      </div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="tabular-nums text-[var(--color-text)]">
                        {subscription.renewsAt
                          ? new Date(subscription.renewsAt).toLocaleDateString()
                          : 'n/a'}
                      </div>
                      <div className="truncate text-[var(--color-text-muted)]">
                        {subscription.sourceReference}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </TableShell>

        <Surface className="p-5">
          <div className="mb-4">
            <h2 className="text-lg font-semibold text-[var(--color-text)]">Entitlement summary</h2>
            <p className="text-sm text-[var(--color-text-muted)]">
              The app should use this state to answer whether a user is Pro right now.
            </p>
          </div>
          <div className="space-y-3">
            {entitlements.map((entitlement) => (
              <div
                key={entitlement.id}
                className="rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4"
              >
                <div className="mb-2 flex flex-wrap items-center gap-2">
                  <Badge tone={entitlement.isPro ? 'success' : 'muted'}>
                    {entitlement.isPro ? 'Pro' : 'Free'}
                  </Badge>
                  <Badge tone={providerTone(entitlement.source === 'billing' ? 'stripe' : 'none')}>
                    {entitlement.source}
                  </Badge>
                  <Badge tone={statusTone(entitlement.status)}>{entitlement.status}</Badge>
                </div>
                <div className="text-sm font-medium text-[var(--color-text)]">
                  {usersById.get(entitlement.userId)?.displayName ?? entitlement.userId}
                </div>
                <div className="text-sm text-[var(--color-text-muted)]">{entitlement.planKey}</div>
                <div className="pt-2 text-sm text-[var(--color-text-muted)] tabular-nums">
                  {new Date(entitlement.startsAt).toLocaleDateString()}
                  {entitlement.endsAt
                    ? ` - ${new Date(entitlement.endsAt).toLocaleDateString()}`
                    : ' - open ended'}
                </div>
                {entitlement.reason ? (
                  <div className="pt-2 text-pretty text-sm text-[var(--color-text-muted)]">
                    {entitlement.reason}
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        </Surface>
      </div>

      <TableShell>
        <div className="border-b border-white/8 px-4 py-4">
          <h2 className="text-lg font-semibold text-[var(--color-text)]">Payment event ledger</h2>
          <p className="text-sm text-[var(--color-text-muted)]">
            Reconciliation and support timeline for renewals, failures, refunds, and store events.
          </p>
        </div>
        {filteredEvents.length === 0 ? (
          <EmptyState
            title="No payment events for this filter"
            body="Try a different provider filter or clear it to see the full ledger."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/8">
              <thead className="bg-white/[0.03]">
                <tr className="text-left text-xs uppercase text-[var(--color-text-muted)]">
                  <th className="px-4 py-3 font-medium">Event</th>
                  <th className="px-4 py-3 font-medium">User</th>
                  <th className="px-4 py-3 font-medium">Amount</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Occurred</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/8 text-sm">
                {filteredEvents.map((event) => (
                  <tr key={event.id}>
                    <td className="px-4 py-4">
                      <div className="font-medium text-[var(--color-text)]">{event.kind}</div>
                      <div className="text-[var(--color-text-muted)]">{event.reference}</div>
                    </td>
                    <td className="px-4 py-4">
                      <div className="text-[var(--color-text)]">
                        {usersById.get(event.userId)?.displayName ?? event.userId}
                      </div>
                      <div className="text-[var(--color-text-muted)]">
                        {usersById.get(event.userId)?.email ?? 'Unknown'}
                      </div>
                    </td>
                    <td className="px-4 py-4 tabular-nums text-[var(--color-text)]">
                      {formatMoney(event.amountCents, event.currency)}
                    </td>
                    <td className="px-4 py-4">
                      <div className="flex flex-wrap gap-2">
                        <Badge tone={providerTone(event.provider)}>{event.provider}</Badge>
                        <Badge tone={statusTone(event.status)}>{event.status}</Badge>
                      </div>
                    </td>
                    <td className="px-4 py-4 tabular-nums text-[var(--color-text-muted)]">
                      {new Date(event.occurredAt).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </TableShell>
    </div>
  )
}
