import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { supabase } from './lib/supabase'
import { Sidebar } from './components/Sidebar'
import { ToastProvider, useToast } from './components/Toast'
import './App.css'

type Page = 'packs' | 'sounds' | 'users'

type PresetPack = { id: string; name: string; slug: string; is_active: boolean }
type PresetSound = { id: string; name: string; storage_path: string; pack_id: string }
type Profile = { id: string; display_name: string | null; onboarding_completed: boolean }

// ─── shared primitives ────────────────────────────────────────────────────────

function Card({ children, style }: { children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <div
      style={{
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        ...style,
      }}
    >
      {children}
    </div>
  )
}

function Badge({ children, variant = 'default' }: { children: React.ReactNode; variant?: 'default' | 'success' | 'danger' | 'muted' }) {
  const map = {
    default: { bg: 'var(--color-primary-muted)', color: 'var(--color-primary-hover)' },
    success: { bg: 'var(--color-success-muted)', color: 'var(--color-success)' },
    danger: { bg: 'var(--color-danger-muted)', color: 'var(--color-danger)' },
    muted: { bg: 'rgba(255,255,255,0.06)', color: 'var(--color-text-muted)' },
  }
  const { bg, color } = map[variant]
  return (
    <span
      style={{
        background: bg,
        color,
        fontSize: 11,
        fontWeight: 600,
        padding: '2px 8px',
        borderRadius: 9999,
        letterSpacing: '0.02em',
      }}
    >
      {children}
    </span>
  )
}

function Input({
  placeholder,
  value,
  onChange,
  style,
}: {
  placeholder?: string
  value: string
  onChange: (v: string) => void
  style?: React.CSSProperties
}) {
  return (
    <input
      placeholder={placeholder}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      style={{
        background: 'var(--color-surface-raised)',
        border: '1px solid var(--color-border)',
        borderRadius: 'var(--radius-sm)',
        padding: '8px 12px',
        color: 'var(--color-text)',
        fontSize: 13,
        outline: 'none',
        transition: 'border-color 150ms',
        ...style,
      }}
      onFocus={(e) => { e.currentTarget.style.borderColor = 'var(--color-primary)' }}
      onBlur={(e) => { e.currentTarget.style.borderColor = 'var(--color-border)' }}
    />
  )
}

function Select({
  value,
  onChange,
  children,
  style,
}: {
  value: string
  onChange: (v: string) => void
  children: React.ReactNode
  style?: React.CSSProperties
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      style={{
        background: 'var(--color-surface-raised)',
        border: '1px solid var(--color-border)',
        borderRadius: 'var(--radius-sm)',
        padding: '8px 12px',
        color: value ? 'var(--color-text)' : 'var(--color-text-muted)',
        fontSize: 13,
        outline: 'none',
        cursor: 'pointer',
        ...style,
      }}
    >
      {children}
    </select>
  )
}

function Btn({
  children,
  onClick,
  variant = 'primary',
  disabled = false,
}: {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'ghost' | 'danger'
  disabled?: boolean
}) {
  const styles: Record<string, React.CSSProperties> = {
    primary: {
      background: disabled ? 'rgba(99,102,241,0.4)' : 'var(--color-primary)',
      color: '#fff',
    },
    ghost: {
      background: 'transparent',
      color: 'var(--color-text-muted)',
      border: '1px solid var(--color-border)',
    },
    danger: {
      background: 'var(--color-danger-muted)',
      color: 'var(--color-danger)',
    },
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        padding: '8px 16px',
        borderRadius: 'var(--radius-sm)',
        border: 'none',
        fontSize: 13,
        fontWeight: 600,
        cursor: disabled ? 'not-allowed' : 'pointer',
        transition: 'opacity 150ms',
        opacity: disabled ? 0.6 : 1,
        ...styles[variant],
      }}
      onMouseEnter={(e) => { if (!disabled) e.currentTarget.style.opacity = '0.85' }}
      onMouseLeave={(e) => { e.currentTarget.style.opacity = '1' }}
    >
      {children}
    </button>
  )
}

function EmptyState({ message }: { message: string }) {
  return (
    <div
      style={{
        textAlign: 'center',
        padding: '48px 24px',
        color: 'var(--color-text-muted)',
        fontSize: 13,
      }}
    >
      <div style={{ fontSize: 32, marginBottom: 12, opacity: 0.4 }}>◌</div>
      {message}
    </div>
  )
}

function Spinner() {
  return (
    <div
      style={{
        width: 20,
        height: 20,
        border: '2px solid var(--color-border)',
        borderTopColor: 'var(--color-primary)',
        borderRadius: '50%',
        animation: 'spin 0.7s linear infinite',
      }}
    />
  )
}

function PageHeader({ title, subtitle, action }: { title: string; subtitle?: string; action?: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 28 }}>
      <div>
        <h1 style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--color-text)', margin: 0 }}>
          {title}
        </h1>
        {subtitle && (
          <p style={{ color: 'var(--color-text-muted)', fontSize: 13, marginTop: 4 }}>{subtitle}</p>
        )}
      </div>
      {action}
    </div>
  )
}

// ─── Packs page ───────────────────────────────────────────────────────────────

function PacksPage({ packs, loading, onRefresh }: { packs: PresetPack[]; loading: boolean; onRefresh: () => void }) {
  const { toast } = useToast()
  const [name, setName] = useState('')
  const [slug, setSlug] = useState('')
  const [saving, setSaving] = useState(false)
  const [showForm, setShowForm] = useState(false)

  async function handleCreate() {
    if (!supabase || !name.trim() || !slug.trim()) return
    setSaving(true)
    try {
      const { error } = await supabase.from('preset_packs').insert({ name: name.trim(), slug: slug.trim() })
      if (error) throw error
      toast(`Pack "${name}" created`, 'success')
      setName('')
      setSlug('')
      setShowForm(false)
      onRefresh()
    } catch (err) {
      toast(`Failed to create pack: ${(err as Error).message}`, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function toggleActive(pack: PresetPack) {
    if (!supabase) return
    const { error } = await supabase
      .from('preset_packs')
      .update({ is_active: !pack.is_active })
      .eq('id', pack.id)
    if (error) toast(error.message, 'error')
    else {
      toast(`Pack ${pack.is_active ? 'deactivated' : 'activated'}`, 'success')
      onRefresh()
    }
  }

  return (
    <div>
      <PageHeader
        title="Preset Packs"
        subtitle={`${packs.length} packs total`}
        action={
          <Btn onClick={() => setShowForm((v) => !v)}>
            {showForm ? 'Cancel' : '+ New Pack'}
          </Btn>
        }
      />

      {showForm && (
        <Card style={{ padding: 20, marginBottom: 20 }}>
          <div style={{ fontWeight: 600, marginBottom: 14, fontSize: 13 }}>New Preset Pack</div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>Pack Name *</label>
              <Input
                placeholder="e.g. Anime Sounds"
                value={name}
                onChange={(v) => {
                  setName(v)
                  if (!slug) setSlug(v.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''))
                }}
                style={{ width: 220 }}
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>Slug *</label>
              <Input
                placeholder="anime_sounds"
                value={slug}
                onChange={setSlug}
                style={{ width: 180 }}
              />
            </div>
            <Btn onClick={() => void handleCreate()} disabled={saving || !name || !slug}>
              {saving ? 'Saving…' : 'Create Pack'}
            </Btn>
          </div>
        </Card>
      )}

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
          <Spinner />
        </div>
      ) : packs.length === 0 ? (
        <Card>
          <EmptyState message="No preset packs yet. Create your first one above." />
        </Card>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(280px,1fr))', gap: 14 }}>
          {packs.map((pack) => (
            <PackCard key={pack.id} pack={pack} onToggle={() => void toggleActive(pack)} />
          ))}
        </div>
      )}
    </div>
  )
}

function PackCard({ pack, onToggle }: { pack: PresetPack; onToggle: () => void }) {
  return (
    <Card style={{ padding: 18 }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8, marginBottom: 10 }}>
        <div>
          <div style={{ fontWeight: 600, fontSize: 14, color: 'var(--color-text)', marginBottom: 3 }}>
            {pack.name}
          </div>
          <code style={{ fontSize: 11, color: 'var(--color-text-muted)', background: 'rgba(255,255,255,0.04)', padding: '2px 6px', borderRadius: 4 }}>
            {pack.slug}
          </code>
        </div>
        <Badge variant={pack.is_active ? 'success' : 'muted'}>
          {pack.is_active ? 'Active' : 'Inactive'}
        </Badge>
      </div>
      <div style={{ marginTop: 14, borderTop: '1px solid var(--color-border)', paddingTop: 12, display: 'flex', gap: 8 }}>
        <Btn variant="ghost" onClick={onToggle}>
          {pack.is_active ? 'Deactivate' : 'Activate'}
        </Btn>
      </div>
    </Card>
  )
}

// ─── Sounds page ──────────────────────────────────────────────────────────────

function SoundsPage({
  sounds,
  packs,
  loading,
  onRefresh,
}: {
  sounds: PresetSound[]
  packs: PresetPack[]
  loading: boolean
  onRefresh: () => void
}) {
  const { toast } = useToast()
  const [name, setSoundName] = useState('')
  const [path, setSoundPath] = useState('')
  const [packId, setSoundPackId] = useState('')
  const [saving, setSaving] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [filterPack, setFilterPack] = useState('')
  const [search, setSearch] = useState('')

  async function handleCreate() {
    if (!supabase || !name || !path || !packId) return
    setSaving(true)
    try {
      const { error } = await supabase.from('preset_sounds').insert({
        name: name.trim(),
        slug: name.trim().toLowerCase().replace(/\s+/g, '_'),
        storage_path: path.trim(),
        pack_id: packId,
        storage_bucket: 'preset-packs',
      })
      if (error) throw error
      toast(`Sound "${name}" added`, 'success')
      setSoundName('')
      setSoundPath('')
      setSoundPackId('')
      setShowForm(false)
      onRefresh()
    } catch (err) {
      toast(`Failed: ${(err as Error).message}`, 'error')
    } finally {
      setSaving(false)
    }
  }

  const packMap = Object.fromEntries(packs.map((p) => [p.id, p.name]))

  const filtered = sounds.filter((s) => {
    const matchesPack = filterPack ? s.pack_id === filterPack : true
    const matchesSearch = search
      ? s.name.toLowerCase().includes(search.toLowerCase()) ||
        s.storage_path.toLowerCase().includes(search.toLowerCase())
      : true
    return matchesPack && matchesSearch
  })

  return (
    <div>
      <PageHeader
        title="Sounds"
        subtitle={`${sounds.length} sounds total`}
        action={<Btn onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : '+ New Sound'}</Btn>}
      />

      {showForm && (
        <Card style={{ padding: 20, marginBottom: 20 }}>
          <div style={{ fontWeight: 600, marginBottom: 14, fontSize: 13 }}>New Sound Row</div>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>Sound Name *</label>
              <Input placeholder="e.g. Sword Slash" value={name} onChange={setSoundName} style={{ width: 200 }} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>Storage Path *</label>
              <Input placeholder="pack_slug/file.mp3" value={path} onChange={setSoundPath} style={{ width: 240 }} />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <label style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>Pack *</label>
              <Select value={packId} onChange={setSoundPackId} style={{ width: 180 }}>
                <option value="">Select pack…</option>
                {packs.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </Select>
            </div>
            <Btn onClick={() => void handleCreate()} disabled={saving || !name || !path || !packId}>
              {saving ? 'Saving…' : 'Add Sound'}
            </Btn>
          </div>
        </Card>
      )}

      {/* Filters */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 16, flexWrap: 'wrap' }}>
        <Input placeholder="Search sounds…" value={search} onChange={setSearch} style={{ width: 220 }} />
        <Select value={filterPack} onChange={setFilterPack} style={{ width: 180 }}>
          <option value="">All packs</option>
          {packs.map((p) => (
            <option key={p.id} value={p.id}>{p.name}</option>
          ))}
        </Select>
        {(search || filterPack) && (
          <Btn variant="ghost" onClick={() => { setSearch(''); setFilterPack('') }}>
            Clear
          </Btn>
        )}
      </div>

      <Card>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
            <Spinner />
          </div>
        ) : filtered.length === 0 ? (
          <EmptyState message={sounds.length === 0 ? 'No sounds yet.' : 'No sounds match your filters.'} />
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                {['Name', 'Pack', 'Storage Path'].map((h) => (
                  <th
                    key={h}
                    style={{
                      textAlign: 'left',
                      padding: '11px 16px',
                      fontSize: 11,
                      fontWeight: 600,
                      color: 'var(--color-text-muted)',
                      letterSpacing: '0.06em',
                      textTransform: 'uppercase',
                    }}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((sound, i) => (
                <tr
                  key={sound.id}
                  style={{
                    borderBottom: i < filtered.length - 1 ? '1px solid var(--color-border)' : 'none',
                    transition: 'background 120ms',
                  }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.025)' }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
                >
                  <td style={{ padding: '12px 16px', fontWeight: 500, fontSize: 13 }}>{sound.name}</td>
                  <td style={{ padding: '12px 16px' }}>
                    <Badge variant="default">{packMap[sound.pack_id] ?? sound.pack_id}</Badge>
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <code style={{ fontSize: 11, color: 'var(--color-text-muted)', background: 'rgba(255,255,255,0.04)', padding: '2px 6px', borderRadius: 4 }}>
                      {sound.storage_path}
                    </code>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  )
}

// ─── Users page ───────────────────────────────────────────────────────────────

function UsersPage({ users, loading }: { users: Profile[]; loading: boolean }) {
  const [search, setSearch] = useState('')

  const filtered = users.filter((u) => {
    const term = search.toLowerCase()
    return (
      !term ||
      u.id.toLowerCase().includes(term) ||
      (u.display_name ?? '').toLowerCase().includes(term)
    )
  })

  const done = users.filter((u) => u.onboarding_completed).length

  return (
    <div>
      <PageHeader title="Users" subtitle={`${users.length} total · ${done} onboarded`} />

      {/* Stats strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 12, marginBottom: 24 }}>
        {[
          { label: 'Total Users', value: users.length, variant: 'default' as const },
          { label: 'Onboarded', value: done, variant: 'success' as const },
          { label: 'Pending Onboarding', value: users.length - done, variant: 'warning' as const },
        ].map(({ label, value, variant }) => (
          <Card key={label} style={{ padding: '16px 20px' }}>
            <div style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 600, letterSpacing: '0.05em', textTransform: 'uppercase', marginBottom: 8 }}>
              {label}
            </div>
            <div
              style={{
                fontSize: 28,
                fontWeight: 700,
                letterSpacing: '-0.02em',
                color: variant === 'success' ? 'var(--color-success)' : variant === 'warning' ? 'var(--color-warning)' : 'var(--color-text)',
              }}
            >
              {value}
            </div>
          </Card>
        ))}
      </div>

      <div style={{ marginBottom: 14 }}>
        <Input placeholder="Search by name or user ID…" value={search} onChange={setSearch} style={{ width: 280 }} />
      </div>

      <Card>
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', padding: 60 }}>
            <Spinner />
          </div>
        ) : filtered.length === 0 ? (
          <EmptyState message="No users found." />
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                {['Display Name', 'User ID', 'Onboarding'].map((h) => (
                  <th
                    key={h}
                    style={{
                      textAlign: 'left',
                      padding: '11px 16px',
                      fontSize: 11,
                      fontWeight: 600,
                      color: 'var(--color-text-muted)',
                      letterSpacing: '0.06em',
                      textTransform: 'uppercase',
                    }}
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((user, i) => (
                <tr
                  key={user.id}
                  style={{
                    borderBottom: i < filtered.length - 1 ? '1px solid var(--color-border)' : 'none',
                    transition: 'background 120ms',
                  }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.025)' }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
                >
                  <td style={{ padding: '12px 16px', fontWeight: 500, fontSize: 13 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div
                        style={{
                          width: 30,
                          height: 30,
                          borderRadius: '50%',
                          background: 'var(--color-primary-muted)',
                          color: 'var(--color-primary-hover)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: 12,
                          fontWeight: 700,
                          flexShrink: 0,
                        }}
                      >
                        {(user.display_name ?? 'U').charAt(0).toUpperCase()}
                      </div>
                      {user.display_name ?? <span style={{ color: 'var(--color-text-muted)', fontStyle: 'italic' }}>No name</span>}
                    </div>
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <code style={{ fontSize: 11, color: 'var(--color-text-muted)', background: 'rgba(255,255,255,0.04)', padding: '2px 6px', borderRadius: 4 }}>
                      {user.id}
                    </code>
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <Badge variant={user.onboarding_completed ? 'success' : 'muted'}>
                      {user.onboarding_completed ? 'Done' : 'Pending'}
                    </Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  )
}

// ─── Root ─────────────────────────────────────────────────────────────────────

function AdminApp() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState<Page>('packs')

  const packsQuery = useQuery({
    queryKey: ['preset_packs'],
    queryFn: async () => {
      if (!supabase) return [] as PresetPack[]
      const { data, error } = await supabase
        .from('preset_packs')
        .select('id,name,slug,is_active')
        .order('created_at', { ascending: false })
      if (error) throw error
      return (data ?? []) as PresetPack[]
    },
  })

  const soundsQuery = useQuery({
    queryKey: ['preset_sounds'],
    queryFn: async () => {
      if (!supabase) return [] as PresetSound[]
      const { data, error } = await supabase
        .from('preset_sounds')
        .select('id,name,storage_path,pack_id')
        .order('created_at', { ascending: false })
      if (error) throw error
      return (data ?? []) as PresetSound[]
    },
  })

  const usersQuery = useQuery({
    queryKey: ['profiles_snapshot'],
    queryFn: async () => {
      if (!supabase) return [] as Profile[]
      const { data, error } = await supabase
        .from('profiles')
        .select('id,display_name,onboarding_completed')
        .limit(200)
      if (error) throw error
      return (data ?? []) as Profile[]
    },
  })

  const packs = packsQuery.data ?? []
  const sounds = soundsQuery.data ?? []
  const users = usersQuery.data ?? []

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <Sidebar active={page} onChange={(p) => setPage(p as Page)} />

      <main style={{ flex: 1, padding: '36px 40px', overflowY: 'auto', minWidth: 0 }}>
        {!supabase && (
          <div
            style={{
              background: 'var(--color-danger-muted)',
              border: '1px solid var(--color-danger)',
              color: 'var(--color-danger)',
              borderRadius: 'var(--radius-md)',
              padding: '12px 16px',
              marginBottom: 24,
              fontSize: 13,
            }}
          >
            <strong>Configuration missing:</strong> Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in .env.local
          </div>
        )}

        {page === 'packs' && (
          <PacksPage
            packs={packs}
            loading={packsQuery.isLoading}
            onRefresh={() => void queryClient.invalidateQueries({ queryKey: ['preset_packs'] })}
          />
        )}

        {page === 'sounds' && (
          <SoundsPage
            sounds={sounds}
            packs={packs}
            loading={soundsQuery.isLoading}
            onRefresh={() => void queryClient.invalidateQueries({ queryKey: ['preset_sounds'] })}
          />
        )}

        {page === 'users' && (
          <UsersPage users={users} loading={usersQuery.isLoading} />
        )}
      </main>
    </div>
  )
}

export default function App() {
  return (
    <ToastProvider>
      <AdminApp />
    </ToastProvider>
  )
}
