import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { readEntitlements, readUsers, setUserOverride } from '../lib/admin-api'
import { useToast } from '../components/Toast'
import {
  Badge,
  Button,
  EmptyState,
  LoadingState,
  SectionHeader,
  Surface,
  TableShell,
  TextInput,
} from '../components/ui'

function statusTone(status: string) {
  if (status === 'active' || status === 'manual') return 'success'
  if (status === 'grace_period' || status === 'past_due') return 'warning'
  if (status === 'canceled') return 'critical'
  return 'muted'
}

export function UsersPage() {
  const { toast } = useToast()
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')

  const usersQuery = useQuery({
    queryKey: ['users'],
    queryFn: readUsers,
  })

  const entitlementsQuery = useQuery({
    queryKey: ['entitlements'],
    queryFn: readEntitlements,
  })

  const overrideMutation = useMutation({
    mutationFn: setUserOverride,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      void queryClient.invalidateQueries({ queryKey: ['users'] })
      void queryClient.invalidateQueries({ queryKey: ['entitlements'] })
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const filteredUsers = useMemo(() => {
    const allUsers = usersQuery.data ?? []
    const term = search.trim().toLowerCase()
    if (!term) return allUsers
    return allUsers.filter((user) =>
      [user.displayName, user.email, user.id, user.planKey]
        .join(' ')
        .toLowerCase()
        .includes(term),
    )
  }, [search, usersQuery.data])

  const users = usersQuery.data ?? []
  const entitlements = entitlementsQuery.data ?? []
  const entitlementByUser = new Map(entitlements.map((item) => [item.userId, item]))

  if (usersQuery.isLoading) {
    return <LoadingState label="Loading users…" />
  }

  if (usersQuery.error) {
    throw usersQuery.error
  }

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Users and entitlements"
        subtitle="Search customers, inspect plan status, and apply support overrides without touching raw billing rows."
        actions={<TextInput value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search by email, name, user ID, or plan…" className="w-full md:w-80" />}
      />

      <div className="grid gap-4 md:grid-cols-3">
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">Total visible users</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">{users.length}</div>
        </Surface>
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">Manual overrides</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">
            {users.filter((item) => item.overrideActive).length}
          </div>
        </Surface>
        <Surface className="p-5">
          <div className="text-sm text-[var(--color-text-muted)]">Pro or grace period</div>
          <div className="pt-2 text-3xl font-semibold tabular-nums">
            {users.filter((item) => ['active', 'grace_period', 'manual'].includes(item.planStatus)).length}
          </div>
        </Surface>
      </div>

      {filteredUsers.length === 0 ? (
        <EmptyState
          title="No users match this search"
          body="Try a broader term or clear the filters to inspect all profiles."
          action={<Button variant="secondary" onClick={() => setSearch('')}>Clear search</Button>}
        />
      ) : (
        <TableShell>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-white/8">
              <thead className="bg-white/[0.03]">
                <tr className="text-left text-xs uppercase text-[var(--color-text-muted)]">
                  <th className="px-4 py-3 font-medium">User</th>
                  <th className="px-4 py-3 font-medium">Plan</th>
                  <th className="px-4 py-3 font-medium">Usage</th>
                  <th className="px-4 py-3 font-medium">Entitlement</th>
                  <th className="px-4 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/8 text-sm">
                {filteredUsers.map((user) => {
                  const entitlement = entitlementByUser.get(user.id)
                  return (
                    <tr key={user.id}>
                      <td className="px-4 py-4 align-top">
                        <div className="space-y-1">
                          <div className="font-medium text-[var(--color-text)]">{user.displayName}</div>
                          <div className="text-[var(--color-text-muted)]">{user.email}</div>
                          <div className="font-mono text-xs text-[var(--color-text-muted)]">{user.id}</div>
                        </div>
                      </td>
                      <td className="px-4 py-4 align-top">
                        <div className="flex flex-wrap gap-2">
                          <Badge tone={statusTone(user.planStatus)}>{user.planStatus}</Badge>
                          <Badge tone="muted">{user.planKey}</Badge>
                          <Badge tone="default">{user.billingProvider}</Badge>
                        </div>
                        <div className="pt-2 text-sm text-[var(--color-text-muted)]">
                          Region {user.region} · onboarded {user.onboardingCompleted ? 'yes' : 'no'}
                        </div>
                      </td>
                      <td className="px-4 py-4 align-top">
                        <div className="space-y-1 text-[var(--color-text-muted)]">
                          <div className="tabular-nums text-[var(--color-text)]">{user.soundsSynced} synced sounds</div>
                          <div className="tabular-nums">{user.recordingsCount} recordings</div>
                          <div>Last seen {new Date(user.lastSeenAt).toLocaleString()}</div>
                        </div>
                      </td>
                      <td className="px-4 py-4 align-top">
                        {entitlement ? (
                          <div className="space-y-1">
                            <Badge tone={entitlement.isPro ? 'success' : 'muted'}>
                              {entitlement.isPro ? 'Pro access' : 'Free'}
                            </Badge>
                            <div className="text-[var(--color-text-muted)]">
                              {entitlement.source.replace('_', ' ')}
                            </div>
                            <div className="tabular-nums text-[var(--color-text-muted)]">
                              {new Date(entitlement.startsAt).toLocaleDateString()}
                              {entitlement.endsAt
                                ? ` - ${new Date(entitlement.endsAt).toLocaleDateString()}`
                                : ' - open ended'}
                            </div>
                            {entitlement.reason ? (
                              <div className="text-pretty text-xs text-[var(--color-text-muted)]">
                                {entitlement.reason}
                              </div>
                            ) : null}
                          </div>
                        ) : (
                          <div className="text-[var(--color-text-muted)]">No entitlement record</div>
                        )}
                      </td>
                      <td className="px-4 py-4 align-top">
                        <Button
                          variant={user.overrideActive ? 'danger' : 'secondary'}
                          onClick={() =>
                            overrideMutation.mutate({
                              userId: user.id,
                              enabled: !user.overrideActive,
                            })
                          }
                          disabled={overrideMutation.isPending}
                        >
                          {user.overrideActive ? 'Remove override' : 'Grant Pro override'}
                        </Button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </TableShell>
      )}
    </div>
  )
}
