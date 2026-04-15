import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { createPack, createSound, readPacks, readSounds, setPackActive } from '../lib/admin-api'
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

export function CatalogPage() {
  const { toast } = useToast()
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')
  const [packName, setPackName] = useState('')
  const [packSlug, setPackSlug] = useState('')
  const [soundName, setSoundName] = useState('')
  const [soundStoragePath, setSoundStoragePath] = useState('')
  const [soundPackId, setSoundPackId] = useState('')
  const [soundLicense, setSoundLicense] = useState('Pixabay License')
  const [soundProvider, setSoundProvider] = useState('Manual')

  const packsQuery = useQuery({
    queryKey: ['packs'],
    queryFn: readPacks,
  })
  const soundsQuery = useQuery({
    queryKey: ['sounds'],
    queryFn: readSounds,
  })

  const packMutation = useMutation({
    mutationFn: createPack,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      if (result.ok) {
        setPackName('')
        setPackSlug('')
        void queryClient.invalidateQueries({ queryKey: ['packs'] })
      }
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const soundMutation = useMutation({
    mutationFn: createSound,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      if (result.ok) {
        setSoundName('')
        setSoundStoragePath('')
        setSoundPackId('')
        void queryClient.invalidateQueries({ queryKey: ['packs'] })
        void queryClient.invalidateQueries({ queryKey: ['sounds'] })
      }
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const activateMutation = useMutation({
    mutationFn: setPackActive,
    onSuccess(result) {
      toast(result.message, result.ok ? 'success' : 'error')
      if (result.ok) {
        void queryClient.invalidateQueries({ queryKey: ['packs'] })
      }
    },
    onError(error) {
      toast((error as Error).message, 'error')
    },
  })

  const filteredSounds = useMemo(() => {
    const allSounds = soundsQuery.data ?? []
    const term = search.trim().toLowerCase()
    if (!term) return allSounds
    return allSounds.filter((sound) =>
      [sound.name, sound.packName, sound.storagePath, sound.licenseLabel, sound.sourceProvider]
        .join(' ')
        .toLowerCase()
        .includes(term),
    )
  }, [search, soundsQuery.data])

  const packs = packsQuery.data ?? []

  if (packsQuery.isLoading || soundsQuery.isLoading) {
    return <LoadingState label="Loading catalog…" />
  }

  return (
    <div className="space-y-6">
      <SectionHeader
        title="Catalog management"
        subtitle="Manage packs and approved preset sounds while preserving the existing mobile preset delivery path."
        actions={
          <TextInput
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search sounds, packs, licenses, or providers…"
            className="w-full md:w-80"
          />
        }
      />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)]">
        <Surface className="space-y-5 p-5">
          <div className="space-y-1">
            <h2 className="text-lg font-semibold text-[var(--color-text)]">Create preset pack</h2>
            <p className="text-sm text-[var(--color-text-muted)]">
              Packs stay staged until they are published.
            </p>
          </div>
          <div className="space-y-3">
            <div className="space-y-2">
              <Label>Pack name</Label>
              <TextInput
                value={packName}
                onChange={(event) => {
                  const value = event.target.value
                  setPackName(value)
                  if (!packSlug) {
                    setPackSlug(value.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''))
                  }
                }}
                placeholder="Anime Hits"
              />
            </div>
            <div className="space-y-2">
              <Label>Pack slug</Label>
              <TextInput
                value={packSlug}
                onChange={(event) => setPackSlug(event.target.value)}
                placeholder="anime_hits"
              />
            </div>
            <Button
              className="w-full"
              onClick={() => packMutation.mutate({ name: packName, slug: packSlug })}
              disabled={!packName || !packSlug || packMutation.isPending}
            >
              {packMutation.isPending ? 'Saving…' : 'Create pack'}
            </Button>
          </div>

          <div className="space-y-3 border-t border-white/8 pt-5">
            <div className="space-y-1">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Add preset sound</h2>
              <p className="text-sm text-[var(--color-text-muted)]">
                New sounds enter the catalog as draft rows and can later be published.
              </p>
            </div>
            <div className="space-y-2">
              <Label>Sound name</Label>
              <TextInput
                value={soundName}
                onChange={(event) => setSoundName(event.target.value)}
                placeholder="Sword Slash"
              />
            </div>
            <div className="space-y-2">
              <Label>Storage path</Label>
              <TextInput
                value={soundStoragePath}
                onChange={(event) => setSoundStoragePath(event.target.value)}
                placeholder="anime_hits/sword_slash.mp3"
              />
            </div>
            <div className="space-y-2">
              <Label>Pack</Label>
              <SelectInput value={soundPackId} onChange={(event) => setSoundPackId(event.target.value)}>
                <option value="">Select a pack…</option>
                {packs.map((pack) => (
                  <option key={pack.id} value={pack.id}>
                    {pack.name}
                  </option>
                ))}
              </SelectInput>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-2">
                <Label>License</Label>
                <TextInput
                  value={soundLicense}
                  onChange={(event) => setSoundLicense(event.target.value)}
                  placeholder="Pixabay License"
                />
              </div>
              <div className="space-y-2">
                <Label>Source provider</Label>
                <TextInput
                  value={soundProvider}
                  onChange={(event) => setSoundProvider(event.target.value)}
                  placeholder="Pixabay"
                />
              </div>
            </div>
            <Button
              className="w-full"
              onClick={() =>
                soundMutation.mutate({
                  name: soundName,
                  slug: soundName.toLowerCase().replace(/\s+/g, '_'),
                  packId: soundPackId,
                  storagePath: soundStoragePath,
                  licenseLabel: soundLicense,
                  sourceProvider: soundProvider,
                })
              }
              disabled={!soundName || !soundStoragePath || !soundPackId || soundMutation.isPending}
            >
              {soundMutation.isPending ? 'Saving…' : 'Create sound row'}
            </Button>
          </div>
        </Surface>

        <div className="space-y-6">
          <Surface className="p-5">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Preset packs</h2>
              <p className="text-sm text-[var(--color-text-muted)]">
                Publish staged packs only after their sounds, licenses, and previews are ready.
              </p>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              {packs.map((pack) => (
                <div
                  key={pack.id}
                  className="rounded-[var(--radius-md)] border border-white/8 bg-[var(--color-surface-raised)] p-4"
                >
                  <div className="mb-3 flex items-start justify-between gap-3">
                    <div>
                      <div className="text-sm font-medium text-[var(--color-text)]">{pack.name}</div>
                      <div className="font-mono text-xs text-[var(--color-text-muted)]">{pack.slug}</div>
                    </div>
                    <Badge tone={pack.isActive ? 'success' : 'warning'}>
                      {pack.isActive ? 'Published' : 'Staged'}
                    </Badge>
                  </div>
                  <div className="text-sm text-[var(--color-text-muted)]">
                    {pack.soundCount} sounds · {pack.visibility}
                  </div>
                  <div className="pt-4">
                    <Button
                      variant={pack.isActive ? 'ghost' : 'secondary'}
                      onClick={() =>
                        activateMutation.mutate({
                          packId: pack.id,
                          isActive: !pack.isActive,
                        })
                      }
                      disabled={activateMutation.isPending}
                    >
                      {pack.isActive ? 'Move to staged' : 'Publish pack'}
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Surface>

          <TableShell>
            <div className="border-b border-white/8 px-4 py-4">
              <h2 className="text-lg font-semibold text-[var(--color-text)]">Preset sounds</h2>
              <p className="text-sm text-[var(--color-text-muted)]">
                Approved app sounds remain compatible with `preset_sounds` and `preset-packs`.
              </p>
            </div>
            {filteredSounds.length === 0 ? (
              <EmptyState
                title="No sounds match this filter"
                body="Try a different term or add a new sound row."
              />
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-white/8">
                  <thead className="bg-white/[0.03]">
                    <tr className="text-left text-xs uppercase text-[var(--color-text-muted)]">
                      <th className="px-4 py-3 font-medium">Sound</th>
                      <th className="px-4 py-3 font-medium">Pack</th>
                      <th className="px-4 py-3 font-medium">License</th>
                      <th className="px-4 py-3 font-medium">Storage</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/8 text-sm">
                    {filteredSounds.map((sound) => (
                      <tr key={sound.id}>
                        <td className="px-4 py-4">
                          <div className="font-medium text-[var(--color-text)]">{sound.name}</div>
                          <div className="text-[var(--color-text-muted)]">{sound.durationLabel}</div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex flex-wrap gap-2">
                            <Badge tone="default">{sound.packName}</Badge>
                            <Badge tone={sound.status === 'approved' ? 'success' : 'warning'}>
                              {sound.status}
                            </Badge>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="text-[var(--color-text)]">{sound.licenseLabel}</div>
                          <div className="text-[var(--color-text-muted)]">{sound.sourceProvider}</div>
                        </td>
                        <td className="px-4 py-4 font-mono text-xs text-[var(--color-text-muted)]">
                          {sound.storagePath}
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
