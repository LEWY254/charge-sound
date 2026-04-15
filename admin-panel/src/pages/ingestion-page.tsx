import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { publishImport, queueManualImport, readIngestionItems, readProviders } from '../lib/admin-api'
import { useToast } from '../components/Toast'
import {
  Badge,
  Button,
  EmptyState,
  Label,
  LoadingState,
  SectionHeader,
  SelectInput,
  Surface,
  TableShell,
  TextInput,
} from '../components/ui'

function riskTone(risk: string) {
  if (risk === 'high') return 'critical'
  if (risk === 'medium') return 'warning'
  return 'success'
}

export function IngestionPage() {
  const { toast } = useToast()
  const queryClient = useQueryClient()
  const [providerId, setProviderId] = useState('')
  const [title, setTitle] = useState('')
  const [sourceUrl, setSourceUrl] = useState('')
  const [licenseLabel, setLicenseLabel] = useState('Pixabay License')
  const [attributionRequired, setAttributionRequired] = useState(false)

  const providersQuery = useQuery({
    queryKey: ['providers'],
    queryFn: readProviders,
  })

  const importsQuery = useQuery({
    queryKey: ['ingestion-items'],
    queryFn: readIngestionItems,
  })

  const queueMutation = useMutation({
    mutationFn: queueManualImport,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      if (result.ok) {
        setTitle('')
        setSourceUrl('')
        setProviderId('')
        void queryClient.invalidateQueries({ queryKey: ['ingestion-items'] })
      }
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const publishMutation = useMutation({
    mutationFn: publishImport,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      if (result.ok) {
        void queryClient.invalidateQueries({ queryKey: ['ingestion-items'] })
      }
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const providers = providersQuery.data ?? []
  const items = importsQuery.data ?? []

  if (providersQuery.isLoading || importsQuery.isLoading) {
    return <LoadingState label="Loading ingestion queue…" />
  }

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Royalty-free ingestion"
        subtitle="Support manual curation today and provider-assisted or scheduled imports as the catalog pipeline matures."
      />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)]">
        <Surface className="space-y-5 p-5">
          <div className="space-y-1">
            <h2 className="text-lg font-semibold text-[var(--color-text)]">Queue manual import</h2>
            <p className="text-sm text-[var(--color-text-muted)]">
              Paste a royalty-free source link, capture the license, and push it into review.
            </p>
          </div>

          <div className="space-y-3">
            <div className="space-y-2">
              <Label>Provider</Label>
              <SelectInput value={providerId} onChange={(event) => setProviderId(event.target.value)}>
                <option value="">Choose provider…</option>
                {providers.map((provider) => (
                  <option key={provider.id} value={provider.id}>
                    {provider.name}
                  </option>
                ))}
              </SelectInput>
            </div>
            <div className="space-y-2">
              <Label>Track title</Label>
              <TextInput
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                placeholder="Pixel Charge Chime"
              />
            </div>
            <div className="space-y-2">
              <Label>Source URL</Label>
              <TextInput
                value={sourceUrl}
                onChange={(event) => setSourceUrl(event.target.value)}
                placeholder="https://provider.example/sound"
              />
            </div>
            <div className="space-y-2">
              <Label>License label</Label>
              <TextInput
                value={licenseLabel}
                onChange={(event) => setLicenseLabel(event.target.value)}
                placeholder="Pixabay License"
              />
            </div>
            <label className="flex min-h-11 items-center gap-3 rounded-[var(--radius-sm)] border border-white/8 px-3 text-sm text-[var(--color-text)]">
              <input
                type="checkbox"
                checked={attributionRequired}
                onChange={(event) => setAttributionRequired(event.target.checked)}
              />
              Attribution required for publishing
            </label>
            <Button
              className="w-full"
              onClick={() =>
                queueMutation.mutate({
                  providerId,
                  title,
                  sourceUrl,
                  licenseLabel,
                  attributionRequired,
                })
              }
              disabled={!providerId || !title || !sourceUrl || !licenseLabel || queueMutation.isPending}
            >
              {queueMutation.isPending ? 'Queueing…' : 'Queue review item'}
            </Button>
          </div>
        </Surface>

        <div className="space-y-6">
          <Surface className="p-5">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Provider connectors</h2>
              <p className="text-sm text-[var(--color-text-muted)]">
                Manual, assisted, and automated sources can coexist as long as they preserve license metadata.
              </p>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
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
                  <div className="space-y-1 text-sm text-[var(--color-text-muted)]">
                    <div>Mode: {provider.syncMode}</div>
                    <div>Connector: {provider.kind}</div>
                    <div>
                      Attribution: {provider.attributionRequired ? 'Required' : 'Optional'}
                    </div>
                    <div className="tabular-nums">
                      Last sync: {new Date(provider.lastSyncAt).toLocaleString()}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </Surface>

          <TableShell>
            <div className="border-b border-white/8 px-4 py-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Review queue</h2>
              <p className="text-sm text-[var(--color-text-muted)]">
                Duplicate risk and attribution checks help prevent invalid or redundant publishing.
              </p>
            </div>
            {items.length === 0 ? (
              <EmptyState
                title="No imports waiting for review"
                body="Queue a manual link or enable assisted provider syncs."
              />
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-white/8">
                  <thead className="bg-white/[0.03]">
                    <tr className="text-left text-xs uppercase text-[var(--color-text-muted)]">
                      <th className="px-4 py-3 font-medium">Track</th>
                      <th className="px-4 py-3 font-medium">Provider</th>
                      <th className="px-4 py-3 font-medium">Compliance</th>
                      <th className="px-4 py-3 font-medium">Status</th>
                      <th className="px-4 py-3 font-medium">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/8 text-sm">
                    {items.map((item) => (
                      <tr key={item.id}>
                        <td className="px-4 py-4">
                          <div className="font-medium text-[var(--color-text)]">{item.title}</div>
                          <a
                            className="truncate text-[var(--color-primary-hover)]"
                            href={item.sourceUrl}
                            target="_blank"
                            rel="noreferrer"
                          >
                            {item.sourceUrl}
                          </a>
                        </td>
                        <td className="px-4 py-4">
                          <div className="text-[var(--color-text)]">{item.providerName}</div>
                          <div className="text-[var(--color-text-muted)]">{item.licenseLabel}</div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex flex-wrap gap-2">
                            <Badge tone={riskTone(item.duplicateRisk)}>{item.duplicateRisk} duplicate risk</Badge>
                            <Badge tone={item.attributionRequired ? 'warning' : 'success'}>
                              {item.attributionRequired ? 'Attribution required' : 'Attribution optional'}
                            </Badge>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <Badge tone={item.status === 'approved' ? 'success' : item.status === 'review' ? 'warning' : 'muted'}>
                            {item.status}
                          </Badge>
                        </td>
                        <td className="px-4 py-4">
                          <Button
                            variant="secondary"
                            onClick={() => publishMutation.mutate({ itemId: item.id })}
                            disabled={item.status === 'approved' || publishMutation.isPending}
                          >
                            {item.status === 'approved' ? 'Published' : 'Approve'}
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </TableShell>
        </div>
      </div>
    </div>
  )
}
